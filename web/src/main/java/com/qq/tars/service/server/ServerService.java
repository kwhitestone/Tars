/*
 * Tencent is pleased to support the open source community by making Tars available.
 *
 * Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

package com.qq.tars.service.server;

import com.google.common.base.Preconditions;
import com.qq.tars.db.AdapterMapper;
import com.qq.tars.db.ServerMapper;
import com.qq.tars.entity.AdapterConf;
import com.qq.tars.entity.ConfigFile;
import com.qq.tars.entity.ServerConf;
import com.qq.tars.exception.DBConsistencyException;
import com.qq.tars.generated.tars.ConfigInfo;
import com.qq.tars.service.config.AddConfigFile;
import com.qq.tars.service.config.ConfigService;
import com.qq.tars.tools.DateTime;
import org.apache.commons.lang3.StringUtils;
import org.apache.ibatis.session.RowBounds;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
public class ServerService {

    @Autowired
    private ServerMapper serverMapper;

    @Autowired
    private AdapterMapper adapterMapper;

    @Autowired
    private ConfigService configService;

    @Transactional(rollbackFor = {Exception.class})
    public ServerConf addServerConf(DeployServer deployServer) {
        ServerConf serverConf = new ServerConf();
        BeanUtils.copyProperties(deployServer, serverConf);
        serverConf.setEnableSet(deployServer.isEnableSet() ? "Y" : "N");
        serverConf.setPosttime(DateTime.now());
        serverMapper.insertServerConf(serverConf);

        List<DeployAdapter> adapters = deployServer.getAdapters();
        adapters.forEach(servant -> {
            AdapterConf adapterConf = new AdapterConf();
            BeanUtils.copyProperties(servant, adapterConf);

            adapterConf.setApplication(serverConf.getApplication());
            adapterConf.setServerName(serverConf.getServerName());
            adapterConf.setNodeName(serverConf.getNodeName());

            adapterConf.setEndpoint(String.format("%s -h %s -t 60000 -p %s",
                    servant.getPortType(), servant.getBindIp(), servant.getPort()));

            adapterConf.setServant(String.format("%s.%s.%s",
                    adapterConf.getApplication(), adapterConf.getServerName(), servant.getObjName()));

            adapterConf.setAdapterName(String.format("%sAdapter",
                    adapterConf.getServant()));

            adapterConf.setPosttime(DateTime.now());
            adapterMapper.insertAdapterConf(adapterConf);
        });

        // 插入默认节点配置文件
        configService.addDefaultNodeConfigFile(serverConf.getApplication(), serverConf.getServerName(),
                serverConf.getNodeName(), "Y".equals(serverConf.getEnableSet()), serverConf.getSetName(),
                serverConf.getSetArea(), serverConf.getSetGroup());

        // 对于not_tars服务，增加默认配置文件
        if (deployServer.getServerType().equals("not_tars")) {
            String objName = "";
            if (adapters.size()>0) {
                objName = adapters.get(0).getObjName();
            }
            String file =
                    "<tars>\n" +
                    "   <servicestarter>\n" +
                    "       #precmd 表示开始启动程序之前执行的命令， 以 && 分隔，如 rpm -ivh xxx.rpm && sleep 10\n" +
                    "       precmd = \n" +
                    "       #env 表示程序启动时要设置的环境变量， 以 && 分隔， 如 LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./libs/ && LOGPATH=/data/log/\n" +
                    "       env = \n" +
                    "       #exe 表示可执行文件， 不填表示使用ServerName\n" +
                    "       exe = \n" +
                    "       #param 表示启动exe的参数 , 比如填上 -c {srsconfig} ， 表示启动参数是 -c srsconfig, srsconfig为另外一个配置文件\n" +
                    "       param = \n" +
                    "       #servant 为查询此服务信息的tars接口名\n" +
                    "       servant = "+objName+"\n" +
                    "       #info 为可以本服务的信息， json 格式 ， 注意查询时会被自动加上 \"ip\" 字段以表示本机ip \n" +
                    "       info = {\"port\": 0}\n" +
                    "   </servicestarter>\n" +
                    "</tars>";

            AddConfigFile conf = new AddConfigFile();
            conf.setApplication(deployServer.getApplication());
            conf.setConfig(file);
            conf.setFilename(deployServer.getApplication() + "." + deployServer.getServerName() + ".service");
            conf.setLevel(5);
            conf.setServerName(deployServer.getServerName());
            conf.setSetName(deployServer.getSetName());
            conf.setNodeName(deployServer.getNodeName());
            conf.setSetArea(deployServer.getSetArea());
            conf.setSetGroup(deployServer.getSetGroup());

            List<ConfigFile> serverconfigs =
            configService.getServerConfigFile(
                    deployServer.getApplication(),
                    deployServer.getServerName(),
                    deployServer.getSetName(),
                    deployServer.getSetArea(),
                    deployServer.getSetGroup());
            for (ConfigFile confFile : serverconfigs) {
                if (confFile.getFilename().equals(conf.getFilename())) {
                    try {
                        configService.deleteConfigFile(confFile.getId());
                    } catch (DBConsistencyException e) {
                        e.printStackTrace();
                    }
                }
            }
            configService.addConfigFile(conf);
        }

        return serverConf;
    }

    public int updateServerConf(ServerConf serverConf) {
        serverConf.setPosttime(DateTime.now());
        return serverMapper.updateServerConf(serverConf);
    }

    public ServerConf loadServerConf(long id) {
        return serverMapper.loadServerConf(id);
    }

    public ServerConf loadServerConf(String application, String serverName, String nodeName) {
        return serverMapper.loadServerConfByName(application, serverName, nodeName);
    }

    public List<ServerConf> loadServerConfs(List<Long> ids) {
        return serverMapper.loadServerConfs(ids);
    }

    public List<ServerConf> getServerConf(String treeNodeId, int curPage, int pageSize) {
        ServerConf serverConf = getServerConf4Tree(treeNodeId);

        return serverMapper.getServerConf(
                StringUtils.trimToNull(serverConf.getApplication()),
                StringUtils.trimToNull(serverConf.getServerName()),
                "Y".equals(serverConf.getEnableSet()),
                StringUtils.trimToNull(serverConf.getSetName()),
                StringUtils.trimToNull(serverConf.getSetArea()),
                StringUtils.trimToNull(serverConf.getSetGroup()),
                new RowBounds(curPage, pageSize)
        );
    }

    public List<ServerConf> getServerConfsByTemplate(String templateName) {
        Preconditions.checkArgument(StringUtils.isNotBlank(templateName));
        return serverMapper.getServerConfsByTemplate(templateName);
    }

    public ServerConf getServerConf4Tree(String treeNodeId) {
        ServerConf serverConf = new ServerConf();
        AtomicBoolean enableSet = new AtomicBoolean(false);
        Arrays.stream(treeNodeId.split("\\.")).forEach(s -> {
            int i = Integer.parseInt(s.substring(0, 1));
            String v = s.substring(1);
            switch (i) {
                case 1:
                    serverConf.setApplication(v);
                    break;
                case 2:
                    serverConf.setSetName(v);
                    enableSet.set(true);
                    break;
                case 3:
                    serverConf.setSetArea(v);
                    enableSet.set(true);
                    break;
                case 4:
                    serverConf.setSetGroup(v);
                    enableSet.set(true);
                    break;
                case 5:
                    serverConf.setServerName(v);
                    break;
                default:
                    break;
            }
        });
        serverConf.setEnableSet(enableSet.get() ? "Y" : "N");
        return serverConf;
    }

    public List<ServerConf> queryInactiveServerConfs(String application, String serverName, String nodeName,
                                                     int curPage, int PageSize) {
        return serverMapper.queryInactiveServerConf(application, serverName, nodeName, new RowBounds(curPage, PageSize));
    }

}
