#!/bin/sh
for file in $(ls $1);
do
./convert.sh $file
done
