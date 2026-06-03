#!/bin/bash
# ============================================================
# setup-ssl.sh — 准备环境 + 按需申请 Let's Encrypt 证书
# 幂等：域名已被 certbot 接管则跳过，一次一个域名
# 适用环境：Debian / Ubuntu，Nginx
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
info() { echo -e "${CYAN}[INFO]${NC} $1"; }
ok() { echo -e "${GREEN}[OK]${NC}   $1"; }
err() { echo -e "${RED}[ERR]${NC}  $1"; }

if [ "$EUID" -ne 0 ]; then
	err "请以 root 或使用 sudo 运行"
	exit 1
fi

# ─── 1. 安装 certbot ────────────────────────────────────
if command -v certbot &>/dev/null; then
	ok "certbot 已安装: $(certbot --version 2>&1)"
else
	if ! command -v apt &>/dev/null; then
		err "未检测到 apt，请手动安装 certbot"
		exit 1
	fi
	apt update && apt install -y certbot
	ok "certbot 安装成功: $(certbot --version 2>&1)"
fi

# ─── 2. 创建验证目录 ────────────────────────────────────
WEBROOT="/var/lib/letsencrypt"
mkdir -p "$WEBROOT"
ok "验证目录: $WEBROOT"

# ─── 3. 确保续期钩子目录存在 ──────────────────────────
HOOK_DIR="/etc/letsencrypt/renewal-hooks/deploy"
mkdir -p "$HOOK_DIR"
ok "续期钩子目录: $HOOK_DIR"

# ─── 4. 输入域名 ────────────────────────────────────────
echo ""
info "请输入域名（一次一个，多个域名请多次执行）"
echo ""
read -rp "域名: " DOMAIN

if [ -z "$DOMAIN" ]; then
	err "域名不能为空"
	exit 1
fi

CERT_DIR="/etc/letsencrypt/live/$DOMAIN"

# ─── 5. 检查是否已被接管 ────────────────────────────────
if [ -f "$CERT_DIR/fullchain.pem" ]; then
	EXPIRY=$(openssl x509 -enddate -noout -in "$CERT_DIR/fullchain.pem" 2>/dev/null | cut -d= -f2)
	if [ -n "$EXPIRY" ]; then
		EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
		NOW_EPOCH=$(date +%s)
		DAYS_LEFT=$(((EXPIRY_EPOCH - NOW_EPOCH) / 86400))
		echo ""
		ok "${DOMAIN} 已被 certbot 接管，证书剩余 ${DAYS_LEFT} 天，无需操作"
		echo ""
		info "如需重新申请，先执行: certbot delete --cert-name ${DOMAIN}"
		exit 0
	fi
fi

# ─── 6. 输出 nginx HTTP 配置（申请前必须先配好） ──────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   第一步：请先在 nginx 中添加以下 HTTP 配置                ║"
echo "║   然后 nginx -t && nginx -s reload 确保生效          ║"
echo "║   确认后脚本会自动申请证书                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cat <<NGINX_HTTP
server {
    listen 80;
    server_name $DOMAIN;

    location ^~ /.well-known/acme-challenge/ {
        root $WEBROOT;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
NGINX_HTTP

echo ""
read -rp "nginx 已配好并重载？(y/N): " NGINX_READY
if [[ "$NGINX_READY" != "y" && "$NGINX_READY" != "Y" ]]; then
	info "请先配置 nginx，然后重新执行此脚本"
	exit 0
fi

# ─── 7. 申请证书 ────────────────────────────────────────
echo ""
info "开始为 ${DOMAIN} 申请证书..."
info "请确认域名已解析到本机，且 80 端口可访问"
echo ""

read -rp "邮箱地址 (留空则不提供): " EMAIL
EMAIL_ARGS=()
if [ -n "$EMAIL" ]; then
	EMAIL_ARGS=(-m "$EMAIL")
else
	EMAIL_ARGS=(--register-unsafely-without-email)
fi

certbot certonly --webroot \
	-w "$WEBROOT" \
	-d "$DOMAIN" \
	"${EMAIL_ARGS[@]}" \
	--agree-tos \
	--non-interactive

echo ""
ok "证书申请完成！证书目录: $CERT_DIR"
echo ""

# ─── 8. 验证续期 ────────────────────────────────────────
certbot renew --dry-run 2>&1 | tail -3
echo ""

# ─── 9. 输出 nginx HTTPS 配置 ─────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   第二步：现在添加 HTTPS 配置到同一个 nginx 站点文件       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cat <<NGINX_HTTPS
server {
    listen 443 ssl;
    http2 on;
    server_name $DOMAIN;

    # ── 证书路径（certbot 自动维护符号链接，续期后路径不变） ──
    ssl_certificate     /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 1d;

    add_header Strict-Transport-Security "max-age=63072000" always;

    root /var/www/html;
    index index.html;
}
NGINX_HTTPS

echo ""
info "后续操作:"
echo ""
echo "  1) 将以上 HTTPS 配置添加到站点文件"
echo "  2) 将 reload 脚本放入 $HOOK_DIR 目录或创建软链"
echo ""
info "查看证书: certbot certificates"
echo ""
ok "全部完成！"
