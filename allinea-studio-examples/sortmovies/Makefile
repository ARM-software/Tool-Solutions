## Set compiler
CC=gcc
#CC=armclang

CFLAGS=-g
LFLAGS=

ifeq ($(DEBUG),1)
CFLAGS+=-DDEBUG
endif

all: sortmovies_1.exe sortmovies_2.exe sortmovies_3.exe

sortmovies_1.exe: sortmovies_1.c
	${CC} ${CFLAGS} -O0 -fsanitize=address $< -o $@ ${LFLAGS}

sortmovies_2.exe: sortmovies_2.c
	${CC} ${CFLAGS} -O3 $< -o $@ ${LFLAGS}

sortmovies_3.exe: sortmovies_3.c
	${CC} ${CFLAGS} -O3 $< -o $@ ${LFLAGS}

clean:
	rm sortmovies_1.exe sortmovies_2.exe sortmovies_3.exe

