# 0.2.0 专注系统测试与交付记录

验证日期：2026-10-15（Asia/Shanghai）。本记录仅针对本次功能，历史文档中的荣耀设备记录不代表本次真机测试。

## 已执行
| 检查 | 结果 |
|---|---|
| Flutter 静态分析 | 无问题 |
| Flutter 全套测试 | 38/38 通过，包括6项新逻辑/交互测试和1项新页面渲染测试 |
| Android 原生数据库/规则测试 | 11/11 通过，Robolectric 4.17、SDK28 模拟环境、SQLite LEGACY 驱动 |
| schedule_core | 49/49 通过 |
| schedule_storage | 25/25 通过，包括独立进程重新打开数据库 |
| 页面检查 | 430×932 渲染白名单、统计图、5秒退出弹窗，无布局异常；这是渲染测试，不是真机截图 |

原生用例覆盖：不足4999ms拒绝/5000ms允许、取消重开和旧令牌失效、两次后第三次拒绝、跨月恢复及旧月账本保留、正常完成不扣次、暂停仅累加限制时长、进程重建、服务运行空档、修改时钟/时区、权限撤销结束、数据库故障注入后的事务回滚、白名单重开保留/卸载清理/专注时禁改、重复开始去重、月末跨月确认。

Flutter 用例覆盖：跨午夜/跨年时长分配与次数归属、整数毫秒不重复计入、闰年月份/周一起算、退出按钮禁用与恢复、倒计时结束不自动退出、取消不扣次/重开重置、0次不创建倒计时、受限会话禁止重置/跳过/修改时长。截图数据为测试构造，不能作为真实专注记录。

## 发现并修复
1. 本机 Google Maven 无法直连、旧代理失效，导致首次原生测试尚未执行；使用可选测试 init 脚本切换 Maven 来源，并排除 JVM 测试不需要的 Flutter 调试 ABI 包后解决。
2. Flutter/AGP 主机测试包含资源时遇到生成资产任务依赖校验；SQLite 测试不需要 Android UI 资源，关闭该选项，Flutter 页面另行测试。
3. 旧 SQLite 测试驱动不支持常量表达式索引；改为带 CHECK 的 active_slot 列和部分唯一索引，提高低版本兼容性，并维持单活动会话约束。
4. 今日统计最初按结束日期累加整段时长；已改为对已完成会话的区间按日边界分配，避免跨午夜时长全部落到第二天。
5. 横屏拦截界面改为可滚动，避免安全入口超出可见区域。
6. 覆盖层/服务异常与数据库异常分别记录，避免将所有故障误报为存储失败。

## 复现命令

```powershell
. ./tools/android_env.ps1
cd apps/campus_time
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --release --no-pub
cd android
./gradlew.bat :app:testDebugUnitTest
```

只有本机仓库网络问题需要以下替代测试命令（不用于 release 构建）：

```powershell
./gradlew.bat :app:testDebugUnitTest -I ../../../tools/focus-tests.init.gradle '-Dhttp.proxyHost=' '-Dhttps.proxyHost='
```

本地日志位于 `output/android/focus-*.log`，Robolectric XML 报告位于 `apps/campus_time/build/app/test-results/testDebugUnitTest/`。日志和构建缓存不上传仓库。

## 尚未执行 / 限制
当前 ADB 无设备，SDK 未安装模拟器系统镜像；未进行本次荣耀10或荣耀90安装、真实应用切换、息屏省电、辅助权限撤销及系统重启验收。Robolectric验证数据库和时钟策略，不能代替系统辅助服务拦截与厂商后台策略测试。真机步骤见 [FOCUS_SYSTEM.md](FOCUS_SYSTEM.md)。

应用限制是可撤销的辅助功能覆盖层，不是系统锁屏；Play 审核和厂商稳定性未验证。纯本地月份/次数不能抵抗清除数据、卸载或故意改时间。当前沿用调试签名，仅作测试安装包。

## 最终安装包
- `campus-time-0.2.0.apk`，versionCode 16，package `cn.huangrui.campus_time`。
- Release 构建成功；APK v2 签名验证通过，16 KB zip alignment 验证通过。
- minSdk24 / targetSdk36 / compileSdk36，应用名称“课间”。
- SHA-256：`b5cb0cb601665cd6a0f1a604cd93304775f6a18e6ffaf647b7f50d1cfc4a4cf6`。
- 本机成果：`output/android/campus-time-0.2.0.apk`；聊天工作区另有交付副本。APK及日志未纳入源代码提交。
