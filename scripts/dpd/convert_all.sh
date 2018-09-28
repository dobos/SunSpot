#!/bin/sh

# Usage: ./convert_all <path to data files> <path to bulk-load file>

outfile="$2/dpd_frame.txt"
echo -n > $outfile

for file in $(ls $1/dDPD*);
do
  echo Converting $file
  cat $file | ./convert_frame.sh >> $outfile
done

outfile="$2/dpd_group.txt"
echo -n > $outfile

for file in $(ls $1/gDPD*);
do
  echo Converting $file
  cat $file | ./convert_group.sh >> $outfile
done

outfile="$2/dpd_spot.txt"
echo -n > $outfile

for file in $(ls $1/sDPD*);
do
  echo Converting $file
  cat $file | ./convert_spot.sh >> $outfile
done
