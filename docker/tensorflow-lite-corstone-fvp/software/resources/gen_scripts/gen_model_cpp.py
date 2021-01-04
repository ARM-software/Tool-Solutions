# The confidential and proprietary information contained in this file may
# only be used by a person authorised under and to the extent permitted
# by a subsisting licensing agreement from ARM Limited or its affiliates.
#
# (C) COPYRIGHT 2020 ARM Limited or its affiliates.
# ALL RIGHTS RESERVED
#
# This entire notice must be reproduced on all copies of this file
# and copies of this file may only be made by a person if such person is
# permitted to do so under the terms of a subsisting license agreement
# from ARM Limited or its affiliates.

"""
Utility script to generate model c file that can be included in the
project directly. This should be called as part of cmake framework
should the models need to be generated at configuration stage.
"""

import os
from argparse import ArgumentParser
from pathlib import Path
from typing import IO

from gen_utils import write_license_header, write_autogen_comment, write_includes

parser = ArgumentParser()

parser.add_argument("--tflite_path", help="Model (.tflite) path", required=True)
parser.add_argument("--output_dir", help="Output directory", required=True)
parser.add_argument("--license_template", type=str, help="Path to the header template file",
                    default=os.path.join(os.path.dirname(os.path.realpath(__file__)),"header_template.txt"))

args = parser.parse_args()


def write_model(f: IO, tflite_path):
    write_includes(f, ['"Model.hpp"'])

    model_arr_name = "nn_model"
    f.write(f"static const uint8_t {model_arr_name}[] MODEL_TFLITE_ATTRIBUTE =")

    write_tflite_data(f, tflite_path)

    f.write(f"""

const uint8_t * GetModelPointer()
{{
    return {model_arr_name};
}}

size_t GetModelLen()
{{
    return sizeof({model_arr_name});
}}\n
""")


def write_tflite_data(f: IO, tflite_path):
    # Extract array elements

    bytes = model_hex_bytes(tflite_path)
    line = '{\n'
    i = 1
    while True:
        try:
            el = next(bytes)
            line = line + el + ', '
            if i % 20 == 0:
                line = line + '\n'
                f.write(line)
                line = ''
            i += 1
        except StopIteration:
            line = line[:-2] + '};\n'
            f.write(line)
            break


def model_hex_bytes(tflite_path):
    with open(tflite_path, 'rb') as tflite_model:
        byte = tflite_model.read(1)
        while byte != b"":
            yield f'0x{byte.hex()}'
            byte = tflite_model.read(1)


def main(args):
    if not os.path.isfile(args.tflite_path):
        raise Exception(f"{args.tflite_path} not found")

    # Cpp filename:
    cpp_filename = Path(os.path.join(args.output_dir, os.path.basename(args.tflite_path) + ".cc")).absolute()
    print(f"++ Converting {os.path.basename(args.tflite_path)} to\
    {os.path.basename(cpp_filename)}")

    os.makedirs(cpp_filename.parent, exist_ok=True)
    # Write file here
    with open(cpp_filename, "w") as f:
        write_license_header(f, args.license_template)
        write_autogen_comment(f, os.path.basename(__file__), os.path.basename(args.tflite_path))
        write_model(f, tflite_path = args.tflite_path)


if __name__ == '__main__':
    main(args)
