#!/bin/bash

echo "双显卡笔记本更新Manjaro系统后需要添加grub参数避免无法开机"

if [[ $(whoami) != root ]]; then
  echo -e "\033[41;37m[ERROR] Need sudo or root privilege.\033[0m"
  exit 1
fi

GRUB_CFG="/boot/grub/grub.cfg"
GRUB_CFG_BACKUP="$GRUB_CFG"_bak
KERNEL_CONF='acpi_osi=! acpi_osi="Windows 2009"'
BOOT_WAIT_TIMEOUT=3

echo "Backup path: $GRUB_CFG_BACKUP"
cp $GRUB_CFG $GRUB_CFG_BACKUP

sed -i 's/quiet/quiet $KERNEL_CONF/g' $GRUB_CFG

sed -i 's/timeout=10/timeout=$BOOT_WAIT_TIMEOUT/g' $GRUB_CFG

echo "Result:"
cat $GRUB_CFG | grep "quiet"
cat $GRUB_CFG | grep "timeout="

echo -e "\033[42;3mAll Done.\033[0m"