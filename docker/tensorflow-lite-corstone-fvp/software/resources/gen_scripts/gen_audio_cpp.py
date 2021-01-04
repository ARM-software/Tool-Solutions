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
Utility script to convert a set of audio clip in a given location into
corresponding cpp files and a single hpp file referencing the vectors
from the cpp files.
"""
import glob
import numpy as np
from os import path
from argparse import ArgumentParser

from gen_utils import write_license_header, write_autogen_comment, write_includes, write_hex_array, prepare_audio_clip

parser = ArgumentParser()
parser.add_argument("--audio_folder_path", type=str, help="path to audio folder to convert.")
parser.add_argument("--source_folder_path", type=str, help="path to source folder to be generated.")
parser.add_argument("--header_folder_path", type=str, help="path to header folder to be generated.")
parser.add_argument("--sampling_rate", type=int, help="target sampling rate.", default=16000)
parser.add_argument("--mono", type=bool, help="convert signal to mono.", default=True)
parser.add_argument("--offset", type=float, help="start reading after this time (in seconds).", default=0)
parser.add_argument("--duration", type=float, help="only load up to this much audio (in seconds).", default=0)
parser.add_argument("--res_type", type=str, help="Resample type.", default='kaiser_best')
parser.add_argument("--min_samples", type=int, help="Minimum sample number.", default=16000)
parser.add_argument("--license_template", type=str, help="Path to the header template file",
                    default=path.join(path.dirname(path.realpath(__file__)),"header_template.txt"))
parser.add_argument("-v", "--verbosity", action="store_true")
args = parser.parse_args()


def write_hpp_file(header_file_path, header_template_file, num_audios, audio_filenames,
        audio_array_namesizes):

    with open(header_file_path, "w") as f:
        write_license_header(f, header_template_file)
        write_autogen_comment(f, path.basename(__file__), path.basename(header_file_path))

        header_guard = "\n#ifndef GENERATED_AUDIOCLIPS_H\n#define GENERATED_AUDIOCLIPS_H\n\n"
        f.write(header_guard)

        write_includes(f, ['<cstdint>'])

        define_number_audios = "\n#define NUMBER_OF_AUDIOCLIPS  ("+ str(num_audios) +"U)\n"
        f.write(define_number_audios)

        start_filenames_vector = "static const char *audio_clip_filenames[] = {"
        f.write(start_filenames_vector)

        files_list = ['\n    "' + item + '"' for item in audio_filenames]
        filenames_list = ', '.join(files_list)
        f.write(filenames_list)

        f.write('\n};\n\n')

        extern_declarations = [f"extern const int16_t {arr_name[0]}[{arr_name[1]}];\n" for arr_name in audio_array_namesizes]
        f.writelines(extern_declarations)
        f.write('\n')

        imgarr_names_vector = 'static const int16_t *audio_clip_arrays[] = {\n    ' +\
            (',\n    ').join(f"{arr_name[0]}" for arr_name in audio_array_namesizes) + '\n};\n\n'
        f.write(imgarr_names_vector)

        end_header_guard = "\n#endif // GENERATED_AUDIOCLIPS_H\n"
        f.write(end_header_guard)


def write_cc_file(clip_filename, cc_filename, headerfiles, header_template_file, array_name,
                  sampling_rate_value, mono_value, offset_value, duration_value, res_type_value, min_len):
    print(f"++ Converting {clip_filename} to {path.basename(cc_filename)}")

    with open(cc_filename, "w") as f:
        # Write the headers string, note
        write_license_header(f, header_template_file)
        write_autogen_comment(f, path.basename(__file__), path.basename(clip_filename))
        write_includes(f, headerfiles)

        clip_data, samplerate = prepare_audio_clip(path.join(args.audio_folder_path,clip_filename),sampling_rate_value, mono_value, offset_value, duration_value, res_type_value, min_len)
        clip_data = (((clip_data+1)/2)*(2**16-1)-2**15).flatten().astype(np.int16)

        # Convert the audio and write it to the cc file
        feature_vec_define = f"const int16_t {array_name} [{len(clip_data)}] IFM_BUF_ATTRIBUTE = "
        f.write(feature_vec_define)
        write_hex_array(f, clip_data)
        return len(clip_data)


def main(args):
    # Keep the count of the audio files converted
    audioclip_idx = 0
    audioclip_filenames = []
    audioclip_array_names = []
    header_filename = "AudioClips.hpp"
    headerfiles_to_inc = [f'"{header_filename}"',
                           '"BufAttributes.hpp"',
                           '<cstdint>']
    header_filepath = path.join(args.header_folder_path, header_filename)

    for filepath in sorted(glob.glob(path.join(args.audio_folder_path, '**/*.wav'), recursive=True)):
        filename = path.basename(filepath)
        try:
            audioclip_filenames.append(filename)

            # Save the cc file
            cc_filename = path.join(args.source_folder_path,
                (filename.rsplit(".")[0]).replace(" ","_")+".cc")
            array_name = "audio" + str(audioclip_idx)
            array_size = write_cc_file(filename, cc_filename, headerfiles_to_inc, args.license_template, array_name,
                                        args.sampling_rate, args.mono, args.offset,
                                        args.duration, args.res_type, args.min_samples)

            audioclip_array_names.append([array_name,array_size])
            # Increment audio index
            audioclip_idx = audioclip_idx + 1
        except:
            if args.verbosity:
                print(f"Failed to open {filename} as an audio.")

    write_hpp_file(header_filepath, args.license_template, audioclip_idx, audioclip_filenames, audioclip_array_names)


if __name__ == '__main__':
    main(args)
