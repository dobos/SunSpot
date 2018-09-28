#!/bin/sh

# Usage: ./convert_all <path to data files> <path to bulk-load file>

outfile="$2/sdd_frame.txt"
echo -n > $outfile

for file in $(ls $1/hSDD*);
do
  echo Converting $file
  cat $file | ./convert_frame.sh >> $outfile
done

outfile="$2/sdd_group.txt"
echo -n > $outfile

for file in $(ls $1/gSDD*);
do
  echo Converting $file
  cat $file | ./convert_group.sh >> $outfile
done

outfile="$2/sdd_spot.txt"
echo -n > $outfile

for file in $(ls $1/sSDD*);
do
  echo Converting $file
  cat $file | ./convert_spot.sh >> $outfile
done
