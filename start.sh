#!/bin/sh
# 启动脚本：支持动态配置注入与双进程守护

# 1. 环境检查
if [ -z "$UUID" ] || [ -z "$ARGO_TOKEN" ]; then
    echo "错误: 请确保已设置环境变量 UUID 和 ARGO_TOKEN"
    exit 1
fi

# 2. 动态生成配置
# 使用 envsubst 将模板中的变量注入到配置文件中
if [ -f "config.json.template" ]; then
    envsubst < config.json.template > config.json
    echo "✅ 配置已从模板生成"
else
    echo "警告: 未找到 config.json.template，直接使用现有 config.json"
fi

# 3. 定义守护函数
# 确保进程在崩溃后能自动重启
run_with_retry() {
    command=$1
    args=$2
    while true; do
        echo "🚀 正在启动 $command..."
        $command $args
        echo "⚠️ $command 已退出，5秒后尝试重启..."
        sleep 5
    done
}

# 4. 启动服务
# 启动 cloudflared 隧道（后台运行）
run_with_retry "cloudflared" "tunnel --no-autoupdate run --token $ARGO_TOKEN" &

# 启动 sing-box 服务（前台运行，以便接收 Docker 信号）
echo "🚀 正在启动 sing-box..."
run_with_retry "sing-box" "run -c config.json"
