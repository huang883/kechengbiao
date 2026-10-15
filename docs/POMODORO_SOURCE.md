# 番茄钟开源依据

参考项目：https://github.com/antigones/flutter_pomodoro_cat
固定提交：718df16c5027f0426ff743f76994b785306df1f6
许可证：MIT，Copyright (c) 2020 antigones。
参考文件：lib/pomodoro_widget.dart、pomodoro_page.dart、short_pause_page.dart、long_pause_page.dart。
移植范围：三阶段页面组织、开始/暂停/重置语义和分钟秒格式化方法。改造为现有Riverpod/ChangeNotifier、Material 3、SharedPreferences、flutter_local_notifications，计时改为持久化截止时间；不引入旧Dart 2依赖、图片、音乐或字体。
MIT全文随APK打包，设置的开源许可页可查看。番茄钟离线运行，不连接上游服务。
