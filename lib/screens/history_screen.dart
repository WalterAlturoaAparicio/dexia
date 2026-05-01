import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Avistamiento>> _future;
  _Filter _filtro = _Filter.todos;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DatabaseService.instance.getAllAvistamientos();
  }

  Future<void> _delete(int id) async {
    await DatabaseService.instance.deleteAvistamiento(id);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Mis avistamientos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: _Filter.values.map((f) {
                final active = f == _filtro;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filtro = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.green : AppTheme.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: active
                              ? AppTheme.green
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? AppTheme.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // List
          Expanded(
            child: FutureBuilder<List<Avistamiento>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.green),
                  );
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }

                final all = snap.data ?? [];
                final lista = _aplicarFiltro(all);

                if (lista.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.nature_people_outlined,
                            size: 64, color: AppTheme.green.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          all.isEmpty
                              ? 'Aún no hay avistamientos'
                              : 'Nada con este filtro',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final av = lista[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i == 0 ||
                            !_sameDay(lista[i - 1].fechaHora, av.fechaHora))
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatDate(av.fechaHora),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        BirdTile(
                          avistamiento: av,
                          onDelete: av.id != null
                              ? () => _confirmDelete(av.id!)
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Avistamiento> _aplicarFiltro(List<Avistamiento> all) {
    switch (_filtro) {
      case _Filter.todos:
        return all;
      case _Filter.validados:
        return all.where((a) => a.synced).toList();
      case _Filter.sinSync:
        return all.where((a) => !a.synced).toList();
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_sameDay(dt, now)) return 'HOY';
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'AYER';
    return DateFormat('d MMM yyyy', 'es').format(dt).toUpperCase();
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Eliminar avistamiento'),
        content: const Text('¿Seguro que quieres eliminar este registro?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _delete(id);
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

enum _Filter {
  todos('Todos'),
  validados('Validados'),
  sinSync('Sin sync');

  final String label;
  const _Filter(this.label);
}
