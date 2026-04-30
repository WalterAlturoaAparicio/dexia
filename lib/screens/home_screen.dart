import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/prediction.dart';
import '../services/classifier_service.dart';
import 'result_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imagenSeleccionada;
  bool _cargando = false;
  String? _mensajeError;

  // ── Permisos ──────────────────────────────────────────────────────────────

  Future<bool> _solicitarPermisoCamara() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _mostrarDialogoPermiso('Cámara');
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _solicitarPermisoGaleria() async {
    final status = await Permission.photos.request();
    if (status.isPermanentlyDenied) {
      _mostrarDialogoPermiso('Galería de fotos');
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  void _mostrarDialogoPermiso(String permiso) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permiso de $permiso requerido'),
        content: Text(
          'Se necesita acceso a $permiso para clasificar aves. '
          'Habilítalo en los ajustes de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
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

  // ── Selección de imagen ───────────────────────────────────────────────────

  /// Shows a bottom sheet to let the user pick camera or gallery (RF01).
  void _mostrarSelectorFuente() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Seleccionar imagen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.camera_alt),
                ),
                title: const Text('Tomar foto'),
                subtitle: const Text('Usar la cámara del dispositivo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _tomarFoto();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.photo_library),
                ),
                title: const Text('Elegir de galería'),
                subtitle: const Text('Seleccionar una foto existente'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarDeGaleria();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tomarFoto() async {
    if (!await _solicitarPermisoCamara()) return;
    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (xFile != null) await _procesarImagen(xFile);
  }

  Future<void> _seleccionarDeGaleria() async {
    if (!await _solicitarPermisoGaleria()) return;
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile != null) await _procesarImagen(xFile);
  }

  // ── Inferencia (RF02) ─────────────────────────────────────────────────────

  Future<void> _procesarImagen(XFile xFile) async {
    setState(() {
      _imagenSeleccionada = File(xFile.path);
      _cargando = true;
      _mensajeError = null;
    });

    try {
      final Uint8List bytes = await xFile.readAsBytes();
      final ResultadoInferencia resultado =
          await ClassifierService.instance.classify(bytes);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imagenFile: _imagenSeleccionada!,
            resultado: resultado,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _mensajeError = 'Error al clasificar: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('DexIA Aves'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis avistamientos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen preview
              Expanded(
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          _imagenSeleccionada!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _PlaceholderImagen(colorScheme: colorScheme),
              ),

              const SizedBox(height: 24),

              if (_cargando)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Identificando ave…',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                  ],
                ),

              if (_mensajeError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _mensajeError!,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Single CTA button – opens source picker (RF01)
              FilledButton.icon(
                onPressed: _cargando ? null : _mostrarSelectorFuente,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Identificar ave'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

class _PlaceholderImagen extends StatelessWidget {
  final ColorScheme colorScheme;
  const _PlaceholderImagen({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined,
              size: 72, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Toca el botón para fotografiar\no seleccionar un ave',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
