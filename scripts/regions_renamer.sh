#!/bin/bash

for var in "$@"
do
    NAME="$( basename $var _regions.txt ).bed"
    DIR="$( dirname "$var" )"
    cp $var $DIR/$NAME
done