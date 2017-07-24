#!/bin/bash

if [ $# != 2 ] ; then
    echo "usage:"
    echo "./build.sh type[cpp/java] localip"
    exit
fi


PWD_DIR=`pwd`
MachineIp=$2
MachineName=

depend() {
    yum install -y git
    git clone https://github.com/Tencent/rapidjson.git
    cp -r ./rapidjson ../cpp/thirdparty/
}

java() {
    cd ../java/
    mvn clean install 
    mvn clean install -f core/client.pom.xml 
    mvn clean install -f core/server.pom.xml
    cd -

    cd ${PWD_DIR}
    cd ../web/
	
    mkdir ./src/main/resourcesback/
    cp ./src/main/resources/*.* ./src/main/resourcesback/	
	
    sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./src/main/resources/*`
    sed -i "s/registry1.tars.com/${MachineIp}/g" `grep registry1.tars.com -rl ./src/main/resources/*`
    sed -i "s/registry2.tars.com/${MachineIp}/g" `grep registry2.tars.com -rl ./src/main/resources/*`

    mvn clean package
    cp ./target/tars.war /usr/local/resin/webapps/

    cd -
    mkdir -p /data/log/tars/
    cp ./conf/resin.xml /usr/local/resin/conf/
    /usr/local/resin/bin/resin.sh restart
	
    cd ${PWD_DIR}
    cd ../web/
    cp ./src/main/resourcesback/* ./src/main/resources/ -f
    rm -rf ./src/main/resourcesback
}

cpp() {   
    ps -ef |grep "tars" | grep -v "grep" | kill -9 `awk '{print $2}'` 
    cd ${PWD_DIR}
    rm ../deploy/ -rf
    yum install glibc-devel flex bison dos2unix -y
    cd ../cpp/build/
    find ./ -name "*.sh" | xargs dos2unix 
    chmod u+x build.sh
    ./build.sh all
    ./build.sh install
    
    cd ${PWD_DIR}    
    cd ../cpp/build/
    make framework-tar 
    make tarsstat-tar
    make tarsnotify-tar
    make tarsproperty-tar
    make tarslog-tar
    make tarsquerystat-tar
    make tarsqueryproperty-tar
    
    echo "buildframework.............."
    cd ${PWD_DIR}
    mkdir -p ../deploy/
    cd ../cpp/build/framework/deploy/
    rm ../../framework.tgz -f
    tar czfv ../../framework.tgz tars_install.sh tarsnode_install.sh tarsnode tarsregistry tarsAdminRegistry tarspatch tarsconfig    
    
    
    echo "copyframewrok.............."
    cd ${PWD_DIR}
    mkdir -p /usr/local/app/tars/
    cp ../cpp/build/*.tgz ../deploy/
    cp ../cpp/build/framework.tgz /usr/local/app/tars/
    
    cd /usr/local/app/tars/
    rm -f app_log
    rm -f remote_app_log	
    rm tarsnode -rf
    tar xzfv framework.tgz

    sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
    sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./*`
    sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
    sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`

    ln -s /data/tars/app_log app_log
    ln -s /data/tars/remote_app_log remote_app_log

    find ./ -name "*.sh" | xargs dos2unix 
    chmod u+x tars_install.sh
    ./tars_install.sh
    ./tarspatch/util/init.sh
}

initsql() {
    mysql -uroot -proot@appinside -e "grant all on *.* to 'tars'@'%' identified by 'tars2015' with grant option;"
    mysql -uroot -proot@appinside -e "grant all on *.* to 'tars'@'localhost' identified by 'tars2015' with grant option;"
    mysql -uroot -proot@appinside -e "grant all on *.* to 'tars'@'${MachineName}' identified by 'tars2015' with grant option;"
    mysql -uroot -proot@appinside -e "flush privileges;"
    cp -r ../cpp/framework/sql/ ./
    cd sql
    sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
    sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./*`
    chmod u+x exec-sql.sh
    ./exec-sql.sh
    cd ../
    rm -rf sql
}

$1
