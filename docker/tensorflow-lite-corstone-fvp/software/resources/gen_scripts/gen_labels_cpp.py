#!env/bin/python3

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
Utility script to convert a given text file with labels (annotations for an
NN model output vector) into a vector list initialiser. The intention is for
this script to be called as part of the build framework to auto-generate the
cpp file with labels that can be used in the application without modification.
"""

from os import path
from argparse import ArgumentParser
from collections import namedtuple

from gen_utils import write_license_header, write_autogen_comment, write_includes, write_hex_array


def list_to_cpp_vec_list_initialiser(labels: list, indentation: int) -> str:
    """
    Converts a list of strings to a C++ styled list initialiser
    Parameters:
    labels (list): List of strings
    indentation (int): number of spaces for indentation for all lines

    Returns:
    string formatted as a C++ styled initaliser list.
    """

    space_indent = " " * indentation
    initaliser_list = "{\n"
    for label in labels:
        initaliser_list += space_indent + f'"{label.strip()}",\n'
    initaliser_list += space_indent + "};"
    return initaliser_list


def is_a_header_path(filename: str) -> bool:
    """
    Checks if the given filename conforms to standard C++ header
    file naming convention.
    """
    split_path = filename.split('.')

    if len(split_path) > 0 and split_path[-1] in ['h', 'hpp', 'hxx']:
        return True

    return False


parser = ArgumentParser()

# Label file path
parser.add_argument("--labels_file", type=str,
    help="Path to the label text file", required=True)

# Output file to be generated
parser.add_argument("--output_file", type=str,
    help="Path to required output file", required=True)

# License template
parser.add_argument("--license_template", type=str,
    help="Path to the header template file",
    default=path.join(path.dirname(path.realpath(__file__)),
        "header_template.txt"))

parser.add_argument("--desc", type=str,
    help="Description string to add as comments")

parser.add_argument("--vector_name", type=str,
    help="Name for the generated vector",
    default="labelsVec")

args = parser.parse_args()

def main(args):
    # Get the labels from text file
    labels = []
    with open(args.labels_file, "r") as f:
        labels = f.readlines()

    # No labels?
    if len(labels) == 0:
        raise Exception(f"no labels found in {args.label_file}")

    # write this list to file
    with open(args.output_file, "w", newline="") as f:
        # Write license header
        write_license_header(f, args.license_template)

        # Create a list of writable items
        line = namedtuple("line", ['string', 'lf_cnt'])

        write_autogen_comment(f, path.basename(__file__), path.basename(args.labels_file))

        # For the include guard (only if output is a header file)
        if is_a_header_path((path.basename(args.output_file))):
            f.write("#pragma once\n\n")

        # Description if provided:
        if args.desc is not None:
            f.write(args.desc+"\n\n")

        # includes
        write_includes(f, ["<vector>", "<string>"])

        # initialisation:
        strvec = f"static std::vector <std::string> {args.vector_name} = " +\
            list_to_cpp_vec_list_initialiser(labels, 4)
        f.write(strvec+"\n\n")

        # getter function
        getter_fn = f"""bool GetLabelsVector(std::vector<std::string>& labels)
        {{
            labels = {args.vector_name};
            return true;
        }}\n
        """
        f.write(getter_fn)


if __name__ == '__main__':
    main(args)