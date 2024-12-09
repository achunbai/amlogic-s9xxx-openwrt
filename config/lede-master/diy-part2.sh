#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt for Amlogic s9xxx tv box
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/coolsnowwolf/lede / Branch: master
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Modify default theme（FROM uci-theme-bootstrap CHANGE TO luci-theme-material）
# sed -i 's/luci-theme-bootstrap/luci-theme-material/g' ./feeds/luci/collections/luci/Makefile

# Add autocore support for armvirt
sed -i 's/TARGET_rockchip/TARGET_rockchip\|\|TARGET_armvirt/g' package/lean/autocore/Makefile

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/lean/default-settings/files/zzz-default-settings
echo "DISTRIB_SOURCECODE='lede'" >>package/base-files/files/etc/openwrt_release

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
# sed -i 's/192.168.1.1/192.168.31.4/g' package/base-files/files/bin/config_generate

# Replace the default software source
# sed -i 's#openwrt.proxy.ustclug.org#mirrors.bfsu.edu.cn\\/openwrt#' package/lean/default-settings/files/zzz-default-settings
#
# ------------------------------- Main source ends -------------------------------

# ------------------------------- Other started -------------------------------
#
# Add luci-app-amlogic
rm -rf package/luci-app-amlogic
git clone https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic

# 移除 package/openclash（如果存在）
if [ -d "package/openclash" ]; then
    rm -rf package/openclash
    echo "已删除目录 package/openclash。"
fi

# 创建 package/openclash 目录
mkdir -p package/openclash
if [ $? -ne 0 ] || [ ! -d "package/openclash" ]; then
    echo "创建目录 package/openclash 失败。"
    exit 1
fi
echo "已创建目录 package/openclash。"

# 创建临时目录
mkdir -p tmp
echo "已创建临时目录 tmp。"

# 下载 master.zip 到 tmp 目录
wget -O tmp/master.zip https://github.com/vernesong/OpenClash/archive/master.zip
if [ $? -ne 0 ]; then
    echo "下载 master.zip 失败。"
    exit 1
fi
echo "已下载 master.zip。"

# 解压 master.zip 到 tmp 目录
unzip tmp/master.zip -d tmp
if [ $? -ne 0 ]; then
    echo "解压 master.zip 失败。"
    exit 1
fi
echo "已解压 master.zip 到 tmp 目录。"

# 检查解压后的目录是否存在
if [ ! -d "tmp/OpenClash-master/luci-app-openclash" ]; then
    echo "解压后的目录 tmp/OpenClash-master/luci-app-openclash 不存在。"
    exit 1
fi

# 拷贝解压后的 luci-app-openclash 内容到 package/openclash
cp -r tmp/OpenClash-master/luci-app-openclash/* package/openclash/
if [ $? -ne 0 ]; then
    echo "拷贝文件到 package/openclash 失败。"
    exit 1
fi
echo "已将 luci-app-openclash 拷贝到 package/openclash。"

# 清理临时文件
rm -rf tmp
echo "已清理临时目录。"

echo "luci-app-openclash 已成功更新到 package/openclash。"
#
# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# ------------------------------- Other ends -------------------------------

