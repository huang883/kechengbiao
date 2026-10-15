# QA_REPORT

## 最新状态：Android 阶段（2026-10-06）
新增验收见 [ANDROID_QA](ANDROID_QA.md)：核心 41、数据库 20、PDFium 2、Flutter 6 项，共 69 项通过。平台运行状态与 APK 校验在该记录单独维护。以下保留先前阶段证据。

## Phase 2 已完成（2026-10-05）
新增 Drift/SQLite 与 Repository，20 项数据库测试通过，连同下述 36 项核心测试共 56 项。两个包格式检查与静态分析通过。跨进程重开测试覆盖课程、周次、元数据、待办、作息和周校正。完整记录见 DATABASE_QA.md。

以下为首轮 Phase 0/1 的历史验收记录；其中数据库“TODO”已由上述 Phase 2 结果更新。Flutter 页面、手机提取与 APK 仍未实现。

## 结果与范围
本轮验证真实文件 → 桌面几何提取 → Dart ParsedSchedule → CourseSchedule / activeWeeks → 按周/日期筛选。没有正式数据库写入。

参考 PDF SHA-256：`e1273a871985d63e06043e0e8415454dbe1efe1d77a827705d1e9bcab347a7a3`。
1 页 A4 横向，20 个非空单元格；两格各有两条规则，所以 22 条规则，按名称/教师/教学班分为 14 门课程。底部其他课程另留 1 条，星期与节次 unclear。

## 自动验证
- 36 项 Dart 测试：21 项解析、6 项教学周/筛选、2 项独立基准、7 项异常校验。
- 独立人工基准逐条覆盖全部 22 条规则的课程名、星期、节次、教室和完整周数组；不是拿解析器输出生成期望结果。
- 独立日期核对覆盖 140 天，周日为显式测试输入；另测周一锚点和 manualWeekOffset=-1。均不视为学校实际约定。
- 原始 PDF 重新提取后与冻结证据样本逐字节一致。
- Dart format、dart analyze --fatal-infos 与 dart test 由 tools/verify.ps1 统一执行，日志保存在 output/analysis。

## 人工核对和修复
- 阅读完整 PDF 渲染页，核对学期页脚、列头、节次、两格双条目、末尾“其他课程”。
- 修复拆分误把教师后的教学班数字或长课程换行当新记录的问题；单元格边界和完整字段结构共同限制拆分。
- 学分缺失保留 unclear，原文末尾 64/32/48 等按总学时保存。
- Jobin Joy 跨行时保留字间空格，避免拆成两个 Course。
- QA 加入非法日期及倒置日期范围测试，先观察失败，再增加严格日历校验。
- 最初手工估算课程总数/周总条数有误；逐项重新核对整页并加入 22 条独立基准后更正，没有仅依据程序实际值修改验收标准。

## 角色审查
ORCHESTRATOR：七份事实源、合约与 ACR-001 审核通过。
PDF PARSER ENGINEER：解析和校验已完成，真实原文证据保留；移动提取未完成。
DOMAIN & DATABASE ENGINEER：本轮仅完成纯领域切片，数据库仍 TODO。
QA & INTEGRATION ENGINEER：领域与桌面数据链通过；不声称 flutter analyze/test、Widget/Integration tests、SQLite 重启持久化、通知、Android build 或 APK 已完成。

## 未关闭事项
周起始约定、节次钟点、底部英语未排课项仍需预览内用户配置/修复/显式排除。已测试模板以外不保证识别；多页、扫描件、不同布局应返回不支持，不能生成推测课程。
Python/pdfplumber 为验证工具，不能代表最终手机端 PDF 支持；详见 KNOWN_ISSUES。
