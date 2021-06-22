#!/usr/bin/env python
from PIL import Image
import subprocess
from os import path, listdir
from collections import namedtuple
import re
from itertools import cycle
import numpy as np

from sw.data_injection_utils.builder import Builder

from sw.data_injection_utils.config import AppConfiguration

from sw.data_injection_utils.fvp_inference_runner import FvpInferenceRunner

cfg=AppConfiguration()

# Parse CLI argument
cfg.ParseInputArguments()

#build the samples
builder=Builder(cfg)
if not builder.build():
    cfg.logging.error("Building samples failed, exiting...")
    exit()


# image format for the usecase
image_size = (96,96)
image_format = "L"
if cfg.usecase == "img_class":
    image_size = (224,224)
    image_format = "RGB"

# get a cycle list of all images in image_path
image_list = []
valid_images = [".jpg",".jpeg",".gif",".png",".tga",".bmp"]

for f in listdir(cfg.image_path):
    ext = path.splitext(f)[1]
    if ext.lower() not in valid_images:
        continue
    image_list.append(path.join(cfg.image_path, f))
image_pool = cycle(image_list)

if len(image_list) == 0:
    cfg.logging.error(f"No images found in path {cfg.image_path}, aborting...")
    exit()

# Create runner
runner = FvpInferenceRunner(cfg)

# if we use camera, init camera
if cfg.use_camera:
    import pygame
    import pygame.camera
    from pygame.locals import *
    pygame.init()
    pygame.camera.init()
    camlist = pygame.camera.list_cameras()
    if camlist:
        cam = pygame.camera.Camera(camlist[0],(640,480))
        cam.start()
        image_name = "camera feed"
    else:
        cfg.logging.warning("No camera found, falling back to images instead")
        cfg.use_camera = False

from sw.data_injection_utils.inference_gui import InferenceGUI

# create window
window = InferenceGUI()

running = True

# main loop
while running:
    if not cfg.use_camera: # iterate through images in image_path
        image_name = next(image_pool)
        image = Image.open(image_name, mode='r')
    else: # get input image from camera
        camimage = cam.get_image()
        strFormat = 'RGBA'
        raw_str = pygame.image.tostring(camimage, strFormat, False)
        image = Image.frombytes(strFormat, camimage.get_size(), raw_str)

    # resize image to use case size
    resized_image = image.resize(image_size)
    resized_image = resized_image.convert(image_format)

    # write image to .dat-file, to send into FVP dynamically
    rgb_data = np.array(resized_image, dtype=np.uint8).flatten()
    rgb_data.astype('uint8').tofile(f"{cfg.repo_root}/image_data.dat")

    # run inference 
    result = runner._run_simulation(300)

    #update GUI
    running = window.update_window("image", resized_image)
    running = window.update_window("image_name", path.basename(image_name))
    running = window.update_window("result", result)

window.window.close()
