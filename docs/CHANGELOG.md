# 文件变更记录

## 数据库阶段续轮

本轮新增文件：

|路径|原因|
|---|---|
|packages/schedule_core/lib/src/persistence.dart|纯 Dart 持久化实体、快照、错误与 Repository 抽象|
|packages/schedule_storage/pubspec.yaml、pubspec.lock|Drift/SQLite 包及已测试依赖锁定|
|packages/schedule_storage/analysis_options.yaml、build.yaml|分析规则与生成配置|
|packages/schedule_storage/lib/schedule_storage.dart|对外导出 Repository 和数据库入口，隐藏生成行类型|
|packages/schedule_storage/lib/src/schema.drift|初始 schema v1、索引、外键、检查约束和周次触发器|
|packages/schedule_storage/lib/src/database.dart|内存/文件连接、外键开启、版本保护|
|packages/schedule_storage/lib/src/database.g.dart|Drift 自动生成的映射代码|
|packages/schedule_storage/lib/src/codec.dart|JSON 证据序列化、领域对象恢复与绑定参数|
|packages/schedule_storage/lib/src/import_repository.dart|草稿版本、修改历史、明确确认、原子提交及幂等|
|packages/schedule_storage/lib/src/course_repository.dart|领域快照、更新订阅与元数据读取|
|packages/schedule_storage/lib/src/task_repository.dart|任意分钟待办持久化 CRUD 与筛选|
|packages/schedule_storage/lib/src/settings_repository.dart|作息原子替换、周偏移及颜色保存|
|packages/schedule_storage/schemas/drift_schema_v1.json|冻结结构，供后续迁移与改动检查|
|packages/schedule_storage/test/import_repository_test.dart|确认、并发、回滚、逐条数据读回与来源隔离测试|
|packages/schedule_storage/test/task_settings_test.dart|任意分钟、任务 CRUD、SQL 绑定、作息原子替换测试|
|packages/schedule_storage/test/persistence_test.dart|跨进程文件重开与未知版本保留数据测试|
|packages/schedule_storage/test/support/fixture.dart|复用真实 PDF，显式标注测试周序/排除理由|
|packages/schedule_storage/test/support/reopen_probe.dart|独立进程读取已关闭的数据库|
|tools/verify_storage.ps1|生成、schema 比对、分析、构建读取程序和数据库测试|
|docs/DATABASE_SCHEMA.md|结构说明、ACR-002 与事务边界|
|docs/DATABASE_QA.md|数据库阶段验收结果|
|output/database/analyze.log、tests.log|生成的验证记录|

本轮修改文件：

- packages/schedule_core/lib/schedule_core.dart：导出持久化抽象，仍不依赖 Drift。
- tools/verify.ps1：接入数据库验证；tools/write_analysis_report.py：更新报告中的实现状态。
- .gitignore：忽略 SQLite 运行数据文件。
- README.md：更新阶段成果、复现与下一步。
- docs/PROJECT_SPEC.md、ARCHITECTURE.md、DATA_MODEL.md、API_CONTRACTS.md、TASK_BOARD.md、DECISIONS.md、KNOWN_ISSUES.md、QA_REPORT.md、CHANGELOG.md：同步已实现合约、状态与验证边界。
- output/analysis/*：重新生成验证日志和解析结果；输入 PDF 和 sources/ 未改变。

删除文件：无。临时测试数据库在校验路径后清理；生成工具缓存与独立读取程序位于 .dart_tool/、build/，不属于业务源码。

## 首轮 Phase 0/1

所有路径相对于项目根目录。全部为新增文件；无既有项目文件被修改或删除。迭代修正仅涉及本轮新建文件。

|新增路径|原因|
|---|---|
|README.md|项目入口、当前边界、复现方式|
|.gitignore|忽略本地 SDK、依赖缓存、生成报告与临时文件|
|docs/PROJECT_SPEC.md|冻结功能范围与验收标准|
|docs/ARCHITECTURE.md|分层、依赖与导入写入边界|
|docs/DATA_MODEL.md|统一模型和 ACR-001|
|docs/API_CONTRACTS.md|区分本轮已实现与后续接口|
|docs/TASK_BOARD.md|任务状态和阶段依赖|
|docs/DECISIONS.md|重要选择和资料来源|
|docs/KNOWN_ISSUES.md|缺失学校信息及平台限制|
|docs/QA_REPORT.md|验证结果与角色交接总结|
|docs/CHANGELOG.md|完整变更路径和目的|
|tools/extract_pdf.py|从真实 PDF 的线框表提取文字和坐标证据|
|tools/write_analysis_report.py|生成供人检查的 Markdown 解析报告|
|tools/verify.ps1|一键复现真实文件到领域测试链|
|packages/schedule_core/pubspec.yaml|独立纯 Dart 包与测试依赖|
|packages/schedule_core/pubspec.lock|固定本轮已测试依赖|
|packages/schedule_core/analysis_options.yaml|静态分析规则|
|packages/schedule_core/lib/schedule_core.dart|公共导出入口|
|packages/schedule_core/lib/src/models.dart|正式领域与草稿 DTO 分离|
|packages/schedule_core/lib/src/parser.dart|周次、单元格、其他课程和校验逻辑|
|packages/schedule_core/lib/src/calendar.dart|教学周与按周/日期筛选|
|packages/schedule_core/bin/analyze_pdf.dart|只读内存投影与 JSON 输出|
|packages/schedule_core/test/parser_test.dart|解析规则和真实 PDF 回归|
|packages/schedule_core/test/calendar_test.dart|校正、跨年、停课、换教室测试|
|packages/schedule_core/test/real_pdf_golden_test.dart|目视独立录入 22 条基准及 140 天核对|
|packages/schedule_core/test/validation_test.dart|异常日期、越界和不可变性测试|
|packages/schedule_core/test/fixtures/huang_extracted.json|有源文件哈希和坐标的真实提取样本|
|output/analysis/parsed_schedule.json|生成的完整结构化解析证据|
|output/analysis/PDF_ANALYSIS.md|生成的可读课程/周次报告|
|output/analysis/analyze.log、tests.log|生成的最终验证日志|

临时产物：`tmp/pdfs/`（PDF 渲染图、重新提取样本）；本地工具：`.tools/`；Dart 构建缓存：包内 `.dart_tool/`。它们不属于应用业务代码。
以上为初始领域阶段记录；本阶段新增内容如下。

## 2026-10-06 Android 阶段
|路径|变更与目的|
|---|---|
|apps/campus_time/lib/main.dart、app.dart|平台初始化、私有 SQLite 路径、Riverpod 注入、5 页导航、主题、生命周期|
|apps/campus_time/lib/application/|应用状态、草稿修订、保存刷新、串行本地提醒|
|apps/campus_time/lib/features/|Today、真实时间周表、Tasks、Import Preview、Settings|
|apps/campus_time/lib/shared/ui.dart|统一界面组件、颜色与中文错误提示|
|apps/campus_time/android/|原生 Android 工程、通知权限/接收器、日历图标、desugaring|
|apps/campus_time/pubspec.yaml、pubspec.lock|固定应用依赖与本地领域/数据库/PDF 包|
|apps/campus_time/test/|真实数据库 Widget 链路、确认失效、任意分钟冲突保存、手机尺寸渲染|
|packages/schedule_pdf/|PDFium 坐标提取、真实 PDF 逐字段回归、字形诊断工具|
|packages/schedule_core/lib/src/timeline.dart、test/timeline_test.dart|作息映射、时间轴、当前/下一项、冲突边界；公共入口导出|
|packages/schedule_core/lib/src/parser.dart|兼容 PDFium adapter 标签，无语义字段变更|
|tools/android_env.ps1、build_android.ps1、verify_android.ps1|本机独立工具配置、分析/测试/打包、签名/对齐检查与 SHA256|
|docs/ANDROID_PLAN.md、ANDROID_GUIDE.md、ANDROID_QA.md|ACR-003、使用步骤、验收证据及设备验证边界|
|README、ARCHITECTURE、API_CONTRACTS、TASK_BOARD、DECISIONS、KNOWN_ISSUES、QA_REPORT|同步实际进度与限制|
|output/android/|生成的预览图、构建日志与安装包；不包含原始 PDF|

未修改原始 PDF 或 sources 同步文件。测试明确使用临时数据，没有替用户确认学校作息或导入正式课程。

## 2026-10-06 真机测试环境周期
新增 docs/DEVICE_TEST_ENVIRONMENT_REPORT.md、DEVICE_TEST_PROFILE.md、REAL_DEVICE_TEST_REPORT.md 与 output/device-qa/ 日志；更新任务板。重新检查 ADB/Flutter 工具链、USB 枚举、依赖、静态分析和 6 项 Flutter 测试。尚未检测到 Android 手机，未修改应用代码、安装 App、清除设备数据或改动系统驱动；真机用例按环境阻断记录。

## 2026-10-07 · 0.1.1+2 · IMP-001
- import_page.dart：预览顶部与末尾提供周起始确认入口，显示已保存状态，区分学期/课程待处理原因；SemesterEditor 仅保存其他学期字段。
- week_start_dialog.dart：七天显式选择与直接保存；取消不写入，保存草稿不导入课程。
- app_test.dart：新增真实 PDF 首屏入口、取消、保存、残留问题、排除后 22 条正式导入回归。
- visual_test.dart：增加未确认预览与星期选择弹窗截图；已目视检查，按钮可见。
- pubspec / settings：0.1.1+2；构建与验包脚本按 pubspec 生成版本文件名，保留旧 APK。
- 更新 README、使用说明、任务板、真机报告；新增 BUG_REPORT_IMPORT_WEEK_START.md。数据库 schema 与正式确认约束不变。


## 0.1.2+3 / 2026-10-08
- 新增可编辑的周起始和第一周日期，显式保存并重置手动周偏移。
- 周表列按周起始连续排列；新增学期级停课日期与原因，可添加/修改/删除。
- 日期停课统一用于周表数量、Today、课程冲突、缺作息列表和提醒；保留个人待办。
- schema v2无损新增class_days_off，保留v1基线并补充有数据升级/重新打开测试。
- 主机回归：core 44、storage 21、Flutter 8个页面回归及1个通知回归均已分别通过（74项，未重复运行未改动的PDF适配器测试）。实际设备安装与配置回归记录在本次报告。


## 0.1.3：日期调课与周表待办（2026-10-08）
- 周课表“调课”或设置“按日期调课”：输入当前学期的来源日期、覆盖日期，预览课程与来源周次/星期，再确认保存。
- 来源采用该日期原始课表；来源日不变，目标日以调入课程覆盖原课程（优先于停课），个人待办不变；可修改来源或撤销。
- 保存后周表目标日期提示、调课列表、Today及课程详情持续显示“由第 N 周星期 X（月/日）调入”。
- 周表仅展示未完成待办，按实际开始时间定位并在首行显示开始时刻，点开查看完整起止时间；短待办保留可点击高度，重叠项分列，完成后隐藏。
- 数据库v3增量升级保留既有数据；v1、v2升级、跨周来源、空来源、撤销、通知覆盖及待办定位已通过自动测试。


## 0.1.4（2026-10-09）
修复调课列表向下滑动无法关闭：列表采用与弹窗联动的滚动控制器，拖到最小高度关闭；增加顶部拖动条与固定“关闭”按钮。专用页面测试覆盖按钮关闭和列表下拉关闭。


## 0.1.5（2026-10-09）：固定周表星期与日期行
星期/日期行移出纵向滚动列表，固定在周导航和调课按钮下方；课程、待办与日期提示在下方滚动。静态检查及APK签名/对齐检查通过，已覆盖安装荣耀10。真机滚动到19:30晚间课程后星期行仍可见；切至第7周时日期更新为10/12—10/18，已返回本周。截图：device-qa/v015-fixed-weekdays-evening.png、v015-next-week-fixed-header.png。本次未修改课程或待办数据。


## 0.1.6（2026-10-09）：周课表相对周提示
右上角按实际日期与当前查看周的关系显示本周、上一周、下一周、前N周或后N周。点击仍回本周，长按提示“回到本周”；当前日期不在学期时禁用返回。采用实际周日期差，避免手动教学周偏移干扰。静态检查、APK签名/对齐通过，已覆盖安装荣耀10。真机验证顺序：本周→上一周→前2周→点击回本周→下一周→后2周→点击回本周，全部通过。证据device-qa/v016-relative-week-results.json及v016-state-*.xml。


## 0.1.7（2026-10-12）：单节调课
- 调课窗口增加“添加单节调课”，选择来源日期、课程、起止节次、目标日期及起始节次。
- 默认移走原课所选节次，可开启“保留原课”；目标仅覆盖相应节次，连续课未被选中的部分保留。
- 保存后展示来源周次、星期、节次及日期，支持修改和撤销。整天调课保留。
- 数据库v4增量升级；49项领域、23项存储、11项页面/通知测试通过，三个模块静态检查通过。
- 按用户要求跳过真机验证，手机未安装本版。


## 0.1.8（2026-10-13）：默认作息与下课刻度
学校上课时间为空时，编辑窗口预填用户提供校历的11节作息，点击保存后生效；已有配置保持原值，可用“填入默认11节作息”恢复预设后保存。周表时间轴按已保存配置显示“上/下”时刻及参考线，自动避开相邻整点刻度，保留固定星期行。


## 0.1.9（2026-10-13）：番茄钟
底部新增“番茄钟”第4个入口，原有今天/周表/待办/导入/设置保留。默认25分钟专注、5分钟短休息、15分钟长休息，每4次完成专注进入长休息；下一阶段手动开始。支持开始、暂停/继续、重置、切换阶段、自定义时长、今日完成次数与分钟统计。倒计时采用截止时间并保存本地，离页/重启后恢复；跳过不计完成，后台超时只结算已开始的一轮。

参考MIT项目 https://github.com/antigones/flutter_pomodoro_cat ，固定版本及适配范围见POMODORO_SOURCE.md；许可证随APK打包并注册到开源许可页。番茄钟提醒使用独立ID，课程提醒刷新后保留，暂停/重置取消。可选择开启Android精确提醒，未授权时使用非精确提醒并提示可能延迟。

验证：3个计时状态测试、2个通知测试、12个页面交互测试、1个新页面字体渲染测试通过（修正测试异步等待后补跑失败项）；静态检查通过。截图preview-pomodoro.png为桌面Flutter渲染，不是真机截图。按此前用户要求跳过本轮真机验证，未安装手机。

## 0.1.10：默认课表、多课表与任意课程颜色
内置经用户确认的默认课表，新增周课表切换和名称编辑。课程颜色支持 HSV、HEX 与快捷色板，保存同步到周课表和今天，自动调整课卡文字对比度。新导入与已有课表隔离保存；保留升级数据及未确认预览。详见 MULTI_TIMETABLE_COLORS.md。

## 0.1.11：WakeUp 参考默认配色
根据 WakeUp 3.22 开源版实际默认颜色数组更新 9 色模板与快捷色板，保留所有手动设置颜色。参考来源及色值见 WAKEUP_COLORS.md。

## 0.1.12：点击课程编辑、空白处新建与白色字体
课程卡片固定白字；新建和编辑支持名称、地点、星期、周次、节次与自定义钟点。数据库 v5 为自定义钟点新增独立表，旧数据无损升级。详见 COURSE_EDITOR.md。

## 0.1.13：无需撤销调课即可编辑时间，待办可不指定时间
点击已调入课程修改此次目标时间与地点并保留来源；原排课直接修改不再阻止。待办增加指定时间开关，不定时待办独立展示并支持完成。数据库 v6 无损升级，详见 UNTIMED_TRANSFER_EDIT.md。

## 0.1.14：默认修改原排课，保留调课目标时间
已调入课程编辑窗口新增范围选择，默认修改原排课，也可选择只改这次调课；两个范围分别保留未保存的输入。详见 TRANSFER_EDIT_SCOPE.md。
