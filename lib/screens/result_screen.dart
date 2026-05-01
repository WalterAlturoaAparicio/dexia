import 'dart:io';

import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';
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
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );
    // Small bounce when result card appears
    Future.delayed(const Duration(milliseconds: 150),
        () => _bounceCtrl.forward());
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final top = widget.resultado.top3.first;
      await DatabaseService.instance.insertAvistamiento(
        Avistamiento(
          imagenPath: widget.imagenFile.path,
          especieNombre: top.ave.nombre,
          especieCientifico: top.ave.cientifico,
          especieId: top.ave.id,
          confianza: top.confianza,
          fechaHora: DateTime.now(),
        ),
      );
      if (mounted) setState(() => _guardado = true);
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
              // Hero image
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.resultado.tiempoInferencia.inMilliseconds} ms',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Result card with bounce animation
                    ScaleTransition(
                      scale: _bounceAnim,
                      child: ResultCard(prediction: top),
                    ),

                    const SizedBox(height: 20),

                    // Top 3 section
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

                    ...widget.resultado.top3.asMap().entries.map((e) =>
                        ConfidenceIndicator(
                          birdName: e.value.ave.nombre,
                          confidence: e.value.confianza,
                          isTop: e.key == 0,
                        )),

                    const SizedBox(height: 20),

                    // Save button
                    if (_guardado)
                      _SavedBanner()
                    else
                      FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.white,
                                ),
                              )
                            : const Icon(Icons.bookmark_add_rounded),
                        label: Text(_guardando
                            ? 'Guardando…'
                            : 'Guardar avistamiento'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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

class _SavedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 20),
          SizedBox(width: 8),
          Text(
            'Avistamiento guardado localmente',
            style: TextStyle(
              color: AppTheme.success,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
