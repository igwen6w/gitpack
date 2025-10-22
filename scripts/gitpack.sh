#!/bin/bash
#
# Git文件变更打包脚本 v3.0
# 功能：
#   - 交互选择 commit（支持区间选择）
#   - 支持匹配文件模式过滤
#   - 自动打包变更文件（含选中 commit 本身）
#   - 支持 zip / tar.gz / tar.bz2 格式
#   - 自动处理初始 commit 情况
#   - 支持自定义输出目录
#
# 用法: ./archive.sh
#

set -e

VERSION="3.0"

# ======== 颜色定义 ========
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ======== 显示版本信息 ========
show_version() {
    echo "gitpack v${VERSION}"
    echo "Git 文件变更打包工具"
    exit 0
}

# ======== 显示帮助信息 ========
show_help() {
    cat << EOF
gitpack v${VERSION} - Git 文件变更打包工具

用法: gitpack [选项]

选项:
  --help, -h     显示此帮助信息
  --version, -v  显示版本信息

功能特性:
  • 交互式选择 commit（支持区间选择）
  • 支持文件匹配模式过滤（如: *.js, src/*）
  • 自动打包变更文件（包含选中 commit 本身）
  • 支持多种压缩格式: zip / tar.gz / tar.bz2
  • 自动处理初始 commit 情况
  • 支持自定义输出目录

打包模式:
  1) 从指定 commit 到 HEAD（当前版本）
  2) 指定 commit 区间（从 commit A 到 commit B）

示例:
  gitpack              # 交互式运行
  gitpack --help       # 显示帮助
  gitpack --version    # 显示版本

EOF
    exit 0
}

# ======== 解析命令行参数 ========
for arg in "$@"; do
    case $arg in
        --help|-h)
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        *)
            print_error "未知选项: $arg"
            echo "使用 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# ======== 检查Git仓库 ========
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "当前目录不是Git仓库！"
    exit 1
fi

echo "Git文件变更打包工具"
echo "===================="

# ======== 选择模式 ========
echo
echo "请选择打包模式："
echo "  1) 从指定 commit 到 HEAD（当前版本）"
echo "  2) 指定 commit 区间（从 commit A 到 commit B）"
echo
read -p "请选择模式 [1-2]: " mode
mode=${mode:-1}

if [[ ! "$mode" =~ ^[12]$ ]]; then
    print_error "无效的模式选择: $mode"
    exit 1
fi

# ======== 显示最近提交 ========
echo
echo "最近的提交记录："
commits=($(git log --oneline -30 --format="%H"))
git log --oneline -30 --format="%C(yellow)%h%C(reset) %C(green)(%cr)%C(reset) %s %C(blue)<%an>%C(reset)" | nl -w2 -s') '

if [ "$mode" == "1" ]; then
    # 模式1: 从 commit 到 HEAD
    echo
    read -p "请选择起始 commit 编号 [1-${#commits[@]}]: " choice
    
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#commits[@]} ]; then
        print_error "无效的选择: $choice"
        exit 1
    fi
    
    start_commit=${commits[$((choice-1))]}
    end_commit="HEAD"
    commit_short=$(echo $start_commit | cut -c1-8)
    
    print_info "已选择: $commit_short → HEAD"
else
    # 模式2: commit 区间
    echo
    read -p "请选择起始 commit 编号（较早的提交）[1-${#commits[@]}]: " start_choice
    read -p "请选择结束 commit 编号（较新的提交）[1-${#commits[@]}]: " end_choice
    
    if ! [[ "$start_choice" =~ ^[0-9]+$ ]] || [ "$start_choice" -lt 1 ] || [ "$start_choice" -gt ${#commits[@]} ]; then
        print_error "无效的起始选择: $start_choice"
        exit 1
    fi
    
    if ! [[ "$end_choice" =~ ^[0-9]+$ ]] || [ "$end_choice" -lt 1 ] || [ "$end_choice" -gt ${#commits[@]} ]; then
        print_error "无效的结束选择: $end_choice"
        exit 1
    fi
    
    if [ "$end_choice" -ge "$start_choice" ]; then
        print_error "结束 commit 必须比起始 commit 更新（编号更小）"
        exit 1
    fi
    
    start_commit=${commits[$((start_choice-1))]}
    end_commit=${commits[$((end_choice-1))]}
    start_short=$(echo $start_commit | cut -c1-8)
    end_short=$(echo $end_commit | cut -c1-8)
    commit_short="${start_short}_to_${end_short}"
    
    print_info "已选择: $start_short → $end_short"
fi

# ======== 文件匹配模式 ========
read -p "文件匹配模式 (默认 *, 如: *.js, src/*): " file_pattern
file_pattern=${file_pattern:-"*"}

# ======== 获取变更文件 ========
if [ "$mode" == "1" ]; then
    print_info "获取 ${commit_short} 到 HEAD 的变更文件..."
    
    if git rev-list --parents -n 1 "$start_commit" | grep -q ' '; then
        # 有父节点
        changed_files=$(git diff --name-only "${start_commit}^" HEAD)
    else
        # 初始提交
        changed_files=$(git diff --name-only "$start_commit" HEAD)
    fi
else
    print_info "获取 ${start_short} 到 ${end_short} 的变更文件..."
    
    if git rev-list --parents -n 1 "$start_commit" | grep -q ' '; then
        # 有父节点
        changed_files=$(git diff --name-only "${start_commit}^" "$end_commit")
    else
        # 初始提交
        changed_files=$(git diff --name-only "$start_commit" "$end_commit")
    fi
fi

if [ -z "$changed_files" ]; then
    print_warn "没有找到变更文件"
    exit 1
fi

# ======== 文件过滤 ========
if [ "$file_pattern" != "*" ]; then
    filtered_files=$(echo "$changed_files" | grep -E "$(echo $file_pattern | sed 's/\*/.*/')" || true)
    if [ -z "$filtered_files" ]; then
        print_warn "没有匹配模式 '$file_pattern' 的文件"
        exit 1
    fi
    changed_files="$filtered_files"
fi

# ======== 显示文件信息 ========
file_count=$(echo "$changed_files" | wc -l)
print_info "找到 $file_count 个变更文件"
echo "$changed_files" | head -5
[ $file_count -gt 5 ] && echo "... (还有 $((file_count-5)) 个文件)"

# ======== 确认打包 ========
echo
read -p "继续打包? [y/N]: " confirm
[[ ! $confirm =~ ^[Yy]$ ]] && { print_info "已取消"; exit 0; }

# ======== 输出目录 ========
echo
read -p "输出目录 (默认: 当前目录): " output_dir
output_dir=${output_dir:-"."}

# 创建输出目录（如果不存在）
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
    print_info "已创建目录: $output_dir"
fi

# ======== 输出文件名 ========
if [ "$mode" == "1" ]; then
    default_name="changes_from_${commit_short}_to_HEAD_$(date +%Y%m%d_%H%M%S).tar.gz"
else
    default_name="changes_${commit_short}_$(date +%Y%m%d_%H%M%S).tar.gz"
fi

read -p "输出文件名 (默认: $default_name): " output_file
output_file=${output_file:-$default_name}

# 组合完整路径
output_path="$output_dir/$output_file"

# ======== 创建临时目录并复制文件 ========
temp_dir="temp_$(date +%s)"
mkdir -p "$temp_dir"

print_info "复制文件中..."
copied=0
while read -r file; do
    if [ -f "$file" ]; then
        target_dir="$temp_dir/$(dirname "$file")"
        mkdir -p "$target_dir"
        cp "$file" "$target_dir/"
        copied=$((copied + 1))
        printf "\r复制进度: %d/%d" "$copied" "$file_count"
    fi
done <<< "$changed_files"

echo
print_info "创建压缩包: $output_path"

# ======== 根据扩展名选择压缩方式 ========
case "$output_file" in
    *.tar.gz|*.tgz) tar -czf "$output_path" -C "$temp_dir" . ;;
    *.zip)          (cd "$temp_dir" && zip -qr "$(realpath "$output_path")" .) ;;
    *.tar.bz2)      tar -cjf "$output_path" -C "$temp_dir" . ;;
    *)              tar -czf "${output_path}.tar.gz" -C "$temp_dir" .
                    output_path="${output_path}.tar.gz" ;;
esac

# ======== 清理临时目录 ========
rm -rf "$temp_dir"

# ======== 完成信息 ========
file_size=$(du -h "$output_path" | cut -f1)
echo
print_info "✓ 打包完成!"
print_info "文件: $(realpath "$output_path")"
print_info "大小: $file_size"
print_info "包含: $copied 个文件"
