#!/bin/sh
# Convert DPD data into file ready for database ingestion

awk '{
if ($1 == "h")
{
  print $0
}
}' | tr -s ' ' | tr -d '\r'
