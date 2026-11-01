# iPhone / iPad 版

原生 SwiftUI 客户端，适用于 iOS / iPadOS 17 及以上；Liquid Glass 需要 iOS / iPadOS 26 及以上。没有网页容器或网络依赖。

- iPhone 使用竖屏紧凑版面，缩小题目和填空框并保留大键盘；iPad 横屏左右分区、竖屏上下排列。
- 同一套100道题、计时、附近5题、逐题操作、错题回顾和最快纪录。
- 数字键盘和比较符号键盘固定占用同样大小的区域，切换时周围控件不移动。
- 自动保存本机进度；离开应用期间已开始的本轮计时继续累计。
- Mac、iPhone 与 iPad 的成绩分别保存，不自动同步。

## 安装到自己的 iPhone / iPad

1. 用 Xcode 26 或更新版本打开 `Grade2MathPractice.xcodeproj`。
2. 选择 `Grade2MathPracticeIPad` target，在 Signing & Capabilities 中选择自己的 Team，保留自动签名。
3. 连接 iPhone / iPad，按设备提示信任 Mac，并在需要时开启开发者模式。
4. 将运行目标设为自己的 iPhone / iPad，点击 Run 安装运行。

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

已通过 iPad 模拟器 SDK 和真机 SDK 编译，以及共用核心的8项测试（含整套100题）。当前开发环境缺少可用的 iPad 模拟器交互窗口，尚未完成 iPad 触控、旋转、分屏或真机视觉验收。

## 按记录练错题

练习记录显示每轮的错题数量。新完成的练习会保存具体错题，可点击“练错题”进入该轮的错题练习，题量按实际错题数显示。错题练习成绩单独标记，不参与整套100题最快纪录；可返回原来的整套练习进度。

旧版本记录仍可显示错题数量。只有当前仍保留完整作答的最近一轮能自动恢复具体错题；其他旧记录若只有总分，将标注“旧记录未保存具体题目”，不提供错误的重练入口。Mac、iPhone 和 iPad 记录分别保存。

## 家庭手机容器安装

可将真机构建打包为 IPA 后导入 LiveContainer。iPhone 与 iPad 共用题库和存档格式，但各设备记录独立保存；导入手机不覆盖 iPad 资料。无需联网即可练习。现有 target 与 Bundle ID 保留，方便更新已有 iPad 安装。

### iPhone 适配验证（1.4.0）

已通过 iOS 真机 Release 编译及8项共用核心测试。iPhone 模拟器 SDK 编译通过；模拟器截图为黑屏，未作为视觉验收依据。真机触控布局与退出重开保存仍需在目标设备验收。
