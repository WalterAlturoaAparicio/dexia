import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

import '../models/prediction.dart';

class ClassifierService {
  ClassifierService._internal();
  static final ClassifierService _instance = ClassifierService._internal();
  static ClassifierService get instance => _instance;

  OrtSession? _session;
  List<BirdClass>? _classes;
  String? _inputName;
  bool _isInitialized = false;

  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];
  static const int _inputSize = 224;
  static const int _numClasses = 16;

  bool get isReady => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    OrtEnv.instance.init();

    final modelBytes =
        await rootBundle.load('assets/efficientnet_b0_best.onnx');
    final modelUint8 = modelBytes.buffer.asUint8List();

    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(modelUint8, sessionOptions);

    // Detect input node name at runtime
    _inputName = _session!.inputNames.first;

    final classJson = await rootBundle.loadString('assets/classes.json');
    final classMap = jsonDecode(classJson) as Map<String, dynamic>;
    _classes = List.generate(_numClasses, (i) {
      final entry = classMap[i.toString()] as Map<String, dynamic>;
      return BirdClass(
        index: i,
        id: entry['id'] as String,
        nombre: entry['nombre'] as String,
        cientifico: entry['cientifico'] as String,
      );
    });

    _isInitialized = true;
  }

  Future<ResultadoInferencia> classify(Uint8List imageBytes) async {
    if (!_isInitialized || _session == null || _classes == null) {
      throw StateError('ClassifierService no inicializado.');
    }

    final stopwatch = Stopwatch()..start();

    final inputTensor = _preprocess(imageBytes);

    final runOptions = OrtRunOptions();
    final outputs =
        await _session!.runAsync(runOptions, {_inputName!: inputTensor});

    stopwatch.stop();

    final rawOutput = outputs![0]!.value;
    final List<double> logits;
    if (rawOutput is List<List<double>>) {
      logits = rawOutput[0];
    } else if (rawOutput is List<double>) {
      logits = rawOutput;
    } else {
      throw StateError('Formato de salida ONNX inesperado: ${rawOutput.runtimeType}');
    }

    final probs = _softmax(logits);

    final indexed =
        List.generate(probs.length, (i) => MapEntry(i, probs[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    final top3 = indexed.take(3).map((e) => Prediction(
          ave: _classes![e.key],
          confianza: e.value,
        )).toList();

    inputTensor.release();
    for (final o in outputs) {
      o?.release();
    }
    runOptions.release();

    return ResultadoInferencia(top3: top3, tiempoInferencia: stopwatch.elapsed);
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
    _isInitialized = false;
  }

  OrtValueTensor _preprocess(Uint8List rawBytes) {
    img.Image decoded = img.decodeImage(rawBytes)!;
    img.Image resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final Float32List buffer =
        Float32List(1 * 3 * _inputSize * _inputSize);

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final r = (pixel.rNormalized - _mean[0]) / _std[0];
        final g = (pixel.gNormalized - _mean[1]) / _std[1];
        final b = (pixel.bNormalized - _mean[2]) / _std[2];

        buffer[0 * _inputSize * _inputSize + y * _inputSize + x] = r;
        buffer[1 * _inputSize * _inputSize + y * _inputSize + x] = g;
        buffer[2 * _inputSize * _inputSize + y * _inputSize + x] = b;
      }
    }

    return OrtValueTensor.createTensorWithDataList(
      buffer,
      [1, 3, _inputSize, _inputSize],
    );
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }
}
