# CustomStatusBar — iOS 17 / arm64e / rootless

这是一个 Theos 工程，用于在 SpringBoard 中测试自定义状态栏 UI。

## 编译

建议使用 Theos + rootless toolchain：

```bash
make clean package FINALPACKAGE=1
```

产物位于：
`packages/`

## 工程文件

- `Tweak.xm`：核心状态栏 UI
- `CustomStatusBar.plist`：仅注入 SpringBoard
- `Makefile`：iOS 17 / arm64e
- `control`：Deb 包信息

## 注意

这是第一版 UI 测试工程，目前信号/Wi-Fi 图标属于自绘测试 UI，
尚未替换成 Apple 私有框架中的实时状态数据。

如果你使用 Relaxin/rootHide，而不是标准 Theos rootless，
需要根据你的 GitHub 编译环境调整打包规则。
