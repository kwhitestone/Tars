#!/bin/bash

if [ $# != 4 ] ; then
    echo "usage:"
    echo "./init.sh localip mysqlip mysqluser mysqlpass"
    exit
fi

PWD_DIR=$PWD
MachineIp=$1
MysqlIp=$2
MysqlUser=$3
MysqlPass=$4

#copy 
mkdir -p /usr/local/app/tars/
cp framework.tgz tarsweb.tgz sql.tgz /usr/local/app/tars/

#java web
cd /usr/local/app/tars/
tar -zxvf tarsweb.tgz
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./tarsweb/*`
sed -i "s/registry1.tars.com/${MachineIp}/g" `grep registry1.tars.com -rl ./tarsweb/*`
sed -i "s/registry2.tars.com/${MachineIp}/g" `grep registry2.tars.com -rl ./tarsweb/*`
mkdir -p /data/log/tars/
mv /usr/local/resin/conf/resin.xml /usr/local/resin/conf/resin.xml_`date +%y%m%d_%H%M%S` -f
cp tarsweb/tars.war /usr/local/resin/webapps/ -r
cp tarsweb/resin.xml /usr/local/resin/conf/
/usr/local/resin/bin/resin.sh stop
/usr/local/resin/bin/resin.sh start

#cpp
tar -zxvf framework.tgz
rm -f app_log
rm -f remote_app_log	
sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./* |grep -v "\\./init\\.sh" `
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./* |grep -v "\\./init\\.sh" `
sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./* |grep -v "\\./init\\.sh" `
sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./* |grep -v "\\./init\\.sh" `
yum install -y dos2unix
find ./ -name "*.sh" | xargs dos2unix
ln -s /data/tars/app_log app_log
ln -s /data/tars/remote_app_log remote_app_log
chmod u+x tars_install.sh
./tars_install.sh
./tarspatch/util/init.sh

#sql
tar -zxvf sql.tgz
cd sql
sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./*`
mysql -h${MysqlIp} -u${MysqlUser} -p${MysqlPass} -e "grant all on *.* to 'tars'@'%' identified by 'tars2015' with grant option;"
mysql -h${MysqlIp} -u${MysqlUser} -p${MysqlPass} -e "grant all on *.* to 'tars'@'localhost' identified by 'tars2015' with grant option;"
mysql -h${MysqlIp} -u${MysqlUser} -p${MysqlPass} -e "grant all on *.* to 'tars'@'${MachineName}' identified by 'tars2015' with grant option;"
mysql -h${MysqlIp} -u${MysqlUser} -p${MysqlPass} -e "flush privileges;"
mysqldump -h${MysqlIp} -u${MysqlUser} -p${MysqlPass} db_tars > db_tars.sql
cd ../
#rm -rf sql/
