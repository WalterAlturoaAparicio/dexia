import 'dart:io';

import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';

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

class _ResultScreenState extends State<ResultScreen> {
  bool _guardando = false;
  bool _guardado = false;

  /// RF08 – persists the sighting locally with SQLite.
  Future<void> _guardarAvistamiento() async {
    setState(() => _guardando = true);
    try {
      final top = widget.resultado.top3.first;
      final av = Avistamiento(
        imagenPath: widget.imagenFile.path,
        especieNombre: top.ave.nombre,
        especieCientifico: top.ave.cientifico,
        especieId: top.ave.id,
        confianza: top.confianza,
        fechaHora: DateTime.now(),
      );
      await DatabaseService.instance.insertAvistamiento(av);
      if (mounted) setState(() => _guardado = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final top = widget.resultado.top3.first;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Resultado'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen analizada
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.imagenFile,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta resultado principal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      top.ave.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      top.ave.cientifico,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(top.confianza * 100).toStringAsFixed(1)}% de confianza',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // RF04 – Top 3 predicciones
              Text(
                'Top 3 predicciones',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...widget.resultado.top3.asMap().entries.map((entry) {
                return _BarraPrediccion(
                  rango: entry.key + 1,
                  prediccion: entry.value,
                  esTop: entry.key == 0,
                );
              }),

              const SizedBox(height: 8),

              // Tiempo de inferencia
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Inferencia: ${widget.resultado.tiempoInferencia.inMilliseconds} ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // RF08 – Save button
              _guardado
                  ? _SavedBanner(colorScheme: colorScheme)
                  : FilledButton.icon(
                      onPressed: _guardando ? null : _guardarAvistamiento,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.bookmark_add),
                      label: Text(
                          _guardando ? 'Guardando…' : 'Guardar avistamiento'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Clasificar otra foto'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
  final ColorScheme colorScheme;
  const _SavedBanner({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            'Avistamiento guardado localmente',
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraPrediccion extends StatelessWidget {
  final int rango;
  final Prediction prediccion;
  final bool esTop;

  const _BarraPrediccion({
    required this.rango,
    required this.prediccion,
    required this.esTop,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final confianza = prediccion.confianza;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: esTop
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rango',
                  style: TextStyle(
                    color: esTop
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediccion.ave.nombre,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      prediccion.ave.cientifico,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(confianza * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: esTop
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confianza,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                esTop ? colorScheme.primary : colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
