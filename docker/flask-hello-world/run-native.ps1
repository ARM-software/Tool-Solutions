# this will automatically get and run the native image for the machine you are on
# connect a browser to localhost:80 
# make sure to change the image name to your hub account
docker run --rm -i --name flask-native -p 80:5000 jasonrandrews/flask-hello-world