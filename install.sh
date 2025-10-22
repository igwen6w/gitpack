#!/usr/bin/env bash
set -e
chmod +x scripts/gitpack.sh
sudo ln -sf "$(pwd)/scripts/gitpack.sh" /usr/local/bin/gitpack
echo "✅ 已安装 gitpack 命令"
