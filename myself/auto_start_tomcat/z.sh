#!/bin/sh
set -x
#tmp=run
CATALINA_HOME=`pwd`
#CATALINA_HOME=`echo  $0 |sed  "s/\(.*\)$tmp/\1/g"`
#echo $CATALINA_HOME
count="ps -fu `whoami` |grep bootstrap.jar   |  grep $CATALINA_HOME | grep -v grep | wc -l"
t=`eval $count`
#echo $t

tomcat_help()
{
echo "================================================"
echo "=1.Check tomcat run                            ="
echo "=2.Start tomcat                                ="
echo "=3.Quit tomcat                                 ="
echo "=4.Tail tomcat logs                            ="
echo "=5.restart tomcat                              ="
echo "================================================"
}

check_tomcat()
{
  echo "--------------------------"
  echo "-->  check tomcat info  <--"
  echo "--------------------------"
  ps -fu `whoami` | grep  bootstrap.jar  | grep $CATALINA_HOME | grep -v grep
  if [ $t -ne 0 ] ;then
  echo "-->Tomcat exist $t"
  echo "--------------------------"
  else
  echo "-->Tomcat  is not exist $t"
  echo "--------------------------"
  fi
}


start_tomcat()
{
  if [ $t -ne 0 ];then                  # if ps -fu `whoami` |  grep -E java  >/dev/null 2>$1 ; then
  echo "--------------------------"
    echo "-->Tomcat exist $t"
  echo "--------------------------"
  else
  echo "--------------------------"
  echo "-->Start tomcat pls wait"
  echo "--------------------------"
  sh $CATALINA_HOME/startup.sh
  fi
}

kill_tomcat()
{
#echo "-->Stop tomcat $t"
#ps -ef |  grep $CATALINA_HOME | grep -v grep | awk '{ print $2 }'| xargs kill -9 2>/dev/null
# ps -ef | grep tomcat | grep 8011 | grep -v grep | awk '{ print $2 }'| xargs kill -9
#if [ -f $CATALINA_HOME/bin/shutdown.sh ];
#   then
#   echo $"Stopping Tomcat"
#   sh $CATALINA_HOME/bin/shutdown.sh
#   else
#   ps -ef | grep tomcat | grep $CATALINA_HOME | grep -v grep | awk '{ print $2 }'| xargs kill -9
#   fi
  if [ $t -ne 0 ] ;then
  echo "--------------------------"
  echo "-->Tomcat exist $t Stop tomcat now"
  echo "--------------------------"
  ps -fu `whoami`  |grep   bootstrap.jar  |  grep $CATALINA_HOME | grep -v grep | awk '{ print $2 }'| xargs kill -9  #2 >/dev/null
  sleep 3                          #ps -fu `whoami` | grep -E  java| grep -v grep | awk '{ print $2 }'| xargs kill -9 2 >/dev/null
  else
  echo "--------------------------"
  echo "-->Tomcat  is stop $t"
  echo "--------------------------"
  fi
rm -rf $CATALINA_HOME/../work/*
}

tail_logs()
{
  echo "--------------------------"
  echo "-->tail tomcat:$CATALINA_HOME../logs/catalina.out"
  echo "--------------------------"
  tailf $CATALINA_HOME/../logs/catalina.out

}

run_tomcat()
{

case $1 in
1)
check_tomcat
;;
2)
start_tomcat
;;
3)
kill_tomcat
;;
4)
tail_logs
;;
5)
echo "restart tomcat now"
kill_tomcat
echo "pls wait 6s"
sleep 6
sh $CATALINA_HOME/startup.sh | tee $CATALINA_HOME/autostart.log
check_tomcat
echo "tomcat is running..."
;;
*)
tomcat_help
;;
esac
}

run_tomcat $1
