import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 修仙风格交互反馈动画组件库
class CultivationInteractions {
  /// 灵气波纹点击效果
  static Widget spiritRipple({
    required Widget child,
    Color? rippleColor,
    Duration? duration,
    double? radius,
    VoidCallback? onTap,
  }) {
    return _SpiritRippleEffect(
      child: child,
      rippleColor: rippleColor ?? const Color(0xFF26A69A),
      duration: duration ?? const Duration(milliseconds: 600),
      radius: radius,
      onTap: onTap,
    );
  }

  /// 悬浮光晕效果
  static Widget hoverGlow({
    required Widget child,
    Color? glowColor,
    double? intensity,
  }) {
    return _HoverGlowEffect(
      child: child,
      glowColor: glowColor ?? const Color(0xFF5C6BC0),
      intensity: intensity ?? 1.0,
    );
  }

  /// 按压缩放反馈
  static Widget pressScale({
    required Widget child,
    double? scale,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    return _PressScaleEffect(
      child: child,
      scale: scale ?? 0.95,
      duration: duration ?? const Duration(milliseconds: 150),
      onTap: onTap,
    );
  }

  /// 能量脉冲悬浮效果
  static Widget energyPulse({
    required Widget child,
    Color? pulseColor,
    Duration? duration,
  }) {
    return _EnergyPulseEffect(
      child: child,
      pulseColor: pulseColor ?? const Color(0xFFE91E63),
      duration: duration ?? const Duration(milliseconds: 1500),
    );
  }

  /// 星光闪烁悬浮
  static Widget starTwinkle({
    required Widget child,
    Color? starColor,
  }) {
    return _StarTwinkleEffect(
      child: child,
      starColor: starColor ?? const Color(0xFFFFD54F),
    );
  }

  /// 组合交互效果 - 同时具备多种反馈
  static Widget combined({
    required Widget child,
    VoidCallback? onTap,
    bool enableRipple = true,
    bool enableScale = true,
    bool enableGlow = true,
    Color? rippleColor,
    Color? glowColor,
  }) {
    Widget result = child;

    if (enableGlow) {
      result = CultivationInteractions.hoverGlow(
        child: result,
        glowColor: glowColor,
      );
    }

    if (enableScale) {
      result = CultivationInteractions.pressScale(
        child: result,
        onTap: onTap,
      );
    }

    if (enableRipple) {
      result = CultivationInteractions.spiritRipple(
        child: result,
        rippleColor: rippleColor,
        onTap: onTap,
      );
    }

    return result;
  }
}

/// 灵气波纹效果实现
class _SpiritRippleEffect extends StatefulWidget {
  const _SpiritRippleEffect({
    required this.child,
    required this.rippleColor,
    required this.duration,
    this.radius,
    this.onTap,
  });

  final Widget child;
  final Color rippleColor;
  final Duration duration;
  final double? radius;
  final VoidCallback? onTap;

  @override
  State<_SpiritRippleEffect> createState() => _SpiritRippleEffectState();
}

class _SpiritRippleEffectState extends State<_SpiritRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRipple() {
    if (!_isAnimating) {
      setState(() => _isAnimating = true);
      _controller.forward().then((_) {
        _controller.reset();
        setState(() => _isAnimating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _startRipple();
        widget.onTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_isAnimating)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: _SpiritRipplePainter(
                      progress: _animation.value,
                      color: widget.rippleColor,
                      radius: widget.radius,
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

/// 灵气波纹绘制器
class _SpiritRipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double? radius;

  _SpiritRipplePainter({
    required this.progress,
    required this.color,
    this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = radius ?? math.max(size.width, size.height) * 0.7;
    
    // 绘制多层波纹效果
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.15;
      final rippleProgress = (progress - delay).clamp(0.0, 1.0);
      
      if (rippleProgress > 0) {
        final paint = Paint()
          ..color = color.withOpacity((1 - rippleProgress) * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(
          center,
          maxRadius * rippleProgress,
          paint,
        );

        // 添加灵气粒子
        for (int j = 0; j < 8; j++) {
          final angle = (j * 45) * (math.pi / 180);
          final distance = maxRadius * rippleProgress * 0.8;
          final particlePos = Offset(
            center.dx + distance * math.cos(angle),
            center.dy + distance * math.sin(angle),
          );
          
          final particlePaint = Paint()
            ..color = color.withOpacity((1 - rippleProgress) * 0.8)
            ..style = PaintingStyle.fill;

          canvas.drawCircle(particlePos, 2.0, particlePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 悬浮光晕效果
class _HoverGlowEffect extends StatefulWidget {
  const _HoverGlowEffect({
    required this.child,
    required this.glowColor,
    required this.intensity,
  });

  final Widget child;
  final Color glowColor;
  final double intensity;

  @override
  State<_HoverGlowEffect> createState() => _HoverGlowEffectState();
}

class _HoverGlowEffectState extends State<_HoverGlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(
                    _animation.value * 0.3 * widget.intensity,
                  ),
                  blurRadius: 20.0 * _animation.value * widget.intensity,
                  spreadRadius: 5.0 * _animation.value * widget.intensity,
                ),
              ],
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 按压缩放效果
class _PressScaleEffect extends StatefulWidget {
  const _PressScaleEffect({
    required this.child,
    required this.scale,
    required this.duration,
    this.onTap,
  });

  final Widget child;
  final double scale;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  State<_PressScaleEffect> createState() => _PressScaleEffectState();
}

class _PressScaleEffectState extends State<_PressScaleEffect>
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
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 能量脉冲效果
class _EnergyPulseEffect extends StatefulWidget {
  const _EnergyPulseEffect({
    required this.child,
    required this.pulseColor,
    required this.duration,
  });

  final Widget child;
  final Color pulseColor;
  final Duration duration;

  @override
  State<_EnergyPulseEffect> createState() => _EnergyPulseEffectState();
}

class _EnergyPulseEffectState extends State<_EnergyPulseEffect>
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
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
                color: widget.pulseColor.withOpacity(_animation.value * 0.4),
                blurRadius: 15.0 + (10.0 * _animation.value),
                spreadRadius: 2.0 + (3.0 * _animation.value),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// 星光闪烁效果
class _StarTwinkleEffect extends StatefulWidget {
  const _StarTwinkleEffect({
    required this.child,
    required this.starColor,
  });

  final Widget child;
  final Color starColor;

  @override
  State<_StarTwinkleEffect> createState() => _StarTwinkleEffectState();
}

class _StarTwinkleEffectState extends State<_StarTwinkleEffect>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 200)),
        vsync: this,
      );
    });
    
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startTwinkling() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && _isHovered) {
          _controllers[i].forward().then((_) {
            if (mounted && _isHovered) {
              _controllers[i].reverse();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _startTwinkling();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        for (final controller in _controllers) {
          controller.reset();
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_isHovered)
            ...List.generate(_animations.length, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, _) {
                  final angle = (index * 60) * (math.pi / 180);
                  final distance = 30.0 + (10.0 * _animations[index].value);
                  
                  return Positioned(
                    left: distance * math.cos(angle),
                    top: distance * math.sin(angle),
                    child: Opacity(
                      opacity: _animations[index].value,
                      child: Icon(
                        Icons.auto_fix_high,
                        size: 12 + (4 * _animations[index].value),
                        color: widget.starColor,
                      ),
                    ),
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}