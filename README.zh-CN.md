# NetBar

**在 macOS 菜单栏里紧凑显示网速、CPU 和内存。**

[English](README.md) · [下载预览版](https://github.com/meihaowei/NetBar/releases/download/v1.0.6-local/NetBar-1.0.6-local.dmg) · [源代码](https://github.com/meihaowei/NetBar)

NetBar 是一个原生 AppKit 小工具，不显示 Dock 图标，不需要账号，不包含统计 SDK，
也不会在后台访问网络。

## 界面预览

![菜单栏中的 NetBar](docs/netbar-status.png)

菜单栏使用两行显示数据：

| 行 | 左侧 | 右侧 |
| --- | --- | --- |
| 上行 | `↑` 上传速度 | CPU 占用 |
| 下行 | `↓` 下载速度 | 内存占用 |

各项使用固定字符宽度，因此数字变化时不会左右跳动。数据每秒刷新一次。

点击状态栏项目可以查看精确数值：

![NetBar 详细菜单](docs/netbar-menu.png)

菜单中包含实时下载和上传速度、CPU 占用、已用内存、总内存，以及退出命令。

## 安装

系统要求：

- macOS 12 或更高版本
- Apple Silicon 或 Intel Mac

1. 下载[当前预览版 DMG](https://github.com/meihaowei/NetBar/releases/download/v1.0.6-local/NetBar-1.0.6-local.dmg)。
2. 打开 DMG，将 `NetBar.app` 拖入“应用程序”。
3. 从“应用程序”启动 NetBar，它会立即出现在菜单栏。

> [!IMPORTANT]
> 当前预览版使用临时签名，尚未经过 Apple 公证。其他电脑的 macOS 可能阻止打开。
> 可供公开信任下载的版本需要 Developer ID 签名和 Apple 公证。

## 从源码构建

项目需要 Swift 6、Xcode Command Line Tools 和 macOS SDK：

```sh
git clone https://github.com/meihaowei/NetBar.git
cd NetBar
chmod +x scripts/release.sh
./scripts/release.sh --local
open NetBar.app
```

本地构建同时支持 Apple Silicon 和 Intel Mac，适合开发和测试。

## 隐私

NetBar 仅通过 Apple 公共系统接口读取汇总的网卡、CPU 和内存计数器。
它不会读取网络包内容，也不会收集、保存或上传个人数据。

## 许可证

MIT，详见 [LICENSE](LICENSE)。
