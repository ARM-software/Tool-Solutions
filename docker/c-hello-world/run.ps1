# docker run will automatically get and run the specified image using the platform flag
# make sure to delete any existing images because docker will not pull a 
# different architecture if an image already exists

# uncomment 1 line to select the architectures

docker run --rm -it --platform linux/arm64  jasonrandrews/c-hello-world
#docker run --rm -it --platform linux/arm/v7 jasonrandrews/c-hello-world
#docker run --rm -it --platform linux/amd64  jasonrandrews/c-hello-world
