import 'package:flutter/services.dart';

/// Android owns the session; Flutter never deducts a quota or infers completion.
class FocusBridge {
  const FocusBridge();
  static const channel = MethodChannel('campus_time/focus');
  Future<dynamic> call(String method, [Map<String, dynamic>? arguments]) async {
    try {
      return await channel.invokeMethod<dynamic>(method, arguments);
    } on PlatformException catch (e) {
      throw StateError(e.message ?? '专注操作失败，请重试');
    }
  }

  Future<Map<String, dynamic>> status() async =>
      Map<String, dynamic>.from(await call('status') as Map);
}
