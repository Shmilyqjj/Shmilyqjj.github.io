---
title: 基于Manjaro KDE版打造美观舒适开发环境
author: 佳境
avatar: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/Resources/img/custom/avatar.jpg
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
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/Manjaro-Cover.png
abbrlink: 3f34ebe3
date: 2021-07-07 11:22:00
---
# 基于Manjaro KDE版打造美观舒适开发环境

## 系统安装与初始化配置
### 安装系统
到[Manjaro官网](https://manjaro.org/)下载最新ManjaroLinux发行版（本文基于Manjaro KDE Plasma 5.21.5版本）
到[Rufus官网](http://rufus.ie)下载镜像克隆工具，使用Rufus克隆Manjaro镜像到U盘，模式选择UEFI

系统BIOS设置项：
Boot顺序将系统安装盘改为第一项
关闭安全启动Security Boot => 否则无法引导进入Linux
SATA模式由Raid On切换为AHCI => 若系统有NVME硬盘则需要此操作，避免Linux无法识别到NVME硬盘（双系统用户先进入Windows->cmd运行msconfig->引导->勾选安全引导->重启的过程中会修复硬盘的AHCI驱动避免因切换AHCI导致无法启动Windows系统->重启后再取消勾选安全引导）

![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-01.JPG)  
双显卡用户注意事项(单显卡忽略此步骤)：
Nvidia+Intel双显卡笔记本安装需要这步：安装前给内核传参=>按e在quiet后加：acpi_osi=! acpi_osi="Windows 2009"  按F10启动，否则会卡死无法进入桌面
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-02.JPG)  
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-03.JPG) 

双击 Install Manjaro Linux打开安装向导
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-01.png)  
时区选择Asia/ShangHai
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-02.png) 
键盘默认即可
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-03.png)
接下来是关键步骤 磁盘要选手动分区 
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-04.png) 
磁盘空间规划：
/boot/efi分区挂载到原EFI分区，共384G空闲空间，根分区xfs格式192G，home分区xfs格式160G，var分区ext4格式24G，swap给8G（xfs读取效率和断电容错较好但写效率略微低于ext4，ext4写效率高些读效率低于xfs）
在空闲区域创建分区 步骤如下：
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-05.png)
数据分区最终结果如下：
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-06.png)
启动分区(EFI分区) 如下设置：
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-07.png)
最后设置系统管理员用户
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-08.png)
安装完成后 可以重启

双显卡用户注意事项(单显卡忽略此步骤)：
重启第一次进入系统也需要按e在quiet后加：acpi_osi=! acpi_osi="Windows 2009"  按F10启动，否则会卡死无法进入桌面
进入系统后：
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

至此 Manjaro Linux系统安装完成

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
注意，如果遇到“无效或已损坏的软件包 (PGP 签名)”这样的报错，可以尝试修改“Optional TrustedOnly”为“Optional TrustAll”

根据个人习惯创建一些目录
（我的习惯并不好，把一部分项目文件放在/opt下，/opt本身是用于安装一些大型软件的。正常情况下，一个用户的个人文件放在家目录下比较规范）
```shell
su root
chmod 1777 /opt
# 存放我的应用
mkdir /opt/apps
chmod 1777 -R /opt/apps/
usermod -a -G root shmily 
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

配置免密
```shell
# sudo免密 避免频繁输入密码 以我用户名shmily为例(sudo su只切用户不带root的环境变量 sudo su -带root环境变量跟root用户一样)
sudo vim /etc/sudoers
shmily ALL=(ALL) NOPASSWD: ALL
清徐%sudo ALL=(ALL) ALL前的注释#
sudo vim /etc/sudoers.d/10-installer
在%wheel ALL=(ALL) ALL行后添加如下配置
shmily ALL=(ALL) NOPASSWD: ALL
%shmily ALL=(ALL) NOPASSWD: ALL
```
软件商店勾选启用AUR和Snap源
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-09.png)

### 中文输入法安装
输入法首选安装:
sudo pacman -S fcitx5 fcitx5-chinese-addons fcitx5-qt fcitx5-gtk kcm-fcitx5 fcitx5-material-color
yay -S noto-color-emoji-fontconfig  打字支持emoji表情😘
```shell
sudo vim ~/.pam_environment （在当前桌面登陆的用户下执行）
INPUT_METHOD  DEFAULT=fcitx5
GTK_IM_MODULE DEFAULT=fcitx5
QT_IM_MODULE  DEFAULT=fcitx5
XMODIFIERS    DEFAULT=\@im=fcitx5
```
**<u>后续如果其他用户需要中文输入法 也需要在每个用户的家目录下加以上环境变量</u>**
注销重新登陆后生效
配置输入法：
将拼音上移，作为默认输入法
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-10.png)
设置shift按键为切换中英文输入的按键
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-11.png)
根据个人习惯 设置共享输入状态 (我一般不设置) 
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-12.png)
更换输入法主题:
```shell
vim ~/.config/fcitx5/conf/classicui.conf
# 垂直候选列表
Vertical Candidate List=False
# 按屏幕 DPI 使用
PerScreenDPI=True
# Font (设置成你喜欢的字体)
Font="思源黑体 CN Medium 13"
# 主题名称(对应~/.local/share/fcitx5/themes下的主题目录名称)
Theme=Material-Color-DeepPurple
然后重启输入法即可生效
也可以下载主题包文件解压到~/.local/share/fcitx5/themes目录下并修改~/.config/fcitx5/conf/classicui.conf来设置不同主题
```
简约黑白主题下载地址:[fcitx5-simple-themes.zip](https://github.com/Shmilyqjj/BlogImages-0/blob/master/cdn_sources/Blog_Images/Manjaro/fcitx5-simple-themes.zip)

启用云拼音
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-42.png)
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-43.png)
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-44.png)
**说明：**fcitx5为主体，fcitx5-chinese-addons中文输入方式支持fcitx5-qt，对Qt5程序的支持fcitx5-gtk，对GTK程序的支持fcitx5-qt4-gitAUR，对Qt4程序的支持kcm-fcitx5是KDE下的配置工具，不过在gnome下也可以正常使用。
提示：一般情况下，只安装fcitx5-qt和fcitx5-gtk就可以了，配置工具fcitx5的配置文件位于~/.local/share/fcitx5，尽管您可以使用文本编辑器编辑配置文件，但是使用 GUI 配置显然更方便，kcm-fcitx5集成到 KCM 中的配置工具，专为KDE而生fcitx5-config-qt-git AUR：Qt前端的fcitx5配置工具，与kcm-fcitx5相冲突。
注意：对于非KDE界面，可以使用fcitx5-config-qt-gitAUR,该软件包与kcm-fcitx5相冲突，你需要手动卸载它。
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
git config --global core.safecrlf false
git config --global core.autocrlf input #提交时转换为LF，检出时不转换
git config http.proxy socks5://127.0.0.1:7891  # 因为我的Clash代理sock端口是7891
git config --global --add remote.origin.proxy ""
git config --global core.editor "vim"
```

### 开机自启脚本部署
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
# ls -l命令简写ll
 sudo vim /etc/profile和~/.bashrc
 alias ls='ls --color'
 alias ll='ls -l --color'
```

### 双系统优化
Windows+Linux双系统可以加如下参数使Windows把硬件时间当作UTC（避免双系统切换导致的时间错乱）
Reg add HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_DWORD /d 1

### Linux音频音质优化及蓝牙连接问题解决
1.蓝牙连接总是失败，极小概率成功：
vim /etc/bluetooth/main.conf  修改ControllerMode为bredr
```conf
# Restricts all controllers to the specified transport. Default value
# is "dual", i.e. both BR/EDR and LE enabled (when supported by the HW).
# Possible values: "dual", "bredr", "le"
# ControllerMode = dual 
ControllerMode = bredr 
```
2.音质提升
目前Linux系统播放音质差是通病，使用pulseaudio可以让Linux音质恢复到与Mac、Windows相近的水平，更多pulseaudio的高阶使用可参考：[PulseAudio - ArchWiki](https://wiki.archlinux.org/title/PulseAudio)
软件包管理器中安装pulseaudio、pulseaudio-bluetooth，以及其他pulseaudio相关包(可自行选择)
安装后重启蓝牙服务并启动pulseaudio：
```shell
systemctl restart bluetooth
systemctl status bluetooth
pulseaudio --start   # 将此命令放到开机自启脚本
```
3.蓝牙设备经常需要重新配对
蓝牙鼠标、蓝牙耳机经常需要重新配对,每次重启都需要重新配对,解决办法:
sudo vim /etc/bluetooth/main.conf
修改FastConnectable = false，取消#注释，改为FastConnectable = true
修改AutoEnable=false，取消#注释，改为AutoEnable=true
systemctl restart bluetooth


## 安装应用和工具
### 常用软件安装
```shell
# 微信、TIM
sudo pacman -S yay
yay --aururl https://aur.tuna.tsinghua.edu.cn --save
sudo pacman -Sy base-devel
yay -S com.qq.weixin.spark
yay -S com.qq.tim.spark
yay -S ocs-url
增大dpi避免窗口和字体过小（在打开的窗口中设置 2k屏幕建议值168-192）：
env WINEPREFIX=/home/shmily/.deepinwine/Spark-WeChat/ deepin-wine5 winecfg
env WINEPREFIX=/home/shmily/.deepinwine/Spark-TIM/ deepin-wine5 winecfg
-------------------------------------------------------------------------------------------------------
sudo pacman -S google-chrome  # Chrome
sudo pacman -S netease-cloud-music  # 网易云音乐
yay -S tenvideo # 腾讯视频
sudo pacman -S unrar unzip p7zip  # 解压
### 安装WPS：软件商店安装如下包：wps-office-cn wps-office-mui-zh-cn wps-office-mime-cn ttf-wps-fonts
sudo pacman -S gimp  # 修图
sudo pacman -S neofetch screenfetch  # 输出系统信息
-------------------------------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------------------------------
### 企业微信安装
https://aur.archlinux.org/packages/com.qq.weixin.work.deepin/ 下载deb包
用Ark打开deb包 解压出data.tar.xz 再解压data.tar.xz中的opt/apps/com.qq.weixin.work.deepin解压到/opt/apps/
cd /opt/apps/com.qq.weixin.work.deepin 修改/opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop中Icon的值：/opt/apps/com.qq.weixin.work.deepin/entries/icons/hicolor/48x48/apps/com.qq.weixin.work.deepin.svg
sudo cp /opt/apps/com.qq.weixin.work.deepin/entries/applications/com.qq.weixin.work.deepin.desktop /usr/share/applications
增大dpi避免窗口和字体过小（在打开的窗口中设置 2k屏幕建议值168-192）：
env WINEPREFIX=/home/shmily/.deepinwine/Deepin-WXWork/ deepin-wine5 winecfg
-------------------------------------------------------------------------------------------------------
设置shell欢迎语 登陆Shell环境 会自动输出
cat <<EOT >/etc/motd
QJJ加油，你最月半！ 
EOT
-------------------------------------------------------------------------------------------------------
软件仓库安装：Typora，Shotcut，laptop-mode-tools(可选 有tlp可以不用) 
软件仓库安装:timeshift (系统可能已经自带了)
软件仓库安装:深度影院 深度相机 BaiduNetDisk百度网盘
-------------------------------------------------------------------------------------------------------
# 安装文件同步工具 多端同步
sudo pacman -S syncthing
参考https://github.com/syncthing/syncthing/tree/main/etc/linux-desktop创建快捷方式
启动Syncthing的快捷方式syncthing-start.desktop
[Desktop Entry]
Name=Start Syncthing
GenericName=File synchronization
Comment=Starts the main syncthing process in the background.
Exec=/usr/bin/syncthing serve --no-browser --logfile=default
Icon=syncthing
Terminal=false
Type=Application
Keywords=synchronization;daemon;
Categories=Network;FileTransfer;P2P
查看Syncthing UI的快捷方式syncthing-ui.desktop
[Desktop Entry]
Name=Syncthing Web UI
GenericName=File synchronization UI
Comment=Opens Syncthing's Web UI in the default browser (Syncthing must already be started).
Exec=/usr/bin/syncthing -browser-only
Icon=syncthing
Terminal=false
Type=Application
Keywords=synchronization;interface;
Categories=Network;FileTransfer;P2P
生效快捷方式
sudo desktop-file-install syncthing-start.desktop
sudo desktop-file-install syncthing-ui.desktop
```

### Clash科学上网
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
**使用WebUI管理连接**：
根据cat ~/.config/clash/config.yaml | grep external-controller的结果，通过http://clash.razord.top进行策略组节点的切换
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-13.png)

只浏览网页推荐使用Chrome浏览器插件Proxy SwitchyOmega:
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-14.png)
**必要时可以使用系统全局代理**：
进入系统设置->网络设置->使用系统代理服务器配置(或使用手动设置的代理服务器)->http代理设为127.0.0.1:7890 Socks代理设置为127.0.0.1:7891
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-15.png)
**配置Clash开机自启**：
```shell
cp /usr/share/applications/Clash.desktop ~/.config/autostart/
```

### 截屏录屏
1. 功能全面的录屏和串流直播软件
sudo pacman -S obs-studio
2. kazam
sudo pacman -S kazam 可以截图和录屏的工具
3. 深度截图
sudo pacman -S deepin-screenshot
4. 自带截图工具Spectacle
日常截图自带截图工具就足够了，只是与Windows端我们常用的Ctrl+Alt+A不太一样，可以记住它的快捷键，用起来也很方便
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-16.png) 
主要常用的就是Meta+Print （即Win+PrtScn） 截取当前活动的窗口
5. 深度录屏
sudo pacman -S deepin-screen-recorder    
ln -s /usr/bin/deepin-screen-recorder /usr/bin/sr   运行sr命令使用
添加截图功能到系统全局快捷方式:设置->快捷键->自定义快捷键->编辑->新建->全局快捷键->命令/URL->命令/usr/bin/deepin-screen-recorder 触发器Ctrl+Alt+A

### 词典翻译
词典与屏幕取词翻译工具
sudo pacman -S goldendict
下载[朗文词典文件:提取码9m43](https://pan.baidu.com/s/1Zr7Z0iOPba7oDw75OzQQzw) (如果链接失效也可从其他途径下载)
mkdir /home/shmily/tools/.LDOCE_Dict 将词典文件放进去
在GoldenDict上配置词典即可.
[!alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-45.png)

### 久坐提醒
可以设置久坐提醒,小憩时间的工具,可强制休息
```shell
yay -S stretchly-bin
```
[!alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-46.png)

### 开发环境安装
```shell
sudo pacman -S net-tools dnsutils inetutils iproute2 stress python-pip screen htop bat tree ncdu tig tldr
sudo pacman -S nodejs
sudo pacman -S npm
sudo pacman -S make
sudo pacman -S cmake
sudo pacman -S clang
sudo pacman -S maven
----------------------------------------------------------------------------------
# Java、Scala环境安装
# 下载jdk-8u181-linux-x64.tar.gz
# 卸载系统默认jdk（系统默认使用Java8会导致部分依赖java运行的软件出现不兼容现象，建议将系统JAVA_HOME改为jdk11+版本）
sudo archlinux-java unset  # 否则不会从环境变量读java地址
sudo tar -zxvf jdk-8u181-linux-x64.tar.gz -C /opt/Env/
# 下载scala-2.12.12.tgz
sudo tar -zxvf scala-2.12.12.tgz -C /opt/Env/
# 下载Golang https://golang.google.cn/dl/go1.18.3.linux-amd64.tar.gz
sudo tar -zxvf go1.18.3.linux-amd64.tar.gz -C /opt/Env/
mkdir -p /home/shmily/.gopath  
sudo vim /etc/profile
export JAVA8_HOME=/opt/Env/jdk1.8.0_181
export JAVA_HOME=/opt/Env/jdk-11.0.11
export PATH=$PATH:$JAVA_HOME/bin
export SCALA_HOME=/opt/Env/scala-2.12.12
export PATH=$PATH:$SCALA_HOME/bin
source /etc/profile
export GO_HOME=/opt/Env/go1.18.3
export PATH=$PATH:$GO_HOME/bin
sudo pacman -S pkg-config
-------------------------------------------------------------------
Python源切换
sudo pip config --global set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
sudo pip config --global set install.trusted-host pypi.tuna.tsinghua.edu.cn
----------------------------------------------------------------------------------------
Mysql安装：
pacman -Si mysql	 # 查看仓库中的MySQL版本号
sudo pacman -S mysql  # 安装mysql
sudo mkdir /opt/mysql-data
sudo chmod 1777 /opt/mysql-data
sudo mysqld --initialize --user=shmily --basedir=/usr --datadir=/opt/mysql-data --character-set-server=UTF8MB4
vim /etc/mysql/my.cnf  修改datadir=/opt/mysql-data
chmod -R 777 /opt/mysql-data
sudo systemctl start mysqld.service
systemctl status mysqld.service
初始密码登陆  
alter user 'root'@'localhost' identified with mysql_native_password by '123456'
mysql -uroot -p123456
sudo systemctl enable mysqld.service  # 设置开机启动mysql server (可选)
```

### 支持Ubuntu系安装包(.deb包)
git clone https://github.com/helixarch/debtap
cd debtap
sudo cp debtap /usr/local/bin
（前三步可以用yay -S debtap或yaourt -S debtap代替）
sudo debtap -u  更新软件包
如果sudo debtap -u过程下载很慢，需要换源
```text
vim /usr/bin/debtap
替换：http://ftp.debian.org/debian/dists
https://mirrors.ustc.edu.cn/debian/dists

替换：http://archive.ubuntu.com/ubuntu/dists
https://mirrors.ustc.edu.cn/ubuntu/dists/
```
然后就可以操作安装.deb包了
debtap xxx.deb （一路下一步，证书选GPL）得到解析后的安装包(Final Package)
sudo pacman -U 解析后的安装包


### 开发工具安装
```shell
# JetBrains全家桶 命令行方式安装
sudo pacman -S intellij-idea-ultimate-edition  # 安装IDEA最新旗舰版
sudo pacman -S pycharm-community-edition # 安装PyCharm
sudo pacman -S goland  # 安装Goland
# JetBrains全家桶 手动下载方式安装 [推荐]
# 以GoLand为例
tar -zxvf goland-xxx.tar.gz -C /opt/apps/
mv /opt/apps/goland-2021.3.4 /opt/apps/GoLand
cd /opt/apps/GoLand
touch GoLand.desktop 内容如下
[Desktop Entry]
Name=GoLand
Comment=GoLand
Exec=/opt/apps/GoLand/bin/goland.sh
Icon=/opt/apps/GoLand/bin/goland.png
Terminal=false
Type=Application
Categories=Development
然后执行sudo desktop-file-install GoLand.desktop 安装快捷方式
-----------------------------------------------------------------------
# 安装VSCode(yay -S visual-studio-code-bin)：
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
-----------------------------------------------------------------------
# Typora markdown工具
yay -S typora 
# Sublime安装 参考https://www.sublimetext.com/docs/3/linux_repositories.html#pacman
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
```

### 虚拟机软件安装
安装VirtualBox:
mhwd-kernel -li  (当前系统是linux510，则安装linux510-virtualbox-host-modules) 
sudo pacman -Syu virtualbox linux510-virtualbox-host-modules
重启或执行sudo vboxreload

安装KVM（备选）：
pacman -S qemu libvirt ovmf virt-manager
（kvm负责CPU和内存的虚拟化，qemu向Guest OS模拟硬件，ovmf为虚拟机启用UEFI支持，libvirt提供管理虚拟机和其它虚拟化功能的工具和API，virt-manager是管理虚拟机的GUI）
systemctl enable libvirtd
systemctl start libvirtd
usermod -a -G kvm shmily
启动qem/virt-manager

### 安卓应用支持
参考UOS(Deepin)对于安卓应用支持的解决方案，采用XDroid作为安卓应用支持软件。
先下载XDroid软件：[官网下载XDroid](https://www.linzhuotech.com/Product/download)
执行tar -zxvf xDroidInstall-x86_64-vxxxx.tar.gz 解压
执行 ./xDroidInstall-x86_64-vxxxx.run 安装XDroid
安装后重启一到两次即可完成安装
应用商城
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-38.png) 
已安装应用
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-39.png) 
使用Android APP
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-40.png) 


## 系统界面美化
Manjaro Linux是可以随用户心情随意定制的，可定制化程度极高，是桌面控的福音。下面做一些简单的界面设置。
### Dock栏
sudo pacman -S latte-dock
根据偏好设置latte dock
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-17.png) 
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-18.png) 
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-19.png) 
效果
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-20.png) 

替代品: plank 
优点: 资源占用较latte-dock小很多,支持多种皮肤下载
缺点: 点图标后所有该程序的窗口都被打开
sudo pacman -S plank
设置plank:
plank --preferences

### oh-my-zsh
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-21.png) 
```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
#安装powerlevel10k主题
sudo pacman -Sy --noconfirm zsh-theme-powerlevel10k
#配置powerlevel10k
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >>! ~/.zshrc
#使配置立即生效
source ~/.zshrc
# 按提示设置即可 设置时建议不要带图标，因为在其他用到zsh的终端上可能会出现乱码或方框，很不美观，可以在其他用到zsh的终端上重新执行p10k configure命令来设置更合适的样式。
# 安装语法高亮插件
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
echo "source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc
source ~/.zshrc
```

### 命令行终端
可选代替Konsole的更好看的命令行终端
Tabby(原Terminus)：https://github.com/Eugeny/tabby
继续配置Konsole:

|   |   |
| ---- | ---- |
| <img src="https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-22.png" width=100% style="border:solid 3px #CCFFFF" title="Konsole配置" align=left alt="Konsole配置"> | <img src="https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-23.png" width=100% style="border:solid 3px #CCFFFF" title="Konsole配置" align=right alt="Konsole配置"> |
| <img src="https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-24.png" width=100% style="border:solid 3px #CCFFFF" title="Konsole配置" align=left alt="Konsole配置"> | <img src="https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-25.png" width=100% style="border:solid 3px #CCFFFF" title="Konsole配置" align=right alt="Konsole配置"> |
| <img src="https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-26.png" width=100% style="border:solid 3px #CCFFFF" title="Konsole配置" align=left alt="Konsole配置"> | <img src="https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-27.png" width=100% style="border:solid 3px #CCFFFF" title="Konsole配置" align=right alt="Konsole配置"> |


### 全局主题
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-Desktop.png) 

打开设置->外观->全局主题
之所以喜欢用Mac的全局主题（McSur-dark）是因为它的任务栏比较好看比较精致
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-28.png) 

### 窗口
窗口选择了这款，按钮比较简洁，是和Mac相近的，但按钮位置在右边，我还是比较习惯这种按键位置。点击主题上的按钮可以调节主题按键大小，下方可以调节窗口边框大小
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-29.png) 
窗口配色方案我选的Ambiance-ISH，亮色看起来更敞亮，心情更好。
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-30.png) 

### 登陆页
登陆页面只有每次开机时才会出现，锁屏是单独的锁屏页面。
打开设置->开机与关机->登录屏幕(SDDM) 在这里设置
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-33.png) 
效果：
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-32.png) 

### 欢迎屏幕
开机在登陆页面输入密码后会进入欢迎屏幕，大概有2秒左右停留在欢迎屏幕，随便选个好看的就可以了。
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-31.png) 

### 锁屏界面
每次锁屏(Meta+L)后都会显示这个页面。
打开设置->工作区行为->锁屏->外观：配置
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-34.png) 

### 桌面特效
这里会有一些神奇的界面效果，如窗口惯性拖动，最小化神灯效果，窗口切换效果等。
打开设置->工作区行为->桌面特效
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-35.png) 
主要改动的地方：气泡相关、窗口背景虚化、窗口透明度、窗口惯性晃动、最小化过渡动画(神灯)、窗口后滑特效、窗口打开\关闭动效、虚拟桌面切换动效

### 手动安装主题、壁纸、插件
本节主要使用kpackagetool5命令
打开https://store.kde.org/  可以安装一些主题
比如安装动态壁纸插件：
下载Smart Video Wallpaper插件的tar包：https://store.kde.org/p/1316299/
kpackagetool5 -t Plasma/Wallpaper -i smartvideowallpaper.tar.gz
然后进入壁纸设置选择壁纸类型还有视频路径即可
比如安装主题：kpackagetool5 -t Plasma/Theme -i Gently.tar.gz

### 娱乐命令
```shell
yay -S oneko   # 一只跟着鼠标走的小猫
sudo pacman -S nyancat  # shell窗口中的彩虹猫
yay -S hollywood  # 好莱坞效果shell
sudo pacman -S cmatrix  # 黑客帝国效果shell
sudo pacman -S sl  # ls错写成sl后会显示小火车
sudo pacman -S fortune-mod # 随机一句笑话\名言 (中文版本可以在应用商店安装fortune-mod-zh)
sudo pacman -S cowsay  # cowsay -f tux haha ; cowsay haha 让cowsay说出fortune的内容: fortune | cowsay
sudo pacman -S figlet # 艺术字生成器，由ASCII字符组成，把文本显示成标题栏,可加颜色  figlet haha 
sudo pacman -S toilet # 艺术字生成器，由ASCII字符组成，把文本显示成标题栏,可加颜色  toilet haha 
sudo pacman -S xorg-xeyes  # 执行xeyes 一双大眼睛盯着你的鼠标
cal 1 1998 显示月日历
shred /tmp/aaa 损坏文件,破坏文件内容让人无法识别和查看
yay -S boxes # ASCII艺术框 echo "Haha" | boxes ; echo "Haha" | boxes -d dog
yay -S aview # 图片转ASCII图像
```

### 动态壁纸工具
KDE本身有动态壁纸插件,可以在壁纸设置中下载**SmartER video Wallpaper**插件:
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-41.png) 
还有一款资源开销较低的动态壁纸软件:**fantascene-dynamic-wallpaper** 可以在应用商店找到
动态壁纸将动态视频文件反序列化到内存中,会一定程度占用显卡\CPU和内存资源.低配电脑不建议使用.


## 系统使用小技巧与问题处理
### 解决无法写和更新NTFS盘数据的问题：
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

### 系统清理
内存清理
sudo su
sync
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
echo 3 > /proc/sys/vm/drop_caches
日志清理
journalctl --disk-usage 查看日志占用
sudo journalctl --vacuum-size=500M  限制归档日志大小，对日志做清除操作，适用于/var占用较大的场景

### 搜索工具
Alt+Space 全局搜索工具 会在桌面上方弹出搜索框 可以搜索应用、文件、目录、服务、设置等
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-36.png) 

### 解决thermal误报导致自动关机
报错kernel: thermal thermal_zone3: critical temperature reached (125 C), shutting down  直接被关机
sudo chmod 665 /sys/class/thermal/thermal_zone3/mode
sudo echo "disabled" > /sys/class/thermal/thermal_zone3/mode 
这个参数需要每次系统启动时重新写入,放入开机启动脚本路径/etc/rc.local.d/

### bash下所有命令均不可用
原因:可能存在错误的环境变量配置,不过不影响zsh因为zsh是单独的.zshrc配置文件
修复: 在~/.bashrc末尾加上如下内容 修复PATH
export PATH="$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

### 包管理器与软件依赖管理
```shell
# 卸载孤包:（孤包:孤立包,不被引用的包,无用的包）
pacman -R $(pacman -Qtdq)
# 清除已下载的安装包
sudo pacman -Scc
# 对整个系统进行更新
sudo pacman -Syu
# 升级软件包
sudo pacman -Syu
# 清理软件包缓存
sudo pacman -Sc
# 清理所有的缓存文件
sudo pacman -Scc
# 安装或者升级单个软件包，或者一列软件包（包含依赖包），使用如下命令：
sudo pacman -S package_name1 package_name2 ...
# 安装或者升级单个软件包，或者一列软件包,同步包数据库后再执行安装
sudo pacman -Sy package_name package_name2 ...
# 安装本地包 其扩展名为pkg.tar.gz或pkg.tar.xz
sudo pacman -U local_package_name
# 安装一个远程包
sudo pacman -U url http://www.example.com/repo/example.pkg.tar.xz
# 在仓库中搜索含关键字的包
sudo pacman -Ss keyword
# 查看已安装软件
sudo pacman -Qs keyword   
# 删除单个软件包，保留其全部已经安装的依赖关系
sudo pacman -R package_name
# 删除指定软件包，及其所有没有被其他已安装软件包使用的依赖关系(要删除软件包和所有依赖这个软件包的程序，警告: 此操作是递归的，请小心检查，可能会一次删除大量的软件包)
sudo pacman -Rs package_name
# 从 AUR 安装软件包
yay -S package 
# yay卸载包
yay -Rns package 
# 升级所有已安装的包(包括AUR源)
yay -Syu
# 更新AUR仓库的软件
yay -Syyu
# 打印系统统计信息
yay -Ps
# 检查安装包的版本
yay -Qi package
```


### 必须掌握的系统备份和恢复技巧
Linux各个依赖包之间存在复杂的依赖关系，同时我们经常使用较高的权限操作，可能会因为种种原因导致系统出现各种问题，所以备份还原是必备的技巧，能在系统宕机或滚挂后可以还原到某个先前的时间节点，来保护我们辛辛苦苦调教了很久的系统不会出意外。
注意：系统检测到有大更新时，不要急于更新，要首先使用timeshift做一个快照，再更新。原因是部分情况下，系统更新后看似没问题，但实际上软件的依赖库版本发生了变化，导致有部分软件无法正常运行了，这种情况不易发现。要养成先快照再升级的习惯。
系统备份和还原两种方式：
使用tar压缩包打包备份系统 https://www.cnblogs.com/smlile-you-me/p/13601039.html
使用timeshift的快照备份和还原系统
1. 按照向导设置：选择快照类型:RSYNC->选择快照位置(选一个分区，注意只能选Linux文件系统的分区，不支持远程、NTFS等)->选择快照等级(根据重要性和磁盘空间选择备份周期和保留快照数)->用户主目录(默认全部)
2. 点击创建 会立刻运行快照创建程序，创建完如图
![alt ](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Manjaro/ManjaroInstall-37.png) 
3. 家目录有些文件可能不需要备份，需要排除一部分文件：设定->筛选 可以自定义不对特定模式的文件创建快照
4. 恢复快照: 选中要恢复的快照 点击恢复即可
5. 当错误操作导致系统崩溃无法进入界面时，需要进入命令行使用timeshift相关命令恢复:
通过Ctrl+Alt+F1（一般是F1-F6都可）进入tty终端 输入用户和密码登录 
  ```shell
  *** 查看可还原的还原点
  sudo timeshift --list  
  /dev/nvme0n1p9 is mounted at: /run/timeshift/backup, options: rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota

  Device : /dev/nvme0n1p9
  UUID   : d4fa3365-62fe-4488-ba18-b36ddac64c4d
  Path   : /run/timeshift/backup
  Mode   : RSYNC
  Status : OK
  2 snapshots, 75.5 GB free

  Num     Name                 Tags  Description  
  ------------------------------------------------------------------------------
  0    >  2021-08-12_12-24-49  O                  
  1    >  2021-08-12_14-00-01  M                  
  *** 还原快照  --skip-grub选项为跳过grub安装，一般来说grub不需要重新安装，除非bios启动无法找到正确的grub启动项，才需要安装
  sudo timeshift --restore --snapshot '2021-08-12_14-00-01' --skip-grub
  ```

6. 无法进入系统也无法进入tty命令行
参照文章开始的部分创建Manjaro安装盘，进入LiveCD桌面，安装timeshift 按上一步的步骤进行恢复
恢复完成后桌面无法加载程序快捷方式->解决：yay -Syuu执行系统更新即可

### 使用Wine运行Windows程序
**Wine （“Wine Is Not an Emulator” 的首字母缩写）**是一个能够在多种POSIX-compliant操作系统（诸如Linux，macOS及BSD等）上运行Windows应用的兼容层。Wine不是像虚拟机或者模拟器一样模仿内部的Windows逻辑，而是將Windows API调用翻译成为动态的POSIX调用，免除了性能和其他一些行为的内存占用，让你能够干净地集合Windows应用到你的桌面。
安装wine 忽略 之前的步骤已经有wine了
sudo pacman -S wine wine_gecko wine-mono
sudo pacman -S lib32-mesa lib32-nvidia-utils
**中文显示问题修复：**
  在windows下拷贝字体文件——simsun.ttc（c:\windows\fonts\simsun.ttc），复制到
~/.wine/drive_c/windows/Fonts下；
然后，编辑reg文件，文件内容如下：
```text
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

```
（注：按照windows的格式，最后一行之后要敲回车符）保存文件名为fonts.reg，保存在~/.wine下；然后导入regedit：打开gnome-terminal，输入指令  cd ~/.wine ; regedit fonts.reg 最后，打开regedit，~/.wine/drive_c/windows/regedit.exe,依次找到 HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\FontSubstitutes，将该键下的MS Shell Dlg和MS Shell Dlg2键值删除。

**Wine使用**
Wine运行程序: wine xxx.exe
msi安装包运行: msiexec -i <msi安装包>

**Deepin-wine**
Deepin-Wine是Deepin团队移植的Wine，在其基础上移植的很多软件如微信、TIM/QQ、网易云音乐等有着更好的兼容性和使用体验。
注意，Deepin-Wine是32位的，并且其依赖于Wine，因此本机上安装的Wine最好是32位的，否则Deepin-Wine使用命令时会有不便。
安装(忽略 之前的步骤已有此依赖) yaourt deepin-wine
使用方法与wine基本一致

更多Wine进阶使用可以了解[Wine官方网站](https://www.winehq.org/) [Linux使用Wine](https://blog.csdn.net/buildcourage/article/details/80871141)

### AUR仓库与软件包查询
https://aur.archlinux.org/packages

### 系统硬件信息查询
全部硬件信息输出：
```shell
 sudo dmidecode  >> hardware.info
 hwinfo
```

### 钉钉Linux版无法输入中文
sudo vim /usr/bin/dingtalk 在 export PATH 后面加如下两行
```
export XMODIFIERS="@im=ibus"
export QT_IM_MODULE="ibus"
```

## 参考链接
[Manjaro Wiki](https://wiki.manjaro.org/index.php?title=Main_Page)
[Manjaro Gnome 下fcitx5的安装](https://www.zhihu.com/question/333951476/answer/1280162871)
[Fcitx5-Material-Color](https://github.com/hosxy/Fcitx5-Material-Color)
[ArchLinux Wiki](https://wiki.archlinux.org/)
[Syncthing](https://github.com/syncthing/syncthing)
[Manjaro安装Mysql8.0（血泪篇）](https://blog.csdn.net/uniondong/article/details/98392738)
[archlinux Timeshift系统备份与还原](https://www.cnblogs.com/orginly/p/14806538.html)
[轻松上手Manjaro之Manjaro下使用Wine](https://blog.csdn.net/zbgjhy88/article/details/85110956)
[Manjaro-KDE安装动态桌面插件](https://blog.csdn.net/weixin_43372529/article/details/112190604)
[如何让Ubuntu系统支持LDAC，APTX，AAC编码（提升蓝牙音质）](https://blog.csdn.net/hqsiswiliam/article/details/105574212)
[PulseAudio - ArchLinux Wiki](https://wiki.archlinux.org/title/PulseAudio)
