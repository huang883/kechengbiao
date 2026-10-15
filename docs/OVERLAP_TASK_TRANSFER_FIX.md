# 0.2.1：重叠布局、待办下拉关闭与调课保留原课

## 修复内容
1. 周表原先按当天最大重叠数平分固定列宽，导致课程和待办挤成窄条，甚至未冲突的课程也变窄。现在卡片宽度固定为正常日列宽，重叠项并排排列，按实际需要拓宽该日期；必要时横向滑动查看其他日期。星期行随横向移动，与日列保持一致，纵向滚动时固定在顶部。空白点击新建课程也按拓宽后的日期边界定位。
2. 待办编辑从固定高度 ListView 改为 DraggableScrollableSheet，共享滚动控制器。列表在顶部时下拉缩小至最小高度后关闭；提供拖动把手和显式关闭按钮；拖动收起键盘。关闭不保存草稿，不修改已保存待办。
3. 单节调课不再裁切目标位置原有课程；整天调入不再替换目标当天原课表。两类调课都保留原课与调入课，重叠时并排显示，预览说明同时保留及冲突。单节来源默认移走、可选择保留的规则继续有效；整天复制来源仍保留。节假日仍停常规课程，显式调入课程照常显示。
4. 整天调入使用稳定独立ID，避免跨周复制同一条规则时与目标原课共用ID。今日时间轴、冲突检测和提醒均通过同一个课程筛选服务获得完整课程。

无需数据库迁移：原课一直保存在数据库中，旧版只在显示时裁切/替换。升级后已有调课的目标原课也会重新显示，不需撤销重建。若以前依赖覆盖来取消课程，现在需明确修改原排课。

## 验证
- Flutter analyze：通过。
- Flutter 全套：40项通过，新增覆盖课程与待办重叠后的卡片尺寸、实际时间位置、星期行固定、待办下拉关闭/未保存内容不写入/关闭按钮。
- schedule_core：49项通过，修正原先覆盖语义的断言；验证目标原课完整保留、冲突同时返回双方、空来源整天调入不清空目标、复制同规则仍保持独立ID。
- schedule_storage：25项通过，补充落盘重开后原课与调入课同时保留的验证。
- 430×932渲染检查确认课程与待办并排；不是手机实拍。
- Release APK构建成功；签名、16 KB zip对齐及版本元数据由 verify_android.ps1 检查。
- 本次未进行荣耀真机安装验证。

## 修改文件
- `apps/campus_time/lib/features/schedule/schedule_page.dart`
- `apps/campus_time/lib/features/tasks/tasks_page.dart`
- `apps/campus_time/lib/features/settings/lesson_transfer_editor.dart`
- `apps/campus_time/lib/features/settings/replacement_settings.dart`
- `packages/schedule_core/lib/src/calendar.dart`
- 对应UI、课程筛选和持久化测试，以及版本号、README和本说明。

版本：0.2.1+17。测试日志位于本机 `output/android/overlap-*.log`。
