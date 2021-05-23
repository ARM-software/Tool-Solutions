
# Base image derived from Ubuntu 18.04 used for the build and the dev images
docker buildx build --platform linux/arm64,linux/arm/v7  --target base --push -t armswdev/armnn:base -f Dockerfile .

# Full Arm NN build
docker buildx build --platform linux/arm64,linux/arm/v7 --target build --push -t armswdev/armnn:build -f Dockerfile .

# Builds the deverloper image used to create a software application with Arm NN
docker buildx build --platform linux/arm64,linux/arm/v7 --target dev --push -t armswdev/armnn:dev -f Dockerfile .

