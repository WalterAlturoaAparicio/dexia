import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';

/// Displays all locally saved sightings (RF08).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Avistamiento>> _futureAvistamientos;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureAvistamientos =
        DatabaseService.instance.getAllAvistamientos();
  }

  Future<void> _delete(int id) async {
    await DatabaseService.instance.deleteAvistamiento(id);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis avistamientos'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: FutureBuilder<List<Avistamiento>>(
        future: _futureAvistamientos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nature_people_outlined,
                      size: 72, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no tienes avistamientos guardados.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final av = lista[i];
              return _AvistamientoTile(
                avistamiento: av,
                onDelete: () => _delete(av.id!),
              );
            },
          );
        },
      ),
    );
  }
}

class _AvistamientoTile extends StatelessWidget {
  final Avistamiento avistamiento;
  final VoidCallback onDelete;

  const _AvistamientoTile({
    required this.avistamiento,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd MMM yyyy – HH:mm', 'es')
        .format(avistamiento.fechaHora);
    final imagenExiste = File(avistamiento.imagenPath).existsSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Thumbnail
          SizedBox(
            width: 90,
            height: 90,
            child: imagenExiste
                ? Image.file(
                    File(avistamiento.imagenPath),
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_outlined,
                        color: colorScheme.outline),
                  ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    avistamiento.especieNombre,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    avistamiento.especieCientifico,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(avistamiento.confianza * 100).toStringAsFixed(1)}% · $dateStr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                  if (!avistamiento.synced)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off,
                              size: 12, color: colorScheme.error),
                          const SizedBox(width: 4),
                          Text(
                            'Sin sincronizar',
                            style:
                                TextStyle(fontSize: 11, color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: colorScheme.error,
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar avistamiento'),
                content: const Text(
                    '¿Seguro que quieres eliminar este registro?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onDelete();
                    },
                    child: Text('Eliminar',
                        style: TextStyle(color: colorScheme.error)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
