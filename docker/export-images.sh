#!/bin/bash

# Docker Compose 镜像导出脚本
# 自动检测 rootless/root 模式
# 用法: ./export-images.sh [docker-compose文件路径] [输出目录]

set -e

COMPOSE_FILE="${1:-docker-compose.yml}"
OUTPUT_DIR="${2:-.}"
OUTPUT_FILE="${OUTPUT_DIR}/images.tar.gz"
IMAGE_LIST_FILE="${OUTPUT_DIR}/images-list.txt"

# ============================================
# 检测 Docker 权限模式
# ============================================
detect_docker_mode() {
	# 方法1: 检查环境变量 DOCKER_HOST (rootless 特征)
	if [[ -n "$DOCKER_HOST" && "$DOCKER_HOST" == *"/run/user/"* ]]; then
		echo "rootless"
		return
	fi

	# 方法2: 检查 XDG_RUNTIME_DIR 下的 docker.sock
	if [[ -n "$XDG_RUNTIME_DIR" && -S "$XDG_RUNTIME_DIR/docker.sock" ]]; then
		echo "rootless"
		return
	fi

	# 方法3: 测试能否直接连接 daemon
	if docker ps &>/dev/null; then
		echo "direct"
		return
	fi

	# 方法4: 尝试 sudo
	if sudo docker ps &>/dev/null; then
		echo "sudo"
		return
	fi

	# 无法连接
	echo "none"
}

# 获取 docker 命令
get_docker_cmd() {
	local mode=$(detect_docker_mode)
	case $mode in
	rootless | direct)
		echo "docker"
		;;
	sudo)
		echo "sudo docker"
		;;
	none)
		echo ""
		;;
	esac
}

# ============================================
# 主程序
# ============================================
echo "=== Docker Compose 镜像导出工具 ==="
echo ""

# 检查 docker 是否安装
if ! command -v docker &>/dev/null; then
	echo "错误: Docker 未安装"
	exit 1
fi

# 检查 compose 文件
if [ ! -f "$COMPOSE_FILE" ]; then
	echo "错误: 找不到文件 $COMPOSE_FILE"
	exit 1
fi

# 检测权限模式
PERMISSION_MODE=$(detect_docker_mode)

if [ "$PERMISSION_MODE" = "none" ]; then
	echo "错误: 无法连接 Docker daemon"
	echo "提示: 请确保用户有 Docker 权限或可以使用 sudo"
	exit 1
fi

echo "检测到 Docker 模式: $PERMISSION_MODE"

# 设置 docker 命令
# sudo usermod -aG docker "$USER"
DOCKER_CMD=$(get_docker_cmd)
echo "使用命令: $DOCKER_CMD"
echo ""

echo "使用 compose 文件: $COMPOSE_FILE"

# 获取镜像列表
echo "正在解析镜像列表..."
IMAGES=$($DOCKER_CMD compose -f "$COMPOSE_FILE" config --images 2>/dev/null | sort -u)

if [ -z "$IMAGES" ]; then
	echo "错误: 未找到任何镜像定义"
	exit 1
fi

# 显示镜像列表
echo ""
echo "找到以下镜像:"
echo "$IMAGES" | nl
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 保存镜像列表
echo "$IMAGES" >"$IMAGE_LIST_FILE"
echo "镜像列表已保存到: $IMAGE_LIST_FILE"

IMAGE_COUNT=$(echo "$IMAGES" | wc -l)
echo "共 $IMAGE_COUNT 个镜像"
echo ""

# 拉取镜像
read -p "是否先拉取最新镜像? (y/N): " -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "正在拉取镜像..."
	echo "$IMAGES" | xargs -I {} $DOCKER_CMD pull {}
	echo "镜像拉取完成"
	echo ""
fi

# 确认导出
read -p "确认导出镜像? (y/N): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "已取消"
	rm -f "$IMAGE_LIST_FILE"
	exit 0
fi

# 导出镜像（管道直接压缩，避免中间文件权限问题）
echo "正在导出并压缩镜像..."
START_TIME=$(date +%s)

$DOCKER_CMD save $IMAGES | gzip >"$OUTPUT_FILE"

END_TIME=$(date +%s)
EXPORT_DURATION=$((END_TIME - START_TIME))
echo "导出完成，耗时 ${EXPORT_DURATION} 秒"

# 结果
echo ""
echo "=== 导出完成 ==="
echo "输出文件: $OUTPUT_FILE"
echo "文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo ""
echo "传输到目标机器后，导入方法:"
echo "  docker load -i images.tar.gz"
echo ""
echo "镜像列表文件: $IMAGE_LIST_FILE"
