#!/usr/bin/python3

# Simple script to show a picture of the captured image
# Script assumes image.txt is present in the current directory
# Requires numpy and matplotlib

import numpy as np
import matplotlib.pyplot as plt
import sys 

arr = np.loadtxt("image.txt")
arr2 = arr.reshape(28, 28)
print("array shape: ", arr2.shape, file=sys.stderr)
print("array dim: ", arr2.ndim, file=sys.stderr)
print("array size: ", arr2.size, file=sys.stderr)
print("array type: ", arr2.dtype.name, file=sys.stderr)
plt.imshow(arr2)
plt.show()

