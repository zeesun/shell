#!/bin/sh
DB_CONNECT_STRING="aijs/aijs@zmjs"

now=`date +%Y%m%d%H%M%S`
curdate=`date +%Y%m%d`
curday=`date +%d`
curmonth=`date +%Y%m`

#得到上个月的月份，比如本月是200710,那么要得到的是200709
zeros=`printf "%s" "0"`
CURRENT_YEAR=`date +%Y`
LAST_YEAR=`expr $CURRENT_YEAR - 1`
curmonth=`date +%m`
if [ $curmonth -gt 2 ]
 then
  LAST_MONTH=`expr $curmonth - 2`
  if [ $LAST_MONTH -lt 10 ]
   then
  	MONTH="$CURRENT_YEAR$zeros$LAST_MONTH"
  else
    MONTH="$CURRENT_YEAR$LAST_MONTH"
  fi
 else
  LAST_MONTH=12
  MONTH="$LAST_YEAR$LAST_MONTH"
fi
#MONTH="200904"
echo $MONTH


echo "ftp begin"
if true; then
ftp -i -n 10.70.72.148 << EOF
user billing bill&recS 
lcd /data1/home/jsusr1/center/scripts/spdz/CRING
cd /source/ydbb/
bin
prom off
get $MONTH.txt
bye
EOF
echo "ftp end"
mv $MONTH.txt cring.txt
sqlplus $DB_CONNECT_STRING > /dev/null 2>&1 << SQLEOF
delete from all_cring where bill_month=to_char($MONTH);
delete from acc_settle_sp_unconfirm where bill_month=to_char($MONTH) and acc_settle_id in (324400,324500);
commit;
exit
SQLEOF
sqlldr aijs/aijs@zmjs control=cring.ctl
echo "sqlldr end"

sqlplus $DB_CONNECT_STRING > /dev/null 2>&1 << SQLEOF
insert into acc_settle_sp_unconfirm select bill_month,null,324400,0,1,hplmn2,110000039,null,null,0,0,0,0,0,0,0,0,0,music_total*10,0,0,0,0,0,music_sp*10,music_self*10,0,0,0,null,null,null,null,0 from all_cring where bill_month=$MONTH;
commit;
insert into acc_settle_sp_unconfirm select bill_month,null,324500,0,1,hplmn2,110000040,null,null,0,0,0,0,0,0,0,0,0,down_total*10,0,0,0,0,0,down_sp*10,down_self*10,0,0,0,null,null,null,null,0 from all_cring where bill_month=$MONTH;
commit;
exit
SQLEOF
fi
mv cring.txt $MONTH.txt
echo "OK! END"

exit 0
