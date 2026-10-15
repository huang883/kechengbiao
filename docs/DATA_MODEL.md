# DATA_MODEL v0.1

## 正式实体合约
- Semester：id, name, startDate, endDate, totalWeeks, weekStartDay (ISO 1..7), manualWeekOffset。
- Course：id, name, teacher, color, remark。
- CourseSchedule：id, courseId, semesterId, weekday (ISO 1..7), startSection, endSection, classroom, activeWeeks, remark。
- ClassTimeConfig：semesterId, section, startTime (HH:mm), endTime (HH:mm)。同学期节次唯一、起止合法；缺失不得渲染假钟点。
- TaskEvent：id, title, date, startTime, endTime, description, completed, reminderMinutes, repeatRule。首版同日事件要求 endTime > startTime；repeatRule=null，复杂重复在单独规格后实现。
- TimelineItem：id, sourceType(course/task), sourceId, startDateTime, endDateTime, title, completed；课程由规则+节次配置投影，任务直接使用真实时间。区间 [start,end)，相接不冲突。

## 导入 DTO
ParsedSchedule：semester (字段可 unclear), records, issues, sourceSha256。
ParsedCourseRecord：课程字段、星期、节次、周数组、教学班 teachingClass、备注、totalHours、credits、source(page/cell/bbox/rawText)。原始空备注保留空串；明确“无”保留字面值，缺失用 unclear。
每条源记录独立保存。其他课程单独保留；没有星期/节次不得自动绑定常规英语排课。

### ARCHITECTURE_CHANGE_REQUEST ACR-001 — APPROVED by ORCHESTRATOR
问题：既定正式模型没有教学班、原文出处和总学时字段，解析结果不能丢失这些信息。
原因：真实 PDF 页脚标明字段顺序，教学班及备注属于需求。
建议修改：添加独立 ImportRecordMetadata (scheduleId, teachingClass, totalHours, credits, source, draftRevision)；Course/CourseSchedule 原字段不变。
影响模块：导入 DTO、后续数据库审计表；是否 Breaking Change：否（初始合约新增）。
迁移方案：初始 SQLite schema 同时建元数据表；后续升级须版本迁移。当前纯领域切片在 ParsedCourseRecord 保留这些字段。

## 身份与约束
初版同一导入内 Course 按规范化课程名+教师+教学班分组；不同教师或教学班不擅自合并。每条排课获得独立 ID。重新导入的实体匹配由用户预览决定，禁止仅凭名字覆盖旧数据。
activeWeeks 非空、升序、唯一且全部位于 1..totalWeeks；节次正整数且 start<=end；星期 1..7；外键完整。
unknown 使用 JSON 字面字符串 `unclear`；在正式模型中通过校验拒绝不完整必要数据，不向日期/整数中强塞字符串。

## Phase 2 持久化落地
Semester、Course、CourseSchedule、ClassTimeConfig、TaskEvent 与 Repository 抽象类型已实现于 schedule_core。Android 阶段已实现 TimelineItem 与 TimelineResult，字段与既有契约一致，无 schema 改动。
新增 ImportDraft、ImportResult、SemesterSnapshot、ImportRecordMetadata、RepositoryException，均为不依赖 Drift 的领域边界对象；ACR-002 的完整批准记录见 DATABASE_SCHEMA。
ClassTimeConfig 包含 semesterId；TaskEvent 的 date 为学校日历日期，存储为 YYYY-MM-DD，时间字段为 HH:mm；repeatRule 非 null 暂不接受，reminderMinutes 由应用层本地通知调度读取。
activeWeeks 在 SQLite 中按 schedule_weeks 规范化存储，读取时恢复升序数组。教学班、原文坐标、总学时与学分写入 import_record_metadata；数值未知用 SQL NULL，原始 JSON 保持 unclear。
正式实体 ID 为 sourceSha256 命名空间，防止解析时的 course_1 等局部 ID 跨文件冲突。正式学期 ID 为 semester_<sourceSha256>；同源重复导入不会复制数据，不自动合并不同 PDF 的学期。
