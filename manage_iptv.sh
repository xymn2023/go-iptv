#!/bin/bash

# 定义镜像和容器名称
IMAGE_NAME="go-iptv"
CONTAINER_NAME="my-go-iptv"
REPO_URL="https://github.com/wz1st/go-iptv.git"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 菜单函数
show_menu() {
    echo -e "${YELLOW}=== Go-IPTV Docker 管理脚本 ===${NC}"
    echo "1. 下载源码并构建镜像 (Git + Build)"
    echo "2. 启动容器 (Run)"
    echo "3. 查看容器实时日志 (Logs)"
    echo "4. 停止并删除容器 (Stop & RM)"
    echo "5. 进入容器内部 (Shell)"
    echo "6. 退出脚本"
    echo -ne "${GREEN}请选择操作 [1-6]: ${NC}"
}

# 1. 构建镜像
build_image() {
    if [ ! -d "go-iptv" ]; then
        echo -e "${YELLOW}正在克隆项目源码...${NC}"
        git clone $REPO_URL
    fi
    cd go-iptv || exit
    echo -e "${YELLOW}正在开始 Docker 构建 (Dockerfile-local)...${NC}"
    docker build -f Dockerfile-local -t $IMAGE_NAME:latest .
    echo -e "${GREEN}构建完成！${NC}"
    cd ..
}

# 2. 启动容器
run_container() {
    echo -e "${YELLOW}正在准备挂载目录并启动容器...${NC}"
    # 确保当前目录下有 go-iptv 文件夹，否则 pwd 会指向错误位置
    if [ -d "go-iptv" ]; then
        cd go-iptv
    fi
    
    docker run -d \
      --name $CONTAINER_NAME \
      --restart always \
      --privileged \
      -p 8080:80 \
      -p 8081:8080 \
      -v $(pwd)/iptv_config:/config \
      -v $(pwd)/iptv_database:/app/database \
      $IMAGE_NAME:latest

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器启动成功！${NC}"
        echo -e "管理后台地址: http://$(curl -s ifconfig.me):8080"
    else
        echo -e "${RED}启动失败，请检查端口是否被占用或镜像是否存在。${NC}"
    fi
}

# 主循环
while true; do
    show_menu
    read choice
    case $choice in
        1) build_image ;;
        2) run_container ;;
        3) docker logs -f $CONTAINER_NAME ;;
        4) 
            docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME 
            echo -e "${RED}容器已停止并移除。${NC}"
            ;;
        5) docker exec -it $CONTAINER_NAME /bin/bash || docker exec -it $CONTAINER_NAME /bin/sh ;;
        6) exit 0 ;;
        *) echo -e "${RED}无效输入，请重新选择。${NC}" ;;
    esac
    echo -e "\n"
done
