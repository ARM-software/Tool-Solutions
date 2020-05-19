#!/bin/bash

echo "Downloading this dataset is subject to IMDB terms and conditions. See https://www.imdb.com/interfaces/ for more information."
echo "Press any key to continue or CTRL-C to exit"
read 
wget https://datasets.imdbws.com/title.basics.tsv.gz
wget https://datasets.imdbws.com/title.ratings.tsv.gz
gunzip title.basics.tsv.gz
gunzip title.ratings.tsv.gz
echo "Dataset (title.basics.tsv and title.ratings.tsv) downloaded."

