# iPad 版

原生 SwiftUI 客户端，适用于 iPadOS 17 及以上；Liquid Glass 需要 iPadOS 26 及以上。没有网页容器或网络依赖。

- 针对手指点击设计的大按键，横屏左右分区、竖屏上下排列。
- 同一套100道题、计时、附近5题、逐题操作、错题回顾和最快纪录。
- 数字键盘和比较符号键盘固定占用同样大小的区域，切换时周围控件不移动。
- 自动保存本机进度；离开应用期间已开始的本轮计时继续累计。
- Mac 与 iPad 的成绩分别保存，不自动同步。

## 安装到自己的 iPad

1. 用 Xcode 26 或更新版本打开 `Grade2MathPractice.xcodeproj`。
2. 选择 `Grade2MathPracticeIPad` target，在 Signing & Capabilities 中选择自己的 Team，保留自动签名。
3. 连接 iPad，按设备提示信任 Mac，并在需要时开启开发者模式。
4. 将运行目标设为自己的 iPad，点击 Run 安装运行。

真机安装需要 Apple 账号签名。当前仓库不包含证书、开发团队、设备标识或签名配置文件；未提供可直接安装的已签名 IPA。App Store / TestFlight 分发需要另行配置开发者账号和发布流程。

参考：[Apple：在模拟或实体设备上运行应用](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)。

## 命令行编译检查

在仓库根目录执行：

```sh
xcodebuild -project iPad/Grade2MathPractice.xcodeproj \
  -scheme Grade2MathPracticeIPad \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/iPad build CODE_SIGNING_ALLOWED=NO
```

将 SDK 改为 `iphoneos`、destination 改为 `generic/platform=iOS` 可生成未签名真机构建；这不等于已安装运行。

项目文件已经随源码提交，日常使用不需要 Ruby。若更改源文件清单后要重新生成工程，可安装 `xcodeproj` Ruby gem，再运行 `ruby scripts/generate-ipad-project.rb`。

## 验证范围

已通过 iPad 模拟器 SDK 和真机 SDK 编译，以及共用核心的5项测试（含整套100题）。当前开发环境缺少可用的 iPad 模拟器交互窗口，尚未完成 iPad 触控、旋转、分屏或真机视觉验收。
