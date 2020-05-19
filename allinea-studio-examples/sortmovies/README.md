# Sort movies code example

This is an example of a C application sorting movies from a database by rating score. There are three versions of the same application in this repository:

- sortmovies_1.c: crashes for large data sets files,
- sortmovies_2.c: fixes the issue in sortmovies_1 but has performance issues,
- sortmovies_3.c: is an optimized version of sortmovies_2.

All versions need two input data sets in TSV:

- one set with movie ID and title
- one set with movie ID, number of votes and average rating

All versions output a result file in TSV that ranks movies from the highest to the lowest score.


## Get input data
Input data sets that can be downloaded from IMDB (title.basics.tsv and title.ratings.tsv) by running the following script:
```console
$ ./get_data.sh
```
Downloading the data is subject to IMDB's terms and conditions.

## Create test data sets
The original data set is quite large. Smaller test data sets (title.test.basics.tsv and title.test.ratings.tsv) can be created by running the following script:
```console
$ ./gen_test_data.sh SIZE
```
The argument SIZE is required and can either be _small_ (~6 MB of data), _medium_ (~12 MB of data) or _large_ (~30 MB of data).

## Compile
To compile the three versions of the application, run the following command to use the whole dataset (title.basics.tsv and title.ratings.tsv):
```console
$ make
```
To run on a smaller test data set created with `get_movies.sh` (title.test.basics.tsv and title.test.ratings.tsv), run:
```console
$ make DEBUG=1
```
The Makefile uses GCC by default but it can also use the Arm Compiler for Linux, part of [Allinea Studio](https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-allinea-studio). Just edit the Makefile to specify your preferred compiler: `CC=gcc` or `CC=armclang`.

## Execute
To execute a version of the application, run the following command:
```console
$ ./sortmovies_$VER.exe
```
Where $VER is either 1, 2, or 3.

Depending on how the application is compiled, the application will run using the whole dataset (title.basics.tsv and title.ratings.tsv) or the test dataset (title.test.basics.tsv and title.test.ratings.tsv).

## Debug
To debug version 1 of the application with Arm DDT, part of [Allinea Studio](https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-allinea-studio), run:
```console
$ ddt ./sortmovies_1.exe
```
In the "Run" window, in the "Plugin" section, make sure that the "Address Sanitizer" plugin is enabled.

## Profile
To profile version 2 of the application with Arm MAP, part of [Allinea Studio](https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-allinea-studio), run:
```console
$ map ./sortmovies_1.exe
```

## Arm Allinea Studio License
[Allinea Studio](https://developer.arm.com/tools-and-software/server-and-hpc/downloads/arm-allinea-studio) is a commercial suite of high-performance tools for developing Arm-based server and HPC applications. It includes the Arm Compiler for Linux and the Arm Forge development toolkit. They are designed to get your application running at optimal performance on Armv8-A. [Click here](https://pages.arm.com/Hpc-trial-request.html) to request a trial licence. 
