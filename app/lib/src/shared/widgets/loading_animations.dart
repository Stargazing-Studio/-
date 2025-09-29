import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 修仙风格的加载动画组件
class CultivationLoadingIndicators {
  /// 修炼进度 - 太极旋转加载
  static Widget cultivation({
    double size = 48.0,
    Color? color,
    Duration? duration,
  }) {
    return _CultivationSpinner(
      size: size,
      color: color ?? const Color(0xFF26A69A),
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  /// 炼丹炉加载 - 火焰效果
  static Widget alchemyFurnace({
    double size = 60.0,
    Color? flameColor,
  }) {
    return _AlchemyFurnace(
      size: size,
      flameColor: flameColor ?? const Color(0xFFFF6B35),
    );
  }

  /// 灵力汇聚 - 粒子聚合
  static Widget spiritGathering({
    double size = 50.0,
    Color? particleColor,
  }) {
    return _SpiritGathering(
      size: size,
      particleColor: particleColor ?? const Color(0xFF5C6BC0),
    );
  }

  /// 突破加载 - 能量爆发
  static Widget breakthrough({
    double size = 56.0,
    Color? energyColor,
  }) {
    return _BreakthroughLoader(
      size: size,
      energyColor: energyColor ?? const Color(0xFFE91E63),
    );
  }

  /// 文字流加载 - 适用于叙事内容
  static Widget narrativeLoading({
    String text = '道韵流转中...',
    TextStyle? textStyle,
    Color? dotColor,
  }) {
    return _NarrativeLoader(
      text: text,
      textStyle: textStyle,
      dotColor: dotColor ?? const Color(0xFF26A69A),
    );
  }

  /// 卡片加载骨架屏 - 修仙风格
  static Widget skeletonCard({
    double width = double.infinity,
    double height = 120.0,
    Color? shimmerColor,
  }) {
    return _SkeletonCard(
      width: width,
      height: height,
      shimmerColor: shimmerColor ?? const Color(0xFF26A69A),
    );
  }
}

/// 太极修炼旋转器
class _CultivationSpinner extends StatefulWidget {
  const _CultivationSpinner({
    required this.size,
    required this.color,
    required this.duration,
  });

  final double size;
  final Color color;
  final Duration duration;

  @override
  State<_CultivationSpinner> createState() => _CultivationSpinnerState();
}

class _CultivationSpinnerState extends State<_CultivationSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 6.28318, // 2π
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _TaijiPainter(
                color: widget.color,
                progress: _controller.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 太极图绘制器
class _TaijiPainter extends CustomPainter {
  const _TaijiPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 外圆
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius * 0.9, outerPaint);

    // 太极内容
    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final blackPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // 绘制太极图的两半
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 1.6,
      height: radius * 1.6,
    );

    // 左半圆（白）
    canvas.drawArc(rect, -math.pi / 2, math.pi, true, whitePaint);
    // 右半圆（黑）
    canvas.drawArc(rect, math.pi / 2, math.pi, true, blackPaint);

    // 内部小圆
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.4),
      radius * 0.2,
      blackPaint,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.4),
      radius * 0.2,
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 炼丹炉加载动画
class _AlchemyFurnace extends StatefulWidget {
  const _AlchemyFurnace({
    required this.size,
    required this.flameColor,
  });

  final double size;
  final Color flameColor;

  @override
  State<_AlchemyFurnace> createState() => _AlchemyFurnaceState();
}

class _AlchemyFurnaceState extends State<_AlchemyFurnace>
    with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _flameController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 炼丹炉本体
          Container(
            width: widget.size * 0.8,
            height: widget.size * 0.8,
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8D6E63), width: 2),
            ),
          ),
          // 旋转的火焰
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: AnimatedBuilder(
                  animation: _flameController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _FlamePainter(
                        color: widget.flameColor,
                        intensity: _flameController.value,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 火焰绘制器
class _FlamePainter extends CustomPainter {
  const _FlamePainter({
    required this.color,
    required this.intensity,
  });

  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // 绘制多个火焰舌头
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final flameHeight = (radius * 0.6) * (0.8 + 0.4 * intensity);
      
      final start = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      final end = Offset(
        center.dx + (radius + flameHeight) * math.cos(angle),
        center.dy + (radius + flameHeight) * math.sin(angle),
      );

      final paint = Paint()
        ..color = color.withOpacity(0.7 + 0.3 * intensity)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 灵力粒子聚合
class _SpiritGathering extends StatefulWidget {
  const _SpiritGathering({
    required this.size,
    required this.particleColor,
  });

  final double size;
  final Color particleColor;

  @override
  State<_SpiritGathering> createState() => _SpiritGatheringState();
}

class _SpiritGatheringState extends State<_SpiritGathering>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SpiritParticlesPainter(
              color: widget.particleColor,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

/// 灵力粒子绘制器
class _SpiritParticlesPainter extends CustomPainter {
  const _SpiritParticlesPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 绘制向中心聚合的粒子
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final distance = radius * (1 - progress) * 0.8;
      
      final position = Offset(
        center.dx + distance * math.cos(angle),
        center.dy + distance * math.sin(angle),
      );

      final paint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, 3.0, paint);
    }

    // 中心聚合点
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 2 + 4 * progress, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 突破能量加载器
class _BreakthroughLoader extends StatefulWidget {
  const _BreakthroughLoader({
    required this.size,
    required this.energyColor,
  });

  final double size;
  final Color energyColor;

  @override
  State<_BreakthroughLoader> createState() => _BreakthroughLoaderState();
}

class _BreakthroughLoaderState extends State<_BreakthroughLoader>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外层能量波
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + 0.5 * _waveController.value,
                child: Opacity(
                  opacity: 1 - _waveController.value,
                  child: Container(
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.energyColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // 内核脉冲
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.3 + 0.3 * _pulseController.value,
                child: Container(
                  width: widget.size * 0.4,
                  height: widget.size * 0.4,
                  decoration: BoxDecoration(
                    color: widget.energyColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 叙事文字加载
class _NarrativeLoader extends StatefulWidget {
  const _NarrativeLoader({
    required this.text,
    this.textStyle,
    required this.dotColor,
  });

  final String text;
  final TextStyle? textStyle;
  final Color dotColor;

  @override
  State<_NarrativeLoader> createState() => _NarrativeLoaderState();
}

class _NarrativeLoaderState extends State<_NarrativeLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _dotCount = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              style: widget.textStyle ?? 
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 30,
              child: Text(
                '•' * (_dotCount.value + 1),
                style: TextStyle(
                  color: widget.dotColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 骨架屏卡片
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({
    required this.width,
    required this.height,
    required this.shimmerColor,
  });

  final double width;
  final double height;
  final Color shimmerColor;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1C1F33),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // 骨架结构
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: widget.width * 0.6,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: widget.width * 0.8,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: widget.width * 0.4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              // 闪烁效果
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                    (widget.width + 100) * (_controller.value - 0.5),
                    0,
                  ),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          widget.shimmerColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}