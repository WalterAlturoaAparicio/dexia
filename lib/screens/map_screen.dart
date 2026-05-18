import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Avistamiento> _avistamientos = [];
  bool _cargando = true;

  // Centro por defecto: Ibagué, Tolima
  static const LatLng _centroDefault = LatLng(4.4389, -75.2322);

  @override
  void initState() {
    super.initState();
    _cargarAvistamientos();
  }

  Future<void> _cargarAvistamientos() async {
    final lista = await DatabaseService.instance.getConUbicacion();
    if (mounted) {
      setState(() {
        _avistamientos = lista;
        _cargando = false;
      });
      // Si hay registros, centrar el mapa en el más reciente
      if (lista.isNotEmpty) {
        final primero = lista.first;
        _mapController.move(
          LatLng(primero.latitud!, primero.longitud!),
          13,
        );
      }
    }
  }

  // ── RF07 – Abrir navegación externa ──────────────────────────────────────

  Future<void> _abrirEnGoogleMaps(Avistamiento av) async {
    final lat = av.latitud!;
    final lng = av.longitud!;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }

  Future<void> _abrirEnWaze(Avistamiento av) async {
    final lat = av.latitud!;
    final lng = av.longitud!;
    final uri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Waze')),
        );
      }
    }
  }

  // ── Modal de detalle ─────────────────────────────────────────────────────

  void _mostrarDetalle(Avistamiento av) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (_) => _DetalleSheet(
        avistamiento: av,
        onGoogleMaps: () {
          Navigator.pop(context);
          _abrirEnGoogleMaps(av);
        },
        onWaze: () {
          Navigator.pop(context);
          _abrirEnWaze(av);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Mapa de avistamientos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_cargando)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.green,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${_avistamientos.length} registros',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green))
          : _avistamientos.isEmpty
              ? _EmptyMap()
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: _centroDefault,
                        initialZoom: 11,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        // Capa de tiles OpenStreetMap (sin API key)
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.dexia.aves',
                          maxZoom: 19,
                        ),
                        // Pins de avistamientos
                        MarkerLayer(
                          markers: _avistamientos.map((av) {
                            return Marker(
                              point: LatLng(av.latitud!, av.longitud!),
                              width: 56,
                              height: 56,
                              child: GestureDetector(
                                onTap: () => _mostrarDetalle(av),
                                child: _MapPin(av: av),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    // Botón "Mi ubicación" (centrar en el más reciente)
                    Positioned(
                      bottom: 24,
                      right: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'center',
                        backgroundColor: AppTheme.white,
                        foregroundColor: AppTheme.navy,
                        elevation: 4,
                        onPressed: () {
                          if (_avistamientos.isNotEmpty) {
                            final av = _avistamientos.first;
                            _mapController.move(
                              LatLng(av.latitud!, av.longitud!),
                              14,
                            );
                          }
                        },
                        child: const Icon(Icons.my_location_rounded),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Pin del mapa ──────────────────────────────────────────────────────────────

class _MapPin extends StatelessWidget {
  final Avistamiento av;
  const _MapPin({required this.av});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.green,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.green.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: _PinImage(path: av.imagenPath),
          ),
        ),
        // Pico del pin
        CustomPaint(
          size: const Size(14, 7),
          painter: _PinTailPainter(),
        ),
      ],
    );
  }
}

class _PinImage extends StatelessWidget {
  final String path;
  const _PinImage({required this.path});

  @override
  Widget build(BuildContext context) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    return const Icon(Icons.flutter_dash, color: AppTheme.white, size: 20);
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.green;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Modal de detalle (RF06 + RF07) ───────────────────────────────────────────

class _DetalleSheet extends StatelessWidget {
  final Avistamiento avistamiento;
  final VoidCallback onGoogleMaps;
  final VoidCallback onWaze;

  const _DetalleSheet({
    required this.avistamiento,
    required this.onGoogleMaps,
    required this.onWaze,
  });

  @override
  Widget build(BuildContext context) {
    final av = avistamiento;
    final conf = av.confianza;
    final color = AppTheme.confidenceColor(conf);
    final dateStr = DateFormat('d MMM yyyy – HH:mm', 'es').format(av.fechaHora);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Imagen + info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: _SheetImage(path: av.imagenPath),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      av.especieNombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.navy,
                      ),
                    ),
                    Text(
                      av.especieCientifico,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${(conf * 100).toStringAsFixed(0)}% confianza',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fecha y coordenadas
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: dateStr,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label:
                '${av.latitud!.toStringAsFixed(5)}, ${av.longitud!.toStringAsFixed(5)}',
          ),

          const SizedBox(height: 20),

          // RF07 – Botones de navegación externa
          const Text(
            'Navegar hasta aquí',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NavButton(
                  label: 'Google Maps',
                  icon: Icons.map_rounded,
                  color: const Color(0xFF4285F4),
                  onTap: onGoogleMaps,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavButton(
                  label: 'Waze',
                  icon: Icons.navigation_rounded,
                  color: const Color(0xFF33CCFF),
                  onTap: onWaze,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetImage extends StatelessWidget {
  final String path;
  const _SheetImage({required this.path});

  @override
  Widget build(BuildContext context) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, width: 90, height: 90, fit: BoxFit.cover);
      }
    } catch (_) {}
    return Container(
      width: 90,
      height: 90,
      color: AppTheme.greenLight,
      child: const Icon(Icons.photo, color: AppTheme.green, size: 36),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 72, color: AppTheme.green.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Sin avistamientos con ubicación',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Guarda un avistamiento con GPS activo\ny aparecerá aquí como un pin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
