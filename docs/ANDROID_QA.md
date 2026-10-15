# Android 阶段验收 — 2026-10-06

## 已通过
- 核心 41 项：原 36 项解析/周计算/140 天真实数据基准，加 5 项真实分钟时间轴、缺失作息、稳定排序及冲突边界测试。
- 数据库 20 项：草稿版本、确认事务、去重、回滚、任意分钟待办、设置、独立进程重开。
- PDFium 2 项：读取真实 PDF bytes；所有课程字段、学期、来源哈希与独立桌面基准一致；无效 bytes 明确拒绝。
- Flutter 6 项：空应用无自动导入；第 11/12 周从 0 到 14 条；任意分钟冲突可保存；修订后确认勾选失效且重新确认才入库；控制器读取保存结果；430×932 手机尺寸页面渲染。
- 四个包静态检查。界面测试使用内存 SQLite；跨进程文件重开由数据库包独立覆盖。

## 视觉检查
`output/android/preview-{today,schedule,tasks,import}.png` 为 Flutter 引擎实际渲染。中文字体仅在本机测试时加载 Windows 字体，不打包分发。测试钟点是明确构造的示例；APK 没有内置学校作息或自动导入数据。

## Android 构建
最终通用 release APK 构建成功（78.5 MiB）：Flutter 3.47.6、Dart 3.13.5、JDK 21、Android SDK 35/36、NDK 28.2.13676358、CMake 3.22.1。首次工具缺失已补齐；release 保留 ic_notification 资源，避免资源裁剪破坏提醒图标。Cupertino 备用字体已打包，最终构建不再出现缺失字体警告。

最终包核验：包名 cn.huangrui.campus_time，显示名称「课间」，versionName 0.1.0 / versionCode 1，minSdk 24 / targetSdk 36；仅 arm64-v8a、armeabi-v7a、x86_64，排除了缺少 Flutter 引擎的 32 位 x86。APK v2 签名与 16 KB zip 对齐检查通过。三种架构均含 Flutter/App/PDFium/SQLite/JNI 原生库；两组图标字体与通知 drawable 存在；没有打包原始 PDF、样本 JSON 或数据库。

交付：`output/android/campus-time-0.1.0.apk`，82,346,847 bytes。
SHA256：`e8c55670bff2b7718c6d852528cb67aa847caccb525c7990e0b4a72af5893884`。
证据：同目录 build.log、flutter-analyze.log、flutter-tests.log、apk-signature.log、apk-metadata.txt、apk-content-check.json、SHA256SUMS.txt。

## 尚未验收
没有已连接的 Android 手机或模拟器。因此不把 Widget、Windows PDFium 测试或 APK 构建当成手机端运行证明。待验证：系统文件选择器→PDFium→确认→退出重进；通知授权、系统重启和省电行为；实际手机字体、键盘及大字号。

本地测试签名不等于应用商店发布签名；上架前需自行管理发布密钥。

## 角色交接与总控复核
[ROLE HANDOFF] Role：QA / 构建工程师；Completed：69 项测试、静态检查、页面目视检查、通用 APK 构建与签名/内容验证；Files：应用源码、3 个基础包、构建/验证脚本及本文列出的交付物；Public APIs：API_CONTRACTS v0.3；Dependencies：既有 schema v1 与官方工具链；Known Issues：设备运行和通知行为未验收；Recommended Next Role：ORCHESTRATOR。

[ORCHESTRATOR REVIEW] PROJECT_SPEC / DATA_MODEL / API_CONTRACTS 一致，ACR-003 无破坏性变更，不改变数据库 schema；测试通过，安装包生成完成。Android 生成任务 DONE；真机验收明确保留未完成状态，不以桌面验证替代。

## 0.1.1+2 导入修复验收 — 2026-10-07
IMP-001 入口与误导提示修复，静态分析零问题，7 项 Flutter 测试通过。新增真实 PDF 完整预览→周起始确认→明确处理未排课条目→最终确认 22 条排课测试，包含取消不写入、未选不默认、首屏可点击。390×844 行为测试与 430×932 截图检查通过。

APK：output/android/campus-time-0.1.1.apk，82,346,847 bytes，versionCode=2。v2 签名、16 KB zip 对齐、三架构与包名验证通过；签名证书与 0.1.0 一致，可覆盖安装，schema v1 不变，不需要卸载或清库。
SHA256：e449e7bd002be9c9dc8b26920b1fa21d8ec91065cbc4968760826cd6bc850805。
版本证据固定在 output/android/qa-0.1.1/；output/android 根目录通用日志为最近一次构建。

ADB 当前无设备，没有真机重验，因此 IMP-001 保持 FIXED / AWAITING REAL DEVICE VERIFICATION，未标 CLOSED。用户需要安装新版后在导入预览顶部点击“确认周起始日”。
