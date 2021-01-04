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
Utility script to convert a set of RGB images in a given location into
corresponding cpp files and a single hpp file referencing the vectors
from the cpp files.
"""
import glob
import numpy as np
from os import path
from argparse import ArgumentParser
from PIL import Image

from gen_utils import write_license_header, write_autogen_comment, write_includes, write_hex_array

parser = ArgumentParser()
parser.add_argument("--image_folder_path", type=str, help="path to image folder to convert.")
parser.add_argument("--source_folder_path", type=str, help="path to source folder to be generated.")
parser.add_argument("--header_folder_path", type=str, help="path to header folder to be generated.")
parser.add_argument("--image_size", type=int, nargs=2, help="Size (width and height) of the converted images.")
parser.add_argument("--license_template", type=str, help="Path to the header template file",
                    default=path.join(path.dirname(path.realpath(__file__)),"header_template.txt"))
parser.add_argument("-v", "--verbosity", action="store_true")
args = parser.parse_args()


def write_hpp_file(header_file_path, header_template_file, num_images, image_filenames,
        image_array_names, image_size):

    with open(header_file_path, "w") as f:
        write_license_header(f, header_template_file)
        write_autogen_comment(f, path.basename(__file__), path.basename(header_file_path))

        header_guard = "\n#ifndef GENERATED_IMAGES_H\n#define GENERATED_IMAGES_H\n\n"
        f.write(header_guard)

        write_includes(f, ['<cstdint>'])

        define_number_images = "\n#define NUMBER_OF_IMAGES  ("+ str(num_images) +"U)\n"
        f.write(define_number_images)

        define_imsize = '\n#define IMAGE_DATA_SIZE  (' +\
            str(image_size[0] * image_size[1] * 3) + 'U)\n\n'
        f.write(define_imsize)

        start_filenames_vector = "static const char *img_filenames[] = {"
        f.write(start_filenames_vector)

        files_list = ['\n    "' + item + '"' for item in image_filenames]
        filenames_list = ', '.join(files_list)
        f.write(filenames_list)

        f.write('\n};\n\n')

        extern_declarations = [f"extern const uint8_t {arr_name}[];\n" for arr_name in image_array_names]
        f.writelines(extern_declarations)
        f.write('\n')

        imgarr_names_vector = 'static const uint8_t *img_arrays[] = {\n    ' +\
            (',\n    ').join(image_array_names) + '\n};\n\n'
        f.write(imgarr_names_vector)

        end_header_guard = "\n#endif // GENERATED_IMAGES_H\n"
        f.write(end_header_guard)


def write_cc_file(image_filename, cc_filename, headerfiles, header_template_file, original_image,
        image_size, array_name):
    print(f"++ Converting {image_filename} to {path.basename(cc_filename)}")

    with open(cc_filename, "w") as f:
        # Write the headers string, note
        write_license_header(f, header_template_file)
        write_autogen_comment(f, path.basename(__file__), path.basename(image_filename))
        write_includes(f, headerfiles)

        # Resize the image, in order to avoid skew the image
        # the new size is calculated maintaining the aspect ratio and then pad on just one axis if necessary
        original_image.thumbnail(image_size)
        delta_w = abs(image_size[0] - original_image.size[0])
        delta_h = abs(image_size[1] - original_image.size[1])
        resized_image = Image.new('RGB', args.image_size, (255, 255, 255, 0))
        resized_image.paste(original_image, (int(delta_w / 2), int(delta_h / 2)))

        # Convert the image and write it to the cc file
        rgb_data = np.array(resized_image, dtype=np.uint8).flatten()
        feature_vec_define = "const uint8_t "+ array_name + "[] IFM_BUF_ATTRIBUTE = "
        f.write(feature_vec_define)
        write_hex_array(f, rgb_data)


def main(args):
    # Keep the count of the images converted
    image_idx = 0
    image_filenames = []
    image_array_names = []
    header_filename = "Images.hpp"
    headerfiles_to_inc = [f'"{header_filename}"',
                           '"BufAttributes.hpp"',
                           '<cstdint>']
    header_filepath = path.join(args.header_folder_path, header_filename)

    for filepath in sorted(glob.glob(path.join(args.image_folder_path, '**/*.*'), recursive=True)):
        filename = path.basename(filepath)
        try:
            original_image = Image.open(filepath).convert("RGB")
            image_filenames.append(filename)

            # Save the cc file
            cc_filename = path.join(args.source_folder_path,
                (filename.rsplit(".")[0]).replace(" ","_")+".cc")
            array_name = "im" + str(image_idx)
            image_array_names.append(array_name)
            write_cc_file(filename, cc_filename, headerfiles_to_inc, args.license_template,
                original_image, args.image_size, array_name)

            # Increment image index
            image_idx = image_idx + 1
        except:
            if args.verbosity:
                print(f"Failed to open {filename} as an image..")

    write_hpp_file(header_filepath, args.license_template, image_idx, image_filenames, image_array_names,
        args.image_size)


if __name__ == '__main__':
    main(args)
