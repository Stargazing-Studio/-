import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ling_yan_tian_ji/src/features/map/application/map_providers.dart';
import 'package:ling_yan_tian_ji/src/core/network/api_client.dart';
import 'package:ling_yan_tian_ji/src/shared/widgets/navigation_scaffold.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(mapDataProvider);
    final locationAsync = ref.watch(currentLocationProvider);

    return NavigationScaffold(
      appBar: AppBar(
        title: const Text('山河图 · 已知疆域'),
      ),
      body: mapAsync.when(
        data: (mapData) {
          final current = locationAsync.maybeWhen(data: (value) => value, orElse: () => null);
          return _MapCanvas(mapData: mapData, currentLocation: current);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(error: error, stack: stack),
      ),
    );
  }
}

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({required this.mapData, required this.currentLocation});

  final MapData mapData;
  final LocationNode? currentLocation;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> with SingleTickerProviderStateMixin {
  String? _hoveredNode;
  late final AnimationController _pulse;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    // 在首帧后再启动动画，避免热重载/重启期间调度到已释放的视图（Flutter Web 兼容）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pulse.repeat();
      _started = true;
    });
  }

  @override
  void dispose() {
    if (_started) {
      _pulse.stop();
    }
    _pulse.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    // 热重载/重启时，先停再在下一帧恢复，规避 Web 平台 EngineFlutterView 已释放的异常
    try {
      _pulse.stop();
    } catch (_) {}
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pulse.repeat();
        _started = true;
      }
    });
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.mapData.style;
    final bg = style.backgroundGradient;
    return Container(
      decoration: bg != null && bg.length >= 2
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bg.map(_colorFromHex).toList().take(2).toList(),
              ),
            )
          : BoxDecoration(color: _colorFromHex(style.backgroundColor)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final stack = Stack(
            children: [
              if (style.tiles != null && style.tiles!.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TilesPainter(tiles: style.tiles!),
                  ),
                ),
              if (style.areas != null && style.areas!.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AreaPainter(areas: style.areas!),
                  ),
                ),
              if ((style.gridVisible ?? true) && style.gridColor != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(
                      color: _colorFromHex(style.gridColor!),
                    ),
                  ),
                ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _EdgePainter(
                    nodes: widget.mapData.nodes,
                    edges: widget.mapData.edges,
                    width: width,
                    height: height,
                    fallback: _colorFromHex(style.edgeColor),
                    edgeStyles: style.edgeStyles,
                  ),
                ),
              ),
              // 当前地点的脉冲高亮
              if (widget.currentLocation != null)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _PulsePainter(
                          nx: widget.currentLocation!.x,
                          ny: widget.currentLocation!.y,
                          progress: _pulse.value,
                          color: const Color(0xFF5C6BC0),
                        ),
                      );
                    },
                  ),
                ),
              ...widget.mapData.nodes.map((node) {
                final left = node.x * width;
                final top = node.y * height;
                final isCurrent = widget.currentLocation?.id == node.id;
                return Positioned(
                  left: left - 40,
                  top: top - 40,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredNode = node.id),
                    onExit: (_) => setState(() => _hoveredNode = null),
                    child: _MapNodeChip(
                      node: node,
                      highlighted: _hoveredNode == node.id || isCurrent,
                      onTap: () => _showNodeDetails(context, node, isCurrent),
                      labelColor: (style.nodeLabel?['color'] as String?) ?? style.nodeLabelColor ?? '#E0E5FF',
                      labelSize: (style.nodeLabel?['size'] as num?)?.toDouble() ?? 12.0,
                    ),
                  ),
                );
              })
            ],
          );

          return InteractiveViewer(
            minScale: 0.6,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(200),
            child: SizedBox(width: width, height: height, child: stack),
          );
        },
      ),
    );
  }

  void _showNodeDetails(BuildContext context, LocationNode node, bool isCurrent) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final travelController = ref.watch(travelControllerProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: node.connections
                        .map((conn) => Chip(label: Text('通往 $conn')))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: isCurrent
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await travelController.travelTo(node.id);
                                  if (context.mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('已前往 ${node.name}')),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                } catch (error) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('无法前往：$error')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.navigation_rounded),
                        label: Text(isCurrent ? '已抵达' : '前往此地'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _MapNodeChip extends StatelessWidget {
  const _MapNodeChip({
    required this.node,
    required this.highlighted,
    required this.onTap,
    required this.labelColor,
    required this.labelSize,
  });

  final LocationNode node;
  final bool highlighted;
  final VoidCallback onTap;
  final String labelColor;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final fill = node.style['fill_color'] as String? ?? '#26A69A';
    final border = node.style['border_color'] as String? ?? '#E0E5FF';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _colorFromHex(fill).withValues(alpha: highlighted ? 0.9 : 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _colorFromHex(border),
            width: highlighted ? 3 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(node.style['icon'] as String? ?? node.category),
              size: 16,
              color: Colors.white,
            ),
            Text(
              node.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _colorFromHex(labelColor),
                    fontWeight: FontWeight.w700,
                    fontSize: labelSize,
                  ),
            ),
            Text(
              node.category,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  IconData _iconFor(String value) {
    switch (value) {
      case 'village':
        return Icons.home_work_outlined;
      case 'market':
        return Icons.store_mall_directory_outlined;
      case 'secret_realm':
        return Icons.auto_fix_high_outlined;
      case 'academy':
        return Icons.cast_for_education_outlined;
      case 'trail':
      case 'path':
        return Icons.alt_route_outlined;
      case 'camp':
        return Icons.cabin_outlined;
      case 'wilds':
        return Icons.park_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter({
    required this.nodes,
    required this.edges,
    required this.width,
    required this.height,
    required this.fallback,
    required this.edgeStyles,
  });

  final List<LocationNode> nodes;
  final List<MapEdge> edges;
  final double width;
  final double height;
  final Color fallback;
  final Map<String, dynamic>? edgeStyles;

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final node in nodes) node.id: node};
    for (final edge in edges) {
      final from = nodeMap[edge.from];
      final to = nodeMap[edge.to];
      if (from == null || to == null) continue;
      final p1 = Offset(from.x * width, from.y * height);
      final p2 = Offset(to.x * width, to.y * height);
      final kind = edge.kind ?? 'road';
      final style = (edgeStyles != null ? edgeStyles![kind] as Map<String, dynamic>? : null) ?? {};
      final colorHex = (edge.color ?? style['color'] as String?) ?? '#888888';
      final strokeColor = _colorFromHex(colorHex).withValues(alpha: ((edge.opacity ?? (style['opacity'] as num?)?.toDouble()) ?? 0.5));
      final strokeWidth = edge.width ?? (style['width'] as num?)?.toDouble() ?? 2.0;
      final dash = edge.dash ?? ((style['dash'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList());

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (dash != null && dash.isNotEmpty) {
        _drawDashedLine(canvas, p1, p2, paint, dash);
      } else {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, List<double> dashArray) {
    final total = (end - start).distance;
    final direction = (end - start) / total;
    double distance = 0;
    int index = 0;
    while (distance < total) {
      final len = dashArray[index % dashArray.length];
      final next = distance + len;
      if (index % 2 == 0) {
        final p1 = start + direction * distance;
        final p2 = start + direction * (next.clamp(0, total));
        canvas.drawLine(p1, p2, paint);
      }
      distance = next;
      index++;
      if (len <= 0) break;
    }
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) {
    return oldDelegate.nodes != nodes || oldDelegate.edges != edges;
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    const step = 64.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.nx, required this.ny, required this.progress, required this.color});
  final double nx;
  final double ny;
  final double progress; // 0..1
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(nx * size.width, ny * size.height);
    final maxR = 36.0;
    // 三圈脉冲，错峰
    for (int i = 0; i < 3; i++) {
      final t = (progress + i * 0.33) % 1.0;
      final radius = 8.0 + maxR * t;
      final alpha = (1.0 - t).clamp(0.0, 1.0) * 0.35;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius, paint);
    }
    // 中心点实心高亮
    final core = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, core);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.nx != nx || oldDelegate.ny != ny || oldDelegate.color != color;
}

class _AreaPainter extends CustomPainter {
  _AreaPainter({required this.areas});
  final List<dynamic> areas;

  @override
  void paint(Canvas canvas, Size size) {
    for (final raw in areas) {
      if (raw is! Map<String, dynamic>) continue;
      final pts = raw['points'] as List<dynamic>?;
      if (pts == null || pts.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final p = pts[i] as Map<String, dynamic>;
        final dx = ((p['x'] as num).toDouble()) * size.width;
        final dy = ((p['y'] as num).toDouble()) * size.height;
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }
      path.close();
      final fillColor = (raw['fill_color'] as String?) ?? '#1E3A8A';
      final opacity = (raw['opacity'] as num?)?.toDouble() ?? 0.18;
      final borderColor = raw['border_color'] as String?;

      final paintFill = Paint()
        ..color = _colorFromHex(fillColor).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paintFill);

      if (borderColor != null) {
        final paintStroke = Paint()
          ..color = _colorFromHex(borderColor).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawPath(path, paintStroke);
      }
    }
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  bool shouldRepaint(covariant _AreaPainter oldDelegate) => false;
}

class _TilesPainter extends CustomPainter {
  _TilesPainter({required this.tiles});
  final List<MapTileStyle> tiles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final tile in tiles) {
      final rect = Rect.fromLTWH(
        tile.x0 * size.width,
        tile.y0 * size.height,
        (tile.x1 - tile.x0) * size.width,
        (tile.y1 - tile.y0) * size.height,
      );
      if (tile.backgroundGradient != null && tile.backgroundGradient!.length >= 2) {
        final shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: tile.backgroundGradient!.map(_colorFromHex).toList().take(2).toList(),
        ).createShader(rect);
        final paint = Paint()..shader = shader;
        canvas.drawRect(rect, paint);
      }
      // 可选：绘制 tile 边框，增强拼接边界感
      final border = Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(rect, border);

      // tile 层级内的区域
      if (tile.areas != null) {
        for (final raw in tile.areas!) {
          if (raw is! Map<String, dynamic>) continue;
          final pts = raw['points'] as List<dynamic>?;
          if (pts == null || pts.isEmpty) continue;
          final path = Path();
          for (var i = 0; i < pts.length; i++) {
            final p = pts[i] as Map<String, dynamic>;
            final dx = rect.left + ((p['x'] as num).toDouble()) * rect.width;
            final dy = rect.top + ((p['y'] as num).toDouble()) * rect.height;
            if (i == 0) {
              path.moveTo(dx, dy);
            } else {
              path.lineTo(dx, dy);
            }
          }
          path.close();
          final fillColor = (raw['fill_color'] as String?) ?? '#1E3A8A';
          final opacity = (raw['opacity'] as num?)?.toDouble() ?? 0.18;
          final borderColor = raw['border_color'] as String?;
          final paintFill = Paint()
            ..color = _colorFromHex(fillColor).withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          canvas.drawPath(path, paintFill);
          if (borderColor != null) {
            final paintStroke = Paint()
              ..color = _colorFromHex(borderColor).withValues(alpha: 0.6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
            canvas.drawPath(path, paintStroke);
          }
        }
      }
    }
  }

  Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  bool shouldRepaint(covariant _TilesPainter oldDelegate) => false;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.stack});

  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text('地图加载失败：$error'),
            if (stack != null)
              Text(
                stack.toString(),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }
}
