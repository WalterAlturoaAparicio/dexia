import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ResultScreen extends StatefulWidget {
  final File imagenFile;
  final ResultadoInferencia resultado;

  const ResultScreen({
    super.key,
    required this.imagenFile,
    required this.resultado,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _guardando = false;
  bool _guardado = false;
  Position? _posicionGuardada;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim =
        CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
    Future.delayed(
        const Duration(milliseconds: 150), () => _bounceCtrl.forward());
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  /// RF05 + RF08 – Captura GPS (High Accuracy) y guarda el avistamiento.
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      // Intentar obtener posición; si falla, guardamos sin coordenadas
      final Position? pos =
          await LocationService.instance.tryGetPosition();

      final top = widget.resultado.top3.first;
      await DatabaseService.instance.insertAvistamiento(
        Avistamiento(
          imagenPath: widget.imagenFile.path,
          especieNombre: top.ave.nombre,
          especieCientifico: top.ave.cientifico,
          especieId: top.ave.id,
          confianza: top.confianza,
          fechaHora: DateTime.now(),
          latitud: pos?.latitude,
          longitud: pos?.longitude,
        ),
      );

      if (mounted) {
        setState(() {
          _guardado = true;
          _posicionGuardada = pos;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = widget.resultado.top3.first;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero image ───────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusXl),
                      bottomRight: Radius.circular(AppTheme.radiusXl),
                    ),
                    child: Image.file(
                      widget.imagenFile,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _TimerChip(
                        ms: widget.resultado.tiempoInferencia
                            .inMilliseconds),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Resultado principal ──────────────────────────
                    ScaleTransition(
                      scale: _bounceAnim,
                      child: ResultCard(prediction: top),
                    ),

                    const SizedBox(height: 20),

                    // ── Top 3 ────────────────────────────────────────
                    const Text(
                      'Top 3 predicciones',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.resultado.top3.asMap().entries.map(
                          (e) => ConfidenceIndicator(
                            birdName: e.value.ave.nombre,
                            confidence: e.value.confianza,
                            isTop: e.key == 0,
                          ),
                        ),

                    const SizedBox(height: 20),

                    // ── Botón guardar / banner confirmación ──────────
                    if (_guardado)
                      _SavedBanner(position: _posicionGuardada)
                    else
                      FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.white),
                              )
                            : const Icon(Icons.bookmark_add_rounded),
                        label: Text(_guardando
                            ? 'Obteniendo ubicación…'
                            : 'Guardar avistamiento'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800),
                        ),
                      ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Intentar otra vez'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TimerChip extends StatelessWidget {
  final int ms;
  const _TimerChip({required this.ms});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text('$ms ms',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  final Position? position;
  const _SavedBanner({this.position});

  @override
  Widget build(BuildContext context) {
    final hasGps = position != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Avistamiento guardado',
                style: TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (hasGps) ... [
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 13, color: AppTheme.success),
                const SizedBox(width: 4),
                Text(
                  '${position!.latitude.toStringAsFixed(5)}, '
                  '${position!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ] else ...const [
             SizedBox(height: 6),
             Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_rounded,
                    size: 13, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Sin ubicación GPS',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
