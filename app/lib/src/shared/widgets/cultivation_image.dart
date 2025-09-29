import 'package:flutter/material.dart';

/// 修仙主题图片类型枚举
enum CultivationImageType {
  character,  // 修士头像
  technique,  // 功法图谱
  pill,       // 丹药图鉴
  companion,  // 灵仆形象
  realm,      // 秘境风景
  artifact,   // 法宝图样
  sect,       // 宗门徽记
  general,    // 通用图片
}

/// 修仙主题图片组件，支持占位符和错误处理
class CultivationImage extends StatelessWidget {
  const CultivationImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cultivation = CultivationImageType.general,
    this.showShimmer = true,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final CultivationImageType cultivation;
  final bool showShimmer;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    
    if (imageUrl.startsWith('http')) {
      // 网络图片
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorPlaceholder();
        },
      );
    } else if (imageUrl.startsWith('assets/')) {
      // 本地资源
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorPlaceholder();
        },
      );
    } else {
      // 无效路径
      imageWidget = errorWidget ?? _buildErrorPlaceholder();
    }

    // 应用圆角和修仙主题装饰
    if (borderRadius != null || cultivation != CultivationImageType.general) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Stack(
          children: [
            imageWidget,
            if (cultivation != CultivationImageType.general)
              _buildCultivationOverlay(),
          ],
        ),
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F33),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: placeholder ?? (showShimmer 
        ? _buildShimmerPlaceholder() 
        : _buildDefaultPlaceholder()),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F33),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x3326A69A),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(cultivation),
            size: 32,
            color: const Color(0x8826A69A),
          ),
          const SizedBox(height: 8),
          Text(
            _getTextForType(cultivation),
            style: const TextStyle(
              color: Color(0x8826A69A),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF26A69A),
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return _ShimmerWidget(
      width: width ?? 200,
      height: height ?? 200,
    );
  }

  Widget _buildCultivationOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: _getGradientForType(cultivation),
      ),
    );
  }

  IconData _getIconForType(CultivationImageType type) {
    switch (type) {
      case CultivationImageType.character:
        return Icons.person_outline;
      case CultivationImageType.technique:
        return Icons.auto_fix_high;
      case CultivationImageType.pill:
        return Icons.scatter_plot;
      case CultivationImageType.companion:
        return Icons.pets_outlined;
      case CultivationImageType.realm:
        return Icons.forest_outlined;
      case CultivationImageType.artifact:
        return Icons.diamond_outlined;
      case CultivationImageType.sect:
        return Icons.account_balance;
      case CultivationImageType.general:
        return Icons.image_outlined;
    }
  }

  String _getTextForType(CultivationImageType type) {
    switch (type) {
      case CultivationImageType.character:
        return '修士头像';
      case CultivationImageType.technique:
        return '功法图谱';
      case CultivationImageType.pill:
        return '丹药图鉴';
      case CultivationImageType.companion:
        return '灵仆形象';
      case CultivationImageType.realm:
        return '秘境风景';
      case CultivationImageType.artifact:
        return '法宝图样';
      case CultivationImageType.sect:
        return '宗门徽记';
      case CultivationImageType.general:
        return '图片加载失败';
    }
  }

  Gradient? _getGradientForType(CultivationImageType type) {
    switch (type) {
      case CultivationImageType.character:
        return LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0x1126A69A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case CultivationImageType.technique:
        return RadialGradient(
          colors: [
            const Color(0x115C6BC0),
            Colors.transparent,
          ],
        );
      case CultivationImageType.pill:
        return LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0x11FFD54F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CultivationImageType.companion:
        return LinearGradient(
          colors: [
            const Color(0x114CAF50),
            Colors.transparent,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        );
      case CultivationImageType.realm:
        return LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0x119C27B0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case CultivationImageType.artifact:
        return RadialGradient(
          colors: [
            const Color(0x11FF9800),
            Colors.transparent,
          ],
        );
      case CultivationImageType.sect:
        return LinearGradient(
          colors: [
            const Color(0x11795548),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case CultivationImageType.general:
        return null;
    }
  }
}

/// 闪烁加载效果
class _ShimmerWidget extends StatefulWidget {
  const _ShimmerWidget({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              width: widget.width,
              height: widget.height,
              color: const Color(0xFF1C1F33),
            ),
            Transform.translate(
              offset: Offset(
                (widget.width + 100) * (_controller.value - 0.5),
                0,
              ),
              child: Container(
                width: 100,
                height: widget.height,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0x3326A69A),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 头像组件 - 专门用于修士头像显示
class CultivationAvatar extends StatelessWidget {
  const CultivationAvatar({
    super.key,
    required this.imageUrl,
    this.size = 48.0,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showRealmGlow = true,
    this.realm,
  });

  final String imageUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;
  final bool showRealmGlow;
  final String? realm;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CultivationImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      cultivation: CultivationImageType.character,
    );

    if (showRealmGlow && realm != null) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRealmColor(realm!).withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatar,
      );
    }

    if (borderColor != null) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor!,
            width: borderWidth,
          ),
        ),
        child: ClipOval(child: avatar),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: avatar,
    );
  }

  Color _getRealmColor(String realm) {
    if (realm.contains('练气')) return const Color(0xFF4CAF50);
    if (realm.contains('筑基')) return const Color(0xFF2196F3);
    if (realm.contains('金丹')) return const Color(0xFFFFD54F);
    if (realm.contains('元婴')) return const Color(0xFF9C27B0);
    if (realm.contains('化神')) return const Color(0xFFE91E63);
    if (realm.contains('飞升')) return const Color(0xFFFF9800);
    return const Color(0xFF26A69A);
  }
}

/// 图片画廊组件 - 用于多图展示
class CultivationImageGallery extends StatefulWidget {
  const CultivationImageGallery({
    super.key,
    required this.images,
    this.height = 200.0,
    this.autoPlay = true,
    this.cultivation = CultivationImageType.general,
  });

  final List<String> images;
  final double height;
  final bool autoPlay;
  final CultivationImageType cultivation;

  @override
  State<CultivationImageGallery> createState() => _CultivationImageGalleryState();
}

class _CultivationImageGalleryState extends State<CultivationImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    if (widget.autoPlay && widget.images.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        final nextIndex = (_currentIndex + 1) % widget.images.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F33),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('暂无图片'),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return CultivationImage(
                imageUrl: widget.images[index],
                height: widget.height,
                borderRadius: BorderRadius.circular(12),
                cultivation: widget.cultivation,
              );
            },
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? const Color(0xFF26A69A)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}