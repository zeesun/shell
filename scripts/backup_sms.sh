#!/bin/sh
# set -x	# for dubug

#--------------------------------------------------------------------#
# ������Ż������ݽű�
# Author: fanghm
# ���Ŀ��: 
#	���ظ�ִ��,������ڱ��ݵ�Ŀ��tar�ļ�,׷��;���򴴽��µ�tar�ļ�����
#--------------------------------------------------------------------#
backup_days_before=5	# ���ݵ�ǰ������ǰN����ļ�
#==============================��Ҫ����==============================#

# clear

# calucate dates for later use
now=`date +%Y%m%d%H%M%S` # now="20060710112233" # get_now_time

#--------------------------------------------------------------------#
get_now_time()
{
	now=`date +%Y%m%d%H%M%S`
}

#--------------------------------------------------------------------#
# ׷����־��$logfile
# ����:��־����
#--------------------------------------------------------------------#
log_append()
{
	get_now_time
	echo "${now} \c" >> $logfile
	echo "$1" >> $logfile
}

#--------------------------------------------------------------------#
# ���ñ���·��backpath, ��ȷ��·������
#--------------------------------------------------------------------#
set_backpath()
{
	echo "==>set_back_path $*"
	
	if [ ! -d $1 ]; then
		echo "--create backpath: $1"
		mkdir -p $1		# force to create the directory hierarchy
	fi
	
	backpath=$1
	
	# echo "<==return $backpath\n"
}

#--------------------------------------------------------------------#
# ����ƥ����ļ�ʱ�����ļ�����Ӧ�������б�,�Կո�ָ�
# 1 - �����ļ�·��
# 2 - file pattern 
# eg: ls -1|cut -d _ -f 5|cut -c 1-8|sort|uniq| awk -v ORS="" '{ print $1,$2 }'
# ������ƥ����ļ�ʱ���ؿմ�,����ڶԷ����ִ����в���ʱ,
# Ҫ�Ƚ���-z/-n�жϺ����ʹ��
#--------------------------------------------------------------------#
get_dr_day_list()
{
	echo "==>get_dr_day_list $*"
	
	seq=5	# default date field pos in filename is 5, except defined in $date_in_filename
	if [ -n "$date_in_filename" ]; then
		seq=$date_in_filename
	fi
	
	#local from_path=$PWD
	cd $1
	day_list=`ls -1 $2|cut -d _ -f $seq|cut -c 1-8|sort|uniq| awk -v ORS="" '{ print $1,$2 }'`
	
	if [ -z "$day_list" ]; then
		# ������ls����ƥ���ļ����࣬����������ִ��;Ҳ�����ǲ�����ƥ����ļ�
		echo "--error cought when ls, try another way" 
		day_list=`ls -1|cut -d _ -f $seq|cut -c 1-8|sort|uniq| awk -v ORS="" '{ print $1,$2 }'`
	fi
	
	# cd $from_path
	
	echo "<==return day_list: $day_list"
}
#--------------------------------------------------------------------#
# ��Դ�ļ�����·���£����ļ���ƥ�����tar����(�����ļ�·��)
# usage: 
# 	backup_dr_to_path <tarfile_prefix> <src_file_pattern> <dest_path>
#
# ����: 
# 1 - tar file prefix
# 2 - file pattern without path
# 3 - backup dest path
#--------------------------------------------------------------------#
backup_dr_to_path()
{
	echo "==>backup_dr_to_path: $2"
	
	local tarfile="$1.tar"
	# if dest backed file existed, use -u option to update it! 
	if [ -e $tarfile ]; then	
		echo "--update existed $tarfile ..."
		tar -uf $3/$tarfile $2	# The u function key can be slow.
	else
		tar -cf $3/$tarfile $2
	fi
	
	# rm backuped files
	rm -f $2
	
	echo "<==backup_dr_to_path"
}

#--------------------------------------------------------------------#
# ȡָ���·ݵ���һ��,���ص�last_month
# ����: �·�,��ʽYYYYMM
#--------------------------------------------------------------------#
get_last_month()
{
	echo "==>get_last_month $*"
	local year=`echo $1|cut -c -4`
	local mon=`echo $1|cut -c 5-6`
	
	if [ "$mon" = "12" ]; then 	# 12�µ�����Ϊ��һ��1��
		local last_year=$(($year-1))
		last_month=`printf "%d%02d" ${last_year} 1`
	else
		local last_mon=$(($mon-1))
		last_month=`printf "%d%02d" ${year} ${last_mon}`
	fi
	
	echo "<==return $last_month"
}

#--------------------------------------------------------------------#
# ȡָ�����ڵ�ǰN��,���ص�last_N_day
# get_last_N_day 20040305 5 ����20040229
# ����: 
# 1 - ����,��ʽYYYYMMDD
# 2 - N, days_before_to_backup
#--------------------------------------------------------------------#
get_last_N_day()
{
	echo "==>get_last_N_day $*"
	
	local mon=`echo $1|cut -c -6`
	local day
	if [ $(echo $1|cut -c 7) -eq 0 ]; then
		day=$(echo $1|cut -c 8)
	else
		day=$(echo $1|cut -c 7-8)
	fi
	
	if [ $day -gt $2 ]; then 	# ����
		last_N_day=`printf "%d%02d" $mon $(($day-$2))`
	else
		# ����, ȡ����
		get_last_month $mon
		
		local last_mon=`echo $last_month|cut -c 5-6`
		local last_mon_n=$(($last_mon)) 
		
		# ������������
		local last_day=31
		case $last_mon_n in
			4|6|9|11)	last_day=30;;
			2) last_day=28;;
		esac
		
		local last_year=`echo $last_month|cut -c -4`
		local nyear=$(($last_year))
		
		# �����2�»�Ҫ��������2��ֻ��29��
		# �������: �ܱ�400�����������ܱ�4���������ܱ�100����
		if [ $last_day -eq 28 ]; then 
			if [ $(($nyear%400)) -eq 0 -o  $(($nyear%4)) -eq 0 -a $(($nyear%100)) -ne 0  ]; then
				last_day=29;
			fi
		fi
		echo "--days of $last_month is: $last_day"
		
		if [ $last_day -le $(($2-$day)) ]; then
			local last_month_1=`printf "%d%02d" $last_month 1`
			get_last_N_day $last_month_1 $(($2-$day-$last_day+1))	# �����, �ݹ����
		else
			last_N_day=`printf "%d%02d" $last_month $(($last_day-$2+$day))`
		fi
	fi
	
	echo "<==return $last_N_day"
}

#--------------------------------------------------------------------#
# ������Ż�������
# ���챸�ݻ���,�޲���,��ͨ��ȫ�ֱ�������
# ����need_compress����, tarǰ����compressѹ��
#--------------------------------------------------------------------#
BACKUP_WJ_SMS()
{
	echo "==>BACKUP_WJ_SMS"
	
	get_last_N_day $cur_day $backup_days_before
	backup_day=$last_N_day
	
	get_dr_day_list $srcpath "$filepattern"		# cd $srcpath here!
	
	if [ -n "$day_list" ]; then
		# ���챸��
		for loop_day in $day_list; do
			local month=`echo $loop_day|cut -c -6`
			set_backpath $backroot/$month/$filetype
			
			# $loop_day ��ʱ���Ǵ�С�������У��ʵ���$backup_day ˵���������
			if [ $loop_day -gt $backup_day ]; then
				echo "--backup end."
				break;
			else
				echo "=== backup $loop_day ==="
			fi
			
			if [ "$need_compress" = "N" ]; then	# ��ѹ������
				backup_dr_to_path "${tarfile_prefix}.$loop_day" "$filepattern$loop_day*" $backpath
			else	# ѹ������
				echo "--compress..."
				compress -f $filepattern${loop_day}*	# [0-9]
				backup_dr_to_path "${tarfile_prefix}.$loop_day" "$filepattern$loop_day*.Z" $backpath
			fi
		done
	fi
	
	# reset date_in_filename to blank
	unset date_in_filename
	
	echo "<==BACKUP_WJ_SMS"
}

######################################################################
#                         SCRIPT BEGIN                               #
######################################################################
cur_day=`echo $now|cut -c -8`
cur_month=`echo $now|cut -c -6`

get_now_time
logfile="/data1/home/jsusr1/center/log/backup/backup_gsmc_$now.log"
backroot=/data4/backup/wjsms

echo "$now sms backup begin..." > $logfile

#--------------------------------------------------------------------#
# �������ݵ�Ԥ��������
# ���ݲ���: ����10��ǰ����,��compress��tar,ÿ��GSMC1/GSMC2��һ���ļ�
#--------------------------------------------------------------------#
log_append "backup sms prep sheets"
srcpath=/data2/wj/center/back/settle/wj/sms
filetype="prep"

filepattern="N_CUSMS_HZ_GSMC3*"
tarfile_prefix="gsmc_prep_gsmc3"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC2*"
tarfile_prefix="gsmc_prep_gsmc2"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC1*"
tarfile_prefix="gsmc_prep_gsmc1"
BACKUP_WJ_SMS

#--------------------------------------------------------------------#
# ���ܱ��ݵķ�������,ֱ����Ϊ�嵥����Դ·��
# ���ݲ���: ���ر���,���ѻ����
#--------------------------------------------------------------------#
# log_append "backup sms settled sheets"
# srcpath=/data2/wj/center/back/stat/output/wj/sms

#--------------------------------------------------------------------#
# �ջ��ܱ��ݵĻ��ܻ���,�ļ�С(ÿ��200k����,tarǰ����ѹ��: need_compress="N")
# ���ݲ���: ����10��ǰ����Ϊtar,ÿ��GSMC1/GSMC2��һ���ļ�,Ҳ��ֱ��ɾ��
#--------------------------------------------------------------------#
log_append "backup sms stat sheets"
srcpath=/data2/wj/center/data/back/daystat/output/wj/sms
filetype="stat"
# backup_days_before=10
need_compress="N"

filepattern="N_CUSMS_HZ_GSMC3*"
tarfile_prefix="gsmc_stat_gsmc3"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC2*"
tarfile_prefix="gsmc_stat_gsmc2"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC1*"
tarfile_prefix="gsmc_stat_gsmc1"
BACKUP_WJ_SMS

need_compress="Y"

#--------------------------------------------------------------------#
# ���۳��򱸷ݵ��ջ���stat����,�������۵�,���뱸��,�Ա���������
# ���ݲ���: ����10��ǰ�����Ļ���,ÿ��һ���ļ�
# ע���ļ��������Ǵ�������,���ǻ�������!!!
#--------------------------------------------------------------------#
log_append "backup sms daystat sheets"
# ·������: select dup_file_path from acc_settle_task_def where acc_task_id=2
srcpath=/data2/wj/center/data/back/daystatloader/wj/sms/4
filetype="daystat"
# backup_days_before=10

filepattern="*"		# 4_yyyymmdd_seq_n.stat
tarfile_prefix="gsmc_daystat"
date_in_filename=2	# �������ļ������ֶ�ϵ��
BACKUP_WJ_SMS

#--------------------------------------------------------------------#
# �嵥���ر��ݵĻ���,�����Ϻͷ������һ��
# ���ݲ���: ����10��ǰ����Ϊtar,ÿ��GSMC1/GSMC2��һ���ļ�
# !!!����10��ǰ����ֱ��ɾ��
#--------------------------------------------------------------------#
log_append "backup sms settled sheets"
srcpath=/data2/wj/center/back/dataloader/cdr/wj/sms
filetype="settle"
# backup_days_before=10

filepattern="N_CUSMS_HZ_GSMC3*"
tarfile_prefix="gsmc_settle_gsmc3"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC2*"
tarfile_prefix="gsmc_settle_gsmc2"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC1*"
tarfile_prefix="gsmc_settle_gsmc1"
BACKUP_WJ_SMS

#--------------------------------------------------------------------#
# �嵥�����������,�Ƿֱ����,�ļ���������˱���,��������gzѹ��(300k),����ѹ��
# ���ݲ���: ����10��ǰ����Ϊtar,ÿ��GSMC1/GSMC2��һ���ļ�
# !!!����10��ǰ����ֱ��ɾ��
#--------------------------------------------------------------------#
log_append "backup sms daystat sheets"
srcpath=/data2/wj/center/data/dataloader/output/wj/sms
filetype="drload_out"
# backup_days_before=10
need_compress="Y"

filepattern="N_CUSMS_HZ_GSMC3*"
tarfile_prefix="gsmc_drload_out_gsmc3"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC2*"
tarfile_prefix="gsmc_drload_out_gsmc2"
BACKUP_WJ_SMS

filepattern="N_CUSMS_HZ_GSMC1*"
tarfile_prefix="gsmc_drload_out_gsmc1"
BACKUP_WJ_SMS

#--------------------------------------------------------------------#
# �嵥���ص�sqlldr��־,�ļ���Ϊ:������_����.log,�ļ�С(ÿ��5k)
# ���ݲ���: ����10��ǰ����Ϊtar,ÿ��GSMC1/GSMC2��һ���ļ�,�Ҳ���ѹ��
#--------------------------------------------------------------------#
log_append "backup dr load log"
srcpath=/data2/wj/center/log/dataloader/wj/sms
filetype="drload_log"
# backup_days_before=10
need_compress="N"

filepattern="N_CUSMS_HZ_GSMC*"
tarfile_prefix="gsmc_drload_log"
BACKUP_WJ_SMS

need_compress="Y"

#--------------------------------------------------------------------#
# �ʵ����ص����stat�ļ�
# ���ݲ���: ����10��ǰ����Ϊtar, ע���ļ����������Ǵ�������
#--------------------------------------------------------------------#
log_append "backup acc load file"
srcpath=/data2/wj/center/data/daydataloader/output/wj/sms
filetype="accload_out"
# backup_days_before=10

filepattern="*"
date_in_filename=2
tarfile_prefix="gsmc_accload_out"
BACKUP_WJ_SMS

#--------------------------------------------------------------------#
# �ʵ����ص�sqlldr��־,�ļ���Ϊstat.log,�ļ�С(ÿ��5k)
# ���ݲ���: ����10��ǰ����Ϊtar,ÿ��GSMC1/GSMC2��һ���ļ�,�Ҳ���ѹ��
#--------------------------------------------------------------------#
log_append "backup acc load log"
srcpath=/data2/wj/center/log/daydataloader/wj/sms
filetype="accload_log"
# backup_days_before=10
need_compress="N"

filepattern="N_CUSMS_HZ_GSMC*"
tarfile_prefix="gsmc_accload_log"
BACKUP_WJ_SMS


#--------------------------------------------------------------------#
log_append "backup end!"
echo "logfile is: $logfile"

exit 0