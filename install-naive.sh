#!/bin/bash

# NaiveProxy 安装脚本 for Debian
# 用法: sudo ./install-naive.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Caddyfile 路径
CADDYFILE="/etc/caddy/Caddyfile"

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}错误: 请使用 root 权限运行此脚本${NC}"
    echo "用法: sudo $0"
    exit 1
fi

# 获取用户配置信息
get_user_config() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       请输入 NaiveProxy 配置信息       ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # 域名
    while true; do
        read -p "请输入域名 (例如: example.com): " NAIVE_DOMAIN
        if [ -n "$NAIVE_DOMAIN" ]; then
            break
        else
            echo -e "${RED}域名不能为空，请重新输入${NC}"
        fi
    done

    # 端口号
    while true; do
        read -p "请输入端口号 (默认: 443): " NAIVE_PORT
        NAIVE_PORT=${NAIVE_PORT:-443}
        if [[ "$NAIVE_PORT" =~ ^[0-9]+$ ]] && [ "$NAIVE_PORT" -ge 1 ] && [ "$NAIVE_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}端口号无效，请输入 1-65535 之间的数字${NC}"
        fi
    done

    # 邮箱
    while true; do
        read -p "请输入邮箱 (用于 TLS 证书): " NAIVE_EMAIL
        if [ -n "$NAIVE_EMAIL" ]; then
            break
        else
            echo -e "${RED}邮箱不能为空，请重新输入${NC}"
        fi
    done

    # 用户名
    while true; do
        read -p "请输入用户名: " NAIVE_USER
        if [ -n "$NAIVE_USER" ]; then
            break
        else
            echo -e "${RED}用户名不能为空，请重新输入${NC}"
        fi
    done

    # 密码
    while true; do
        read -s -p "请输入密码: " NAIVE_PASS
        echo ""
        if [ -n "$NAIVE_PASS" ]; then
            read -s -p "请再次确认密码: " NAIVE_PASS_CONFIRM
            echo ""
            if [ "$NAIVE_PASS" = "$NAIVE_PASS_CONFIRM" ]; then
                break
            else
                echo -e "${RED}两次密码不一致，请重新输入${NC}"
            fi
        else
            echo -e "${RED}密码不能为空，请重新输入${NC}"
        fi
    done

    # 反向代理地址 (可选)
    read -p "请输入反向代理地址 (默认: 127.0.0.1:5244): " REVERSE_PROXY
    REVERSE_PROXY=${REVERSE_PROXY:-127.0.0.1:5244}

    echo ""
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}           配置信息确认                 ${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "  域名:       ${GREEN}$NAIVE_DOMAIN${NC}"
    echo -e "  端口:       ${GREEN}$NAIVE_PORT${NC}"
    echo -e "  邮箱:       ${GREEN}$NAIVE_EMAIL${NC}"
    echo -e "  用户名:     ${GREEN}$NAIVE_USER${NC}"
    echo -e "  密码:       ${GREEN}********${NC}"
    echo -e "  反向代理:   ${GREEN}$REVERSE_PROXY${NC}"
    echo ""

    read -p "确认以上信息正确? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}重新输入配置信息...${NC}"
        get_user_config
    fi
}

# 生成 Caddyfile 配置
generate_caddyfile() {
    echo -e "${YELLOW}生成 Caddyfile 配置...${NC}"
    
    # 备份原有配置
    if [ -f "$CADDYFILE" ]; then
        cp "$CADDYFILE" "${CADDYFILE}.bak.$(date +%Y%m%d%H%M%S)"
        echo -e "${GREEN}已备份原有配置${NC}"
    fi

    cat > "$CADDYFILE" << EOF
{
  order forward_proxy first
}
:${NAIVE_PORT}, ${NAIVE_DOMAIN}:${NAIVE_PORT} {
  tls ${NAIVE_EMAIL}
  forward_proxy {
    basic_auth ${NAIVE_USER} ${NAIVE_PASS}
    hide_ip
    hide_via
    probe_resistance
  }
  reverse_proxy ${REVERSE_PROXY}
}
EOF

    chmod 644 "$CADDYFILE"
    echo -e "${GREEN}Caddyfile 配置已生成${NC}"
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    NaiveProxy 一键安装脚本 for Debian    ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 获取用户配置
get_user_config

# 一、安装 Caddy 依赖和添加源
echo ""
echo -e "${YELLOW}[1/6] 安装 Caddy 依赖...${NC}"
apt install -y debian-keyring debian-archive-keyring apt-transport-https curl wget

echo -e "${YELLOW}[2/6] 添加 Caddy 官方源...${NC}"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list

echo -e "${YELLOW}[3/6] 安装 Caddy...${NC}"
apt update
apt install -y caddy

# 二、下载 NaiveProxy 的 Caddy forwardproxy 分支
echo -e "${YELLOW}[4/6] 下载并替换 Caddy (NaiveProxy 版本)...${NC}"
cd /tmp
wget -O caddy-forwardproxy-naive.tar.xz https://github.com/klzgrad/forwardproxy/releases/download/v2.10.0-naive/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
cd caddy-forwardproxy-naive

# 三、替换 Caddy 程序
echo -e "${YELLOW}[5/6] 停止 Caddy 服务并替换程序...${NC}"
systemctl stop caddy || service caddy stop || true
cp caddy /usr/bin/
chmod +x /usr/bin/caddy

# 清理临时文件
cd /
rm -rf /tmp/caddy-forwardproxy-naive.tar.xz /tmp/caddy-forwardproxy-naive

# 四、生成配置并启动服务
echo -e "${YELLOW}[6/6] 配置并启动 Caddy 服务...${NC}"
generate_caddyfile

# 启动 Caddy
systemctl enable caddy
systemctl start caddy

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    NaiveProxy 安装配置完成!            ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}NaiveProxy 连接信息:${NC}"
echo -e "  协议:     ${GREEN}https${NC}"
echo -e "  地址:     ${GREEN}${NAIVE_DOMAIN}${NC}"
echo -e "  端口:     ${GREEN}${NAIVE_PORT}${NC}"
echo -e "  用户名:   ${GREEN}${NAIVE_USER}${NC}"
echo -e "  密码:     ${GREEN}********${NC}"
echo ""
echo -e "${CYAN}客户端连接 URL:${NC}"
echo -e "  ${GREEN}naive+https://${NAIVE_USER}:****@${NAIVE_DOMAIN}:${NAIVE_PORT}${NC}"
echo ""
echo -e "${YELLOW}常用命令:${NC}"
echo -e "  查看状态: ${CYAN}systemctl status caddy${NC}"
echo -e "  查看日志: ${CYAN}journalctl -u caddy -f${NC}"
echo -e "  重启服务: ${CYAN}systemctl restart caddy${NC}"
echo -e "  停止服务: ${CYAN}systemctl stop caddy${NC}"
echo -e "  编辑配置: ${CYAN}nano /etc/caddy/Caddyfile${NC}"
echo ""
