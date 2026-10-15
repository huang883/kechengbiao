# 专注限制系统（0.2.0）

## 架构分析与实施方案
原项目 Flutter/Dart + Riverpod ChangeNotifier + go_router；6 个底部导航页面。课程使用 Drift SQLite v6；原番茄钟由 PomodoroController（SharedPreferences）和 flutter_local_notifications 管理，页面每秒刷新，原倒计时依赖墙上时钟。Android Kotlin MainActivity 原无业务服务；minSdk 24，compile/target 使用 Flutter SDK（本机 target 36），Java 17。复用现有 Material 3 配色、导航、时长设置、休息计时、通知模块；不重建项目。

新增 Kotlin AccessibilityService + SQLiteOpenHelper + MethodChannel。Flutter 展示界面，原生层独立于 Flutter 页面管理受限会话和事务。专注数据库独立于课程库，避免后台服务依赖 Flutter 引擎。只订阅窗口状态包名，不读取窗口内容、输入文字、网页或通讯录，不上传应用使用信息。暂停计时仍保留应用限制。

计划修改：pomodoro_controller.dart / pomodoro_page.dart、app_controller.dart、main.dart、AndroidManifest.xml、MainActivity.kt、pubspec.yaml。新增 focus_bridge.dart / focus_pages.dart / focus_stats.dart、FocusStore.kt / FocusService.kt / FocusReceiver.kt / FocusPolicy.kt、辅助服务配置、测试和本说明。

## GitHub 调研（2026-10-15 核验 GitHub API、许可证及服务源码）
| 仓库 | 技术栈 / 许可证 | 最近推送 / 状态 | 参考与兼容性 |
|---|---|---|---|
| https://github.com/adnanrangrej/Focus-Modes-App | Kotlin、Compose、Hilt、Room / MIT | 2025-10-18，未归档 | AppBlockerService 的窗口事件→辅助功能覆盖层设计可参考；不引入 Compose/Hilt 整套框架。核验提交 8b39ad2c47e26d600b2067d28b25d155440c99e7。 |
| https://github.com/foxeshab/FocusBlock | Kotlin、Android / MIT | 2026-08-01，未归档 | 前台包名判定、应用列表思路可复用；其 minSdk26 高于本项目24，不整体移植；不采用 DeviceAdmin、阻止卸载或严格锁定。提交 670fe96e3396b9c2b18440c65e14549cb784a4cf。 |
| https://github.com/nsh07/Tomato | Kotlin Multiplatform、Compose、Room / GPL-3.0 | 2026-10-14，未归档 | 参考会话统计和计时服务的产品组织；不复制代码或引入其 GPL 模块，避免给既有项目增加许可证义务。提交 d1cb087daf030c205a872305cd5b5974876f7fed。 |
| https://github.com/dewaleolaoye/focus | Kotlin / 未声明许可证 | 2026-09-23，未归档 | 仅评估权限说明交互，不复制未获许可代码。 |

检索覆盖 Android Pomodoro app blocker、Android focus mode open source、Android accessibility app blocker、Android app whitelist、Android focus session tracker、番茄钟 应用限制 开源。推送时间不代表质量或维护承诺。商业「番茄 ToDo」未作为开源代码来源。新代码独立实现；现有 flutter_pomodoro_cat 的 MIT 署名继续保留。

## 权限与平台边界
参考官方资料：
- https://developer.android.com/guide/topics/ui/accessibility/service
- https://developer.android.com/reference/android/os/SystemClock
- https://developer.android.com/training/package-visibility/declaring
- https://support.google.com/googleplay/android-developer/answer/10964491

辅助功能需要用户明确同意并手动开启。isAccessibilityTool=false；canRetrieveWindowContent=false；不请求手势、Usage Access、VPN、设备管理员或全量应用查询权限。Android 11+ 仅查询启动器应用及必要系统 Intent；无启动入口的后台包不列为用户可选应用。辅助服务是系统绑定服务，不冒充 Android 14+ 前台服务类型，不声明 specialUse 前台服务；既有通知权限只用于结束提醒。

Google Play 对非无障碍用途要求醒目披露、明确同意、商店说明及声明审核；本实现不保证获准上架。部分侧载安装在 Android 13+ 需用户自行允许受限设置。设置、权限管理、卸载、紧急电话和系统安全功能始终可用。厂商省电、强制停止、分屏/悬浮窗、系统事件缺失会影响拦截；不是设备管理器或不可解除的系统锁屏。

## 实际数据库设计
`databases/focus.sqlite`，SQLiteOpenHelper schema 1；课程库仍为 Drift schema 6。所有服务事件及通道写操作在 Android 主线程串行执行，数据库事务和唯一约束提供最后防线。

| 表 | 字段及规则 |
|---|---|
| sessions | id(UUID 主键)、started/ended(UTC epoch ms)、planned、timer_ms、restricted_ms、state、consumed、last_elapsed、last_wall、zone、active_slot。active_slot 固定1，活动状态部分唯一索引确保同时只有一个 running/paused 会话。 |
| segments | id、session_id 外键、start/end、timer_ms、restricted_ms、paused；连续同状态区间合并，暂停/继续形成新区间。 |
| exits | session_id 主键/外键、month(YYYY-MM)、at、timer_ms、restricted_ms；同会话最多一条。自然月剩余次数为 max(0,2-count(month))，保留旧月账本。 |
| whitelist | package 主键。用户选择持久化，读取列表时清理已卸载/无启动入口的失效项。必要系统包始终另行允许，不能移除。 |

`focus_safety` SharedPreferences 仅存披露同意、提醒开关和存储故障恢复标记，不承担额度事务。退出令牌仅存原生内存，绑定会话 ID 和 elapsedRealtime 时间；进程重建令牌失效，重新打开重新等待完整5秒。确认时再次验证会话、令牌、实际经过时间和当月额度，在同一个事务中插入退出账本并结束会话。重复事件不会再次扣次；事务失败全部回滚并安全解除限制。

## 状态、时长与恢复
- 专注开始检查用户同意、辅助服务已连接、数据库正常及1—180分钟范围。计时和限制由 Kotlin 管理；休息阶段仍使用原 Flutter 计时。
- 暂停只停止计时时长累计，限制继续。专注期间禁止通过重置、跳阶段、改时长或改白名单绕过普通退出。
- 服务每秒检查；以 SystemClock.elapsedRealtime 计算增量。正常完成按剩余计划时长截断最后区间，不多计一次心跳。短暂间隔最多15秒且墙上时间差与单调时间差偏差不超过2秒；超出则记中断，仅保留最后已确认区间。
- “有效限制时长”是已授权、服务健康且限制模式开启的确认区间，不是被遮挡应用的停留时间，也不是证明用户全程专心。白名单和必要系统功能本来就允许使用。对系统未发送的窗口事件无法提供绝对拦截保证。
- 应用退后台不依赖 Flutter 刷新；活动期间使用有超时的 partial wake lock，结束/异常释放。Android Doze、厂商省电仍可能暂停服务，运行空档保守记中断，不能据墙上时间补记完成。
- 系统撤销权限、服务销毁/中断、时间或时区变化、安全退出均结束并移除覆盖层，不扣普通额度。新进程打开数据库时把孤立活动会话记为中断；重启/升级广播也执行恢复，不自动重新锁住设备。因初始化先恢复孤立会话，重启后的历史可能显示“进程中断”而不是精确区分断电/强杀。
- SQLite 写入失败时解除覆盖层并设置恢复标记；如果磁盘完全不可写，不能保证异常原因落盘，但下次成功打开时保守恢复孤立会话，绝不默认正常完成。系统设置始终作为独立安全恢复途径。
- 自然月使用设备当前时区 YearMonth，退出归属确认发生的月份。历史月份额度不会被清空；调回旧月份时读取旧账本。修改未来月份、清除数据、卸载、root 可绕过纯本地次数限制；本实现不声称防作弊。
- 统计按当前设备时区展示，区间边界使用当地日/月/年而不是固定24小时；时长分配采用累计整数差避免舍入重复。完成/提前退出/中断次数按结束日期计一次；平均时长使用范围内结束的已完成会话完整计时时长。旧版今日汇总保留，不构造没有证据的限制区间。

## 文件清单
新增：
- `apps/campus_time/android/app/src/main/kotlin/cn/huangrui/campus_time/FocusPolicy.kt`：单调时间和额度规则。
- 同目录 `FocusStore.kt`：会话、区间、退出事务、白名单、故障恢复。
- 同目录 `FocusService.kt`：前台应用事件、拦截覆盖层、心跳与结束提醒。
- 同目录 `FocusApps.kt`：应用查询、图标、必要系统应用例外。
- 同目录 `FocusReceiver.kt`：重启、升级、时间/时区变化和锁屏处理。
- `android/app/src/main/res/xml/focus_service.xml`、`res/values/focus_strings.xml`：辅助服务能力和披露。
- `lib/features/pomodoro/focus_bridge.dart`、`focus_pages.dart`、`focus_stats.dart`：平台桥接、授权/退出/白名单/统计页面、时间区间统计。
- `android/app/src/test/kotlin/cn/huangrui/campus_time/FocusStoreTest.kt`：真实 SQLite 接口的 Robolectric 主机测试。
- `test/focus_system_test.dart`、`test/focus_visual_test.dart`：交互、统计及渲染验证。
- `tools/focus-tests.init.gradle`：本机网络受限时可选的测试仓库配置；仅主机测试排除不需要的 Flutter 调试 ABI 包，不用于 APK 构建。

修改：`MainActivity.kt`、`AndroidManifest.xml`、`android/app/build.gradle.kts`、`main.dart`、`application/app_controller.dart`、`pomodoro_controller.dart`、`pomodoro_page.dart`、`pubspec.yaml`、`.gitignore`、README 与本说明。相关旧测试改为读取与原提取样本字节一致的 `assets/default_timetable.json`，使公开仓库不依赖被排除的重复个人 PDF 测试文件。

## 真机验证步骤（待连接设备后执行）
1. 覆盖安装0.2.0，确认既有课表/待办仍在；番茄钟选择1分钟，先不开启辅助功能，点击开始，应展示披露并停留待开始状态。
2. 同意后手动开启“课间专注限制”；返回白名单搜索并选择计算器，保存后重开验证仍选中；卸载一个曾选择的应用后验证失效项清理。
3. 开始专注：打开计算器可用，打开非白名单应用出现拦截；分别用返回课间/桌面、电话和系统设置验证安全入口。检查横屏和大字体下拦截页面可滚动。
4. 暂停再切换非白名单应用仍受限；继续后倒计时恢复。自然结束应解除，次数仍为2/2，统计记录为正常完成。
5. 新开一次：退出窗口出现即5s禁用；尝试快速点击、旋转、切到后台回来；不足5秒不能确认；时间到也不自动退出。取消/返回键不扣次，重开重新5秒。
6. 满5秒主动确认，检查1/2；再做一次检查0/2；第三次只显示机会用完。多点确认不能重复扣次，安全解除始终可用且记录中断。
7. 活动时撤销辅助权限、强制停止、重启设备分别测试：解除限制，记录中断，不计完成、不扣主动次数；不自动恢复锁定。
8. 测试月末23:59跨月确认、跨午夜完成、修改时间/时区。退出按确认月份归属，统计时长按区间分配；改时间期间的活动会话应中断。
9. 在测试设备制造存储不足，验证异常提示和系统设置安全退出；不要在个人主力设备上填满磁盘。
10. 设备息屏、后台和厂商省电分别运行，检查限制稳定性及历史中断。荣耀10/API29、Android13+侧载受限设置、Android14—16均需实机补测。

## 后续优化
优先补齐荣耀真机与 API24/29/33/36 系统矩阵、分屏/悬浮窗和省电模式的拦截验证；提供可导出的历史数据与本地保留策略；统计数据量大时改分页查询。若需要更强连续性，可评估符合政策的前台服务与用户主动电池优化设置，但不能把省电豁免或商店审核通过当成保证。正式发布需替换现有调试签名、由项目所有者确定整体许可证并完成商店辅助功能声明。
