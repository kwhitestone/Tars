#!/bin/bash

PWD_DIR=`pwd`
MachineIp=192.168.137.101
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
    /usr/local/resin/bin/resin.sh start
	
    cd ${PWD_DIR}
    cd ../web/
    cp ./src/main/resourcesback/* ./src/main/resources/ -f
    rm -rf ./src/main/resourcesback
}

cpp() {    
    yum install glibc-devel flex bison -y
    cd ../cpp/build/
    find ./ -name "*.sh" | xargs dos2unix 
    chmod u+x build.sh
    ./build.sh all
    ./build.sh install
    cd -

    cd ../cpp/build/
    make framework-tar
    make tarsstat-tar
    make tarsnotify-tar
    make tarsproperty-tar
    make tarslog-tar
    make tarsquerystat-tar
    make tarsqueryproperty-tar
    cd -

    mkdir -p ../deploy/    
    cp ../cpp/build/framework.tgz ../deploy/
    cd ../deploy/
    tar xzfv framework.tgz

    sed -i "s/192.168.2.131/${MachineIp}/g" `grep 192.168.2.131 -rl ./*`
    sed -i "s/db.tars.com/${MachineIp}/g" `grep db.tars.com -rl ./*`
    sed -i "s/registry.tars.com/${MachineIp}/g" `grep registry.tars.com -rl ./*`
    sed -i "s/web.tars.com/${MachineIp}/g" `grep web.tars.com -rl ./*`

    find ./ -name "*.sh" | xargs dos2unix 
    chmod u+x tars_install.sh
    ./tars_install.sh
    ./tarspatch/util/init.sh
}



$1
