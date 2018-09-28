#!/bin/sh
# Convert SDO data into file ready for database ingestion

awk '
{
	FIELDWIDTHS="1 5 3 3 3 3 3 7 6 6 6 6 6 7 7 7 7 7 8 8"
}
{
  if ($1 == "s")
  {
    size = length($8)
    status = 0
    str = ""
    
    for (i = 1; i <= size; i++) 
    {
      char=substr($8, i, 1)
      if (char != " " && char !~ /[0-9]/) {
        if (status == 0) str = str " "
	    status=1
      }
      str = str char
    }
    if (status == 0) str = str " 0"
    $8 = str
    
    for (i = 1; i <= NF; i++)
    {
      sub(/^\s+/, "", $i)
      printf "%s%s", $i, (i < NF ? " " : "\n")
    }
  }
}' | tr -d '\r'