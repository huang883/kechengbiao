# TASK_BOARD

|任务|状态|依赖/说明|
|---|---|---|
|Phase 0 真实 PDF 阅读、需求与架构合约|DONE|已目视检查完整页面|
|Phase 1 桌面几何提取与来源证据|DONE|真实 PDF 重新提取与已审核样本一致|
|Phase 1 WeekExpressionParser / ParsedSchedule / Validation|DONE|14 门课程、22 条规则、1 条未排课记录|
|Phase 2 最小领域切片：周计算/筛选|DONE|周起始为显式输入；校正与边界通过|
|真实数据链回归（桌面）|DONE|36 项 Dart 测试、22 条独立人工基准、140 天筛选|
|Phase 2 Drift/Repository|DONE|20 项数据库测试；确认门槛、版本、回滚、跨进程重开通过|
|Phase 2 待办/设置持久化基础|DONE|任意分钟 CRUD、完成、提醒设置、作息原子替换、周校正/颜色|
|移动 PDF extraction adapter|IMPLEMENTED|PDFium 真实样本与独立桌面结果逐字段一致；手机运行待验收|
|Phase 3 Import Preview → SQLite → 本周课程|DONE|页面修正、排除、确认、版本变化取消勾选，Widget/数据库链通过|
|Phase 4 Schedule|DONE|7 列、真实分钟定位、重叠并排、切换周重新筛选；缺钟点单列提示|
|Phase 5 Tasks|DONE|任意分钟 CRUD、日期筛选、完成、冲突可保存|
|Phase 6 Timeline/Conflict|DONE|半开区间、稳定排序、编辑排除自身、未知作息不猜测|
|Phase 7 Today|DONE|当前/下一课程、剩余课程、待办与统一时间轴|
|Phase 8 通知/设置|IMPLEMENTED|本地提醒未来 7 天；权限/重启/省电行为待 Android 设备验收|
|Phase 9 QA/APK|DONE（构建）|69 项测试与静态检查通过；通用 APK、签名/内容检查通过；真机验收待设备|

当前角色：ORCHESTRATOR，Android 生成与交付已完成。实现与设备验收分开记录；本对话按逻辑角色顺序执行，无后台多代理。

## 真机测试阶段（2026-10-06）
当前角色：Android Real Device QA / Flutter Integration Test / Bug Fix Coordinator。环境检查已完成，pub get、analyze、6 项 Flutter 测试通过。ADB 重启后仍无设备，Windows 有未确认归属的 USB 描述符错误 43；等待用户完成手机端连接/调试授权。12 组真机流程 BLOCKED，未开始安装，不把桌面通过算作真机通过。见 DEVICE_TEST_ENVIRONMENT_REPORT、DEVICE_TEST_PROFILE、REAL_DEVICE_TEST_REPORT。

## 0.1.1 导入修复（2026-10-07）
IMP-001：顶部周起始日确认入口与精确校验提示已实现，真实样本完整导入回归通过，应用共 7 项测试通过。无 schema/API 破坏性改动，保持用户显式选择及最终确认。待新版 APK 验证与真机复验，不标 CLOSED。

0.1.1 APK 已生成并通过签名、包名、versionCode=2 与文件对齐检查；签名与 0.1.0 相同。代码/构建交付完成，IMP-001 真机状态仍待复验。
