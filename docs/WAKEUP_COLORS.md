# WakeUp 默认课程配色参考（0.1.11）

参考可核实的 WakeUp 3.22 Kotlin 开源版，不声称是当前商店最新版的配色。

来源仓库：https://github.com/tKM9WsmQUaUgNttn3DGUsHkxG8/WakeupSchedule_Kotlin

- app/src/main/res/values/colors.xml：customizedColors 数组含以下 9 色。
- app/src/main/java/com/suda/yzune/wakeupschedule/schedule/ScheduleFragment.kt：275—276 行，对空课程颜色使用 getCustomizedColor(c.id % 9)，证明该数组也用于默认课程颜色，并非只用于选色器。

|颜色|HEX|
|---|---|
|红|#FF1744|
|粉|#FA6278|
|蓝|#2979FF|
|薄荷绿|#1DE9B6|
|黄|#FFEA00|
|橙|#FF9100|
|橙红|#FF3D00|
|浅蓝|#2196F3|
|琉璃蓝|#005CAF|

本项目仅参考上述色值，不复制上游代码。保留原有按课程名称稳定分配颜色的方式，因此同名课程在不同课表中默认配色一致。默认课表、已有未自定义颜色的课程、新导入课程统一生效；不会重写用户手动保存的颜色。选色窗口快捷色板同步更新，完整取色器和 HEX 输入保留。周课表继续以 88% 不透明度显示并自动选择黑/白文字；今天的课程色条与设置色标使用同一默认颜色解析方法。
