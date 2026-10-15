# API_CONTRACTS v0.3

## 本轮实现（纯 Dart）
- WeekExpressionParser.parse(String) → List<int>；解析完整表达式，不接受尾部垃圾、倒序、零/负数或不支持语法；可去除显式 `(9-10节)` 前缀。
- PdfScheduleParser.parse(Map<String,dynamic> extractedPdf) → ParsedSchedule。输入是有版本的坐标提取 DTO，不冒充直接接收 PDF bytes；不写库。
- ImportValidation.validate(ParsedSchedule) → List<ValidationIssue>；severity 为 error/warning，附记录位置。
- ParsedSchedule.projectResolvedRecords() → CourseProjection；仅投影可确定排课，返回 skippedRecordIds；这是内存分析，不是正式导入。
- SemesterWeekCalculator(semester).getWeekForDate(DateTime)、getCurrentWeek(DateTime todayDate) → int?。
- getDateRangeForWeek(int week) → ({DateTime start,DateTime end})；非法 week 抛 RangeError。
- CourseFilterService.getCoursesForWeek(int week) → List<CourseSchedule>。
- getCoursesForDate(DateTime date) → List<CourseSchedule>；计算周次与星期后共同过滤。

## Phase 2 已实现的 Repository 合约
抽象定义：schedule_core/src/persistence.dart；实现：schedule_storage/lib/src/*_repository.dart。ScheduleDatabase 支持传入 QueryExecutor、memory()、file(File)；调用方负责关闭，正式路径由 Android 应用入口提供。

- ImportRepository.createDraft(ParsedSchedule) → Future<ImportDraft>，仅写草稿表；相同 source hash 和原文返回已有草稿，原文不同则 sourceMismatch。
- readDraft(id) → Future<ImportDraft?>；history(id) → Future<List<ImportDraft>>，按 revision 升序。
- editDraft(id, expectedRevision, semesterChanges={}, recordChanges={}, exclusions?, reason) → Future<ImportDraft>。仅允许既定字段修正，来源原文/ID 不可改；exclusions 为完整替换映射，键为记录 ID、值为非空原因，空映射恢复所有记录。
- weekExpression 修改后重新计算 activeWeeks；节次需用 startSection/endSection 单独修改，编辑周次字段不接受“节”前缀。无效周次可保存为 unclear 草稿，但不能确认导入。
- confirmImport(id, expectedRevision, confirmed) → Future<ImportResult>：只有 confirmed=true 且版本最新、必要数据已解决才原子写入。相同版本重复请求 alreadyCommitted=true；已提交草稿禁止再改。正式写入方法不单独公开，取代先前尚未实现的 saveConfirmedImport(transaction) 占位接口（ACR-002）。
- CourseRepository.listSemesters() / loadSemester(id) / watchSemester(id)：返回 SemesterSnapshot，含领域课程、规则、作息；watch 在正式事务提交后刷新。
- CourseRepository.readMetadata(semesterId)：返回各排课原文、教学班、学时、学分和导入版本。
- TaskRepository.create / update / read / list(from?, through?, completed?) / setCompleted / delete。日期筛选含首尾；按日期、起始时间、ID 排序；create 同 ID 报错，update 不存在报 notFound，delete 不存在幂等。允许事件重叠；冲突提示和通知由应用层负责。
- SettingsRepository.replaceClassTimes(semesterId, times)：原子完整替换，检查所属学期、节次唯一、作息顺序和不重叠；空列表清空配置。
- SettingsRepository.setManualWeekOffset / setCourseColor：保存设置并刷新 watchSemester；不改变导入历史快照。

RepositoryException.code：confirmationRequired、staleRevision、invalidImport、invalidDraft、sourceMismatch、alreadyCommitted、invalidEdit、notFound、invalidClassTimes、invalidRange、invalidColor。SQLite 执行异常向上传递，事务自动回滚；应用层负责展示可重试错误。

## Android / Timeline 已实现接口
- SchoolPdfAdapter.extract(Uint8List bytes) → ExtractedPdf v1 Map；PDFium adapter 保留 page/bbox/cell/rawText，未知版式抛中文 FormatException（ACR-003）。
- AppController.importBytes(bytes) → Future<void>：组合移动 PDF 提取、解析、草稿 Repository；页面通过 draft 读取结果，不自动提交。editDraft / confirmDraft 需来自用户操作；勾选确认绑定 revision。
- ClassTimeService.getClassTime(schedule, config) → ({start,end})?；任何所需节次缺失均返回 null，不猜钟点。
- TimelineService.forDate(date, snapshot?, tasks) → TimelineResult(items, unconfiguredSchedules)；同起始时间按结束时间、sourceType、ID 稳定排序。没有课表时可独立显示待办。
- ConflictDetectionService.findConflicts(candidate, items) → overlap[]；candidate.start < item.end && item.start < candidate.end，编辑排除自身。
- Week calibration：newOffset=oldOffset+desiredWeek-calculatedWeek，重新计算并更新所有依赖项。
- NotificationService.synchronize(snapshot, tasks, enabled, now)：串行取消并重建未来 7 天本地提醒，课程提前 10 分钟、待办按 reminderMinutes；排除完成/过时/缺钟点项。设置失败只报告提醒失败，不回滚已保存数据。

## Preview 确认约束
unknown semester dates/totalWeeks/weekStartDay、无法确定的周次/星期/节次须修复或明确排除相关记录后才可提交；原文永远可查。无钟点配置允许用户确认保存规则，但 Today/真实时间轴显示配置提示，不能生成时间或通知。
