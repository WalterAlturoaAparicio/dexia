import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/prediction.dart';
import '../services/classifier_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'result_screen.dart';
import 'vr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _cargando = false;
  int _totalAvistamientos = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final lista = await DatabaseService.instance.getAllAvistamientos();
    if (mounted) setState(() => _totalAvistamientos = lista.length);
  }

  Future<bool> _pedirPermisoCamara() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied && mounted) {
      _mostrarDialogoPermiso('Cámara');
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _pedirPermisoGaleria() async {
    final status = await Permission.photos.request();
    if (status.isPermanentlyDenied && mounted) {
      _mostrarDialogoPermiso('Galería');
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  void _mostrarDialogoPermiso(String tipo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Permiso de $tipo'),
        content: Text('La app necesita acceso a $tipo para identificar aves.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  void _mostrarSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Cómo identificamos el ave?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.navy,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Cámara',
                      onTap: () {
                        Navigator.pop(ctx);
                        _tomarFoto();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galería',
                      onTap: () {
                        Navigator.pop(ctx);
                        _seleccionarGaleria();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tomarFoto() async {
    if (!await _pedirPermisoCamara()) return;
    final xFile = await _picker.pickImage(
        source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 90);
    if (xFile != null) await _procesarImagen(xFile);
  }

  Future<void> _seleccionarGaleria() async {
    if (!await _pedirPermisoGaleria()) return;
    final xFile = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (xFile != null) await _procesarImagen(xFile);
  }

  Future<void> _procesarImagen(XFile xFile) async {
    setState(() => _cargando = true);
    try {
      final Uint8List bytes = await xFile.readAsBytes();
      final ResultadoInferencia resultado =
          await ClassifierService.instance.classify(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) =>
              ResultScreen(imagenFile: File(xFile.path), resultado: resultado),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      _loadCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al clasificar: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('DexIA Aves'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.green,
              child: Text('MG',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Qué ave veremos hoy?',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy)),
              const SizedBox(height: 4),
              Text('$_totalAvistamientos avistamientos guardados',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 20),

              // 2×2 grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  MainButtonCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    subtitle: 'Identificar ave',
                    accent: true,
                    onTap: _cargando ? () {} : _mostrarSelector,
                  ),
                  MainButtonCard(
                    icon: Icons.map_rounded,
                    label: 'Mapa',
                    subtitle: 'Mis avistamientos',
                    iconBg: const Color(0xFFE8EEF5),
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, a, __) => const MapScreen(),
                        transitionsBuilder: (_, a, __, child) =>
                            FadeTransition(opacity: a, child: child),
                        transitionDuration:
                            const Duration(milliseconds: 250),
                      ),
                    ),
                  ),
                  MainButtonCard(
                    icon: Icons.history_rounded,
                    label: 'Historial',
                    subtitle: 'Ver registros',
                    iconBg: const Color(0xFFFEF5E7),
                    badge: _totalAvistamientos,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a, __) => const HistoryScreen(),
                          transitionsBuilder: (_, a, __, child) =>
                              FadeTransition(opacity: a, child: child),
                          transitionDuration: const Duration(milliseconds: 250),
                        ),
                      );
                      _loadCount();
                    },
                  ),
                  MainButtonCard(
                    icon: Icons.view_in_ar_rounded,
                    label: 'Álbum 3D',
                    subtitle: 'Bosque virtual',
                    iconBg: const Color(0xFFE8F5D0),
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, a, __) => const VrScreen(),
                        transitionsBuilder: (_, a, __, child) =>
                            FadeTransition(opacity: a, child: child),
                        transitionDuration:
                            const Duration(milliseconds: 300),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _StreakCard(total: _totalAvistamientos),

              if (_cargando) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.navy,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.green),
                      ),
                      SizedBox(width: 12),
                      Text('Identificando ave…',
                          style: TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.greenLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border:
              Border.all(color: AppTheme.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppTheme.greenDark),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy)),
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int total;
  const _StreakCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sigue explorando',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text('$total aves identificadas',
                    style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.green,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Text('¡A buscar!',
                style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
