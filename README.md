# gitpack - Git 文件变更打包工具

一个用于打包 Git 仓库中指定 commit 范围内变更文件的命令行工具。

## 功能特性

- ✅ 交互式选择 commit（支持区间选择）
- ✅ 支持文件匹配模式过滤（如: `*.js`, `src/*`）
- ✅ 自动打包变更文件（包含选中 commit 本身）
- ✅ 支持多种压缩格式: `zip` / `tar.gz` / `tar.bz2`
- ✅ 自动处理初始 commit 情况
- ✅ 支持自定义输出目录

## 安装

```shell
make gitpack
```

安装后，`gitpack` 命令将可全局使用。

## 使用方法

### 基本用法

```shell
gitpack
```

运行后将进入交互式界面，按照提示操作即可。

### 命令行选项

```shell
gitpack --help      # 显示帮助信息
gitpack -h          # 显示帮助信息（简写）

gitpack --version   # 显示版本信息
gitpack -v          # 显示版本信息（简写）
```

## 使用流程

### 1. 选择打包模式

运行 `gitpack` 后，首先选择打包模式：

- **模式 1**: 从指定 commit 到 HEAD（当前版本）
- **模式 2**: 指定 commit 区间（从 commit A 到 commit B）

### 2. 选择 commit

工具会显示最近 30 条提交记录，选择对应的编号即可：

```
最近的提交记录：
 1) abc1234 (2 hours ago) feat: 添加新功能 <张三>
 2) def5678 (1 day ago) fix: 修复bug <李四>
 3) ghi9012 (2 days ago) docs: 更新文档 <王五>
 ...
```

### 3. 设置文件过滤（可选）

可以指定文件匹配模式，只打包符合条件的文件：

```
文件匹配模式 (默认 *, 如: *.js, src/*): 
```

示例：
- `*.js` - 只打包 JavaScript 文件
- `src/*` - 只打包 src 目录下的文件
- `*` - 打包所有文件（默认）

### 4. 确认并设置输出

确认要打包的文件列表后，可以设置：
- 输出目录（默认当前目录）
- 输出文件名（自动生成，也可自定义）

## 示例

### 示例 1: 打包最近一次提交到 HEAD 的变更

```shell
$ gitpack
请选择打包模式：
  1) 从指定 commit 到 HEAD（当前版本）
  2) 指定 commit 区间（从 commit A 到 commit B）

请选择模式 [1-2]: 1
请选择起始 commit 编号 [1-30]: 5
文件匹配模式 (默认 *, 如: *.js, src/*): *
继续打包? [y/N]: y
输出目录 (默认: 当前目录): ./releases
```

### 示例 2: 只打包 JavaScript 文件

```shell
$ gitpack
# ... 选择模式和 commit ...
文件匹配模式 (默认 *, 如: *.js, src/*): *.js
```

### 示例 3: 打包指定 commit 区间

```shell
$ gitpack
请选择打包模式：
  1) 从指定 commit 到 HEAD（当前版本）
  2) 指定 commit 区间（从 commit A 到 commit B）

请选择模式 [1-2]: 2
请选择起始 commit 编号（较早的提交）[1-30]: 10
请选择结束 commit 编号（较新的提交）[1-30]: 3
```

## 输出格式

默认输出文件名格式：

- **模式 1**: `changes_from_{commit}_to_HEAD_{时间戳}.tar.gz`
- **模式 2**: `changes_{start_commit}_to_{end_commit}_{时间戳}.tar.gz`

支持的压缩格式：
- `.tar.gz` / `.tgz` - gzip 压缩（默认，推荐）
- `.zip` - zip 压缩
- `.tar.bz2` - bzip2 压缩

自定义输出文件名时，根据扩展名自动选择压缩方式。

## 卸载

如需卸载，运行：

```shell
make uninstall
```

## 版本信息

当前版本: v3.0

## 许可证

MIT License
