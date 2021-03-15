# Convertion Scripts

These scripts will convert resources to byte arrays in cpp Code files.

## Included scipts

### convert_tflite_to_cpp.sh

Usage options:

```
-i|--input <model.tflite> :   The model to convert
-o|--output <model.cpp>   :   The output .cpp file name (default: <model.tflite>.cpp)
-h|--help                 :   Help. Shows the usage message
```

### convert_images_to_cpp.sh

Converts a directory of images to cpp code.

Usage options:

```
-i|--input <image-dir>    : The path to the images dir to convert 
-o|--output <output-dir>  : The path to the output dir of .cpp files (default: <image-dir>/out)
--width                   : The the width of the output image data (default: 224)
--height                  : The the height of the output image data (default: same as width)
-g|--grayscale            : Flag for grayscale (single channel) output images (default: 0 (false))
-h|--help                 : Help. Shows the usage message
```

### convert_image_to_cpp.sh

Converts a single image to cpp code

Usage options:

```
-i|--input <image-path>   : The path to the image to convert 
-o|--output <output-path> : The path to the output file (default: <image-name>.cpp)
--width                   : The the width of the output image data (default: same as input)
--height                  : The the height of the output image data (default: same as input)
-g|--grayscale            : Flag for grayscale (single channel) output images (default: 0 (false))
-h|--help                 : Help. Shows the usage message
```
