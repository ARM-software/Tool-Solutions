# Sample Images

## Table of Contents

[[_TOC_]]

## Sources

The sample images used in this project are under the CC license
The originals can be found here:
* https://commons.wikimedia.org/wiki/File:Person-tree.jpg
* https://www.piqsels.com/en/public-domain-photo-ofjja
* https://commons.wikimedia.org/wiki/File:POV-cat.jpg
* https://commons.wikimedia.org/wiki/File:JP-Kyoto-kimono.jpg

## Convert images to cpp code

Using the script `convert_images_to_cpp.sh`, all images in a folder will be converted to cpp code.

To convert all images in the sample folder, run the following command ( <repo-root> is the path to the repository root):

```
$> cd <repo-root>/sw/corstone-300-person-detection
$> <repo-root>/sw/convert_script/convert_images_to_cpp.sh \
    --input samples --output samples-cpp \
    --width 96 --height 96 \
    --grayscale 1
```

Looking in the `samples-cpp` folder, it should look like this:

```
$> ls samples-cpp
images.cpp
images.hpp
JP_Kyoto_kimono.cpp
person_male_man_men.cpp
POV_cat.cpp
tree.cpp
```

### Add you own data

You can add your own test images by simply adding  them to the samples folder, and running the convert script again.

The script works recursively, so if there are images in sub-folders, they will be converted as well. Make sure the images have unique names, since the cpp variable names are based on the image name.

### Using the converted images in the apllication

Move the code-files to the `corstone-300-person-detection` folder. 

All .cpp-files are compiled automatically. So if there are files in the folder that you don't want to include, you can delete them, or alternatively, you can edit CMakeLists.txt to point at what files to compile.

```
ethosu_add_executable(ethosu55-person-detection PRIVATE
    SOURCES 
        main.cpp
        model_vela.cpp
        images.cpp
        <YOUR-IMAGES-FILES-HERE>
    LIBRARIES 
        freertos_kernel
        mobilenet_inference_process
    )
```


## Compile and run application

1. Build Application
    ```
    $> mkdir build; cd build
    $> cmake ..
    $> make
    ```

1. Run Application
    ```
    FVP_Corstone_SSE-300_Ethos-U55  \
        --stat \
        -C mps3_board.visualisation.disable-visualisation=1 \
        -C mps3_board.uart0.out_file=- \
        -C mps3_board.telnetterminal0.start_telnet=0 \
        -C mps3_board.uart0.unbuffered_output=1 \
        -C mps3_board.uart0.shutdown_tag="EXITTHESIM" \
        -C cpu0.CFGITCMSZ=14 \
        -C cpu0.CFGDTCMSZ=14 \
        -C ethosu.num_macs=128 \
        -a ethosu55-person-detection.elf
    ```