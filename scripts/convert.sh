#!/bin/sh
input="$1"
cat $input|awk '{
if ( ($1=="d")||($1=="h") )
{ 
  size=0x1000000;
  MJD=$13-2400000.5;
  X=int(MJD*100); 
  if ($8=="ABAS") obsID=1;
  if ($8=="BOUL") obsID=2;
  if ($8=="DEBR") obsID=3;
  if ($8=="EBRO") obsID=4;
  if ($8=="GYUL") obsID=5;
  if ($8=="HELW") obsID=6;
  if ($8=="HOLL") obsID=7;
  if ($8=="KANZ") obsID=8;
  if ($8=="KIEV") obsID=9;
  if ($8=="KISL") obsID=10;
  if ($8=="KODA") obsID=11;
  if ($8=="MITA") obsID=12;
  if ($8=="MLSO") obsID=13;
  if ($8=="MWIL") obsID=14;
  if ($8=="NNNN") obsID=15;
  if ($8=="RAME") obsID=16;
  if ($8=="ROME") obsID=17;
  if ($8=="SOHO") obsID=18;
  if ($8=="TASH") obsID=19;
  if ($8=="UCCL") obsID=20;
  if ($8=="USSU") obsID=21;
  if ($8=="SHMI") obsID=22;
  frameID=size*obsID+X;
}
if (frameID>0)
 {
  printf "%9d %s\n",frameID,$0
 }
}' > f1.txt

printf "" > "frame_$input"
cat f1.txt|awk '{if (($2=="d")||($2=="h")) print $0}'|sed 's/d //'|sed 's/h //'|while read line 
do
echo $line >> "frame_$input"
done

printf "" > "group_$input"
cat f1.txt|grep " g "|sed 's/g //'|awk '{
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
print $0
}'|while read line 
do
echo $line >> "group_$input"
done

printf "" > "spot_$input"
cat f1.txt|grep " s "|sed 's/s //'|awk '{
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
print $0
}'|while read line 
do
echo $line >> "spot_$input"
done

#cat f1.txt|awk '{if (($2=="d")||($2=="h")) print $0}'|sed 's/d //'|sed 's/h //' > "frame_$input"
#cat f1.txt|grep " g "|sed 's/g //' > "group_$input"
#cat f1.txt|grep " s "|sed 's/s //' > "spot_$input"