#!/bin/bash


if [ "$1" != "small" ] && [ "$1" != "medium" ] && [ "$1" != "large" ]; then
  printf "Usage: ./gen_test_data.sh SIZE\n\twith SIZE: small | medium | large\n"
  exit 1
fi

SIZE=$1

case $SIZE in
  small)
    NB_ELEM_R=50000
    NB_ELEM_B=73059
    ;;
  medium)
    NB_ELEM_R=100000
    NB_ELEM_B=139819
    ;;
  large)
    NB_ELEM_R=200000
    NB_ELEM_B=351347
    ;;
esac


head -n $NB_ELEM_R title.ratings.tsv > test.title.ratings.tsv
head -n $NB_ELEM_B title.basics.tsv > test.title.basics.tsv

echo "Dataset (title.test.basics.tsv and title.test.ratings.tsv) created."
