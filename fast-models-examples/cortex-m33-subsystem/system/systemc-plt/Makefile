CC=g++
CXXVER=6.4
PLT_EXPORT=../subsystem/Linux64-Release-GCC-$(CXXVER)
INC=-I . -I ${SYSTEMC_HOME}/include -I ${MAXCORE_HOME}/AMBA-PV/include -I ${PLT_EXPORT}/ -I ${PVLIB_HOME}/include/fmruntime -I ${PVLIB_HOME}/Iris/include
CFLAGS=-m64 -O3 -Wall -Werror -std=c++11 -pedantic -Wno-long-long -pthread -Wno-deprecated
LDFLAGS=-L${PLT_EXPORT}/ -lMyTopComponent-Linux64-Release-GCC-$(CXXVER) -lscx-MyTopComponent-Linux64-Release-GCC-$(CXXVER) -lscx -larmfastmodelsanalytics.1.1.0 -lrui_5.2.0.x64 -L${PVLIB_HOME}/lib/Linux64_GCC-$(CXXVER) -lpvbus -lfmruntime -lcomponents -lpvbus ${PVLIB_HOME}/lib/Linux64_GCC-$(CXXVER)/libarmctmodel.a -L${PVLIB_HOME}/Iris/Linux64_GCC-$(CXXVER) -lIrisSupport -L${SYSTEMC_HOME}/lib/Linux64_GCC-$(CXXVER) -lsystemc -lm -lpthread -lc -ldl -lrt

SRC=$(wildcard ./*.cpp)
OBJ=$(SRC:.cpp=.o)

%.o: %.cpp
	$(CC) -o $@ $(CFLAGS) $(INC) -c $<

plt: $(OBJ)
	$(CC) -o $@ $^ $(LDFLAGS)

clean:
	rm -rf *.o plt
