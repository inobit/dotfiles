#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=========================================="
echo "清理 Rootless Docker 脚本"
echo "=========================================="

# ============================================
# 1. 停止并删除所有容器
# ============================================
info "停止并删除所有容器..."

# 检查 docker 命令是否存在且可用
if command -v docker &>/dev/null; then
	# 列出当前容器
	containers=$(docker ps -aq 2>/dev/null || true)
	if [ -n "$containers" ]; then
		info "当前容器："
		docker ps -a
		echo ""

		read -p "是否停止并删除所有容器？[Y/n] " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Nn]$ ]]; then
			docker stop $containers 2>/dev/null || true
			docker rm $containers 2>/dev/null || true
			info "容器已删除"
		fi
	else
		info "没有容器需要删除"
	fi

	# 可选：删除镜像
	images=$(docker images -aq 2>/dev/null || true)
	if [ -n "$images" ]; then
		read -p "是否删除所有镜像？[y/N] " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			docker rmi -f $images 2>/dev/null || true
			info "镜像已删除"
		fi
	fi
else
	warn "docker 命令不可用，跳过容器清理"
fi

# ============================================
# 2. 停止 rootless Docker 服务
# ============================================
info "停止 rootless Docker 服务..."

# 停止 docker 服务
systemctl --user stop docker.service 2>/dev/null || true
systemctl --user stop docker.socket 2>/dev/null || true

# 禁用服务
systemctl --user disable docker.service 2>/dev/null || true
systemctl --user disable docker.socket 2>/dev/null || true

# 停止可能存在的其他 docker 相关服务
systemctl --user stop docker-rootless-shutdown.service 2>/dev/null || true
systemctl --user disable docker-rootless-shutdown.service 2>/dev/null || true

info "rootless Docker 服务已停止"

# ============================================
# 3. 禁用 loginctl enable-linger
# ============================================
info "禁用 user-level services (linger)..."

read -p "是否禁用 loginctl linger？[Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
	sudo loginctl disable-linger "$USER" 2>/dev/null || true
	info "linger 已禁用"
fi

# ============================================
# 4. 还原系统配置
# ============================================
info "还原系统配置..."

# 还原 rootlesskit 的 setcap
DOCKER_BIN="$HOME/.docker-bin"
if [ -f "$DOCKER_BIN/rootlesskit" ]; then
	info "移除 rootlesskit 的 capabilities..."
	sudo setcap -r "$DOCKER_BIN/rootlesskit" 2>/dev/null || true
fi

# 也检查 /usr/bin/rootlesskit
if [ -f "/usr/bin/rootlesskit" ]; then
	sudo setcap -r /usr/bin/rootlesskit 2>/dev/null || true
fi

# 还原 unprivileged ports 配置
if [ -f "/etc/sysctl.d/80-unprivileged-ports.conf" ]; then
	info "还原 unprivileged ports 配置..."
	sudo rm -f /etc/sysctl.d/80-unprivileged-ports.conf
	sudo sysctl -w net.ipv4.ip_unprivileged_port_start=1024 2>/dev/null || true
	info "net.ipv4.ip_unprivileged_port_start 已还原为 1024"
fi

# 还原 unprivileged icmp 配置
if [ -f "/etc/sysctl.d/80-unprivileged-icmp.conf" ]; then
	info "还原 unprivileged icmp 配置..."
	sudo rm -f /etc/sysctl.d/80-unprivileged-icmp.conf
	sudo sysctl -w net.ipv4.ping_group_range="0 0" 2>/dev/null || true
fi

# ============================================
# 5. 删除 rootless Docker 文件和目录
# ============================================
info "清理 rootless Docker 文件和目录..."

# 删除 Docker 二进制目录
if [ -d "$DOCKER_BIN" ]; then
	read -p "是否删除 $DOCKER_BIN 目录？[Y/n] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		rm -rf "$DOCKER_BIN"
		info "已删除 $DOCKER_BIN"
	fi
fi

# 删除 Docker 数据目录
if [ -d "$HOME/.local/share/docker" ]; then
	read -p "是否删除 $HOME/.local/share/docker 数据目录？[y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		sudo rm -rf "$HOME/.local/share/docker"
		info "已删除 docker 数据目录"
	fi
fi

# 删除 Docker 配置目录
if [ -d "$HOME/.config/docker" ]; then
	read -p "是否删除 $HOME/.config/docker 配置目录？[Y/n] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		sudo rm -rf "$HOME/.config/docker"
		info "已删除 docker 配置目录"
	fi
fi

# 删除 systemd 用户服务文件
if [ -d "$HOME/.config/systemd/user" ]; then
	docker_services=$(find "$HOME/.config/systemd/user" -name "docker*" 2>/dev/null || true)
	if [ -n "$docker_services" ]; then
		info "发现 docker 相关的 systemd 服务文件："
		echo "$docker_services"
		read -p "是否删除这些文件？[Y/n] " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Nn]$ ]]; then
			sudo rm -rf $docker_services
			info "已删除 systemd 服务文件"
		fi
	fi
fi

# 删除 docker context
if [ -d "$HOME/.docker" ]; then
	read -p "是否删除 $HOME/.docker (docker context)？[Y/n] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		sudo rm -rf "$HOME/.docker"
		info "已删除 .docker 目录"
	fi
fi

# 删除运行时文件
rm -rf "/run/user/$UID/docker" 2>/dev/null || true
rm -rf "/run/user/$UID/docker.sock" 2>/dev/null || true

# ============================================
# 6. 清理环境变量（提示用户）
# ============================================
info "请检查并手动清理 shell 配置文件中的以下内容："

SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
	SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
	SHELL_RC="$HOME/.zshrc"
fi

# ============================================
# 7. 可选：卸载依赖包
# ============================================
info "检查已安装的依赖包..."

installed_packages=""
for pkg in uidmap slirp4netns; do
	if dpkg -l "$pkg" &>/dev/null 2>&1; then
		installed_packages="$installed_packages $pkg"
	fi
done

if [ -n "$installed_packages" ]; then
	echo "已安装的 rootless docker 依赖包：$installed_packages"
	read -p "是否卸载这些包？[y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		sudo apt remove -y $installed_packages
		sudo apt autoremove -y
		info "依赖包已卸载"
	fi
fi

# ============================================
# 完成
# ============================================
echo ""
echo "=========================================="
echo "清理完成！"
echo "=========================================="
echo ""
echo "后续步骤："
echo "1. 运行 'source ~/.bashrc' 或重新登录以刷新环境变量"
echo "2. 如需安装普通 Docker，请运行："
echo "   curl -fsSL https://get.docker.com | sudo sh"
echo "   sudo usermod -aG docker \$USER"
echo ""
