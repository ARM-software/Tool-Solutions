## MNIST Draw
MNIST draw is a fun, single page website that enables users to hand-draw and classify digits (0-9) using machine learning. A machine learning model trained against the MNIST dataset is used for classification.

The project is a modified version of [nmist-draw](https://github.com/rhammell/mnist-draw) which uses the [Arm NN SDK](https://developer.arm.com/products/processors/machine-learning/arm-nn) to perform inferences on an Arm Cortex-A CPU. Usually this means running on a board like the [HiKey 960](https://www.96boards.org/product/hikey960) and accessing it over a network using a browser.

## Setup
Python 3.5+ is required for compatibility with all required modules

```bash
## Go into the repository
cd mnist-draw

## Install required modules
pip3 install -r requirements.txt

## Build the armnn-draw application
make -C armnn-draw

## Set LD_LIBRARY_PATH for Arm NN (if not already done)
export LD_LIBRARY_PATH=$HOME/armnn-devenv/armnn/build
```

## Usage
To launch the website, begin by starting a Python server from the repository folder:
```bash
## Start Python server
python3 -m http.server --cgi 8000
```
Then open a browser on any machine which can access the Arm board running the server and navigate to `http://ip-address:8000` to view it.

An example of the website's interface is shown below. Draw a digit (0-9) on the empty canvas and then hit the 'Predict' button to process their drawing. Any errors during processing will be indicated with a warning icon and printed to the console. Common errors include not compiling the application in armnn-draw/, not using python3, and not install all required packages.

Results are displayed as a bar graph where each classification label receives a score between 0.0 and 1.0 from the machine learning model. Clear the canvas with the 'Clear' button to draw and process other digits.

Interface example: 
<p>
<img src="http://i.imgur.com/fmIa0e5.gif" width="600">
</p>

## Machine Learning Model
Refer to the python script at cgi-bin/mnist.py for implementation details.

A convolutional neural network (CNN) is defined within the model/ directory and used by a program in armnn-draw/ using the [Arm NN SDK](https://developer.arm.com/products/processors/machine-learning/arm-nn). This model is configured for MNIST data inputs. 

Also refer to mnist-draw.pdf for more details on how to try a different model.


