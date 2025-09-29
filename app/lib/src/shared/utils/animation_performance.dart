import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// 动画性能优化工具类
class AnimationPerformanceUtils {
  static const int _targetFrameRate = 60;

  /// 检查设备性能是否支持复杂动画
  static bool shouldUseHighQualityAnimations() {
    final state = SchedulerBinding.instance.lifecycleState;
    if (state == null) {
      return true;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        return true;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        return false;
    }
  }

  /// 获取适合设备性能的动画时长倍数
  static double getAnimationDurationMultiplier() {
    // 基于设备性能调整动画时长
    // 这里可以根据具体需求实现更复杂的逻辑
    return shouldUseHighQualityAnimations() ? 1.0 : 1.5;
  }

  /// 动画性能监控器
  static AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    double? speedMultiplier,
  }) {
    final multiplier = speedMultiplier ?? getAnimationDurationMultiplier();
    final targetMilliseconds = (duration.inMilliseconds * multiplier).round();
    final minMilliseconds = (1000 / _targetFrameRate).round();
    final clampedMilliseconds = targetMilliseconds
        .clamp(minMilliseconds, duration.inMilliseconds * 2)
        .toInt();
    final adjustedDuration = Duration(milliseconds: clampedMilliseconds);

    return AnimationController(
      duration: adjustedDuration,
      vsync: vsync,
    );
  }

  /// 创建性能友好的曲线动画
  static Animation<double> createOptimizedCurvedAnimation({
    required AnimationController parent,
    Curve curve = Curves.easeInOut,
  }) {
    // 在低性能设备上使用更简单的曲线
    final optimizedCurve = shouldUseHighQualityAnimations() 
        ? curve 
        : Curves.linear;

    return CurvedAnimation(
      parent: parent,
      curve: optimizedCurve,
    );
  }
}

/// 性能友好的自定义绘制器基类
abstract class OptimizedCustomPainter extends CustomPainter {
  final bool enableOptimizations;

  const OptimizedCustomPainter({
    this.enableOptimizations = true,
  });

  /// 子类需要实现的优化绘制方法
  void paintOptimized(Canvas canvas, Size size);

  /// 子类需要实现的简化绘制方法（用于性能不足时）
  void paintSimplified(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    if (enableOptimizations && !AnimationPerformanceUtils.shouldUseHighQualityAnimations()) {
      paintSimplified(canvas, size);
    } else {
      paintOptimized(canvas, size);
    }
  }
}

/// 自适应粒子数量的粒子系统
class AdaptiveParticleSystem {
  static int getOptimalParticleCount(int requestedCount) {
    if (!AnimationPerformanceUtils.shouldUseHighQualityAnimations()) {
      // 在低性能设备上减少粒子数量
      return (requestedCount * 0.5).round().clamp(5, requestedCount);
    }
    return requestedCount;
  }

  static Duration getOptimalUpdateInterval() {
    return AnimationPerformanceUtils.shouldUseHighQualityAnimations()
        ? const Duration(milliseconds: 16) // 60fps
        : const Duration(milliseconds: 33); // 30fps
  }
}

/// 动画质量管理器
class AnimationQualityManager {
  static AnimationQuality _currentQuality = AnimationQuality.auto;

  static AnimationQuality get quality => _currentQuality;

  static void setQuality(AnimationQuality quality) {
    _currentQuality = quality;
  }

  static bool shouldShowParticleEffects() {
    switch (_currentQuality) {
      case AnimationQuality.low:
        return false;
      case AnimationQuality.medium:
        return true;
      case AnimationQuality.high:
        return true;
      case AnimationQuality.auto:
        return AnimationPerformanceUtils.shouldUseHighQualityAnimations();
    }
  }

  static bool shouldUseComplexAnimations() {
    switch (_currentQuality) {
      case AnimationQuality.low:
        return false;
      case AnimationQuality.medium:
      case AnimationQuality.high:
        return true;
      case AnimationQuality.auto:
        return AnimationPerformanceUtils.shouldUseHighQualityAnimations();
    }
  }

  static int getParticleCountMultiplier() {
    switch (_currentQuality) {
      case AnimationQuality.low:
        return 1;
      case AnimationQuality.medium:
        return 2;
      case AnimationQuality.high:
        return 3;
      case AnimationQuality.auto:
        return AnimationPerformanceUtils.shouldUseHighQualityAnimations() ? 2 : 1;
    }
  }
}

enum AnimationQuality {
  low,
  medium,
  high,
  auto,
}

/// 性能监控器Widget
class AnimationPerformanceMonitor extends StatefulWidget {
  final Widget child;
  final ValueChanged<double>? onFrameRateUpdate;

  const AnimationPerformanceMonitor({
    super.key,
    required this.child,
    this.onFrameRateUpdate,
  });

  @override
  State<AnimationPerformanceMonitor> createState() => _AnimationPerformanceMonitorState();
}

class _AnimationPerformanceMonitorState extends State<AnimationPerformanceMonitor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Duration> _frameTimes = [];
  double _currentFPS = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _controller.addListener(_measureFrameRate);
  }

  void _measureFrameRate() {
    final now = DateTime.now();
    _frameTimes.add(Duration(microseconds: now.microsecondsSinceEpoch));

    // 保持最近60帧的数据
    while (_frameTimes.length > 60) {
      _frameTimes.removeAt(0);
    }

    if (_frameTimes.length >= 2) {
      final totalTime = _frameTimes.last.inMicroseconds - _frameTimes.first.inMicroseconds;
      final avgFrameTime = totalTime / (_frameTimes.length - 1);
      _currentFPS = 1000000 / avgFrameTime; // 转换为FPS

      widget.onFrameRateUpdate?.call(_currentFPS);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 内存友好的动画缓存
class AnimationCache {
  static final Map<String, Animation<double>> _cache = {};
  static const int _maxCacheSize = 50;

  static Animation<double>? get(String key) {
    return _cache[key];
  }

  static void put(String key, Animation<double> animation) {
    if (_cache.length >= _maxCacheSize) {
      // 移除最旧的缓存项
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = animation;
  }

  static void clear() {
    _cache.clear();
  }

  static void remove(String key) {
    _cache.remove(key);
  }
}

/// 延迟加载动画组件
class LazyAnimationWidget extends StatefulWidget {
  final Widget Function() builder;
  final Duration delay;

  const LazyAnimationWidget({
    super.key,
    required this.builder,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<LazyAnimationWidget> createState() => _LazyAnimationWidgetState();
}

class _LazyAnimationWidgetState extends State<LazyAnimationWidget> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return widget.builder();
    }
    return const SizedBox.shrink();
  }
}

/// 批量动画管理器
class BatchAnimationManager {
  final List<AnimationController> _controllers = [];
  final int maxBatchSize;

  BatchAnimationManager({this.maxBatchSize = 10});

  void addController(AnimationController controller) {
    if (_controllers.length < maxBatchSize) {
      _controllers.add(controller);
    }
  }

  void removeController(AnimationController controller) {
    _controllers.remove(controller);
  }

  void startAll() {
    for (final controller in _controllers) {
      controller.forward();
    }
  }

  void stopAll() {
    for (final controller in _controllers) {
      controller.stop();
    }
  }

  void resetAll() {
    for (final controller in _controllers) {
      controller.reset();
    }
  }

  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();
  }
}