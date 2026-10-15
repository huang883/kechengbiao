# 课间 · 课程与个人时间管理

当前版本 **0.2.1+17**。Flutter/Dart 界面，Android Kotlin 专注服务，课程数据库 Drift SQLite v6，专注数据库 SQLite v1。Android 7.0（API24）及以上。

- PDF 导入、可修改预览、多个课表切换和改名；首次安装使用已有默认课表。
- 周课表/今日日程、节次或精确时间编辑、点空白新建、单节与整日调课及来源提示。
- 课程完整取色器与 HEX 输入、白色课程文字；有时间/无时间待办与本地提醒。
- 番茄钟专注时自动限制非白名单应用，暂停计时仍保持限制。
- 应用白名单搜索、图标与本地保存；课间、电话、桌面、设置等必要功能始终允许。
- 每自然月2次普通提前退出，5秒确认倒计时和原生事务扣次；安全退出及权限撤销始终可用。
- 周/月/年/近5年柱状图、历史详情、完成/提前退出/中断以及实际限制时长分开统计。

专注限制依赖用户主动授权 Android 辅助功能。它不是不可解除的系统锁屏，不能保证绕过厂商省电或强制停止。首次使用请先选白名单、阅读披露并手动开启“课间专注限制”。系统异常保守记为中断，不扣普通提前退出次数。

## 0.2.1 修复

课程和待办重叠时保持卡片宽度，并排显示，必要时左右滑动查看；星期行仍固定在顶部。待办编辑支持直接下拉关闭和关闭按钮。单节及整天调入均保留目标原有课程；时间冲突并存展示，不再裁切或隐藏原课。详见 [修复与测试记录](docs/OVERLAP_TASK_TRANSFER_FIX.md)。

## 设计与验证

[专注系统完整说明](docs/FOCUS_SYSTEM.md)包含架构、GitHub 调研与许可证、数据库设计、权限/商店政策、修改清单、已知限制和真机操作步骤。
[本次测试与交付记录](docs/FOCUS_QA.md)区分已执行自动测试与尚未执行真机项目。
既有功能见 [课程编辑](docs/COURSE_EDITOR.md)、[调课编辑范围](docs/TRANSFER_EDIT_SCOPE.md)、[多课表与颜色](docs/MULTI_TIMETABLE_COLORS.md)。

## 构建

开发环境：Flutter 3.47.6 / Dart 3.13.5、JDK17以上、Android SDK36；依赖版本见 pubspec.lock 和 Gradle 配置。安装 Flutter 并配置 Android SDK 后：

```sh
cd apps/campus_time
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK 位于 `apps/campus_time/build/app/outputs/flutter-apk/app-release.apk`。当前沿用项目调试密钥签名，适合开发测试；正式商店发布前配置正式签名。Windows 本机也可使用 `tools/build_android.ps1`（工具路径由 `tools/android_env.ps1` 设置）。

原生数据库测试：

```sh
cd apps/campus_time/android
./gradlew :app:testDebugUnitTest
```

本机 Google Maven 直连不可用时使用记录在测试说明中的可选 init 脚本；它仅用于 JVM 主机测试，不应用到 APK 构建。

## 数据与来源

默认课表是用户要求随项目保留的内置课程数据，位于 `apps/campus_time/assets/default_timetable.json`。原始 PDF、重复 PDF 提取测试文件、设备序列号报告、个人数据库、签名密钥和本机缓存不上传。解析器/存储测试直接复用该内置样本；PDF 原文件几何比对需自行提供原件。

原番茄钟参考 flutter_pomodoro_cat（MIT），署名保留在 assets/licenses 和 [来源说明](docs/POMODORO_SOURCE.md)。本次专注系统独立实现，参考项目的许可证与固定提交列于专注说明；未使用商业“番茄 ToDo”闭源代码。项目整体许可证由所有者另行指定。
