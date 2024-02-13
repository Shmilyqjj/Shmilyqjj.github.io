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
由于每次绿联nas固件更新后会初始化/etc/init.d目录导致我们的自定义脚本丢失，所以我们把启动脚本放入/etc/rc.d下，名为S99z_startup_script
rm /etc/rc.d/S99z_startup_script ; cp /etc/init.d/z_startup_script /etc/rc.d/S99z_startup_script
```

### 3.系统日志
类似于/var/log/messages 抑或是journalctl
在绿联nas中可以通过以下方式查看系统日志
```shell
grep zerotier $(cat /var/log/ug_sys_log_flag)
```

### 4.重新映射软连接
需求：将别人的存储空间映射到自己目录下以便可以在别人的存储空间上传。每次重启nas后挂载点会变化，这个脚本用于在开机后立刻重新映射软连接
vim /root/.scripts/remapping_soft_links.sh
```shell
#!/bin/bash
# remapping soft links when server restart

QJJ=242136
ZCY=259944
QG=264898

IMPORTANT=$(lsblk | grep -A2 raid1 | grep lvm | grep -v corig | grep 7.3T | awk '{print $7}' | head -n 1)
HE=$(lsblk | grep -A2 raid1 | grep lvm | grep -v corig | grep 16.4T | awk '{print $7}' | head -n 1)
SSD=$(lsblk | grep -A2 nvme0 | grep -v 1.9T | awk '{print $1}')

echo "[$(date +%Y%m%d_%H:%M:%S)]Mount points:" > /root/mount_info
echo IMPORTANT: $IMPORTANT >> /root/mount_info
echo HE: $HE >> /root/mount_info
echo SSD: $SSD >> /root/mount_info

# remount
rm /root/qjj/important
rm /root/qjj/he
rm /root/qjj/ssd
ln -s $IMPORTANT/.ugreen_nas/$QJJ/ /root/qjj/important
ln -s $HE/.ugreen_nas/$QJJ/ /root/qjj/he
ln -s $SSD/.ugreen_nas/$QJJ/ /root/qjj/ssd

rm /root/zcy/important
rm /root/zcy/he
rm /root/zcy/ssd
ln -s $IMPORTANT/.ugreen_nas/$ZCY/ /root/zcy/important
ln -s $HE/.ugreen_nas/$ZCY/ /root/zcy/he
ln -s $SSD/.ugreen_nas/$ZCY/ /root/zcy/ssd

rm /root/qg/important
rm /root/qg/he
rm /root/qg/ssd
ln -s $IMPORTANT/.ugreen_nas/$QG/ /root/qg/important
ln -s $HE/.ugreen_nas/$QG/ /root/qg/he
ln -s $SSD/.ugreen_nas/$QG/ /root/qg/ssd

echo "All Done"
```
chmod +x /root/.scripts/remapping_soft_links.sh
向/etc/rc.d/S99z_startup_script中start方法下加入 /root/.scripts/remapping_soft_links.sh

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
由于每次绿联nas固件更新后会初始化/etc/init.d目录导致我们的自定义脚本丢失，所以我们把启动脚本放入/etc/rc.d下，名为S99z_startup_script
rm /etc/rc.d/S99z_startup_script ; cp /etc/init.d/z_startup_script /etc/rc.d/S99z_startup_script
```

### Home Assistant
```
docker create --restart unless-stopped --net host --name="homeassistant" -v /mnt/media_rw/70404831-2042-45cc-8a22-05ca4dfc95ba/.ugreen_nas/242136/.docker_data/homeassistant:/config homeassistant/home-assistant:latest
```

## 三. 使用
### 1.Linux下挂载nas的smb
sudo mkdir -p /nas/SSD1
sudo mkdir -p /nas/SSD2
sudo mkdir -p /nas/HeSpace
sudo mkdir -p /nas/mt3000
sudo chmod 1777 -R /nas
//172.xx.xx.xx/shmily_SSD1 /nas/SSD1       cifs username=yourusername,password=yourpwd,iocharset=utf8 0 0
//172.xx.xx.xx/shmily_SSD2 /nas/SSD2       cifs username=yourusername,password=yourpwd,iocharset=utf8 0 0
//172.xx.xx.xx/shmily_HeSpace /nas/HeSpace cifs username=yourusername,password=yourpwd,iocharset=utf8 0 0
//172.xx.xx.xx/disk1_part1 /nas/mt3000     cifs username=yourusername,password=yourpwd,iocharset=utf8 0 0
