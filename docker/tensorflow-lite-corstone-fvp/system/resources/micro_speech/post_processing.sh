#!/bin/bash

post_process_output() {
    _=$1 # appname
    output_file=$2

    # Get tensor data from the output file
    tensor_data=$(get_tensor_data "$output_file")

    # Convert comma separated string into an array
    IFS=', ' read -r -a tensor_values <<< "$tensor_data"

    # Micro speech returns 4 classes with probability
    printf "Silence: %s%%\n" "$(get_probability "$(hex2dec "${tensor_values[0]}")")"
    printf "Unknown: %s%%\n" "$(get_probability "$(hex2dec "${tensor_values[1]}")")"
    printf "Yes    : %s%%\n" "$(get_probability "$(hex2dec "${tensor_values[2]}")")"
    printf "No     : %s%%\n" "$(get_probability "$(hex2dec "${tensor_values[3]}")")"
}
