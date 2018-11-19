#!/usr/bin/python3

"""
CGI script that accepts image urls and feeds them into a ML classifier. Results
are returned in JSON format. 
"""

import io
import subprocess
import json
import sys
import os
import re
import base64
import numpy as np
from PIL import Image
#from model import model

# Default output
res = {"result": 0,
       "data": [], 
       "error": ''}

try:
    # Get post data
    if os.environ["REQUEST_METHOD"] == "POST":
        data = sys.stdin.read(int(os.environ["CONTENT_LENGTH"]))

        # Convert data url to numpy array
        img_str = re.search(r'base64,(.*)', data).group(1)
        image_bytes = io.BytesIO(base64.b64decode(img_str))
        im = Image.open(image_bytes)
        # Resize image to 28x28
        im = im.resize((28,28))
        arr = np.array(im)[:,:,0:1]

        # Normalize pixel values
        arr = (255 - arr)
        np.savetxt("image.txt", arr.reshape(784), fmt='%d')

        if os.path.isfile('./armnn-draw/mnist_tf_convol'):
            print('armnn-draw/mnist_tf_convol exists', file=sys.stderr)
        else:
            print('ERROR: Run make in armnn-draw/', file=sys.stderr)

        # Run Arm NN model
        try:
            # two integer arguments are:
            #   accelleration: 0 = CPU unoptimized, 1 = CPU accelerated, 2 = GPU accelerated
            #   model: 0 = simple, low accuracy  1 = optimized, higher accuracy 
            #     change the 2nd 1 to a 0 to use the low accuracy model
            completed = subprocess.run(['./armnn-draw/mnist_tf_convol', '1', '1', 'image.txt'], stderr=subprocess.PIPE, check=True)
        except subprocess.CalledProcessError as err:
            print('ERROR:', err, file=sys.stderr)
            print('Make sure to export LD_LIBRARY_PATH=$HOME/armnn-devenv/armnn/build', file=sys.stderr)
        
        # set predictions to stderr
        output_lines = completed.stderr.decode('utf-8').splitlines()

        # if first element can convert to float, first line is the results line
        is_result = True
        try:
            is_result = (type(float(output_lines[0].split()[0])) == float)
        except ValueError as err:
            is_result = False
        finally:
            print(is_result, file=sys.stderr)
            predictions = output_lines[int(not(is_result))].split()

        print(predictions, file=sys.stderr)

        # Return label data
        res['result'] = 1
        try:
            results = [float(num) for num in predictions]
        except ValueError as err:
            print('ERROR:', err, file=sys.stderr)

        print("results: ", results, file=sys.stderr)
        print("max ", max(results), file=sys.stderr)
        maxpos = results.index(max(results))

        # Normalise result data
        probs = [x/max(results) for x in results]
        print("probabilities: : ", probs, file=sys.stderr)
        res['data'] = probs
        print("done: ", res, file=sys.stderr)

except Exception as e:
    # Return error data
    res['error'] = str(e)

# Print JSON response
print("Content-type: application/json")
print("") 
print(json.dumps(res))


