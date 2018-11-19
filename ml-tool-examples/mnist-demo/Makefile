ARMNN_LIB = ${HOME}/armnn-devenv/armnn/build
ARMNN_INC = ${HOME}/armnn-devenv/armnn/include

BOOST_INC = ${HOME}/armnn-devenv/pkg/boost/install/include

all: mnist_tf_simple mnist_tf_convol reminder

mnist_tf_simple: mnist_tf_simple.cpp mnist_loader.hpp
	g++ -O3 -std=c++17 $< -o $@ \
		-I$(ARMNN_INC) -I$(BOOST_INC) \
		-L$(ARMNN_LIB) -larmnn -larmnnTfParser -lpthread

mnist_tf_convol: mnist_tf_convol.cpp mnist_loader.hpp
	g++ -O3 -g -std=c++17 $< -o $@ \
		-I$(ARMNN_INC) -I$(BOOST_INC) \
		-L$(ARMNN_LIB) -larmnn -larmnnTfParser -lpthread

clean:
	-rm -f mnist_tf_simple mnist_tf_convol

test: mnist_tf_simple mnist_tf_convol
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(ARMNN_LIB) ./mnist_tf_simple 1 10
	LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(ARMNN_LIB) ./mnist_tf_convol 1 10

.PHONY: reminder
reminder: 
	@echo "Make sure to add Arm NN: export LD_LIBRARY_PATH=$(ARMNN_LIB)"
