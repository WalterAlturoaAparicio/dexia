import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../models/prediction.dart';
// ignore: unused_element
// needed by _Thumbnail
import 'dart:io' show File;

// ─────────────────────────────────────────────────────────────────────────────
// MainButtonCard  (used in HomeScreen 2×2 grid)
// ─────────────────────────────────────────────────────────────────────────────
class MainButtonCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? iconBg;
  final int? badge;
  final bool accent;
  final VoidCallback onTap;

  const MainButtonCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconBg,
    this.badge,
    this.accent = false,
  });

  @override
  State<MainButtonCard> createState() => _MainButtonCardState();
}

class _MainButtonCardState extends State<MainButtonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTapDown(_) async {
    await _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  Future<void> _onTapUp(_) async {
    await _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: widget.accent
                ? Border.all(color: AppTheme.green, width: 2)
                : Border.all(color: Colors.transparent),
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.iconBg ?? AppTheme.greenLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(widget.icon,
                        size: 28,
                        color: widget.accent
                            ? AppTheme.green
                            : AppTheme.navy),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (widget.badge != null && widget.badge! > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConfidenceIndicator  (color-coded bar + label)
// ─────────────────────────────────────────────────────────────────────────────
class ConfidenceIndicator extends StatelessWidget {
  final String birdName;
  final double confidence;
  final bool isTop;

  const ConfidenceIndicator({
    super.key,
    required this.birdName,
    required this.confidence,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.confidenceColor(confidence);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isTop)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  birdName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isTop ? FontWeight.w800 : FontWeight.w600,
                    color: isTop ? AppTheme.navy : Colors.grey[600],
                  ),
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: confidence),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResultCard  (top prediction hero card with confidence chip)
// ─────────────────────────────────────────────────────────────────────────────
class ResultCard extends StatelessWidget {
  final Prediction prediction;

  const ResultCard({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) {
    final conf = prediction.confianza;
    final color = AppTheme.confidenceColor(conf);
    final label = AppTheme.confidenceLabel(conf);
    final icon = AppTheme.confidenceIcon(conf);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.ave.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      prediction.ave.cientifico,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _ConfBadge(percentage: conf, color: color),
            ],
          ),
          const SizedBox(height: 12),
          _StatusChip(icon: icon, label: label, color: color),
        ],
      ),
    );
  }
}

class _ConfBadge extends StatelessWidget {
  final double percentage;
  final Color color;
  const _ConfBadge({required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(percentage * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatusChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BirdTile  (history list item)
// ─────────────────────────────────────────────────────────────────────────────
class BirdTile extends StatelessWidget {
  final Avistamiento avistamiento;
  final VoidCallback? onDelete;

  const BirdTile({super.key, required this.avistamiento, this.onDelete});

  @override
  Widget build(BuildContext context) {
// placeholder – just use File below
    final conf = avistamiento.confianza;
    final color = AppTheme.confidenceColor(conf);
    final isValid = avistamiento.synced;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _Thumbnail(path: avistamiento.imagenPath),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avistamiento.especieNombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.navy,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        avistamiento.especieCientifico,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${(conf * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: color),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!isValid)
                            const Row(
                              children: [
                                Icon(Icons.cloud_off,
                                    size: 11, color: Colors.orange),
                                SizedBox(width: 3),
                                Text(
                                  'Sin sync',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          if (isValid)
                            const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 11, color: AppTheme.success),
                                SizedBox(width: 3),
                                Text(
                                  'Validado',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.redAccent),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String path;
  const _Thumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file,
            width: 64, height: 64, fit: BoxFit.cover);
      }
    } catch (_) {}
    return Container(
      width: 64,
      height: 64,
      color: AppTheme.greenLight,
      child: const Icon(Icons.photo, color: AppTheme.green, size: 28),
    );
  }
}
