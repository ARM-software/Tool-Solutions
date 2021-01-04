#!/bin/bash

# This file is sourced byt the run.sh

local_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

post_process_output() {
    _=$1 # appname
    output_file=$2

    # Get tensor data from the output file
    tensor_data=$(get_tensor_data "$output_file")

    # Convert comma separated string into an array
    IFS=', ' read -r -a tensor_values <<< "$tensor_data"

    # This path is relative to run.sh at the same level of resources
    labels_file="$local_dir/labels.txt"

    for i in "${!tensor_values[@]}"; do
        class_num="$((i+1))"
        hex_value="${tensor_values[$i]}"
        dec_value=$(hex2dec "$hex_value")
        if [ "$dec_value" != "0" ]; then
            class=$(get_nth_line "$class_num" "$labels_file")
            probability=$(get_probability "$dec_value")
            printf "%s: %s%%\n" "$class" "$probability"
        fi
    done
}
