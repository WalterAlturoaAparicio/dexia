import 'dart:io';

import 'package:flutter/material.dart';

import '../models/prediction.dart';

class ResultScreen extends StatelessWidget {
  final File imagenFile;
  final ResultadoInferencia resultado;

  const ResultScreen({
    super.key,
    required this.imagenFile,
    required this.resultado,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final top = resultado.top3.first;

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
                  imagenFile,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 24),

              // Tarjeta de resultado principal
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
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

              Text(
                'Top 3 predicciones',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ...resultado.top3.asMap().entries.map((entry) {
                return _BarraPrediccion(
                  rango: entry.key + 1,
                  prediccion: entry.value,
                  esTop: entry.key == 0,
                );
              }),

              const SizedBox(height: 24),

              // Tiempo de inferencia
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Tiempo de inferencia: ${resultado.tiempoInferencia.inMilliseconds} ms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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
              // Insignia de rango
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
              // Porcentaje
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
