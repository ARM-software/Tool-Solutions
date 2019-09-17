# Build the example using buildx for 3 platforms and push to Docker hub
# Make sure to change the tag name of the image to your hub account

docker buildx create --name mybuilder
docker buildx use mybuilder
docker buildx build --platform linux/arm64,linux/amd64,linux/arm/v7 -t jasonrandrews/c-hello-world --push .
