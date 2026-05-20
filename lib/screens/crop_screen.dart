import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Pantalla de recorte manual antes del preprocesamiento (paso intermedio).
/// Recibe los bytes de la imagen cruda y devuelve los bytes del recorte cuadrado.
class CropScreen extends StatefulWidget {
  /// Bytes de la imagen original (JPEG/PNG).
  final Uint8List imageBytes;

  const CropScreen({super.key, required this.imageBytes});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen>
    with SingleTickerProviderStateMixin {
  final CropController _cropController = CropController();

  bool _cropping = false;

  // Tamaño del área de crop mostrado en pantalla (actualizado al mover)
  double _cropW = 0;
  double _cropH = 0;

  late final AnimationController _btnAnim;
  late final Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _btnAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _btnAnim.dispose();
    super.dispose();
  }

  void _onCropMoved(Rect rect) {
    // rect.width / rect.height son fracciones 0..1 relativas a la imagen
    // Mostramos los píxeles reales del recorte para que el usuario tenga referencia
    setState(() {
      _cropW = rect.width;
      _cropH = rect.height;
    });
  }

  Future<void> _confirmar() async {
    HapticFeedback.mediumImpact();
    setState(() => _cropping = true);
    // crop_your_image llama al callback onCropped cuando termina
    _cropController.crop();
  }

  void _onCropped(Uint8List croppedBytes) {
    if (!mounted) return;
    // Devolver bytes recortados al caller
    Navigator.pop(context, croppedBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1A0D),
      body: Stack(
        children: [
          // ── Crop viewer ───────────────────────────────────────────
          Positioned.fill(
            child: Crop(
              image: widget.imageBytes,
              controller: _cropController,
              onCropped: _onCropped,
              aspectRatio: 1.0, // siempre cuadrado
              withCircleUi: false,
              onMoved: _onCropMoved,
              onStatusChanged: (status) {
                if (status == CropStatus.ready && _cropping) {
                  // crop_your_image lanzará onCropped automáticamente
                }
              },
              maskColor: Colors.black.withValues(alpha: 0.72),
              cornerDotBuilder: (size, edgeAlignment) => const _CornerDot(),
              interactive: true,
            ),
          ),

          // ── Top bar ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Back
                    _GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recortar imagen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Ajusta el cuadro para encuadrar el ave',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Reset
                    _GlassButton(
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        // En 1.1.0 no existe reset(); reasignar aspectRatio
                        // fuerza al widget a recentrar el área de recorte.
                        _cropController.aspectRatio = 1.0;
                      },
                      tooltip: 'Restablecer',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _BottomPanel(
                cropW: _cropW,
                cropH: _cropH,
                cropping: _cropping,
                btnScale: _btnScale,
                btnAnim: _btnAnim,
                onConfirm: _confirmar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom panel: dimensiones + botón confirmar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final double cropW;
  final double cropH;
  final bool cropping;
  final Animation<double> btnScale;
  final AnimationController btnAnim;
  final VoidCallback onConfirm;

  const _BottomPanel({
    required this.cropW,
    required this.cropH,
    required this.cropping,
    required this.btnScale,
    required this.btnAnim,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Dimensiones en px relativas (fracción × 224 = tamaño modelo)
    final pxDisplay = cropW > 0
        ? '${(cropW * 224).round()} × ${(cropH * 224).round()} px'
        : '—';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A0D),
        border: Border(
          top: BorderSide(
            color: AppTheme.green.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dimension chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DimChip(
                label: 'Ancho',
                value: cropW > 0 ? '${(cropW * 100).toStringAsFixed(1)}%' : '—',
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 28,
                color: Colors.white12,
              ),
              const SizedBox(width: 8),
              _DimChip(
                label: 'Alto',
                value: cropH > 0 ? '${(cropH * 100).toStringAsFixed(1)}%' : '—',
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 28,
                color: Colors.white12,
              ),
              const SizedBox(width: 8),
              _DimChip(
                label: 'Resolución',
                value: pxDisplay,
                accent: true,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Info hint
          Text(
            'Mantén proporción cuadrada · El modelo recibe 224 × 224 px',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Confirm button
          GestureDetector(
            onTapDown: (_) => btnAnim.forward(),
            onTapUp: (_) async {
              await btnAnim.reverse();
              onConfirm();
            },
            onTapCancel: () => btnAnim.reverse(),
            child: ScaleTransition(
              scale: btnScale,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: cropping
                      ? AppTheme.green.withValues(alpha: 0.5)
                      : AppTheme.green,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: cropping
                      ? []
                      : [
                          BoxShadow(
                            color: AppTheme.green.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: cropping
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Usar este recorte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Widgets helper
// ─────────────────────────────────────────────────────────────────────────────

class _DimChip extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _DimChip({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: accent ? AppTheme.green : Colors.white,
            fontSize: accent ? 13 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _CornerDot extends StatelessWidget {
  const _CornerDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.green.withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
