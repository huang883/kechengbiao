# Android App 实施范围

用户授权：生成 Android App。以既有产品规格为验收基础，按模块推进，不加入账号、云服务等范围外功能。

1. Flutter / Android 工具链与手机端 PDF 提取；真实 PDF 回归。
2. ClassTimeService / Timeline / Conflict：先测试后接 UI。
3. 应用状态、路由、文件与数据库位置；Import Preview 修正/排除/明确确认。
4. Today、真实时间周表、任意分钟 Tasks、Settings、提醒。
5. Widget/业务回归、Android 构建；有设备时执行运行检查。没有设备则明确区分构建成功与真机验收。

## ACR-003 — APPROVED by ORCHESTRATOR
问题：现有解析入口仅接受桌面 pdfplumber adapter 标签，手机上不能依赖 Python。
原因：Flutter 需要可在 Android 运行的 PDF 字形/坐标提取。
建议：新增 schedule_pdf 包，通过 PDFium 的字符坐标重建已验证模板的单元格，输出相同 ExtractedPdf v1，但使用独立 adapter 标识；解析器只增加受支持标识，不改变既有字段。严格检查页面尺寸、星期/节次标题和学期页脚，未知布局明确拒绝。
影响：PDF 适配器、解析标签、回归测试；Breaking Change：否。迁移：无需数据库迁移。原有桌面提取作为独立校验基准。

TimelineItem / ClassTimeService / ConflictDetectionService 沿用已有 API_CONTRACTS，无改动实体语义。通知使用学校时区 Asia/Shanghai，任意分钟任务和课程统一排序。缺失作息的课程单独提示待配置，不进入带虚构钟点的时间轴。
