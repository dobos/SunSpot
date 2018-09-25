#!/bin/sh
# Convert SDO data into file ready for database ingestion

awk '{
if ($1 == "h")
{
  obs="120"
  $1=""
  print obs $0
}
}' | tr -d '\r'
