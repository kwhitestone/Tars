#!/bin/bash

if [ $# != 2 ] ; then
    echo "usage:"
    echo "./build.sh type[cpp/java/initsql/buildall] localip"
    mkdir -p ../deploy/
    cp init.sh ../deploy/
    exit
fi


PWD_DIR=`pwd`
MachineIp=$2
MachineName=

mkdir -p ../deploy/
cp init.sh ../deploy/

depend() {
    yum install -y git
    git clone https://github.com/Tencent/rapidjson.git
    cp -r ./rapidjson ../cpp/thirdparty/
}

java() {
    cd ${PWD_DIR}
    rm ../deploy/tarsweb -rf
    rm ../deploy/tarsweb.tgz -f
    mkdir -p ../deploy/tarsweb/
    cp ./conf/app.config.properties ../deploy/tarsweb/
    cp ./conf/resin.xml ../deploy/tarsweb/
    cp ./conf/tars.conf ../deploy/tarsweb/
    
    cd ../java/
    mvn clean install 
    mvn clean install -f core/client.pom.xml 
    mvn clean install -f core/server.pom.xml
    cd -
    
    cd ${PWD_DIR}
    cd ../web/
    mvn clean package        
    cp ./target/tars.war ${PWD_DIR}/../deploy/tarsweb/ -rf
    cd ${PWD_DIR}
    cd ../deploy/
    tar czvf tarsweb.tgz tarsweb/
    rm tarsweb/ -rf
}

cpp() {   
    ps -ef |grep "tars" | grep -v "grep" | kill -9 `awk '{print $2}'` 
    cd ${PWD_DIR}
    find ../deploy/ -name "*.tgz" | grep -v tarsweb.tgz | xargs rm -f    
    yum install glibc-devel flex bison dos2unix -y
    cd ../cpp/build/
    rm *.tgz -f
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
    mkdir -p ../deploy/sql
    cp -r ../cpp/framework/sql/ ../deploy/sql
    cd ../deploy/ 
    tar czvf sql.tgz sql
    rm sql/ -rf
    cd ../cpp/build/framework/deploy/
    rm ../../framework.tgz -f
    tar czfv ../../framework.tgz tars_install.sh tarsnode_install.sh tarsnode tarsregistry tarsAdminRegistry tarspatch tarsconfig    
    
    echo "copyframewrok.............."
    cd ${PWD_DIR}
    cp ../cpp/build/*.tgz ../deploy/
}

buildall() {
    cpp
    java
}

$1
cd ${PWD_DIR}
mv ../deploy/ ../../ -f
