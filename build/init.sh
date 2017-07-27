#!/bin/bash

if [ $# != 4 ] ; then
    echo "usage:"
    echo "./init.sh localip mysqlip mysqluser mysqlpass"
    exit
fi

MachineIp=$1
MysqlIp=$2
MysqlUser=$3
MysqlPass=$4

tar -zxvf framework.tgz
sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./* |grep -v "\\./init\\.sh" `
sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./* |grep -v "\\./init\\.sh" `
sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./* |grep -v "\\./init\\.sh" `
sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./* |grep -v "\\./init\\.sh" `

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
