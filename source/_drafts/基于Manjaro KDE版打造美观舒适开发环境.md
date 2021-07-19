---
title: 基于Manjaro KDE版打造美观舒适开发环境
author: 佳境
avatar: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/img/custom/avatar.jpg
authorLink: shmily-qjj.top
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true
tags:
  - Linux
  - Manjaro
keywords: Manjaro
description: Manjaro Linux安装部署与美化
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Category_Images/technology/tech06.jpg
date: 2021-07-07 11:22:00
---
# 基于Manjaro KDE版打造美观舒适开发环境

## 系统安装与初始化配置
### 安装系统
到[Manjaro官网](https://manjaro.org/)下载最新ManjaroLinux发行版（本文基于Manjaro KDE Plasma 5.21.5版本）
到[Rufus官网](http://rufus.ie)下载镜像克隆工具
使用Rufus克隆Manjaro镜像到U盘，模式选择UEFI

系统BIOS设置项：
Boot顺序将系统安装盘改为第一项
关闭安全启动Security Boot => 否则无法引导进入Linux
SATA模式由Raid On切换为AHCI => 若系统有NVME硬盘则需要此操作，避免Linux无法识别到NVME硬盘（双系统用户先进入Windows->cmd运行msconfig->引导->勾选安全引导->重启的过程中会修复硬盘的AHCI驱动避免因切换AHCI导致无法启动Windows系统->重启后再取消勾选安全引导）

Windows+Linux双系统可以加如下参数使Windows把硬件时间当作UTC（避免双系统切换导致的时间错乱）
Reg add HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_DWORD /d 1

双显卡用户注意事项(单显卡忽略此步骤)：
Nvidia+Intel双显卡笔记本安装需要这步：安装前给内核传参=>按e在quiet后加：acpi_osi=! acpi_osi="Windows 2009"  按F10启动，否则会卡死无法进入桌面


/boot/efi分区挂载到原EFI分区，共384G空闲空间，根分区xfs格式192G，home分区xfs格式160G，var分区ext4格式24G，swap给8G（xfs读取效率和断电容错较好但写效率略微低于ext4，ext4写效率高些读效率低于xfs）

双显卡用户注意事项(单显卡忽略此步骤)：
重启第一次进入系统也需要按e在quiet后加：acpi_osi=! acpi_osi="Windows 2009"  按F10启动，否则会卡死无法进入桌面
进入系统后，
sudo vim /boot/grub/grub.cfg 在所有quiet后加acpi_osi=! acpi_osi="Windows 2009"参数，下次开机则不需要再加内核参数
（若系统更新了内核，grub.cfg也会被更新，需要重新加内核参数进入系统，重新修改grub.cfg文件）
建议每次更新系统执行如下脚本(update_grub.sh)自动增加内核参数：
```shell
#!/bin/bash
echo "双显卡笔记本更新Manjaro系统后需要添加grub参数避免无法开机"
if [[ $(whoami) != root ]]; then
  echo -e "\033[41;37m[ERROR] Need sudo or root privilege.\033[0m"
  exit 1
fi
GRUB_CFG="/boot/grub/grub.cfg"
GRUB_CFG_BACKUP="$GRUB_CFG"_bak
echo "Backup path: $GRUB_CFG_BACKUP"
cp $GRUB_CFG $GRUB_CFG_BACKUP
if [ -n "$(grep "Windows 2009" $GRUB_CFG)" ]; then
  echo "Grub config is ok,no update."
else
  echo "Grub config need to be updated.Go to update it."
  # 防止不能加载显卡不能进桌面
  sed -i 's/quiet/quiet acpi_osi=! acpi_osi="Windows 2009"/g' $GRUB_CFG
  # 开机等待界面超时时间设为3s
  sed -i 's/timeout=10/timeout=3/g' $GRUB_CFG
fi
echo -e "\033[42;3mAll Done. Result:\033[0m"
cat $GRUB_CFG | grep "quiet"
cat $GRUB_CFG | grep "timeout="
```
双显卡用户目前无论安装任何Linux发行版都很坑，对于Manjaro,奉上设置显卡切换的教程：[Manjaro 笔记本配置Intel与Nvidia双显卡切换，防踩坑教程](https://zhuanlan.zhihu.com/p/102525227) 


### 初始化系统
安装必备系统镜像源
```shell
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
# 更新镜像排名
sudo pacman-mirrors -i -c China -m rank 
cp /etc/pacman.conf /etc/pacman.conf.backup
# 添加ArchLinux中文社区源
sudo vi /etc/pacman.conf
  [archlinuxcn]
  SigLevel = Optional TrustedOnly
  #清华源
  Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
  #中科大源
  #Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
# 配置生效
sudo pacman-mirrors -g
# 更新pacman数据库全面更新系统并签名
sudo pacman -Syyu && sudo pacman -S archlinuxcn-keyring
# 安装一些常用的包
sudo pacman -S acpi vim
```

### 创建一些目录及配置免密
```shell
su root
chmod 1777 /opt
# 存放我的应用
mkdir /opt/apps
chmod 1777 -R /opt/apps/
usermod -a -G root shmily 
# sudo免密 避免频繁输入密码 以我用户名shmily为例(sudo su只切用户不带root的环境变量 sudo su -带root环境变量跟root用户一样)
sudo vim /etc/sudoers
shmily ALL=(ALL) NOPASSWD: ALL
清徐%sudo ALL=(ALL) ALL前的注释#
sudo vim /etc/sudoers.d/10-installer
在%wheel ALL=(ALL) ALL行后添加如下配置
shmily ALL=(ALL) NOPASSWD: ALL
%shmily ALL=(ALL) NOPASSWD: ALL
# 用户代码项目存放目录
su shmily
sudo mkdir -p /opt/Projects/
sudo mkdir -p /opt/Projects/OpenSourceProjects
sudo mkdir -p /opt/Projects/MyProjects
sudo mkdir -p /opt/Projects/EnterpriseProjects
sudo chmod 1777 -R /opt/Projects/
# 系统环境所需目录
sudo mkdir -p /opt/Env/
# 工具目录
sudo mkdir -p /opt/Tools/
```
软件商店启用AUR和Snap源

### 输入法
输入法首选安装:
sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-qt fcitx5-gtk kcm-fcitx5 fcitx5-material-color
```shell
sudo vim ~/.pam_environment （在当前桌面登陆的用户下执行）
INPUT_METHOD  DEFAULT=fcitx5
GTK_IM_MODULE DEFAULT=fcitx5
QT_IM_MODULE  DEFAULT=fcitx5
XMODIFIERS    DEFAULT=\@im=fcitx5
```
**<u>后续如果其他用户需要中文输入法 也需要在每个用户的家目录下加以上环境变量</u>**
注销重新登陆后生效
如何更新主题 换主题[Fcitx5-Material-Color](https://github.com/hosxy/Fcitx5-Material-Color)
**说明：**fcitx5为主体，fcitx5-chinese-addons中文输入方式支持fcitx5-qt，对Qt5程序的支持fcitx5-gtk，对GTK程序的支持fcitx5-qt4-gitAUR，对Qt4程序的支持kcm-fcitx5是KDE下的配置工具，不过在gnome下也可以正常使用。
提示：一般情况下，只安装fcitx5-qt和fcitx5-gtk就可以了，配置工具fcitx5的配置文件位于~/.local/share/fcitx5，尽管您可以使用文本编辑器编辑配置文件，但是使用 GUI 配置显然更方便，kcm-fcitx5集成到 KCM 中的配置工具，专为KDE而生fcitx5-config-qt-git AUR：Qt前端的fcitx5配置工具，与kcm-fcitx5相冲突。
注意：对于非 KDE 界面，可以使用 fcitx5-config-qt-gitAUR,该软件包与 kcm-fcitx5 相冲突，你需要手动卸载它环境变量。
**其他可选输入法组件：**
sunpinyin+sunpinyin-data
fcitx-sunpinyin
ibus-sunpinyin
kcm-fcitx

### Git配置
```shell
git config --global user.name "shmily"
git config --global user.email 710552907@qq.com
git config --global http.version HTTP/1.1
git config --global core.autocrlf false
git config --global core.safecrlf true
git config --global core.autocrlf input #提交时转换为LF，检出时不转换
git config http.proxy socks5://127.0.0.1:7891  # 因为我的Clash代理sock端口是7891
```


### 系统常规优化
```shell
# 1.启用TRIM会帮助清理SSD中的块，从而延长SSD的使用寿命
sudo systemctl enable fstrim.timer
# 2.安装中文字体
sudo pacman -S wqy-zenhei
sudo pacman -S wqy-bitmapfont
sudo pacman -S wqy-microhei
sudo pacman -S ttf-wps-fonts
sudo pacman -S adobe-source-han-sans-cn-fonts
sudo pacman -S adobe-source-han-serif-cn-fonts
```


## 安装常用软件
```shell
# 微信、TIM
sudo pacman -S yay
yay --aururl https://aur.tuna.tsinghua.edu.cn --save
sudo pacman -Sy base-devel
yay -S com.qq.weixin.spark
yay -S com.qq.tim.spark
# #########################
sudo pacman -S google-chrome  # Chrome
sudo pacman -S netease-cloud-music  # 网易云音乐
sudo pacman -S unrar unzip p7zip  # 解压
### 安装WPS：软件商店安装如下包：wps-office-cn wps-office-mui-zh-cn wps-office-mime-cn ttf-wps-fonts
sudo pacman -S gimp  # 修图
sudo pacman -S neofetch screenfetch  # 输出系统信息
yay -S todesk;sudo systemctl enable todeskd.service;sudo systemctl start todeskd.service;sudo systemctl status todeskd.service #远程桌面工具
### 远程桌面连接工具remmina
sudo pacman -S remmina
安装工程会提示
remmina 的可选依赖
    freerdp: RDP plugin
    libsecret: Secret plugin [已安装]
    libvncserver: VNC plugin
    libxkbfile: NX plugin [已安装]
    nxproxy: NX plugin
    spice-gtk: Spice plugin
    telepathy-glib: Telepathy plugin
    xorg-server-xephyr: XDMCP plugin
    gnome-terminal: external tools
选择自己想要的依赖，如RDP远程桌面连接:
sudo pacman -S freerdp
# #########################################################
sudo pacman -S deepin-screen-recorder  # 深度录屏
# 企业微信安装
https://aur.archlinux.org/packages/com.qq.weixin.work.deepin/ 下载deb包
用Ark打开deb包 解压出data.tar.xz 再解压data.tar.xz中的opt/apps/com.qq.weixin.work.deepin解压到/opt/apps/
cd /opt/apps/com.qq.weixin.work.deepin 修改/opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop中Icon的值：/opt/apps/com.qq.weixin.work.deepin/entries/icons/hicolor/48x48/apps/com.qq.weixin.work.deepin.svg
sudo cp /opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop /usr/share/applications
# 安装文件多设备同步工具
sudo pacman -S syncthing
软件仓库安装：Typora，Shotcut，laptop-mode-tools(可选 有tlp可以不用) 
软件仓库安装:timeshift
```

Clash科学上网
[下载Clash](https://github.com/Dreamacro/clash/releases)
```shell
cd ~/下载
gunzip clash-linux-amd64-v1.6.5.gz
mkdir /opt/apps/Clash
mv clash-linux-amd64-v1.6.5 /opt/apps/Clash/
cd /opt/apps/Clash
chmod +x clash-linux-amd64-v1.6.5
./clash-linux-amd64-v1.6.5 直到出现INFO[0003] Mixed(http+socks5) proxy listening at: 127.0.0.1:7890即可关闭
ls ~/.config/clash 会有config.yaml  Country.mmdb 如果没出现上述INFO日志则可能是Country.mmdb下载失败，可以手动下载
sudo touch /usr/share/applications/Clash.desktop
chmod a+x /usr/share/applications/Clash.desktop
cat>/usr/share/applications/Clash.desktop<<EOF
[Desktop Entry]
Name=Clash For Linux
Comment=clash-for-linux
Encoding=UTF-8
Exec=/opt/apps/Clash/clash-linux-amd64-v1.6.5
Icon=/opt/apps/Clash/logo_64.png
Categories=System;Application;Network;
StartupNotify=true
Terminal=false
Type=Application
EOF
# 生效我们的代理配置文件
cp ~/下载/Clash_1625991739.yaml  ~/.config/clash/config.yaml
```
使用WebUI管理连接：
根据cat ~/.config/clash/config.yaml | grep external-controller的结果，通过http://clash.razord.top进行策略组节点的切换
只浏览网页推荐使用Chrome浏览器插件Proxy SwitchyOmega：

必要时可以使用系统全局代理：
进入系统设置->网络设置->使用系统代理服务器配置(或使用手动设置的代理服务器)->http代理设为127.0.0.1:7890 Socks代理设置为127.0.0.1:7891
配置Clash开机自启：
cp /usr/share/applications/Clash.desktop ~/.config/autostart/








### 开发环境安装
sudo pacman -S net-tools dnsutils inetutils iproute2 stress python-pip screen htop bat tree ncdu tig tldr
sudo pacman -S nodejs
sudo pacman -S npm
sudo pacman -S make
sudo pacman -S cmake
sudo pacman -S clang
sudo pacman -S maven
```shell
# 下载jdk-8u181-linux-x64.tar.gz
sudo tar -zxvf jdk-8u181-linux-x64.tar.gz -C /opt/Env/
# 下载scala-2.12.12.tgz
sudo tar -zxvf scala-2.12.12.tgz -C /opt/Env/
sudo vim /etc/profile
export JAVA_HOME=/opt/Env/jdk1.8.0_181
export PATH=$PATH:$JAVA_HOME/bin
export SCALA_HOME=/opt/Env/scala-2.12.12
export PATH=$PATH:$SCALA_HOME/bin
source /etc/profile
```

Python源
sudo pip config --global set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
sudo pip config --global set install.trusted-host pypi.tuna.tsinghua.edu.cn
 
Mysql安装：https://blog.csdn.net/uniondong/article/details/98392738


### 开发工具安装
```shell
sudo pacman -S intellij-idea-ultimate-edition  # 安装IDEA最新旗舰版
sudo pacman -S pycharm-community-edition # 安装PyCharm
sudo pacman -S goland  # 安装Goland
sudo pacman -S gitkraken # Git GUI管理工具
yay -S typora # Typora markdown工具
# 安装VSCode：
# 首先官网去下载安装包vscode官网https://code.visualstudio.com 得到code-stable-xxxxxxx.tar.gz
tar -zxvf code-stable-x64-1623937300.tar.gz -C /opt/apps/
sudo chmod +x /opt/apps/VSCode-linux-x64/code
ln -s /opt/apps/VSCode-linux-x64/code /usr/local/bin/code
touch /usr/share/applications/VSCode.desktop
chmod +x /usr/share/applications/VSCode.desktop
cp /opt/apps/VSCode-linux-x64/resources/app/resources/linux/code.png /usr/share/icons/
cat>/usr/share/applications/VSCode.desktop<<EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Multi-platform code editor for Linux
Exec=/opt/apps/VSCode-linux-x64/code
Icon=/usr/share/icons/code.png
Type=Application
StartupNotify=true
Categories=TextEditor;Development;Utility;
MimeType=text/plain;
EOF

```

Sublime安装https://www.sublimetext.com/docs/3/linux_repositories.html#pacman
激活码：
----- BEGIN LICENSE -----
Member J2TeaM
Single User License
EA7E-1011316
D7DA350E 1B8B0760 972F8B60 F3E64036
B9B4E234 F356F38F 0AD1E3B7 0E9C5FAD
FA0A2ABE 25F65BD8 D51458E5 3923CE80
87428428 79079A01 AA69F319 A1AF29A4
A684C2DC 0B1583D4 19CBD290 217618CD
5653E0A0 BACE3948 BB2EE45E 422D2C87
DD9AF44B 99C49590 D2DBDEE1 75860FD2
8C8BB2AD B2ECE5A4 EFC08AF2 25A9B864
------ END LICENSE ------​

                                                
## 美化


# 安装zsh oh-my-zsh：https://zhuanlan.zhihu.com/p/58073103


Terminus：https://github.com/Eugeny/tabby




 

 
Deepin软件-去软件仓库 ： 深度影院 深度相机





### 虚拟机软件
安装VirtualBox:
mhwd-kernel -li  (我的是linux510，则安装linux510-virtualbox-host-modules) 
sudo pacman -Syu virtualbox linux510-virtualbox-host-modules
重启或执行sudo vboxreload

安装KVM（备选）：
pacman -S qemu libvirt ovmf virt-manager
（kvm负责CPU和内存的虚拟化，qemu向Guest OS模拟硬件，ovmf为虚拟机启用UEFI支持，libvirt提供管理虚拟机和其它虚拟化功能的工具和API，virt-manager是管理虚拟机的GUI）
systemctl enable libvirtd
systemctl start libvirtd
usermod -a -G kvm shmily
启动qem/virt-manager






安装docker
sudo pacman -S docker













ls -l命令简写ll
sudo vim /etc/profile和~/.bashrc
alias ls='ls --color'
alias ll='ls -l --color'



清理内存 echo 1 > /proc/sys/vm/drop_caches

Ramfs: 创建一个最大大小为8G的RAMFS
mkdir -p /ramfs
mount -t ramfs none /ramfs -o maxsize=8388608
实际测试超过8G也会存，可能导致系统内存占满崩溃
所以挂载tmpfs--据说速度比ramfs还快，限制大小有用，能使用SWAP空间
mkdir -p /tmpfs
mount tmpfs /tmpfs -t tmpfs -o size=8192m


系统备份和还原两种方式：
使用tar压缩包打包备份系统 https://www.cnblogs.com/smlile-you-me/p/13601039.html
使用timeshift恢复系统


# 开机自启脚本
su root
vim /etc/systemd/system/rc-local.service 创建该文件
```shell
[Unit]
Description="/etc/rc.local Compatibility" 

[Service]
Type=oneshot
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardInput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
```

vim /etc/rc.local 创建该文件
```shell
#!/bin/sh
# /etc/rc.local
if test -d /etc/rc.local.d; then
    for rcscript in /etc/rc.local.d/*.sh; do
        test -r "${rcscript}" && sh ${rcscript}
    done
    unset rcscript
fi
```
chmod a+x /etc/rc.local
mkdir /etc/rc.local.d
systemctl enable rc-local.service
自定义脚本放在/etc/rc.local.d/里就可以了



# 解决无法写和更新NTFS盘数据的问题：
创建 /usr/bin/fix_ntfs_disk_rw.sh 内容：
```shell
#!/bin/bash
# Fix NTFS Disk which can not be writen on linux system.
# Usage: sh fix_ntfs_disk_rw.sh /run/media/shmily/Entertainment /Entertainment
DEFAULT_MOUNT_POINT=$1
TARGET_MOUNT_POINT=$2
if [ "$(whoami)" != "root" ];then
  echo User root is necessary.
  exit 1
fi
current_point=$(df -h | grep $DEFAULT_MOUNT_POINT | awk '{print $1}')
echo "Remounting point $current_point from $DEFAULT_MOUNT_POINT to $TARGET_MOUNT_POINT"
sudo ntfsfix $current_point
sudo umount $DEFAULT_MOUNT_POINT
sudo mkdir -p $TARGET_MOUNT_POINT
sudo chmod 1777 $TARGET_MOUNT_POINT
sudo mount -t ntfs -o rw $current_point $TARGET_MOUNT_POINT
echo "All Done"
```
将系统默认挂载点重新挂载为自定义的挂载点 用法sh fix_ntfs_disk_rw.sh /run/media/shmily/Entertainment /Entertainment



# 安装Jetbrains全家桶 创建快捷方式参考：
创建GoLand.desktop 内容如下
[Desktop Entry]
Name=GoLand
Comment=GoLand
Exec=/opt/apps/IDEs/GoLand/bin/goland.sh
Icon=/opt/apps/IDEs/GoLand/bin/goland.png
Terminal=false
Type=Application
Categories=Development

然后执行sudo desktop-file-install GoLand.desktop 安装快捷方式



# 使用Wine运行一些常见Windows程序
  中文显示问题修复：
  在windows下拷贝字体文件——simsun.ttc（c:\windows\fonts\simsun.ttc），复制到
~/.wine/drive_c/windows/Fonts下；
然后，编辑reg文件，文件内容如下：
REGEDIT4
[HKEY_LOCAL_MACHINE\Software\Microsoft\NT\CurrentVersion\FontSubstitutes]
"Arial"="simsun"
"Arial CE,238"="simsun"
"Arial CYR,204"="simsun"
"Arial Greek,161"="simsun"
"Arial TUR,162"="simsun"
"Courier New"="simsun"
"Courier New CE,238"="simsun"
"Courier New CYR,204"="simsun"
"Courier New Greek,161"="simsun"
"Courier New TUR,162"="simsun"
"FixedSys"="simsun"
"Helv"="simsun"
"Helvetica"="simsun"
"MS Sans Serif"="simsun"
"MS Shell Dlg"="simsun"
"MS Shell Dlg 2"="simsun"
"System"="simsun"
"Tahoma"="simsun"
"Times"="simsun"
"Times New Roman CE,238"="simsun"
"Times New Roman CYR,204"="simsun"
"Times New Roman Greek,161"="simsun"
"Times New Roman TUR,162"="simsun"
"Tms Rmn"="simsun"
 （注：按照windows的格式，最后一行之后要敲回车符）
保存文件名为fonts.reg，保存在~/.wine下；
然后导入regedit：
    打开gnome-terminal，输入指令  cd ~/.wine
                                regedit fonts.reg
导入成功。
最后，打开regedit，~/.wine/drive_c/windows/regedit.exe,依次找到 HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes，将该键下的MS Shell Dlg和MS Shell Dlg2键值删除。
Wine运行程序： wine xxx.exe



## 参考链接
[Manjaro Gnome 下fcitx5的安装](https://www.zhihu.com/question/333951476/answer/1280162871)
[Fcitx5-Material-Color](https://github.com/hosxy/Fcitx5-Material-Color)


