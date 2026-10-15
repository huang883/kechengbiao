# DATABASE_SCHEMA v1 — Phase 2

状态：已实现并通过 Phase 2 验证。独立 `schedule_storage` 包依赖纯 Dart `schedule_core`，不反向引入 Drift 到领域层。SQLite 文件位置由调用方传入；测试只用临时目录，不建立用户正式课表库。

## ARCHITECTURE_CHANGE_REQUEST ACR-002
问题：原合约没有规定草稿持久化结构、跨 PDF 的实体 ID、重复确认与重新导入的区别。
原因：解析器的 course_1 / semester_1 只在一次解析内唯一；并发确认、旧预览确认与同源多草稿可能写入错误版本或覆盖资料。
建议修改：每个 sourceSha256 对应唯一草稿流，revision 从 1 递增；保留每版完整原文/修订快照和排除理由。提交记录唯一键仍是 sourceSha256 + revision。正式实体 ID 加 sourceSha256 命名空间。确认后草稿冻结，同一版本重试幂等；同源不同内容、旧版本提交或已提交后的修订显式报错，待后续合并规格。
影响模块：持久化 DTO、Repository、未来 ImportService。是否 Breaking Change：否（此前只有待实现合约）；既有解析/周计算 API 不变。
迁移方案：初始 schemaVersion=1，首次创建；未存在已发布旧库，未来升级必须显式迁移和数据保留测试，禁止破坏性重建。
ORCHESTRATOR 决定：APPROVED。Repository 接收 ParsedSchedule，PDF bytes → createPreview 仍属于后续应用服务。

## 表
|表|目的与约束|
|---|---|
|semesters|学期；日期文本 YYYY-MM-DD，总周数、周起始和校正|
|courses|课程本身；教师、颜色、备注|
|course_schedules|排课；外键到课程/学期，星期、节次、教室与备注|
|schedule_weeks|每条 activeWeek 一行，联合主键去重；触发器限制在对应学期范围内|
|class_times|学期+节次联合主键；HH:mm；起止合法|
|task_events|独立日期和任意分钟、完成、提醒、描述；首版 repeatRule 只接受 null|
|import_drafts|source hash 主键、current revision、原始解析 JSON|
|import_revisions|source hash+revision 主键；修订后 JSON、排除理由、修改说明|
|import_commits|source hash 主键（首版一源一次），revision、semesterId；提交幂等标记|
|import_record_metadata|scheduleId 外键；教学班、总学时/学分（未知 null）、source JSON、源记录 ID、草稿版本|

外键在每次开库时开启。周次规范化存储，读取时排序恢复 activeWeeks。原文和所有 revision 保存在导入表，包括用户显式排除的未排课记录；未知字段在 JSON 保持 unclear，数值元数据在 SQL 用 null。

## 事务与读写边界
createDraft 只写导入表；editDraft 用 expectedRevision 乐观锁。confirmImport 先检查 confirmed=true，再在同一事务内读取最新草稿、校验、写实体/周次/元数据/提交标记。任一语句失败全回滚；不对错误做吞掉或部分成功处理。全部用户数据通过参数绑定进入 SQL。
CourseRepository 输出领域对象，不输出 Drift 行类型。watchSemester 在提交后重新读取一致快照；事务中不暴露部分排课。TaskRepository 提供 CRUD 与完成状态保存；设置 Repository 原子替换作息、保存周校正/课程颜色。

schema.drift 为结构来源，database.g.dart 为 Drift 生成代码（禁止手工修改）。已冻结 schemas/drift_schema_v1.json；验证脚本重新导出并比对，防止未提升版本就改变 schema。当前没有旧版生产库，未声称执行过 v1→v2 迁移；未知版本拒绝打开并保留原文件。

## 首版范围
不实现 PDF 移动适配器、Import UI、合并旧学期、重复事件展开、通知、跨设备并发或云同步。相同数据库实例的并发调用须正确处理；跨独立数据库连接竞争允许 SQLite 返回 busy 错误并安全重试，不能部分写入。

参考官方文档：[设置](https://drift.simonbinder.eu/setup/)、[事务](https://drift.simonbinder.eu/dart_api/transactions/)、[迁移](https://drift.simonbinder.eu/migrations/)。
