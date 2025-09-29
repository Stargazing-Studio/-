import 'package:flutter/material.dart';
import 'package:ling_yan_tian_ji/src/shared/animations/cultivation_animations.dart';

/// 修仙风格页面路由动画
class CultivationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final TransitionDirection direction;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final bool maintainState;
  final bool fullscreenDialog;

  CultivationPageRoute({
    required this.child,
    this.direction = TransitionDirection.cultivationSwirl,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOutCubic,
    this.maintainState = true,
    this.fullscreenDialog = false,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              child: child,
              animation: CurvedAnimation(parent: animation, curve: curve),
              secondaryAnimation: secondaryAnimation,
              direction: direction,
            );
          },
        );

  static Widget _buildTransition({
    required Widget child,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required TransitionDirection direction,
  }) {
    // 添加页面退场动画支持
    if (secondaryAnimation.status == AnimationStatus.forward) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    }

    return CultivationAnimations.pageTransition(
      child: child,
      animation: animation,
      direction: direction,
    );
  }
}

/// 灵气流转页面转场 - 用于重要页面切换
class SpiritFlowPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Color? particleColor;

  SpiritFlowPageRoute({
    required this.child,
    this.particleColor,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SpiritFlowTransition(
              animation: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutQuart,
              ),
              particleColor: particleColor ?? const Color(0xFF26A69A),
              child: child,
            );
          },
        );
}

/// 灵气流转转场动画实现
class _SpiritFlowTransition extends StatelessWidget {
  const _SpiritFlowTransition({
    required this.animation,
    required this.child,
    required this.particleColor,
  });

  final Animation<double> animation;
  final Widget child;
  final Color particleColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Stack(
          children: [
            // 背景遮罩渐变
            Container(
              color: Colors.black.withOpacity((1 - animation.value) * 0.8),
            ),
            // 灵气粒子效果
            if (animation.value < 0.8)
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpiritParticlesPainter(
                    progress: animation.value,
                    color: particleColor,
                  ),
                ),
              ),
            // 主要内容
            Transform.scale(
              scale: 0.8 + (0.2 * animation.value),
              child: Transform.translate(
                offset: Offset(
                  0,
                  50 * (1 - animation.value),
                ),
                child: Opacity(
                  opacity: animation.value,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 灵气粒子绘制器
class _SpiritParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpiritParticlesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * (1 - progress))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制向中心汇聚的灵气粒子
    for (int i = 0; i < 20; i++) {
      final angle = (i * 18) * (3.14159 / 180); // 每18度一个粒子
      final distance = (size.width * 0.8) * (1 - progress);
      
      final particlePos = Offset(
        center.dx + distance * (1 + 0.2 * progress),
        center.dy + distance * (1 + 0.2 * progress) * 0.3,
      );
      
      canvas.drawCircle(
        particlePos,
        3.0 * (1 - progress),
        paint,
      );
    }

    // 中心聚合光点
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(
      center,
      10 * progress,
      centerPaint.withOpacity(progress),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 突破境界特效转场
class BreakthroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Color? effectColor;

  BreakthroughPageRoute({
    required this.child,
    this.effectColor,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 1000),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return CultivationAnimations.breakthroughEffect(
              child: child,
              animation: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutBack,
              ),
              effectColor: effectColor,
            );
          },
        );
}

/// 传送门转场 - 用于秘境进入
class PortalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Color? portalColor;

  PortalPageRoute({
    required this.child,
    this.portalColor,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 900),
          reverseTransitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return CultivationAnimations.portalEffect(
              child: child,
              animation: CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
              portalColor: portalColor,
            );
          },
        );
}

/// 快速滑动转场 - 用于快速导航
class QuickSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final AxisDirection direction;

  QuickSlidePageRoute({
    required this.child,
    this.direction = AxisDirection.left,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case AxisDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case AxisDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
              case AxisDirection.left:
                begin = const Offset(1.0, 0.0);
                break;
              case AxisDirection.right:
                begin = const Offset(-1.0, 0.0);
                break;
            }

            return SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
        );
}

/// 页面路由工厂类 - 简化使用
class CultivationRoutes {
  static Route<T> spiritFlow<T>(Widget child, {Color? particleColor}) {
    return SpiritFlowPageRoute<T>(
      child: child,
      particleColor: particleColor,
    );
  }

  static Route<T> breakthrough<T>(Widget child, {Color? effectColor}) {
    return BreakthroughPageRoute<T>(
      child: child,
      effectColor: effectColor,
    );
  }

  static Route<T> portal<T>(Widget child, {Color? portalColor}) {
    return PortalPageRoute<T>(
      child: child,
      portalColor: portalColor,
    );
  }

  static Route<T> slide<T>(Widget child, {AxisDirection direction = AxisDirection.left}) {
    return QuickSlidePageRoute<T>(
      child: child,
      direction: direction,
    );
  }

  static Route<T> cultivation<T>(Widget child, {
    TransitionDirection direction = TransitionDirection.cultivationSwirl,
    Duration? duration,
  }) {
    return CultivationPageRoute<T>(
      child: child,
      direction: direction,
      duration: duration ?? const Duration(milliseconds: 600),
    );
  }
}

/// 页面转场辅助扩展
extension BuildContextAnimations on BuildContext {
  /// 灵气流转导航
  Future<T?> pushSpiritFlow<T>(Widget page, {Color? particleColor}) {
    return Navigator.of(this).push<T>(
      CultivationRoutes.spiritFlow<T>(page, particleColor: particleColor),
    );
  }

  /// 突破转场导航
  Future<T?> pushBreakthrough<T>(Widget page, {Color? effectColor}) {
    return Navigator.of(this).push<T>(
      CultivationRoutes.breakthrough<T>(page, effectColor: effectColor),
    );
  }

  /// 传送门导航
  Future<T?> pushPortal<T>(Widget page, {Color? portalColor}) {
    return Navigator.of(this).push<T>(
      CultivationRoutes.portal<T>(page, portalColor: portalColor),
    );
  }

  /// 快速滑动导航
  Future<T?> pushSlide<T>(Widget page, {AxisDirection direction = AxisDirection.left}) {
    return Navigator.of(this).push<T>(
      CultivationRoutes.slide<T>(page, direction: direction),
    );
  }

  /// 修仙转场导航
  Future<T?> pushCultivation<T>(Widget page, {
    TransitionDirection direction = TransitionDirection.cultivationSwirl,
    Duration? duration,
  }) {
    return Navigator.of(this).push<T>(
      CultivationRoutes.cultivation<T>(
        page,
        direction: direction,
        duration: duration,
      ),
    );
  }
}