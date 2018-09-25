#!/bin/sh

# Usage: ./convert_all <path to data files> <path to bulk-load file>

outfile="$2/frame.txt"
echo -n > $outfile

for file in $(ls $1/HMID*);
do
  echo Converting $file
  cat $file | ./convert_frame.sh >> $outfile
done

outfile="$2/group.txt"
echo -n > $outfile

for file in $(ls $1/g*);
do
  echo Converting $file
  cat $file | ./convert_group.sh >> $outfile
done

outfile="$2/spot.txt"
echo -n > $outfile

for file in $(ls $1/s*);
do
  echo Converting $file
  cat $file | ./convert_spot.sh >> $outfile
done
