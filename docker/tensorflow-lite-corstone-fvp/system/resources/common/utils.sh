#!/bin/bash

hex2dec() {
    hex_value=$1
    printf "%d\n" "$hex_value"
}

get_nth_line() {
    num="$1"
    file="$2"
    sed "${num}q;d" "$file"
}

get_probability() {
    value=$1
    probability="$(bc <<< "scale=2; $value/255*100")"
    printf "%s" "$probability"
}

get_tensor_data() {
    output_file=$1

    # The output file has 0d0a line terminations (Windows)
    # Let bash replace the \r with the actual CR char inside $'...' construct
    # before passing it to sed
    data=$(sed $'s/\r//' "$output_file")

    # Filter the relevant data of the tensor
    tensor_data=$(sed -n '/"data":"/,/}]/{//!p;}' <<< "$data")

    # Remove all \n
    tensor_data=$(echo "$tensor_data" | tr -d '\n')

    printf "%s" "$tensor_data"
}
