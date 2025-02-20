#!/bin/bash

find . -name '.nextflow*' | xargs rm -rf
find . -name 'work' | xargs rm -rf
find . -name 'results' | xargs rm -rf

rm -rf .nf-test
rm -rf .nf-test.log