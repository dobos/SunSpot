#!/bin/sh
# Convert SDO data into file ready for database ingestion

awk '{
if ($1 == "g")
{
  obs="120"
  $1=""
  str=$8
  size=length(str)
  status=0
  $8=""
  for (i = 1; i <= size; i++) 
  {
   char=substr(str,i,1)
   if (char !~ /[0-9]/) {
     if (status == 0) $8=$8" "
	 status=1
   }
   $8=$8char
  }
  if (status==0) $8=$8" 0"
  print obs $0
}
}' | tr -d '\r'