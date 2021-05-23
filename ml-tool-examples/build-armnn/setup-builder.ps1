# Setup a builder to the build the Arm NN software 

docker buildx create --use --platform linux/arm/v7,linux/arm64 --name builder  
docker buildx use builder
docker buildx inspect --bootstrap
