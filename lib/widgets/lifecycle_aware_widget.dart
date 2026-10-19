import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_lifecycle.dart';

/// LifecycleAwareWidget
/// A mixin that can be used with StatefulWidget to handle app lifecycle events
/// Ensures proper cleanup and resource management
mixin LifecycleAwareMixin<T extends StatefulWidget> on State<T> {
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isInitialized = true;
    _onWidgetInit();
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _onWidgetDispose();
      super.dispose();
    }
  }

  /// Called when the widget is initialized
  /// Override this to initialize controllers, timers, etc.
  void _onWidgetInit() {
    // Override in implementing class
  }

  /// Called when the widget is disposed
  /// Override this to cleanup controllers, timers, streams, etc.
  void _onWidgetDispose() {
    // Override in implementing class
  }

  /// Check if widget is still mounted and not disposed
  bool get isWidgetActive => _isInitialized && !_isDisposed && mounted;

  /// Safe way to execute code only if widget is active
  void safeExecute(VoidCallback callback) {
    if (isWidgetActive) {
      callback();
    }
  }

  /// Get current app lifecycle state
  AppLifecycleState? get currentLifecycleState => 
      AppLifecycleManager.instance.currentState.value;

  /// Check if app is in foreground
  bool get isAppInForeground => AppLifecycleManager.instance.isForeground;

  /// Check if app is in background
  bool get isAppInBackground => AppLifecycleManager.instance.isBackground;
}

/// LifecycleAwareWidget
/// A StatelessWidget that automatically handles lifecycle events
/// Use this for screens that need lifecycle awareness
abstract class LifecycleAwareWidget extends StatelessWidget {
  const LifecycleAwareWidget({Key? key}) : super(key: key);

  /// Build method with lifecycle context
  Widget buildWithLifecycle(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppLifecycleManager>(
      init: AppLifecycleManager.instance,
      builder: (lifecycleManager) {
        return buildWithLifecycle(context);
      },
    );
  }
}

/// LifecycleAwareStatefulWidget
/// A StatefulWidget that automatically handles lifecycle events
/// Use this for complex screens that need lifecycle awareness
abstract class LifecycleAwareStatefulWidget extends StatefulWidget {
  const LifecycleAwareStatefulWidget({Key? key}) : super(key: key);

  @override
  State<LifecycleAwareStatefulWidget> createState() => _LifecycleAwareStatefulWidgetState();
}

class _LifecycleAwareStatefulWidgetState extends State<LifecycleAwareStatefulWidget> 
    with LifecycleAwareMixin {
  
  @override
  void _onWidgetInit() {
    onWidgetInit();
  }

  @override
  void _onWidgetDispose() {
    onWidgetDispose();
  }

  /// Called when the widget is initialized
  /// Override this to initialize controllers, timers, etc.
  void onWidgetInit() {
    // Default empty implementation - override in subclass
  }

  /// Called when the widget is disposed
  /// Override this to cleanup controllers, timers, streams, etc.
  void onWidgetDispose() {
    // Default empty implementation - override in subclass
  }

  @override
  Widget build(BuildContext context) {
    return buildWithLifecycle(context);
  }

  /// Build method with lifecycle context
  Widget buildWithLifecycle(BuildContext context) {
    // Default implementation returns empty container
    // Override in subclass to provide actual UI
    return const SizedBox.shrink();
  }
}
