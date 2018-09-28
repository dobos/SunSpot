#!/bin/sh

# Usage: ./convert_all <path to data files> <path to bulk-load file>

outfile="$2/gpr_frame.txt"
echo -n > $outfile

for file in $(ls $1/dGPR*);
do
  echo Converting $file
  cat $file | ./convert_frame.sh >> $outfile
done

outfile="$2/gpr_group.txt"
echo -n > $outfile

for file in $(ls $1/gGPR*);
do
  echo Converting $file
  cat $file | ./convert_group.sh >> $outfile
done
