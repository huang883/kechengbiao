# PROJECT_SPEC v0.1 — 2026-10-05

## 产品与范围
Android 优先的 Flutter / Dart 学生课程与个人时间管理 App；保留 iOS 扩展能力。参考产品仅用于理解用户描述的交互方向，本轮未复制第三方代码。

核心路径：用户选择 PDF → 独立解析 → 可修改的 Import Preview → 用户明确确认 → Drift / SQLite 原子写入 → 按实际教学周筛选 → Schedule / Today / Tasks 统一时间轴。

技术栈固定：Flutter、Riverpod、Drift + SQLite、go_router、file_picker、flutter_local_notifications。领域层和解析规则为独立纯 Dart 包。

## 不可违反的业务规则
- Course 与 CourseSchedule 分离；换教室、换节次、不同周次必须保留独立规则。
- activeWeeks 为去重、升序的整数集合，严禁用首尾范围填平停课周。
- PDF 未给出的数据标为 unclear；缺失的钟点时间、周起始约定不能猜测。
- ClassTimeConfig 独立维护；TaskEvent 支持任意分钟，与节次无关。
- 时间轴按真实 startDateTime 排序；冲突警告不禁止保存。
- 不自动写入正式库；未完成确认不得调用提交接口。
- 日期为学校本地日历日期；当前学校时区使用 Asia/Shanghai，日期运算不依赖电脑时区。
- 每次切换周次都重新筛选课程；周范围外不能套用课程。

## 页面验收（后续阶段）
- Today：日期、教学周、当前/下一节、剩余课程、待办、统一 Timeline。
- Schedule：七天、日期范围、真实时间坐标、滑动/按钮切周、课程详情和颜色。
- Tasks：增删改、完成、今天/本周/全部/已完成；任意分钟、冲突提示。
- Import：文件选择、解析、逐条预览/纠错/排除、明确确认。
- Settings：学期、当前周校正、节次钟点、提醒、课程颜色。

## 阶段边界
本次启动交付 Phase 0 + Phase 1，以及为验证数据链所需的 Phase 2 纯领域最小切片。不会将其称为完整 MVP，也不提前开发页面或数据库。

续轮授权“继续数据库阶段”：已完成 Phase 2 Drift/SQLite、Repository、草稿历史、确认事务、待办与设置的持久化基础；范围仍不包含 Flutter 页面、移动 PDF adapter 或 APK。数据库阶段验证只使用临时库和明确标注的配置测试值，未代替用户确认真实学校周序。

MVP 完成还要求真实 PDF 在 Android 内解析、预览确认后落库、重启保留数据、全部核心业务测试、页面联调与 Android 构建。账号、同步、社交、支付、服务端等排除。

## P0 测试门槛
周次表达式、教学周/校正/跨年边界、周与日期筛选、第11周停课、不同教室、显式节次覆盖、未知字段拦截。后续加入任意分钟事件、重叠、排序、预览提交事务、SQLite 重启持久化。
