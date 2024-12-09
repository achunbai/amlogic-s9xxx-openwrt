#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Add the default password for the 'root' user（Change the empty password to 'password'）
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
# sed -i 's/192.168.1.1/192.168.31.4/g' package/base-files/files/bin/config_generate
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

