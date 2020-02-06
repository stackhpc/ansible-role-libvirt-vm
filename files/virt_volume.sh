#!/bin/bash

# Copyright (c) 2017 StackHPC Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Ensure that a libvirt volume exists, optionally uploading an image.
# On success, output a JSON object with a 'changed' item.

# Parse options
OPTIND=1

while getopts ":n:p:c:f:i:b:a:" opt; do
    case ${opt} in
        n) NAME=$OPTARG;;
        p) POOL=$OPTARG;;
        c) CAPACITY=$OPTARG;;
        f) FORMAT=$OPTARG;;
        i) IMAGE=$OPTARG;;
        b) BACKING_IMAGE=$OPTARG;;
        a) CHECK=$OPTARG;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Check options
if ! [[ -n $NAME && -n $POOL && -n $CAPACITY ]]; then
    echo "Missing manditory options"  >&2
    echo "Usage: $0 -n <name> -p <pool> -c <capacity> [-f <format>] [-i <source image> | -b <backing image>]"
    exit 1
fi
if [[ -n $IMAGE && -n $BACKING_IMAGE ]]; then
  echo "Options -i and -b are mutually exclusive" >&2
  exit 1
fi
if [[ -z "$FORMAT" ]]; then
    FORMAT='qcow2'
fi


# Check whether a volume with this name exists.
output=$(virsh vol-info --pool "$POOL" --vol "$NAME" 2>&1)
result=$?
if [[ $result -eq 0 ]]; then
    echo '{"changed": false}'
    exit 0
fi

# Stop here in check mode, there will be a change
if [[ $CHECK = "True" ]]; then
    echo '{"changed": true}'
    exit 0
fi

# Create the volume.
if [[ -n $BACKING_IMAGE ]]; then
    if [[ "$FORMAT" != 'qcow2' ]]; then
        echo "qcow2 format assumed for backing images, but $FORMAT format was supplied."
        exit 1
    fi
    output=$(virsh vol-create-as --pool "$POOL" --name "$NAME" --capacity "$CAPACITY" --format "$FORMAT" --backing-vol "$BACKING_IMAGE" --backing-vol-format "$FORMAT" 2>&1)
    result=$?
else
    output=$(virsh vol-create-as --pool "$POOL" --name "$NAME" --capacity "$CAPACITY" --format "$FORMAT" 2>&1)
    result=$?
fi
if [[ $result -ne 0 ]]; then
    echo "Failed to create volume"
    echo "$output"
    exit $result
fi

# Determine the path to the volume file.
output=$(virsh vol-key --pool "$POOL" --vol "$NAME" 2>&1)
result=$?
if [[ $result -ne 0 ]]; then
    echo "Failed to get volume file path"
    echo "$output"
    virsh vol-delete --pool "$POOL" --vol "$NAME"
    exit $result
fi

# Change the ownership of the volume to VOLUME_OWNER:VOLUME_GROUP if
# these environmental variables are defined. Without doing this libvirt
# cannot access the volume on RedHat based GNU/Linux distributions.
# Avoid attempting to change permissions on volumes that are not file or
# directory based
if [[ -f "$output" || -d "$output" ]]; then
    existing_owner="$(stat --format '%U' "$output")"
    existing_group="$(stat --format '%G' "$output")"
    new_owner="${VOLUME_OWNER:-$existing_owner}"
    new_group="${VOLUME_GROUP:-$existing_group}"
    output=$(chown "$new_owner":"$new_group" "$output" 2>&1)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo "Failed to change ownership of the volume to $new_owner:$new_group"
        echo "$output"
        virsh vol-delete --pool "$POOL" --vol "$NAME"
        exit $result
    fi
fi

if [[ -n $IMAGE ]]; then
    # Upload an image to the volume.
    output=$(virsh vol-upload --pool "$POOL" --vol "$NAME" --file "$IMAGE" 2>&1)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo "Failed to upload image $IMAGE to volume $NAME"
        echo "$output"
        virsh vol-delete --pool "$POOL" --vol "$NAME"
        exit $result
    fi

    # Resize the volume to the requested capacity. Attempting to resize a raw volume
    # to the same capacity will result in failure, see:
    # https://github.com/stackhpc/ansible-role-libvirt-vm/issues/23
    if [ "${FORMAT,,}" != "raw" ]; then
      output=$(virsh vol-resize --pool "$POOL" --vol "$NAME" --capacity "$CAPACITY" 2>&1)
      result=$?
      if [[ $result -ne 0 ]]; then
          echo "Failed to resize volume $VOLUME to $CAPACITY"
          echo "$output"
          virsh vol-delete --pool "$POOL" --vol "$NAME"
          exit $result
      fi
    fi
fi

echo '{"changed": true}'
exit 0
