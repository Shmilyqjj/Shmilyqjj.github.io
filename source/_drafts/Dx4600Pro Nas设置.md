# DX4600 Pro Nas设置和操作

## 一.系统调整
### 1.SMB挂载到Windows后无权限执行exe文件
```shell
vim /etc/samba/smb.conf.template 增加参数
acl allow execute always = yes
保存，在页面重启SMB服务
```

### 2.开机自启脚本
```
vim /etc/init.d/z_startup_script 内容固定如下 (绿联nas的ugos系统基于openwrt，故服务启动脚本使用openwrt固定的形式)
#!/bin/bash /etc/rc.common
START=99
start(){
        # your commands here 这里添加你要执行的命令
        chmod 0666 /dev/net/tun
        echo "z_startup_script started"
}
stop(){
       echo "z_startup_script stopped"
}
restart(){
        echo "z_startup_script is restart"
}
保存后
chmod +x /etc/init.d/z_startup_script
/etc/init.d/z_startup_script enable
此时查看ll /etc/rc.d/  enable后成功建立软连接表示成功
  S99z_startup_script -> ../init.d/z_startup_script*
注意：START设为99，优先级最低，由于openwrt系统按文件字典序的顺序执行脚本，为了避免你的自定义脚本影响系统启动，需要降低你的脚本的优先级，所以z开头
```

### 3.系统日志
类似于/var/log/messages 抑或是journalctl
在绿联nas中可以通过以下方式查看系统日志
```shell
grep zerotier $(cat /var/log/ug_sys_log_flag)
```

## 二.Docker程序

### 1.Zerotier异地组网
```text
1.提升tun权限
chmod 0666 /dev/net/tun   (/dev/net/tun 每次重启权限都会复原，需要每次修改权限后启动容器)
2.拉取zerotier镜像
docker pull zerotier/zerotier
3.创建zerotier容器
docker create \
--restart unless-stopped \
--device /dev/net/tun \
--net host \
--cap-add NET_ADMIN \
--cap-add SYS_ADMIN \
-v /mnt/media_rw/70404831-2042-45cc-8a22-05ca4dfc95ba/.ugreen_nas/242136/.docker_data/zerotier-one:/var/lib/zerotier-one \
--name zerotier-one \
zerotier/zerotier
注意：
70404831-2042-45cc-8a22-05ca4dfc95ba为ssd盘路径
242136为数据存储实际目录
-v为永久保存config的路径的映射
4.检查容器是否启动成功运行正常
docker ps
5.加入到网络并验证
docker exec zerotier-one /bin/sh -c "zerotier-cli join xxx"
docker exec zerotier-one /bin/sh -c "zerotier-cli peers list"
6. 开机自启
root@UGREEN-CFE3:~# mkdir .config/init
cd /root/.config/init
vim  init_zerotier 内容如下（容器不断重试启动）：
#!/bin/bash
max_retries=10
retries=0
interval_sec=5
while [ $retries -lt $max_retries ]; do
    docker start zerotier-one
    container_status=$(docker inspect -f '{{.State.Status}}' zerotier-one)
    if [ "$container_status" == "running" ]; then
        sleep 2
        docker exec zerotier-one /bin/sh -c "zerotier-cli join your_network_id"
        echo "zerotier-one container started."
        exit 0
    else
        echo "zerotier-one start failed,sleep $interval_sec seconds.(Retries: $((retries+1)))"
        sleep $interval_sec
        ((retries++))
    fi
done
echo "Exceed limits of failed times,failed to start container zerotier-one."
exit 1
保存 并赋权 chmod +x init_zerotier
vim /etc/init.d/z_startup_script 修改 在start()方法里增加如下内容
chmod 0666 /dev/net/tun
/root/.config/init/init_zerotier
```

