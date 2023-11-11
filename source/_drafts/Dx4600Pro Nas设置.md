# DX4600 Pro Nas设置和操作

## 系统调整
### SMB挂载到Windows后无权限执行exe文件
```shell
vim /etc/samba/smb.conf.template 增加参数
acl allow execute always = yes
保存，在页面重启SMB服务
```

### 开机自启脚本
```
vim /etc/init.d/z_startup_script 内容固定如下
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


## Docker程序

### Zerotier异地组网
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
-v /mnt/media_rw/70404831-2042-45cc-8a22-05ca4dfc95ba/.ugreen_nas/242136/docker_config/zerotier-aws-planet/zerotier-one:/var/lib/zerotier-one \
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
```

