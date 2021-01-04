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
Utility script to convert an audio clip into eval platform desired spec.
"""
import soundfile as sf

from argparse import ArgumentParser
from os import path

from gen_utils import prepare_audio_clip

parser = ArgumentParser()
parser.add_argument("--audio_file_path", help="Audio file path", required=True)
parser.add_argument("--output_dir", help="Output directory", required=True)
parser.add_argument("--sampling_rate", type=int, help="target sampling rate.", default=16000)
parser.add_argument("--mono", type=bool, help="convert signal to mono.", default=True)
parser.add_argument("--offset", type=float, help="start reading after this time (in seconds).", default=0)
parser.add_argument("--duration", type=float, help="only load up to this much audio (in seconds).", default=0)
parser.add_argument("--res_type", type=str, help="Resample type.", default='kaiser_best')
parser.add_argument("--min_samples", type=int, help="Minimum sample number.", default=16000)
parser.add_argument("-v", "--verbosity", action="store_true")
args = parser.parse_args()

def main(args):
    audio_data, samplerate = prepare_audio_clip(args.audio_file_path,
                                                args.sampling_rate,
                                                args.mono,  args.offset,
                                                args.duration, args.res_type,
                                                args.min_samples)
    sf.write(path.join(args.output_dir, path.basename(args.audio_file_path)), audio_data, samplerate)

if __name__ == '__main__':
    main(args)