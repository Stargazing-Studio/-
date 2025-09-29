import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 提供常用的修仙主题粒子与光效包装器。
///
/// 这些实现以轻量 CustomPaint / DecoratedBox 的方式模拟粒子、灵气和闪电效果，
/// 在保持视觉层次感的同时避免引入额外依赖，便于在示例页或实际页面复用。
class CultivationParticles {
  const CultivationParticles._();

  /// 灵气碎光粒子，适合包裹人物或法器组件。
  static Widget spiritParticles({
    required Widget child,
    int particleCount = 18,
    Color particleColor = const Color(0xFF26A69A),
  }) {
    return _ParticleOverlay(
      child: child,
      painter: _ParticlePainter(
        count: particleCount,
        baseColor: particleColor,
        seed: 0.82,
        maxRadius: 3.5,
      ),
    );
  }

  /// 星光粒子，适合作为背景层渲染渐隐的星辰。
  static Widget starField({
    required Widget child,
    int starCount = 28,
    Color starColor = const Color(0xFFFFD54F),
  }) {
    return _ParticleOverlay(
      child: child,
      painter: _ParticlePainter(
        count: starCount,
        baseColor: starColor,
        seed: 1.38,
        maxRadius: 2.6,
      ),
    );
  }

  /// 能量波动效果，使用径向渐变模拟灵力波纹。
  static Widget energyWave({
    required Widget child,
    Color waveColor = const Color(0xFF5C6BC0),
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    waveColor.withValues(alpha: 0.0),
                    waveColor.withValues(alpha: 0.18),
                    waveColor.withValues(alpha: 0.35),
                    waveColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.45, 0.8, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 迷雾层，用于营造灵气蒸腾或秘境薄雾的氛围。
  static Widget mysticalMist({
    required Widget child,
    Color mistColor = const Color(0xFFFFFFFF),
    double intensity = 0.18,
  }) {
    final alpha = intensity.clamp(0.05, 0.35);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mistColor.withValues(alpha: alpha * 0.6),
                    Colors.transparent,
                    mistColor.withValues(alpha: alpha),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 闪电/灵光效果，适合突破或雷罚场景。
  static Widget lightningFlash({
    required Widget child,
    Color boltColor = const Color(0xFF80DEEA),
  }) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LightningPainter(color: boltColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticleOverlay extends StatelessWidget {
  const _ParticleOverlay({required this.child, required this.painter});

  final Widget child;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: painter,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.count,
    required this.baseColor,
    required this.seed,
    this.maxRadius = 3.0,
  });

  final int count;
  final Color baseColor;
  final double seed;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final golden = (sqrt(5) - 1) / 2;

    for (var i = 0; i < count; i++) {
      final progress = i / count;
      final angle = 2 * pi * (i * golden + seed);
      final radiusFactor = 0.3 + 0.7 * progress;
      final dx = size.width * (0.5 + 0.45 * cos(angle) * radiusFactor);
      final dy = size.height * (0.5 + 0.45 * sin(angle * 1.2) * radiusFactor);
      final radius = lerpDouble(1.2, maxRadius, progress) ?? maxRadius;
      final color = baseColor.withValues(alpha: 0.15 + 0.7 * (1 - progress));

      paint.color = color;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.count != count ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.seed != seed ||
        oldDelegate.maxRadius != maxRadius;
  }
}

class _LightningPainter extends CustomPainter {
  _LightningPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final random = Random(99);
    final startX = size.width * 0.3;
    final endX = size.width * 0.7;
    final startY = size.height * 0.1;
    final endY = size.height * 0.9;
    path.moveTo(startX, startY);

    const segments = 6;
    for (var i = 1; i <= segments; i++) {
      final t = i / segments;
      final offsetX = lerpDouble(startX, endX, 0.5 + (random.nextDouble() - 0.5) * 0.3) ?? startX;
      final offsetY = lerpDouble(startY, endY, t) ?? startY;
      path.lineTo(offsetX, offsetY);
    }

    path.lineTo(endX, endY);

    canvas.drawPath(path, paint);

    // 外层辉光
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LightningPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
