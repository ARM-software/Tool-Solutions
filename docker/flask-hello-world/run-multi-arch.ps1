# run all 3 architectures on an x86 machine to show how to test Arm images on non-Arm machines
# open a browser tab with localhost:5000   localhost:5001 and localhost:5002
# make sure to change the image name to your hub account
# replace the sha256 values with your own images after running buildx
docker run --rm -d --name flask-amd64 -p 5000:5000 jasonrandrews/flask-hello-world

docker run --rm -d --name flask-arm64 -p 5001:5000 jasonrandrews/flask-hello-world:latest@sha256:841d6e8a61eea4ad411276268ddd7aa08a0fa2595fe18652cdf5fb6528a4afec

docker run --rm -d --name flask-armv7 -p 5002:5000 jasonrandrews/flask-hello-world:latest@sha256:3232ea0ea2ca21645325cbe00187c89b4bdea9403b57fb414c545a609aadb522