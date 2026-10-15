# DATABASE_QA — Phase 2

结果：DONE。统一入口 `tools/verify.ps1` 从原始 PDF 重提取开始完成全部检查，退出码 0。

## 验证结果
|检查|结果|
|---|---|
|原有核心测试|36 项通过|
|新增数据库测试|20 项通过（导入 13、任务/设置 5、文件持久化/版本 2）|
|两个 Dart 包静态分析|零问题，启用 fatal-infos|
|代码格式检查|通过|
|Drift 代码生成|通过|
|schema v1 重新导出与冻结基准比对|一致|
|独立读取程序构建与执行|通过|
|SQLite integrity_check / foreign_key_check|通过|

## 数据链
真实 PDF 冻结证据 → ParsedSchedule → 仅存草稿 → 修订学校周约定/明确排除未排课项（测试输入）→ confirmed=true + 当前 revision → SQLite 事务 → SemesterSnapshot → 按周/日期筛选。

22 条规则逐条验证 activeWeeks、星期、节次、教室、备注读回一致。14 门课程、22 条规则、22 条来源元数据均保留。第 11 周没有课，第 12 周 14 条规则，数字逻辑课程第 14 周换教室仍成立。

## 事务/确认边界
- 创建/修订预览不写正式课程表；confirmed=false、未解决 unknown、旧 revision、非法日期和空导入均被拒绝。
- 同实例并发修订只有一个版本成功；并发确认只有一个正式提交，另一次返回幂等结果。
- 在正式事务最后的提交标记插入处注入 SQLite 失败，学期、课程、规则、周次、元数据与提交表全部回滚，草稿保留，去除故障后重试成功。
- 修正教室/周次不改变原始证据；排除理由和历次修订保留。不存在的记录/字段与无理由排除被拒绝。
- 同源不同原文无法替换证据；两份不同来源使用独立 ID，不互相覆盖。
- SQLite 拒绝不存在的外键、重复周、越界周、缩短学期导致既有周次越界、非法日期/钟点/完成值。
- watchSemester 在提交后读到完整 22 条规则快照。

## 任务与设置
10:17—11:35、12:35—13:18、19:20—21:10 可保存；CRUD、完成、含首尾日期筛选、提醒设置均验证。重叠事件允许保存，冲突提示属于未来应用层。重复 ID 不覆盖；类似 SQL 的标题作为普通文本保存。
作息按学期独立；不允许重复节次、倒序/重叠或其他学期配置。替换中途失败会恢复旧配置。周偏移及课程颜色能保存，并由读模型正确反映。

## 跨进程重开
测试先建立临时文件库、完成导入及设置/待办写入，关闭写连接；启动预先构建的独立进程读取同一文件。读取结果包含 14 门课程、22 条规则、22 条元数据、2 版导入历史、原始 unclear、排除理由、任意分钟时间/完成/提醒、作息/颜色/周偏移。再次连接后重复确认仍幂等。
测试结束时验证临时目录确实位于测试临时根目录下后清理，未创建用户正式数据库。

## 版本与限制
当前初始 schemaVersion=1。未知 v99 测试库被拒绝打开，其 sentinel 数据仍保留；不是删除重建。尚无生产旧版 schema，因此不声称完成 v1→v2 数据迁移。
已验证平台：Windows / Dart 3.13.5 / Drift 2.35.1 / sqlite3 3.7.0。Android/iOS 应用路径配置、平台联调、通知、Import UI、Flutter analyze/test 和 APK 均未执行。

## 角色交接
DOMAIN & DATABASE ENGINEER：实现与持久化测试已完成；公共合约记录在 API_CONTRACTS v0.2。
QA & INTEGRATION ENGINEER：确认门槛、回滚、来源保留、跨进程重开与原有领域回归通过。
ORCHESTRATOR：ACR-002 已批准；Phase 2 标 DONE，Phase 3 仍 TODO。下一角色为 PDF PARSER ENGINEER，验证移动提取适配器。

日志：output/analysis/analyze.log、tests.log；output/database/analyze.log、tests.log。复现：根目录执行 tools/verify.ps1，或仅执行 tools/verify_storage.ps1。
