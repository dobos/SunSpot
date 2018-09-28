#!/bin/sh
# Convert DPD data into file ready for database ingestion

awk '{
	FIELDWIDTHS="1 5 3 3 3 3 3 5 14 6 6 6 14 7 7"
}
{
  if ($1 == "d")
  {
    for (i = 1; i <= NF; i++)
    {
      sub(/^\s+/, "", $i)
      printf "%s%s", $i, (i < NF ? " " : "\n")
    }
  }
}' | tr -s ' ' | tr -d '\r'
