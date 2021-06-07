# Sample Images

## Table of Contents

[[_TOC_]]

## Sources

The sample images used in this project are under the CC license
The originals can be found here:
* https://commons.wikimedia.org/wiki/File:POV-cat.jpg
* https://commons.wikimedia.org/wiki/File:Dog_Breeds.jpg
* https://commons.wikimedia.org/wiki/File:Bonnie_and_Clyde_Movie_Car.JPG
* https://commons.wikimedia.org/wiki/File:Summer_Bicycle.JPG
* https://commons.wikimedia.org/wiki/File:JP-Kyoto-kimono.jpg

## Convert images to cpp code

Using the script `convert_images_to_cpp.sh`, all images in a folder will be converted to cpp code.

To convert all images in the sample folder, run the following command ( <repo-root> is the path to the repository root):

```
$> cd <repo-root>/sw/corstone-300-mobilenet-v2
$> <repo-root>/sw/convert_script/convert_images_to_cpp.sh \
    --input samples --output samples-cpp \
    --width 224 --height 224 
```

Looking in the `samples-cpp` folder, it should look like this:

```
$> ls samples-cpp
Bonnie_and_Clyde_Movie_Car.cpp
Dog_Breeds.cpp
images.cpp
images.hpp
JP_Kyoto_kimono.cpp
POV_cat.cpp
Summer_Bicycle.cpp
```

### Add you own data

You can add your own test images by simply adding  them to the samples folder, and running the convert script again.

The script works recursively, so if there are images in sub-folders, they will be converted as well. Make sure the images have unique names, since the cpp variable names are based on the image name.

### Using the converted images in the apllication

Move the code-files to the `corstone-300-mobilenet-v2` folder. 

All .cpp-files are compiled automatically. So if there are files in the folder that you don't want to include, you can delete them, or alternatively, you can edit CMakeLists.txt to point at what files to compile.

```
ethosu_add_executable(ethosu55-mobilenet-v2 PRIVATE
    SOURCES 
        main.cpp
        model_mobilenet_v2.cpp
        images.cpp
        <YOUR-IMAGES-FILES-HERE>
    LIBRARIES 
        freertos_kernel
        mobilenet_inference_process
    )
```


## Compile and run application

Compile and rerun the application according to the main README.me instructions.

