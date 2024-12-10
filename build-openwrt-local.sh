#!/bin/bash

# 显示菜单并获取用户选择
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    local PS3="$prompt "
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            return
        else
            echo "无效选择，请重试。"
        fi
    done
}

# 默认参数（仅在未通过命令行传递时设置）
SOURCE_BRANCH=""
OPENWRT_BOARD=""
OPENWRT_KERNEL=""
AUTO_KERNEL=""
KERNEL_REPO=""
KERNEL_USAGE=""
OPENWRT_STORAGE=""
BUILDER_NAME="achunbai"

# 解析命令行参数
while getopts ":b:d:k:a:r:u:s:n:" opt; do
    case ${opt} in
        b )
            SOURCE_BRANCH=$OPTARG
            ;;
        d )
            OPENWRT_BOARD=$OPTARG
            ;;
        k )
            OPENWRT_KERNEL=$OPTARG
            ;;
        a )
            AUTO_KERNEL=$OPTARG
            ;;
        r )
            KERNEL_REPO=$OPTARG
            ;;
        u )
            KERNEL_USAGE=$OPTARG
            ;;
        s )
            OPENWRT_STORAGE=$OPTARG
            ;;
        n )
            BUILDER_NAME=$OPTARG
            ;;
        \? )
            echo "Usage: $0 [-b source_branch] [-d openwrt_board] [-k openwrt_kernel] [-a auto_kernel] [-r kernel_repo] [-u kernel_usage] [-s openwrt_storage] [-n builder_name]"
            exit 1
            ;;
    esac
done

# 如果某些参数未通过命令行传递，则进行交互式选择
if [[ -z "$SOURCE_BRANCH" ]]; then
    SOURCE_BRANCH=$(select_option "请选择 source_branch:" "openwrt-main" "lede-master" "immortalwrt-master")
fi

if [[ -z "$OPENWRT_BOARD" ]]; then
    OPENWRT_BOARD=$(select_option "请选择 openwrt_board:" "all" "jp-tvbox")
fi

if [[ -z "$OPENWRT_KERNEL" ]]; then
    OPENWRT_KERNEL=$(select_option "请选择 openwrt_kernel:" "5.4.y" "5.10.y" "5.15.y" "6.1.y" "6.6.y" "6.1.y_6.6.y" "5.15.y_5.10.y")
fi

if [[ -z "$AUTO_KERNEL" ]]; then
    AUTO_KERNEL=$(select_option "请选择 是否自动使用最新版内核:" "true" "false")
fi

if [[ -z "$KERNEL_REPO" ]]; then
    KERNEL_REPO=$(select_option "请选择 kernel_repo:" "ophub/kernel")
fi

if [[ -z "$KERNEL_USAGE" ]]; then
    KERNEL_USAGE=$(select_option "请选择 kernel_usage:" "stable" "flippy" "dev" "beta")
fi

if [[ -z "$OPENWRT_STORAGE" ]]; then
    OPENWRT_STORAGE=$(select_option "请选择 openwrt_storage:" "save" "temp")
fi

if [[ -z "$BUILDER_NAME" ]]; then
    BUILDER_NAME=$(select_option "请选择 builder_name:" "ophub" "angel" "yourname")
fi

echo "您选择的参数如下："
echo "Source Branch: $SOURCE_BRANCH"
echo "OpenWrt Board: $OPENWRT_BOARD"
echo "Kernel Version: $OPENWRT_KERNEL"
echo "Auto Kernel: $AUTO_KERNEL"
echo "Kernel Repo: $KERNEL_REPO"
echo "Kernel Usage: $KERNEL_USAGE"
echo "Storage Type: $OPENWRT_STORAGE"
echo "Builder Name: $BUILDER_NAME"

# 开始编译流程
# 设置环境变量
FEEDS_CONF="config/${SOURCE_BRANCH}/feeds.conf.default"
CONFIG_FILE="config/${SOURCE_BRANCH}/config"
DIY_P1_SH="config/${SOURCE_BRANCH}/diy-part1.sh"
DIY_P2_SH="config/${SOURCE_BRANCH}/diy-part2.sh"
TZ="America/New_York"

# 确认分支格式是否包含冒号，例如 "openwrt:23.05.5"
if [[ "$SOURCE_BRANCH" == *":"* ]]; then
    REPO_URL_PREFIX="${SOURCE_BRANCH%%:*}"
    REPO_BRANCH="${SOURCE_BRANCH##*:}"
else
    # 默认仓库 URL，根据选择的 SOURCE_BRANCH 设置
    if [[ "$SOURCE_BRANCH" == "openwrt-main" ]]; then
        REPO_URL="https://github.com/openwrt/openwrt.git"
        REPO_BRANCH="main"
        TAGS_NAME="official"
    elif [[ "$SOURCE_BRANCH" == "lede-master" ]]; then
        REPO_URL="https://github.com/coolsnowwolf/lede.git"
        REPO_BRANCH="master"
        TAGS_NAME="lede"
    elif [[ "$SOURCE_branch" == "immortalwrt-master" ]]; then
        REPO_URL="https://github.com/immortalwrt/immortalwrt.git"
        REPO_BRANCH="master"
        TAGS_NAME="immortalwrt"
    else
        echo "未知的 source_branch: $SOURCE_BRANCH"
        exit 1
    fi
fi

# 克隆源代码
echo "正在克隆仓库: $REPO_URL 分支: $REPO_BRANCH"
git clone -b "${REPO_BRANCH}" "$REPO_URL" openwrt
if [[ $? -ne 0 ]]; then
    echo "克隆仓库失败，请检查分支名称和仓库地址。"
    exit 1
fi
cd openwrt || exit

# 更新并安装包依赖
./scripts/feeds update -a
./scripts/feeds install -a

# 复制配置文件
cp ../${CONFIG_FILE} .config

# 运行自定义脚本
chmod +x ../${DIY_P1_SH}
chmod +x ../${DIY_P2_SH}
../${DIY_P1_SH}
../${DIY_P2_SH}

# 编译
make defconfig
make -j$(nproc) V=s

# 获取编译后的固件
echo "编译完成，固件位于 bin/targets/ 目录下。"