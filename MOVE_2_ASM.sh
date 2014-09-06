#!/bin/bash
   #===============================================================================================================
   #                                                                                                                                              
   #         FILE: MOVE_2_ASM
   #
   #        USAGE: 
   #
   #  DESCRIPTION:
   #      OPTIONS:  
   # REQUIREMENTS: 
   #       AUTHOR: MattDee (mattdee@gmail.com)
   #      CREATED:
   #      VERSION: 1.0
   #      EUL    : 	THIS CODE IS OFFERED ON AN “AS-IS” BASIS AND NO WARRANTY, EITHER EXPRESSED OR IMPLIED, IS GIVEN. 
   #				THE AUTHOR EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED.
   #				YOU ASSUME ALL RISK ASSOCIATED WITH THE QUALITY, PERFORMANCE, INSTALLATION AND USE OF THE SOFTWARE INCLUDING, 
   #				BUT NOT LIMITED TO, THE RISKS OF PROGRAM ERRORS, DAMAGE TO EQUIPMENT, LOSS OF DATA OR SOFTWARE PROGRAMS, 
   #				OR UNAVAILABILITY OR INTERRUPTION OF OPERATIONS. 
   #				YOU ARE SOLELY RESPONSIBLE FOR DETERMINING THE APPROPRIATENESS OF USE THE SOFTWARE AND ASSUME ALL RISKS ASSOCIATED WITH ITS USE.
   #
   #
   #
   #
   #
   #
   #===============================================================================================================
export RUNTIME=`date +%m_%d_%y_%H%M`



function start_up()
{
    clear screen
    echo "#########################################################"
    echo "# This will migrate your Oracle Database to ASM         #"
    echo "#########################################################"
 
    echo
    echo
    echo
 
    echo "################################################"
    echo "#                                              #"
    echo "#    What would you like to do ?               #"
    echo "#                                              #"
    echo "#          1 ==   Backup Database to ASM       #"
    echo "#                                              #"
    echo "#          2 ==   Create incremental bakup     #"
    echo "#                                              #"
    echo "#          3 ==   Migrate to ASM               #"
    echo "#                                              #"
    echo "#          4 ==   Do NOTHING                   #"
    echo "#                                              #"
    echo "################################################"
    echo
    echo "Please enter in your choice:> "
    read whatwhat
}



function level_0_backup_database()
{
#export ORACLE_SID=zeus

echo "What is the SID you would like to move to ASM? "
read ORASID

echo "What is the name of the ASM Disk Group where you would like to store the backup? "
read BACKUPLOC

export ORACLE_SID=$ORASID
rman target / <<EOF
 
 run {
 shutdown immediate;
 startup mount;
 	allocate channel dev1 type disk; 
	allocate channel dev2 type disk; 
	allocate channel dev3 type disk; 
	allocate channel dev4 type disk; 
	allocate channel dev5 type disk; 
	allocate channel dev6 type disk; 
	allocate channel dev7 type disk; 
	allocate channel dev8 type disk; 
	allocate channel dev9 type disk; 
	allocate channel dev10 type disk; 
 backup spfile;
 backup as copy INCREMENTAL LEVEL 0 database include current controlfile format '${BACKUPLOC}' TAG 'MOVE2ASM_MIGRATION' ;
 ALTER DATABASE BACKUP CONTROLFILE TO '/tmp/control.bkp';
	release channel dev1;
	release channel dev2;
	release channel dev3;
	release channel dev4;
	release channel dev5;
	release channel dev6;
	release channel dev7;
	release channel dev8;
	release channel dev9;
	release channel dev10;
shutdown immediate;
 }
 exit
EOF

echo "Here is your backup summary"
echo "---------------------------"
rman target / <<EOF
LIST BACKUP SUMMARY;
exit;
EOF

}



function level_1_backup_database()
{
#export ORACLE_SID=zeus

echo "What is the SID you would like to move to ASM? "
read ORASID

echo "What is the name of the ASM Disk Group where you would like to store the backup? "
read BACKUPLOC

export ORACLE_SID=$ORASID

rm /tmp/control.bkp

rman target / <<EOF
 
 run {
 shutdown immediate;
 startup mount;
 	allocate channel dev1 type disk; 
	allocate channel dev2 type disk; 
	allocate channel dev3 type disk; 
	allocate channel dev4 type disk; 
	allocate channel dev5 type disk; 
	allocate channel dev6 type disk; 
	allocate channel dev7 type disk; 
	allocate channel dev8 type disk; 
	allocate channel dev9 type disk; 
	allocate channel dev10 type disk; 
 backup spfile;
 backup INCREMENTAL LEVEL 1 FOR RECOVER OF COPY WITH TAG 'MOVE2ASM_MIGRATION' DATABASE  include current controlfile format '${BACKUPLOC}';
 ALTER DATABASE BACKUP CONTROLFILE TO '/tmp/control.bkp';
	release channel dev1;
	release channel dev2;
	release channel dev3;
	release channel dev4;
	release channel dev5;
	release channel dev6;
	release channel dev7;
	release channel dev8;
	release channel dev9;
	release channel dev10;
shutdown immediate;
 }
 exit
EOF


echo "Here is your backup summary"
echo "---------------------------"
rman target / <<EOF
LIST BACKUP SUMMARY;
exit;
EOF

}


function move_2_asm()
{

echo "What is the SID you would like to move to ASM? "
read ORASID

echo "What is the name of the ASM Disk Group where the backup is stored? "
read BACKUPLOC

export ORACLE_SID=$ORASID

#Shutdown the database
sqlplus / as sysdba <<EOF
shutdown immediate;
exit;
EOF


rman target / <<EOF

startup mount;
restore spfile to '${BACKUPLOC}/spfile${ORASID}';
shutdown immediate;

startup force nomount;
ALTER SYSTEM SET DB_CREATE_FILE_DEST='+DATA' SID='*' scope=spfile;
ALTER SYSTEM SET CONTROL_FILES='+DATA','+DATA' SCOPE=SPFILE;
shutdown immediate;

startup force nomount;
restore controlfile from '/tmp/control.bkp';
alter database mount;

SWITCH DATABASE TO COPY;
RUN
{
    allocate channel dev1 type disk;
    allocate channel dev2 type disk;
    allocate channel dev3 type disk;
    allocate channel dev4 type disk;
    allocate channel dev5 type disk;
    allocate channel dev6 type disk;
    allocate channel dev7 type disk;
    allocate channel dev8 type disk;
    allocate channel dev9 type disk;
    allocate channel dev10 type disk;
  RECOVER DATABASE;
}

alter database open;

sql 'select file_name from dba_data_files';

exit;

EOF

echo "++++++++++++++++++++++++++++++++++++++++++++++"
echo "+ Remember to migrate your REDO Logs to ASM! +"
echo "++++++++++++++++++++++++++++++++++++++++++++++"


}

function do_nothing()
{
    echo "################################################"
    echo "You don't want to do nothing...lazy..."
    echo "So...you want to quit...yes? "
    echo "Enter yes or no"
    echo "################################################"
    read DOWHAT
    if [[ $DOWHAT = yes ]]; then
        echo "Yes"
        exit 1
    else
        echo "No"
        work_time
    fi
     
}


function work_time()
{
start_up
case $whatwhat in
    1) 
        level_0_backup_database
        ;;
    2) 
        level_1_backup_database
        ;;
    3)
        move_2_asm
        ;;
    4)
        do_nothing
        ;;
esac
}


work_time














