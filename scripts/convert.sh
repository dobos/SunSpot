#!/bin/sh
input="$1"

# create frame file and filter out rows starting with d or h
printf "" > "frame_$input"
cat $input|awk '{
if (($1=="d")||($1=="h")) {
  #check for errors in SOHO entries at column 15
  if ((x = index($15, "-")) > 1) {
	$15 = substr($15, x + 1, length($15))
  }
  print $0
  }
}'|sed 's/d //'|sed 's/h //'|while read line 
do
echo $line >> "frame_$input"
done

# create group file
printf "" > "group_$input"
cat $input|awk '{
if (($1=="d")||($1=="h")) obs=$8
if ($1=="g") {
  size=length($8)
  status=0
  str=$8
  $8=""
  for (i = 1; i <= size; i++) 
  {
   char=substr(str,i,1)
   if (char !~ /[0-9]/) { $8=$8" "; status=1}
   $8=$8char
  }
  if (status==0) $8=$8" 0"
  printf("%s %s\n", obs, $0)
  }
}'|sed 's/g //'|while read line 
do
echo $line >> "group_$input"
done

# create spot file
printf "" > "spot_$input"
cat $input|awk '{
if (($1=="d")||($1=="h")) obs=$8
if ($1=="s") {
  size=length($8)
  status=0
  str=$8
  $8=""
  for (i = 1; i <= size; i++) 
  {
   char=substr(str,i,1)
   if (char !~ /[0-9]/) { $8=$8" "; status=1}
   $8=$8char
  }
  if (status==0) $8=$8" 0"
  printf("%s %s\n", obs, $0)
  }
}'|sed 's/s //'|while read line 
do
echo $line >> "spot_$input"
done