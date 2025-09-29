import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 修仙主题动画组件库
class CultivationAnimations {
  static const Duration fastDuration = Duration(milliseconds: 300);
  static const Duration normalDuration = Duration(milliseconds: 600);
  static const Duration slowDuration = Duration(milliseconds: 1200);
  static const Duration breathingDuration = Duration(milliseconds: 2000);

  /// 灵气呼吸效果 - 用于修炼界面
  static Widget breathingGlow({
    required Widget child,
    Color? glowColor,
    Duration? duration,
  }) {
    return _BreathingGlow(
      child: child,
      glowColor: glowColor ?? const Color(0xFF26A69A),
      duration: duration ?? breathingDuration,
    );
  }

  /// 突破动画 - 境界提升特效
  static Widget breakthroughEffect({
    required Widget child,
    required Animation<double> animation,
    Color? effectColor,
  }) {
    return _BreakthroughEffect(
      child: child,
      animation: animation,
      effectColor: effectColor ?? const Color(0xFF5C6BC0),
    );
  }

  /// 丹药炼制动画 - 旋转光环效果
  static Widget alchemyCircle({
    required Widget child,
    required Animation<double> animation,
    Color? circleColor,
  }) {
    return _AlchemyCircle(
      child: child,
      animation: animation,
      circleColor: circleColor ?? const Color(0xFFFFD54F),
    );
  }

  /// 功法激活效果 - 星光闪烁
  static Widget techniqueActivation({
    required Widget child,
    required Animation<double> animation,
    Color? starColor,
  }) {
    return _TechniqueActivation(
      child: child,
      animation: animation,
      starColor: starColor ?? const Color(0xFFE1BEE7),
    );
  }

  /// 灵仆召唤波纹效果
  static Widget companionSummon({
    required Widget child,
    required Animation<double> animation,
    Color? rippleColor,
  }) {
    return _CompanionSummon(
      child: child,
      animation: animation,
      rippleColor: rippleColor ?? const Color(0xFF4CAF50),
    );
  }

  /// 秘境传送门效果
  static Widget portalEffect({
    required Widget child,
    required Animation<double> animation,
    Color? portalColor,
  }) {
    return _PortalEffect(
      child: child,
      animation: animation,
      portalColor: portalColor ?? const Color(0xFF9C27B0),
    );
  }

  /// 飞升光柱效果
  static Widget ascensionBeam({
    required Widget child,
    required Animation<double> animation,
    Color? beamColor,
  }) {
    return _AscensionBeam(
      child: child,
      animation: animation,
      beamColor: beamColor ?? const Color(0xFFFF9800),
    );
  }

  /// 页面切换粒子转场
  static Widget pageTransition({
    required Widget child,
    required Animation<double> animation,
    TransitionDirection direction = TransitionDirection.fade,
  }) {
    return _PageTransition(
      child: child,
      animation: animation,
      direction: direction,
    );
  }
}

enum TransitionDirection {
  fade,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
  scale,
  cultivationSwirl,
}

/// 呼吸光晕效果
class _BreathingGlow extends StatefulWidget {
  const _BreathingGlow({
    required this.child,
    required this.glowColor,
    required this.duration,
  });

  final Widget child;
  final Color glowColor;
  final Duration duration;

  @override
  State<_BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<_BreathingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _animation.value * 0.5),
                blurRadius: 20.0 * _animation.value,
                spreadRadius: 5.0 * _animation.value,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// 突破特效
class _BreakthroughEffect extends StatelessWidget {
  const _BreakthroughEffect({
    required this.child,
    required this.animation,
    required this.effectColor,
  });

  final Widget child;
  final Animation<double> animation;
  final Color effectColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外层能量环
            if (animation.value > 0.5)
              Transform.scale(
                scale: (animation.value - 0.5) * 4,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectColor.withValues(alpha: 1 - animation.value),
                      width: 3,
                    ),
                  ),
                ),
              ),
            // 主体内容
            Transform.scale(
              scale: 0.8 + (animation.value * 0.4),
              child: Opacity(
                opacity: animation.value < 0.8 ? 1.0 : (1 - animation.value) * 5,
                child: child,
              ),
            ),
            // 粒子效果
            ...List.generate(8, (index) {
              final angle = (index * 45) * (math.pi / 180);
              final radius = 40 * animation.value;
              return Transform.translate(
                offset: Offset(
                  radius * math.cos(angle),
                  radius * math.sin(angle),
                ),
                child: Opacity(
                  opacity: 1 - animation.value,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: effectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

/// 炼丹法阵
class _AlchemyCircle extends StatelessWidget {
  const _AlchemyCircle({
    required this.child,
    required this.animation,
    required this.circleColor,
  });

  final Widget child;
  final Animation<double> animation;
  final Color circleColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 外层旋转圆环
            Transform.rotate(
              angle: animation.value * 6.28318, // 2π
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: List.generate(6, (index) {
                    final angle = index * 60 * (3.14159 / 180);
                    return Transform.translate(
                      offset: Offset(
                        50 * (1 + 0.2 * animation.value),
                        0,
                      ),
                      child: Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // 内层反向旋转
            Transform.rotate(
              angle: -animation.value * 4.18879, // -4/3π
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
              ),
            ),
            // 中心内容
            child,
          ],
        );
      },
    );
  }
}

/// 功法激活星光效果
class _TechniqueActivation extends StatelessWidget {
  const _TechniqueActivation({
    required this.child,
    required this.animation,
    required this.starColor,
  });

  final Widget child;
  final Animation<double> animation;
  final Color starColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 星光粒子
            ...List.generate(12, (index) {
              final angle = index * 30 * (3.14159 / 180);
              final distance = 60 + 30 * animation.value;
              return Transform.translate(
                offset: Offset(
                  distance * 0.8 * (1 + 0.3 * animation.value),
                  distance * 0.8 * (1 + 0.3 * animation.value) * 0.3,
                ),
                child: Transform.rotate(
                  angle: angle,
                  child: Opacity(
                    opacity: (1 - animation.value).clamp(0.0, 1.0),
                    child: Icon(
                      Icons.auto_fix_high,
                      size: 16 + 8 * animation.value,
                      color: starColor,
                    ),
                  ),
                ),
              );
            }),
            // 主体内容
            Transform.scale(
              scale: 1.0 + 0.1 * animation.value,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// 灵仆召唤波纹
class _CompanionSummon extends StatelessWidget {
  const _CompanionSummon({
    required this.child,
    required this.animation,
    required this.rippleColor,
  });

  final Widget child;
  final Animation<double> animation;
  final Color rippleColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 三层波纹
            ...List.generate(3, (index) {
              final delay = index * 0.2;
              final rippleProgress = (animation.value - delay).clamp(0.0, 1.0);
              return Transform.scale(
                scale: rippleProgress * 3,
                child: Opacity(
                  opacity: (1 - rippleProgress) * 0.6,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: rippleColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            }),
            // 主体内容
            Transform.scale(
              scale: 0.5 + 0.5 * animation.value,
              child: Opacity(
                opacity: animation.value,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 传送门效果
class _PortalEffect extends StatelessWidget {
  const _PortalEffect({
    required this.child,
    required this.animation,
    required this.portalColor,
  });

  final Widget child;
  final Animation<double> animation;
  final Color portalColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 旋转门框
            Transform.rotate(
              angle: animation.value * 12.56637, // 4π
              child: Transform.scale(
                scale: 0.8 + 0.4 * animation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        portalColor.withValues(alpha: 0.3),
                        portalColor.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // 内容
            ClipOval(
              child: Transform.scale(
                scale: animation.value,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 飞升光柱
class _AscensionBeam extends StatelessWidget {
  const _AscensionBeam({
    required this.child,
    required this.animation,
    required this.beamColor,
  });

  final Widget child;
  final Animation<double> animation;
  final Color beamColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 垂直光柱
            Transform.scale(
              scaleY: animation.value * 5,
              child: Container(
                width: 20,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      beamColor.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            // 上升粒子
            ...List.generate(8, (index) {
              return Transform.translate(
                offset: Offset(
                  (index - 4) * 10.0,
                  -100 * animation.value,
                ),
                child: Opacity(
                  opacity: 1 - animation.value,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: beamColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
            // 主体内容
            Transform.translate(
              offset: Offset(0, -20 * animation.value),
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// 页面转场动画
class _PageTransition extends StatelessWidget {
  const _PageTransition({
    required this.child,
    required this.animation,
    required this.direction,
  });

  final Widget child;
  final Animation<double> animation;
  final TransitionDirection direction;

  @override
  Widget build(BuildContext context) {
    switch (direction) {
      case TransitionDirection.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case TransitionDirection.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case TransitionDirection.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case TransitionDirection.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case TransitionDirection.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case TransitionDirection.scale:
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      case TransitionDirection.cultivationSwirl:
        return _CultivationSwirlTransition(
          animation: animation,
          child: child,
        );
    }
  }
}

/// 修仙旋涡转场
class _CultivationSwirlTransition extends StatelessWidget {
  const _CultivationSwirlTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Transform.rotate(
          angle: (1 - animation.value) * 6.28318, // 反向旋转
          child: Transform.scale(
            scale: animation.value,
            child: Opacity(
              opacity: animation.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}