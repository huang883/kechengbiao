# ARCHITECTURE v0.3

Presentation (Flutter + Riverpod + go_router)
→ Application services
→ Repository contracts
→ Drift/SQLite or PDF extraction adapter

纯 Dart `packages/schedule_core` 提供模型、周次解析、校验、排课投影、教学周、筛选及 Repository 抽象合约，禁止依赖 Widget、平台、数据库。`packages/schedule_storage` 实现 Drift/SQLite、导入事务及各 Repository；数据库文件路径由应用层提供，生成的 Drift 行类型不从包入口导出。`tools/extract_pdf.py` 是桌面验证用几何提取适配器；它从真实 PDF 的线框单元格提取文字和坐标，不负责课程语义。手机端使用独立 schedule_pdf / PDFium 适配器，真实样本与桌面结果逐字段回归；不在手机打包 Python。

## 依赖顺序
PDF 几何提取 → ParsedSchedule → ImportValidation → 明确解决/排除异常 → Course/CourseSchedule → SemesterWeekCalculator → CourseFilterService。

之后 Repository + Drift + Import commit → 第一个持久化 milestone → Schedule → Tasks → Timeline/Conflict → Today → Settings/Notifications → QA/APK。

数据库实现和移动 PDF adapter 在合约冻结后可标为 PARALLELIZABLE；按用户要求本对话仍逐项执行。UI 必须等待筛选/时间配置接口和测试通过。

## 导入安全边界
Draft 可持有 unclear；正式领域对象必须已校验。预览可修正字段或显式排除未排课条目，原文与修改历史保留。正式提交必须携带最新草稿 revision 与 confirmed=true；数据库事务去重键为 source hash + revision，失败全回滚。解析服务不拥有 Repository 写权限。

Phase 2 已实现：每个 source hash 唯一草稿流；确认前允许修订、恢复被排除项，保留所有版本；确认后冻结，重试返回原提交结果。不同源文件使用独立实体命名空间，暂不自动合并同名学期/课程。底层 ScheduleDatabase 只由组装层与测试持有；页面依赖 Repository 接口。详见 DATABASE_SCHEMA 的 ACR-002。

## 时间语义
startDate/endDate 是 PDF 中的有效学期边界。first week anchor 为 startDate 当日或之前最近一个 weekStartDay（ISO 1=周一…7=周日）。week=floor((date-anchor)/7)+1+manualWeekOffset。校正偏移参与正反转换；日期不在学期或周号不在 1..totalWeeks 时返回 null。不把周一约定伪装为 PDF 事实。

getDateRangeForWeek 返回整周显示范围，可能跨出学期；getCoursesForDate 始终应用学期有效边界。时钟以注入 todayDate 提供学校本地日期；纯领域计算使用 UTC 日期容器避免夏令时影响。

## Android 组装
`apps/campus_time/lib/main.dart` 初始化 PDFium、应用私有存储路径、SQLite、偏好及通知，向 Riverpod 注入 AppController。五个页面只通过应用控制器调用 Repository；纯领域不依赖 Flutter。控制器负责刷新快照、保存后更新提醒，以及恢复草稿和所选学期。

`packages/schedule_pdf` 使用 PDFium 原始字符顺序与坐标重建已验证单页模板，输出 ExtractedPdf v1；不会调用 Python 或网络上传 PDF。桌面独立提取仍保留作回归基准（ACR-003）。

本地通知使用 Asia/Shanghai，把学校墙上时间转换为真实计划时刻。取消/重建批次串行执行；每次打开或修改日程更新未来 7 天，课程提前 10 分钟，待办尊重单项设置。使用系统允许的非精确闹钟，不宣称秒级或长期自动续排。缺失作息不生成课程提醒。通知失败不撤销已成功保存的数据。
