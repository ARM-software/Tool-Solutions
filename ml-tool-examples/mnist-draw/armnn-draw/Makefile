ARMNN_LIB = ${HOME}/armnn-devenv/armnn/build
ARMNN_INC = ${HOME}/armnn-devenv/armnn/include

all: mnist_tf_convol reminder

mnist_tf_convol: mnist_tf_convol.cpp mnist_loader.hpp
		g++ -O3 -std=c++17 -I${HOME}/armnn-devenv/pkg/boost/install/include -I$(ARMNN_INC) $< -o $@ -L$(ARMNN_LIB) -larmnn -larmnnTfParser -lpthread

clean:
	-rm -f mnist_tf_convol

.PHONY: reminder
reminder: 
	@echo "Make sure to add Arm NN: export LD_LIBRARY_PATH=$(ARMNN_LIB)"


