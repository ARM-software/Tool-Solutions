#!/usr/bin/env python

import pygame
import pygame.camera
from pygame.locals import *
from PIL import Image
import subprocess
from shutil import rmtree
import os
from os import path, mkdir
from collections import namedtuple
import re
import logging
from argparse import ArgumentParser
import requests
from itertools import cycle
import PySimpleGUI as sg
import io
import base64
import time
import numpy as np
import math

# the path of this file
where_am_i = path.dirname(path.abspath(__file__))
eval_kit_base = path.join(where_am_i, "dependencies/ml-embedded-evaluation-kit")

usecase = "person_detection"
image_path = f"{eval_kit_base}/resources/{usecase}/samples/"
use_camera = False

format = "[%(levelname)s] %(message)s"
logging.basicConfig(format=format, level=logging.DEBUG)

def InputArguments():
    """
    Example usage
    """
    global usecase
    global image_path
    global use_camera

    parser = ArgumentParser(description="Build and run Ethos Evaluation Samples")
    parser.add_argument('--usecase', type=str, default=usecase,
                        help='Application to run')
    parser.add_argument('--use_camera', type=bool, default=False,
                        help='Use a camera feed as input')
    parser.add_argument('--image_path', type=str, default="",
                        help='Path to image or folder to use in inference (baked into application)')
    #parser.add_argument('--log_file', type=str, default="/tmp/run_log.txt",
    #                    help="Log file path")
    args = parser.parse_args()
    
    
    usecase = args.usecase
    if len(args.image_path):
        image_path = args.image_path
    else:
        image_path = f"{eval_kit_base}/resources/{usecase}/samples/"
    use_camera = args.use_camera 

class build_samples:
    def __init__(self):

        self.platform_name = "mps3"
        self.platform_subsystem = "sse-300"
        self.platform_toolchain = "scripts/cmake/bare-metal-toolchain.cmake"
        self._cmakelist_path = path.join(eval_kit_base, "CMakeLists.txt")
        self._bin_dir = ""


    def _generate_configure_args(self, extra_build_args: dict = {}) -> list:
        """
        Generates a list of configuration string
        Args:
            extra_build_args:   additional build argument for cmake as a dict
        Returns: list of configuration options to be passed to cmake
        """
        extra_build_arg_string = ""

        for key, value in extra_build_args.items():
            extra_build_arg_string += f' -D{key}={value}'

        _build_args = [
                "-DCMAKE_BUILD_TYPE=Release",
                f"-DTARGET_PLATFORM={self.platform_name}",
                f"-DTARGET_SUBSYSTEM={self.platform_subsystem}",
                f"-DCMAKE_TOOLCHAIN_FILE={self.platform_toolchain}",
                f"{extra_build_arg_string}"
            ]

        return _build_args                                  

    def get_build_dir(self) -> str:
        # check if we are in docker. 
        # this will change the build directory
        docker_check = subprocess.run("grep \"docker\|lxc\" /proc/1/cgroup", shell=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.decode('utf-8')

        build_dir = f'build-{self.platform_name}'

        if len(self.platform_subsystem):
            build_dir += f'-{self.platform_subsystem}'

        if(len(docker_check)):
            build_dir += f'-docker'

        build_dir_root = path.dirname(self._cmakelist_path)
        build_dir = path.join(build_dir_root, build_dir)

        return build_dir

    def cmake_is_configured_correctly(self, extra_build_args: dict) -> bool:
        build_dir = self.get_build_dir()
        command_str = "cmake -N -L"
        command_return = subprocess.run(command_str, shell=True, cwd=build_dir,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.decode('utf-8')
        
        logging.info("Checking cmake configuration")

        for key, value in extra_build_args.items():
            result = re.search(f"{key}(.*)", command_return)
            if result == None or value not in result.group(1):
                return False
         
        logging.info("Cmake configuration OK")

        return True

    def build_vela_model(self):
        global usecase
        global MODEL_VELA
        logging.debug("Optimizing model with vela")
        MODEL = path.join(eval_kit_base, "resources/person_detection/models/person_detection.tflite")
        if usecase == "person_detection":
            MODEL = path.join(eval_kit_base, "resources/person_detection/models/person_detection.tflite")
        elif usecase == "img_class":
            MODEL = path.join(eval_kit_base, "mobilenet_v2_1.0_224_quantized.tflite")
            if not path.exists(MODEL):
                url = 'https://github.com/ARM-software/ML-zoo/raw/68b5fbc77ed28e67b2efc915997ea4477c1d9d5b/models/image_classification/mobilenet_v2_1.0_224/tflite_uint8/mobilenet_v2_1.0_224_quantized_1_default_1.tflite'
                r = requests.get(url, allow_redirects=True)
                open(MODEL, 'wb').write(r.content)
        MODEL_VELA_DIR = path.dirname(MODEL_VELA)
        command_str = f"vela {MODEL} --output-dir={MODEL_VELA_DIR} --accelerator-config=ethos-u55-128 --block-config-limit=0 --config {eval_kit_base}/scripts/vela/vela.ini --memory-mode Shared_Sram --system-config Ethos_U55_High_End_Embedded"
        command_return = subprocess.run(command_str, shell=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT).stdout.decode('utf-8')
        logging.debug(command_return)

    def download_source(self):
        logging.info("Cloning ml-embedded-evaluation-kit source tree")
        command_string = f"git clone -b 21.03 --recursive https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git {eval_kit_base}"
        proc = subprocess.POpen(command_string, shell=True)
        proc.communicate()


    def build(self, extra_build_args: dict = {}) -> bool:
        """
        Configure and build the project using model path
        Args:
            extra_build_args:   additional build argument for cmake a dict
        """
        # check if source exists, if not, download
        if not path.exists(eval_kit_base):
            #download
            self.download_source()
            exit()

        # apply patch        
        logging.debug("applying patch")
        command_string = f"( cd {eval_kit_base}; patch -p1 --forward -b -r /dev/null < {where_am_i}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch )"
        proc = subprocess.run(command_string, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        # copy user samples to the source tree
        from distutils.dir_util import copy_tree
        logging.debug("copying user samples to code tree")
        copy_tree(f"{where_am_i}/sw/ml-eval-kit/samples/", f"{eval_kit_base}/")

        global MODEL_VELA
        if not path.exists(MODEL_VELA):
            self.build_vela_model()

        _build_log = ""
        build_dir = self.get_build_dir()

        if path.isdir(build_dir) == False:
            mkdir(build_dir)

        skip_cmake = self.cmake_is_configured_correctly(extra_build_args)

        if not skip_cmake:
            
            relative_cmakefile_path = path.dirname(
                                        path.relpath(self._cmakelist_path, build_dir))
            configuration_opts = self._generate_configure_args(extra_build_args)
            args = ['cmake'] + configuration_opts + [relative_cmakefile_path]
            
            command_str = " ".join(args)
            logging.info(f'Configuring cmake project...')

            for opts in configuration_opts:
                logging.info(f'\t{opts}')
            build_state = subprocess.run(command_str, shell=True, cwd=build_dir,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            _build_log = build_state.stdout.decode('utf-8')

        build_done = False
        if skip_cmake or 0 == build_state.returncode:
            logging.info('Building project...')
            build_state = subprocess.run('make -j', shell=True, cwd=build_dir,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            _build_log += build_state.stdout.decode('utf-8')
            if 0 == build_state.returncode:
                _build_dir = build_dir
                self._bin_dir = path.join(build_dir, 'bin')
                build_done  = True
                logging.debug(_build_log)

        # Revert patch
        command_string = f"( cd {eval_kit_base}; patch -p1 -R < {where_am_i}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch )"
        proc = subprocess.run(command_string, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        logging.debug("reverting applied patch")

        if not build_done:
            logging.debug(_build_log)
            logging.error('Build failed')

        return build_done

class InferenceGUI:
    def __init__(self):
        # Left column will show the inference result
        self.left_col = [[sg.Text('Inference Results', key='-INFERENCE-')],
                    [sg.Text('No inference Performed yet',size=(30,10), key='-RESULT-')]]
        # HRight column will show the inference image
        self.images_col = [[sg.Text('Inference Image:')],
                    [sg.Text(size=(40,1), key='-IMAGE_NAME-')],
                    [sg.Image(key='-IMAGE-')]]
        # Combile to layout
        self.layout = [[sg.Column(self.left_col, element_justification='c'), sg.VSeperator(),sg.Column(self.images_col, element_justification='c')]]
        # Window creation
        self.window = sg.Window('Multiple Format Image Viewer', self.layout,resizable=True, finalize=True)

    def convert_to_bytes(self, file_or_bytes, resize=None):
        '''
        Will convert into bytes and optionally resize an image that is a file or a base64 bytes object.
        Turns into  PNG format in the process so that can be displayed by tkinter
        :param file_or_bytes: either a string filename or a bytes base64 image object
        :type file_or_bytes:  (Union[str, bytes])
        :param resize:  optional new size
        :type resize: (Tuple[int, int] or None)
        :return: (bytes) a byte-string object
        :rtype: (bytes)
        '''
        if isinstance(file_or_bytes, str):
            img = Image.open(file_or_bytes)
        else:
            img = file_or_bytes
        cur_width, cur_height = img.size
        if resize:
            new_width, new_height = resize
            scale = min(new_height/cur_height, new_width/cur_width)
            img = img.resize((int(cur_width*scale), int(cur_height*scale)), Image.ANTIALIAS)
        bio = io.BytesIO()
        img.save(bio, format="PNG")
        del img
        return bio.getvalue()

    # Update the GUI with image or inference text
    def update_window(self, field, file_or_bytes) -> bool:
        event, values = self.window.read(timeout=1)
        if event in (sg.WIN_CLOSED, 'Exit'):
            return False
        if event == sg.WIN_CLOSED or event == 'Exit':
            return False
        if field == "image":
            try:
                new_size = (256,256)
                self.window['-IMAGE-'].update(data=self.convert_to_bytes(file_or_bytes, resize=new_size))
                logging.info("updating IMAGE")
                self.window.finalize()
            except Exception as E:
                print(f'** Error {E} **')
                return False    # something weird happened making the full filename
        elif field == "image_name":
            try:
                self.window['-IMAGE_NAME-'].update(file_or_bytes)
                logging.info("updating IMAGE_NAME")
                self.window.finalize()
            except Exception as E:
                print(f'** Error {E} **')
                return False    # something weird happened making the full filename
        elif field == "result":
            try:
                self.window['-RESULT-'].update(file_or_bytes)
                logging.info("updating RESULT")
                self.window.finalize()
            except Exception as E:
                print(f'** Error {E} **')
                return False    # something weird happened making the full filename
        return True


# fvp runner will run the FVP with the sample application
class fvp_runner:
    def __init__(self, bin_dir: str):
        self._bin_dir = bin_dir
        self._fvp_exec_path = "FVP_Corstone_SSE-300_Ethos-U55"
        self._cli_args = "-C ethosu.num_macs=128 -C mps3_board.telnetterminal0.start_telnet=0 -C mps3_board.uart0.out_file='-' -C mps3_board.uart0.shutdown_on_eot=1 -C mps3_board.visualisation.disable-visualisation=1 --stat"
        self._axf_path = path.join(self._bin_dir, f"ethos-u-{usecase}.axf")


    def _run_simulation(self, timeout: int) -> str:
        """
        Runs the executable in a subprocess
        """
        logging.info("Starting inference\n")
        isim_timeout_cmd = f'--timelimit {timeout}'
        hex_file_cmd = f'-a python_img.hex'
        axf_cmd = f'-a {self._axf_path}'
        # CLI command
        cmd = ' '.join([self._fvp_exec_path, self._cli_args,
                        isim_timeout_cmd, axf_cmd, 
                        hex_file_cmd])
        logging.debug(f"running command = {cmd}\n")
        logging.info('Starting simulation environment... It may take a while to run depending on usecase. Be patient')
        state = subprocess.run(cmd, shell=True, cwd=where_am_i,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        _simulation_log = state.stdout.decode('utf-8')
        logging.debug(_simulation_log)

        # get the inference result string
        result = re.search(r'(?<=\[INFO\] Profile for Inference: \r\n)(.*?)(?=\[INFO\] Main loop terminated.)', _simulation_log, flags=re.S).group()

        # strip the result of unecessary line endings, tabs and tags
        result = result.replace("[INFO] ", "")
        result = result.replace("\t", "")
        result = result.replace("\r\n", "\n")

        return result

# Parse CLI argument
InputArguments()

# Sample build variables
MODEL_VELA = path.join(eval_kit_base, "output/person_detection_vela.tflite")
if usecase == "person_detection":
    MODEL_VELA = path.join(eval_kit_base, "output/person_detection_vela.tflite")
elif usecase == "img_class":
    MODEL_VELA = path.join(eval_kit_base, "output/mobilenet_v2_1.0_224_quantized_vela.tflite")

_extra_build_args = {
        "USE_CASE_BUILD" : f"\"{usecase}\"",
        f"{usecase}_MODEL_TFLITE_PATH" : MODEL_VELA ,
        f"{usecase}_FILE_PATH" : path.join(image_path, "cat.bmp")
    }

#build the samples
builder = build_samples()
if not builder.build(_extra_build_args):
    logging.error("Building samples failed, exiting...")
    exit()

# image format for the usecase
image_size = (96,96)
image_format = "L"
if usecase == "img_class":
    image_size = (224,224)
    image_format = "RGB"

# get a cycle list of all images in image_path
image_list = []
valid_images = [".jpg",".jpeg",".gif",".png",".tga",".bmp"]
for f in os.listdir(image_path):
    ext = path.splitext(f)[1]
    if ext.lower() not in valid_images:
        continue
    image_list.append(path.join(image_path, f))
image_pool = cycle(image_list)

# Create runner
runner = fvp_runner(builder._bin_dir)

# if we use camera, init camera
if use_camera:
    pygame.init()
    pygame.camera.init()
    camlist = pygame.camera.list_cameras()
    if camlist:
        cam = pygame.camera.Camera(camlist[0],(640,480))
        cam.start()
        image_name = "camera feed"
    else:
        logging.warning("No camera found, falling back to images instead")
        use_camera = False

# create window
window = InferenceGUI()

running = True

# main loop
while running:
    if not use_camera: # iterate through images in image_path
        image_name = next(image_pool)
        image = Image.open(image_name, mode='r')
    else: # get input image from camera
        camimage = cam.get_image()
        strFormat = 'RGBA'
        raw_str = pygame.image.tostring(camimage, strFormat, False)
        image = Image.frombytes(strFormat, camimage.get_size(), raw_str)
        image.show()

    # resize image to use case size
    resized_image = image.resize(image_size)
    resized_image = resized_image.convert(image_format)

    # write image to .hex-file, to send into FVP dynamically
    rgb_data = np.array(resized_image, dtype=np.uint8).flatten()
    with open("python_img.hex", 'w') as f:
        address = int("70000000", base=16)
        for val in rgb_data:
            f.write(f'@{hex(address)} {hex(val)}\n')
            address += 1

    # run inference 
    result = runner._run_simulation(300)

    #update GUI
    running = window.update_window("image", resized_image)
    running = window.update_window("image_name", path.basename(image_name))
    running = window.update_window("result", result)

window.window.close()