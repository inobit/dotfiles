#!/bin/bash


set -e

# ============================================
# 颜色定义
# ============================================
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# 变量
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${1:-docker-compose.yml}"
IMAGE_GZ="images.tar.gz"

# ============================================
# 检测 OS
# ============================================
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# ============================================
# 检测 Docker 是否已安装并运行
# ============================================
is_docker_ready() {
    command -v docker &>/dev/null && docker ps &>/dev/null
}

# ============================================
# 导入镜像
# ============================================
import_images() {
    info "========== 导入镜像 =========="

    local image_gz="$SCRIPT_DIR/$IMAGE_GZ"

    if [[ ! -f "$image_gz" ]]; then
        error "未找到镜像文件: $IMAGE_GZ"
        exit 1
    fi

    info "镜像文件大小: $(du -h "$image_gz" | cut -f1)"
    info "正在导入镜像..."

    local start=$(date +%s)
    docker load -i "$image_gz"
    local end=$(date +%s)

    info "导入完成，耗时 $((end - start)) 秒"

    # 显示镜像
    info "已导入的镜像:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -20

    # 询问删除
    read -r -p "是否删除镜像文件以节省空间? (y/N): "
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$image_gz"
        info "已删除镜像文件"
    fi
}


# ============================================
# 主程序
# ============================================
main() {
    echo ""
    echo "========================================"
    echo "    Docker 迁移安装脚本 (Rootless)"
    echo "========================================"
    echo ""

    if ! is_docker_ready; then
      error "docker is not installed"
      exit 1
    fi

    # 导入镜像
    import_images


    echo ""
    echo "========================================"
    echo "           导入完成"
    echo "========================================"
    echo ""
    info "常用命令:"
    echo "  cd $SCRIPT_DIR"
    echo "  docker compose up -d      # 启动"
    echo "  docker compose down       # 停止"
    echo "  docker compose logs -f    # 日志"
    echo "  docker compose ps         # 状态"
    echo ""
}

main "$@"
