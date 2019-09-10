# build the example using buildx for 3 platform and push to Docker hub
# make sure to change the tag name of the image to your hub account
docker buildx create --name mybuilder
docker buildx use mybuilder
docker buildx build --platform linux/arm64,linux/amd64,linux/arm/v7 -t jasonrandrews/flask-hello-world --push .
