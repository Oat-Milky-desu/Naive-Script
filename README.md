# NaiveProxy 一键部署脚本

基于 Caddy + NaïveProxy 的代理服务部署工具，适用于 Debian/Ubuntu 系统。

## ✨ 功能特性

- 🚀 **一键部署** - 交互式安装，自动配置并启动服务
- 🔒 **自动 HTTPS** - 使用 Let's Encrypt 自动申请 SSL 证书
- 🛡️ **安全加固** - 内置 `hide_ip`、`hide_via`、`probe_resistance` 防护
- 📦 **自动备份** - 覆盖配置前自动备份原有 Caddyfile

## 📋 系统要求

- Debian 10+ / Ubuntu 18.04+
- 已解析到服务器的域名
- 开放对应端口（默认 443）

---

## 🚀 一键安装（推荐）

### 1. 一键运行

```bash
curl -sL https://u.ls/XLbb | sudo bash
```

### 2. 按提示输入配置信息

脚本会引导您输入以下信息：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| 域名 | 已解析到服务器的域名 | `proxy.example.com` |
| 端口 | 服务监听端口 | `443`（默认） |
| 邮箱 | 用于申请 TLS 证书 | `you@example.com` |
| 用户名 | 认证用户名 | `myuser` |
| 密码 | 认证密码 | `mypassword` |
| 反向代理 | 伪装站点地址 | `127.0.0.1:5244`（默认） |

### 3. 安装完成

安装成功后会显示连接信息：

```
NaiveProxy 连接信息:
  协议:     https
  地址:     proxy.example.com
  端口:     443
  用户名:   myuser

客户端连接 URL:
  naive+https://myuser:****@proxy.example.com:443
```

---

## 🔧 手动安装

如果您希望手动执行安装步骤，请按以下流程操作：

### 一、安装 Caddy

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
chmod o+r /usr/share/keyrings/caddy-stable-archive-keyring.gpg
chmod o+r /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### 二、下载 NaïveProxy 版 Caddy

```bash
cd /tmp
wget https://github.com/klzgrad/forwardproxy/releases/download/v2.10.0-naive/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
cd caddy-forwardproxy-naive
```

### 三、替换 Caddy 程序

```bash
sudo service caddy stop
sudo cp caddy /usr/bin/
sudo chmod +x /usr/bin/caddy
```

### 四、配置 Caddyfile

编辑 `/etc/caddy/Caddyfile`：

```bash
sudo nano /etc/caddy/Caddyfile
```

配置内容示例：

```caddyfile
{
  order forward_proxy first
}

:443, your-domain.com:443 {
  tls your-email@example.com
  forward_proxy {
    basic_auth 用户名 密码
    hide_ip
    hide_via
    probe_resistance
  }
  reverse_proxy 127.0.0.1:5244
}
```

> ⚠️ 请将 `your-domain.com`、`your-email@example.com`、`用户名`、`密码` 替换为实际值

### 五、启动服务

```bash
sudo systemctl enable caddy
sudo systemctl start caddy
```

---

## 📚 常用命令

```bash
# 查看服务状态
sudo systemctl status caddy

# 查看实时日志
sudo journalctl -u caddy -f

# 重启服务
sudo systemctl restart caddy

# 停止服务
sudo systemctl stop caddy

# 重新加载配置
sudo systemctl reload caddy

# 编辑配置文件
sudo nano /etc/caddy/Caddyfile
```

---

## 🔗 相关链接

- [NaïveProxy 项目](https://github.com/klzgrad/naiveproxy)
- [Caddy 官方文档](https://caddyserver.com/docs/)
- [forwardproxy 插件](https://github.com/klzgrad/forwardproxy)
