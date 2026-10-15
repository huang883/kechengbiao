import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/app_controller.dart';
import 'features/today/today_page.dart';
import 'features/schedule/schedule_page.dart';
import 'features/tasks/tasks_page.dart';
import 'features/import/import_page.dart';
import 'features/settings/settings_page.dart';
import 'features/pomodoro/pomodoro_page.dart';
import 'shared/ui.dart';

class CampusApp extends ConsumerStatefulWidget {
  final bool liveClock;
  const CampusApp({super.key, this.liveClock = true});
  @override
  ConsumerState<CampusApp> createState() => _CampusAppState();
}

class _CampusAppState extends ConsumerState<CampusApp>
    with WidgetsBindingObserver {
  Timer? timer;
  static const paths = [
    '/today',
    '/schedule',
    '/tasks',
    '/pomodoro',
    '/import',
    '/settings',
  ];
  static const labels = ['今天', '周课表', '待办', '番茄钟', '导入', '设置'];
  late final router = GoRouter(
    initialLocation: '/today',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = paths.indexOf(state.uri.path);
          return Scaffold(
            appBar: AppBar(
              title: Text(
                index == 0 ? '课间' : labels[index],
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            body: SafeArea(child: child),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => context.go(paths[i]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.wb_sunny_outlined),
                  label: '今天',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_view_week_outlined),
                  label: '周课表',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_circle_outline),
                  label: '待办',
                ),
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  label: '番茄钟',
                ),
                NavigationDestination(
                  icon: Icon(Icons.file_upload_outlined),
                  label: '导入',
                ),
                NavigationDestination(icon: Icon(Icons.tune), label: '设置'),
              ],
            ),
          );
        },
        routes: [
          GoRoute(path: paths[0], builder: (_, _) => const TodayPage()),
          GoRoute(path: paths[1], builder: (_, _) => const SchedulePage()),
          GoRoute(path: paths[2], builder: (_, _) => const TasksPage()),
          GoRoute(path: paths[3], builder: (_, _) => const PomodoroPage()),
          GoRoute(path: paths[4], builder: (_, _) => const ImportPage()),
          GoRoute(path: paths[5], builder: (_, _) => const SettingsPage()),
        ],
      ),
    ],
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.liveClock) {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        ref.read(appProvider).pomodoro.tick();
        if (DateTime.now().second == 0) ref.read(appProvider).tick();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(appProvider).pomodoro.tick();
      ref.read(appProvider).tick();
      unawaited(ref.read(appProvider).syncReminders());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: '课间',
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: mint, surface: paper),
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFD9EDE2),
      ),
    ),
  );
}
