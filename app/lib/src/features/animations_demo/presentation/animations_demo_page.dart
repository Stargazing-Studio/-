import 'package:flutter/material.dart';
import 'package:ling_yan_tian_ji/src/shared/animations/cultivation_animations.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/loading_animations.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/interactive_animations.dart';
import 'package:ling_yan_tian_ji/src/shared/animations/particle_effects.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/animated_page_route.dart';

/// 动画演示页面 - 用于测试和展示所有动画效果
class AnimationsDemoPage extends StatefulWidget {
  const AnimationsDemoPage({super.key});

  @override
  State<AnimationsDemoPage> createState() => _AnimationsDemoPageState();
}

class _AnimationsDemoPageState extends State<AnimationsDemoPage>
    with TickerProviderStateMixin {
  late AnimationController _breakthroughController;
  late AnimationController _alchemyController;
  late AnimationController _techniqueController;
  late AnimationController _companionController;
  late AnimationController _portalController;
  late AnimationController _ascensionController;

  int _selectedIndex = 0;
  bool _showParticleEffects = true;
  double _animationSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _breakthroughController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _alchemyController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _techniqueController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _companionController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _portalController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    
    _ascensionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 启动循环动画
    _alchemyController.repeat();
  }

  @override
  void dispose() {
    _breakthroughController.dispose();
    _alchemyController.dispose();
    _techniqueController.dispose();
    _companionController.dispose();
    _portalController.dispose();
    _ascensionController.dispose();
    super.dispose();
  }

  void _triggerBreakthrough() {
    _breakthroughController.forward().then((_) {
      _breakthroughController.reset();
    });
  }

  void _triggerTechnique() {
    _techniqueController.forward().then((_) {
      _techniqueController.reset();
    });
  }

  void _triggerCompanion() {
    _companionController.forward().then((_) {
      _companionController.reset();
    });
  }

  void _triggerPortal() {
    _portalController.forward().then((_) {
      _portalController.reset();
    });
  }

  void _triggerAscension() {
    _ascensionController.forward().then((_) {
      _ascensionController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentWidget = Scaffold(
      appBar: AppBar(
        title: const Text('修仙动画演示'),
        actions: [
          Switch(
            value: _showParticleEffects,
            onChanged: (value) {
              setState(() => _showParticleEffects = value);
            },
          ),
          const Text('粒子效果'),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildBasicAnimationsTab(),
          _buildLoadingAnimationsTab(),
          _buildInteractiveAnimationsTab(),
          _buildParticleEffectsTab(),
          _buildTransitionDemoTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_fix_high),
            label: '修仙动画',
          ),
          NavigationDestination(
            icon: Icon(Icons.hourglass_empty),
            label: '加载动画',
          ),
          NavigationDestination(
            icon: Icon(Icons.touch_app),
            label: '交互反馈',
          ),
          NavigationDestination(
            icon: Icon(Icons.scatter_plot),
            label: '粒子效果',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: '页面转场',
          ),
        ],
      ),
    );

    // 根据设置决定是否添加粒子效果
    if (_showParticleEffects) {
      return CultivationParticles.starField(
        child: CultivationParticles.spiritParticles(
          child: contentWidget,
          particleCount: 15,
          particleColor: const Color(0xFF26A69A),
        ),
        starCount: 20,
        starColor: const Color(0xFFFFD54F).withValues(alpha: 0.4),
      );
    }

    return contentWidget;
  }

  Widget _buildBasicAnimationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: '灵气呼吸效果',
            child: Center(
              child: CultivationAnimations.breathingGlow(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '突破境界特效',
            child: Column(
              children: [
                CultivationAnimations.breakthroughEffect(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C6BC0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  animation: _breakthroughController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerBreakthrough,
                  child: const Text('触发突破'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '炼丹法阵',
            child: Center(
              child: CultivationAnimations.alchemyCircle(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                animation: _alchemyController,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '功法激活星光',
            child: Column(
              children: [
                CultivationAnimations.techniqueActivation(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1BEE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  animation: _techniqueController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerTechnique,
                  child: const Text('激活功法'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '灵仆召唤波纹',
            child: Column(
              children: [
                CultivationAnimations.companionSummon(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  animation: _companionController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerCompanion,
                  child: const Text('召唤灵仆'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '传送门效果',
            child: Column(
              children: [
                CultivationAnimations.portalEffect(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.adjust,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  animation: _portalController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerPortal,
                  child: const Text('开启传送门'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '飞升光柱',
            child: Column(
              children: [
                CultivationAnimations.ascensionBeam(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flight_takeoff,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  animation: _ascensionController,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _triggerAscension,
                  child: const Text('开始飞升'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingAnimationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: '修炼太极旋转',
            child: Center(
              child: CultivationLoadingIndicators.cultivation(
                size: 60.0,
                color: const Color(0xFF26A69A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '炼丹炉火焰',
            child: Center(
              child: CultivationLoadingIndicators.alchemyFurnace(
                size: 80.0,
                flameColor: const Color(0xFFFF6B35),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '灵力聚合',
            child: Center(
              child: CultivationLoadingIndicators.spiritGathering(
                size: 70.0,
                particleColor: const Color(0xFF5C6BC0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '突破能量波',
            child: Center(
              child: CultivationLoadingIndicators.breakthrough(
                size: 70.0,
                energyColor: const Color(0xFFE91E63),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '叙事文字加载',
            child: Center(
              child: CultivationLoadingIndicators.narrativeLoading(
                text: '道韵流转中',
                textStyle: const TextStyle(fontSize: 18),
                dotColor: const Color(0xFF26A69A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '骨架屏卡片',
            child: CultivationLoadingIndicators.skeletonCard(
              height: 100,
              shimmerColor: const Color(0xFF26A69A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveAnimationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: '灵气波纹点击',
            child: Center(
              child: CultivationInteractions.spiritRipple(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF26A69A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.touch_app,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                rippleColor: const Color(0xFF26A69A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '悬浮光晕效果',
            child: Center(
              child: CultivationInteractions.hoverGlow(
                child: Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C6BC0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      '悬浮我',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                glowColor: const Color(0xFF5C6BC0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '按压缩放反馈',
            child: Center(
              child: CultivationInteractions.pressScale(
                child: Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      '按压我',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '能量脉冲',
            child: Center(
              child: CultivationInteractions.energyPulse(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                pulseColor: const Color(0xFFE91E63),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '星光闪烁悬浮',
            child: Center(
              child: CultivationInteractions.starTwinkle(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                starColor: const Color(0xFFFFD54F),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '组合交互效果',
            child: Center(
              child: CultivationInteractions.combined(
                child: Container(
                  width: 120,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      '全效果按钮',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                rippleColor: const Color(0xFF9C27B0),
                glowColor: const Color(0xFF9C27B0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleEffectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: '灵气粒子漂浮',
            child: Container(
              height: 200,
              child: CultivationParticles.spiritParticles(
                child: const Center(
                  child: Text(
                    '灵气粒子环绕',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                particleCount: 25,
                particleColor: const Color(0xFF26A69A),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '能量波纹扩散',
            child: Container(
              height: 200,
              child: CultivationParticles.energyWave(
                child: const Center(
                  child: Text(
                    '能量波纹',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                waveColor: const Color(0xFF5C6BC0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '星辰闪烁背景',
            child: Container(
              height: 200,
              child: CultivationParticles.starField(
                child: const Center(
                  child: Text(
                    '星空背景',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                starCount: 40,
                starColor: const Color(0xFFFFD54F),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '仙雾缭绕',
            child: Container(
              height: 200,
              child: CultivationParticles.mysticalMist(
                child: const Center(
                  child: Text(
                    '仙雾缭绕',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                mistColor: const Color(0xFF9C27B0),
                intensity: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: '雷电闪烁',
            child: Container(
              height: 200,
              child: CultivationParticles.lightningFlash(
                child: const Center(
                  child: Text(
                    '雷电特效',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                boltColor: const Color(0xFFE91E63),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionDemoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            title: '页面转场演示',
            child: Column(
              children: [
                const Text('测试不同的页面转场效果：'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildTransitionButton(
                      '灵气流转',
                      () => _showTransitionDemo(TransitionType.spiritFlow),
                    ),
                    _buildTransitionButton(
                      '突破境界',
                      () => _showTransitionDemo(TransitionType.breakthrough),
                    ),
                    _buildTransitionButton(
                      '传送门',
                      () => _showTransitionDemo(TransitionType.portal),
                    ),
                    _buildTransitionButton(
                      '快速滑动',
                      () => _showTransitionDemo(TransitionType.slide),
                    ),
                    _buildTransitionButton(
                      '修仙旋涡',
                      () => _showTransitionDemo(TransitionType.cultivation),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '性能监控',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('动画速度控制：'),
                  Slider(
                    value: _animationSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: '${_animationSpeed.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() => _animationSpeed = value);
                      _updateAnimationSpeeds(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '提示：监控帧率和内存使用情况，确保动画流畅运行。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _showTransitionDemo(TransitionType type) {
    Route route;
    final demoPage = _TransitionDemoPage(type: type);

    switch (type) {
      case TransitionType.spiritFlow:
        route = CultivationRoutes.spiritFlow(demoPage);
        break;
      case TransitionType.breakthrough:
        route = CultivationRoutes.breakthrough(demoPage);
        break;
      case TransitionType.portal:
        route = CultivationRoutes.portal(demoPage);
        break;
      case TransitionType.slide:
        route = CultivationRoutes.slide(demoPage);
        break;
      case TransitionType.cultivation:
        route = CultivationRoutes.cultivation(demoPage);
        break;
    }

    Navigator.of(context).push(route);
  }

  void _updateAnimationSpeeds(double speed) {
    final duration = Duration(milliseconds: (1200 / speed).round());
    
    _breakthroughController.duration = duration;
    _techniqueController.duration = Duration(milliseconds: (2000 / speed).round());
    _companionController.duration = Duration(milliseconds: (1000 / speed).round());
    _portalController.duration = Duration(milliseconds: (900 / speed).round());
    _ascensionController.duration = Duration(milliseconds: (2000 / speed).round());
  }
}

enum TransitionType {
  spiritFlow,
  breakthrough,
  portal,
  slide,
  cultivation,
}

class _TransitionDemoPage extends StatelessWidget {
  final TransitionType type;

  const _TransitionDemoPage({required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getTypeName(type)} 转场演示'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getTypeIcon(type),
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              '${_getTypeName(type)} 转场效果',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeName(TransitionType type) {
    switch (type) {
      case TransitionType.spiritFlow:
        return '灵气流转';
      case TransitionType.breakthrough:
        return '突破境界';
      case TransitionType.portal:
        return '传送门';
      case TransitionType.slide:
        return '快速滑动';
      case TransitionType.cultivation:
        return '修仙旋涡';
    }
  }

  IconData _getTypeIcon(TransitionType type) {
    switch (type) {
      case TransitionType.spiritFlow:
        return Icons.air;
      case TransitionType.breakthrough:
        return Icons.trending_up;
      case TransitionType.portal:
        return Icons.adjust;
      case TransitionType.slide:
        return Icons.swap_horiz;
      case TransitionType.cultivation:
        return Icons.cyclone;
    }
  }
}