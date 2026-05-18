import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/prediction.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class VrScreen extends StatefulWidget {
  const VrScreen({super.key});

  @override
  State<VrScreen> createState() => _VrScreenState();
}

class _VrScreenState extends State<VrScreen> {
  List<Avistamiento> _avistamientos = [];
  bool _cargando = true;
  bool _modoVr = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final lista = await DatabaseService.instance.getAllAvistamientos();
    // Deduplicar por especie para el álbum
    final Map<String, Avistamiento> vistos = {};
    for (final av in lista) {
      vistos.putIfAbsent(av.especieId, () => av);
    }
    if (mounted) {
      setState(() {
        _avistamientos = vistos.values.toList();
        _cargando = false;
      });
    }
  }

  void _entrarModoVr() {
    if (_avistamientos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Guarda al menos un avistamiento para explorar el bosque 🌿'),
          backgroundColor: AppTheme.navy,
        ),
      );
      return;
    }
    setState(() => _modoVr = true);
    // Landscape for immersion
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  void _salirModoVr() {
    setState(() => _modoVr = false);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_modoVr) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didpop, result) => _salirModoVr(),
        child: Scaffold(
          body: _VrWebView(
            avistamientos: _avistamientos,
            onExit: _salirModoVr,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Álbum de aves'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.green))
          : Column(
              children: [
                // ── Botón explorar en 3D ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _ExploreButton(
                    count: _avistamientos.length,
                    onTap: _entrarModoVr,
                  ),
                ),

                // ── Album grid ───────────────────────────────────────
                Expanded(
                  child: _avistamientos.isEmpty
                      ? _EmptyAlbum()
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _avistamientos.length,
                          itemBuilder: (_, i) =>
                              _AlbumCard(av: _avistamientos[i]),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Album card widget
// ─────────────────────────────────────────────────────────────────────────────
class _AlbumCard extends StatelessWidget {
  final Avistamiento av;
  const _AlbumCard({required this.av});

  @override
  Widget build(BuildContext context) {
    final conf = av.confianza;
    final color = AppTheme.confidenceColor(conf);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CardImage(path: av.imagenPath),
                // Confidence badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${(conf * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // GPS badge
                if (av.tieneUbicacion)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(Icons.location_on_rounded,
                        size: 16, color: Colors.white),
                  ),
              ],
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  av.especieNombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  av.especieCientifico,
                  style: const TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String path;
  const _CardImage({required this.path});

  @override
  Widget build(BuildContext context) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover);
      }
    } catch (_) {}
    return Container(
      color: AppTheme.greenLight,
      child: const Icon(Icons.flutter_dash, size: 48, color: AppTheme.green),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Explore button
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ExploreButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a3d1a), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.green.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.green.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(Icons.view_in_ar_rounded,
                  size: 28, color: AppTheme.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explorar en 3D',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$count ave${count != 1 ? 's' : ''} en tu bosque virtual',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.green,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Text(
                '¡Entrar!',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VR WebView – loads vr_scene.html with injected bird data
// ─────────────────────────────────────────────────────────────────────────────
class _VrWebView extends StatefulWidget {
  final List<Avistamiento> avistamientos;
  final VoidCallback onExit;

  const _VrWebView({required this.avistamientos, required this.onExit});

  @override
  State<_VrWebView> createState() => _VrWebViewState();
}

class _VrWebViewState extends State<_VrWebView> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // Build JSON payload for each unique bird
    final birdJson = widget.avistamientos.map((av) {
      // Convert local file path to data URI so WebView can load it
      String imagePath = '';
      try {
        final f = File(av.imagenPath);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          final b64 = base64Encode(bytes);
          imagePath = 'data:image/jpeg;base64,$b64';
        }
      } catch (_) {}

      return {
        'nombre': av.especieNombre,
        'cientifico': av.especieCientifico,
        'especieId': av.especieId,
        'confianza': av.confianza,
        'fecha': _formatFecha(av.fechaHora),
        'tieneUbicacion': av.tieneUbicacion,
        'imagePath': imagePath,
        'color': _colorForIndex(widget.avistamientos.indexOf(av)),
      };
    }).toList();

    // Load HTML template and inject data
    String html = await rootBundle.loadString('assets/vr_scene.html');
    final jsonStr = jsonEncode(birdJson);
    html = html.replaceFirst('__BIRD_DATA__', jsonStr);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (msg) {
          if (msg.message == 'exit') widget.onExit();
        },
      )
      ..loadHtmlString(html, baseUrl: 'https://localhost');

    if (mounted) setState(() => _ready = true);
  }

  String _formatFecha(DateTime dt) {
    final months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _colorForIndex(int i) {
    const colors = [
      '#80BA27',
      '#27AE60',
      '#2980B9',
      '#8E44AD',
      '#E67E22',
      '#E74C3C',
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF0d1f0d),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF80BA27)),
              SizedBox(height: 16),
              Text('Cargando bosque…',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _controller);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyAlbum extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 72, color: AppTheme.green.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Tu álbum está vacío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Identifica y guarda aves para\nverlas aparecer en tu bosque 3D.',
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
