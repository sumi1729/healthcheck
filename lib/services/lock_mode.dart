import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 端末がロック中か（ロック画面の上に表示されているか）を管理する。
///
/// ロック中は登録画面のみを表示し、実績画面は見せない。
/// 起動時および各 resume（タイルからの再起動やロック解除）で再判定する。
class LockMode {
  LockMode._();
  static final LockMode instance = LockMode._();

  static const _channel = MethodChannel('com.example.practice2.healthcheck/lock');

  /// ロック中なら true。UIはこれを購読して画面を切り替える。
  final ValueNotifier<bool> isLockMode = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(_LifecycleObserver(refresh));
    await refresh();
  }

  Future<void> refresh() async {
    final locked = await _channel.invokeMethod<bool>('isDeviceLocked');
    isLockMode.value = locked ?? false;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  final Future<void> Function() onResume;
  _LifecycleObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}