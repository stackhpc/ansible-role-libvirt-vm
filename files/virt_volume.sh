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

if [[ $# -ne 4 ]] && [[ $# -ne 5 ]]; then
    echo "Usage: $0 <name> <pool> <capacity> <format> [<image>]"
    exit 1
fi

NAME=$1
POOL=$2
CAPACITY=$3
FORMAT=$4
IMAGE=$5

# Check whether a volume with this name exists.
output=$(virsh vol-info --pool $POOL --vol $NAME 2>&1)
result=$?
if [[ $result -eq 0 ]]; then
    echo '{"changed": false}'
    exit 0
elif ! echo "$output" | grep 'Storage volume not found' >/dev/null 2>&1; then
    echo "Unexpected error while getting volume info"
    echo "$output"
    exit $result
fi

# Create the volume.
output=$(virsh vol-create-as --pool $POOL --name $NAME --capacity $CAPACITY --format $FORMAT 2>&1)
result=$?
if [[ $result -ne 0 ]]; then
    echo "Failed to create volume"
    echo "$output"
    exit $result
fi

# Determine the path to the volume file.
output=$(virsh vol-key --pool $POOL --vol $NAME 2>&1)
result=$?
if [[ $result -ne 0 ]]; then
    echo "Failed to get volume file path"
    echo "$output"
    virsh vol-delete --pool $POOL --vol $NAME
    exit $result
fi

# Change the ownership of the volume to qemu. Without doing this libvirt cannot
# access the volume.
output=$(chown qemu:qemu $output 2>1)
result=$?
if [[ $result -ne 0 ]]; then
    echo "Failed to change ownership of the volume to qemu"
    echo "$output"
    virsh vol-delete --pool $POOL --vol $NAME
    exit $result
fi

if [[ -n $IMAGE ]]; then
    # Upload an image to the volume.
    output=$(virsh vol-upload --pool $POOL --vol $NAME --file $IMAGE 2>&1)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo "Failed to upload image $IMAGE to volume $NAME"
        echo "$output"
        virsh vol-delete --pool $POOL --vol $NAME
        exit $result
    fi

    # Resize the volume to the requested capacity.
    output=$(virsh vol-resize --pool $POOL --vol $NAME --capacity $CAPACITY 2>&1)
    result=$?
    if [[ $result -ne 0 ]]; then
        echo "Failed to resize volume $VOLUME to $CAPACITY"
        echo "$output"
        virsh vol-delete --pool $POOL --vol $NAME
        exit $result
    fi
fi

echo '{"changed": true}'
exit 0
