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

# Ensure that a libvirt volume does not exists.
# On success, output a JSON object with a 'changed' item.

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <name> <pool>"
    exit 1
fi

NAME=$1
POOL=$2

# Check whether a volume with this name exists.
output=$(virsh vol-info --pool $POOL --vol $NAME 2>&1)
result=$?
if [[ $result -ne 0 ]]; then
    if echo "$output" | grep 'Storage volume not found' >/dev/null 2>&1; then
        echo '{"changed": false}'
        exit 0
    else
        echo "Unexpected error while getting volume info"
        echo "$output"
        exit $result
    fi
fi

# Delete the volume.
output=$(virsh vol-delete --pool $POOL --vol $NAME 2>&1)
result=$?
if [[ $result -ne 0 ]]; then
    echo "Failed to delete volume"
    echo "$output"
    exit $result
fi

echo '{"changed": true}'
exit 0
