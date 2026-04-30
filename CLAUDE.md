# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Get/update dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Run on a specific device
flutter run -d <device-id>          # list devices: flutter devices

# Build release APK (Android)
flutter build apk --release

# Build release IPA (iOS, requires macOS + Xcode)
flutter build ios --release

# Analyze code (lint)
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

### Inference pipeline (the core of the app)

`ClassifierService` (`lib/services/classifier_service.dart`) is a singleton initialized once in `main()` before `runApp`. It owns the `OrtSession` for the lifetime of the app.

Classify flow:
1. `Uint8List` → `img.decodeImage` → `img.copyResize(224×224, linear)` → pixel loop → `Float32List` NCHW `[1, 3, 224, 224]`
2. ImageNet normalization per channel: `(normalized_value - mean[c]) / std[c]`
3. `_session!.runAsync({_inputName: tensor})` → raw logits `[1, 16]`
4. Softmax → sort descending → top-3 `List<Prediction>`
5. All `OrtValue` handles released after reading

The ONNX input node name is discovered at init time via `_session!.inputNames.first` (stored in `_inputName`). If the model changes, no code change is needed for the input name.

### Data model

```
BirdClass      — index, id (slug), nombre (Spanish), cientifico
Prediction     — ave: BirdClass, confianza: double (0–1)
ResultadoInferencia — top3: List<Prediction>, tiempoInferencia: Duration
```

### Screen flow

```
main() → initialize() → HomeScreen
  ├─ camera / gallery → XFile → classify() → ResultScreen
  └─ ResultScreen → pop → HomeScreen
```

`HomeScreen` manages permission requests (`permission_handler`), image picking (`image_picker`), and passes raw bytes to `ClassifierService`. It owns the `_cargando` loading state shown during inference.

`ResultScreen` is stateless — receives `File` + `ResultadoInferencia` and renders the top-3 predictions.

### Assets

| File | Purpose |
|---|---|
| `assets/efficientnet_b0_best.onnx` | EfficientNet-B0 weights, 16 classes, 16 MB |
| `assets/classes.json` | Maps index (string key `"0"`–`"15"`) to `{id, nombre, cientifico}` |

Class order in `classes.json` must match the training label order (ardea-alba=0 … zenaida-auriculata=15).

### Permissions

- **Android**: `CAMERA`, `READ_EXTERNAL_STORAGE` (≤API 32), `READ_MEDIA_IMAGES` (API 33+) — declared in `android/app/src/main/AndroidManifest.xml`
- **iOS**: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` — declared in `ios/Runner/Info.plist`

### Resource lifecycle

`ClassifierService.dispose()` releases the `OrtSession` and `OrtEnv`. It is called from `_DexIAAppState` on `dispose()` and on `AppLifecycleState.detached`.

## Key constraints

- `OrtSession` is **not** `SendPort`-serializable — it cannot be moved to a Dart `Isolate`. Inference runs on the main isolate via `runAsync` (non-blocking).
- The `image` package v4.x uses `pixel.rNormalized` (returns `double` 0–1). Do not use the v3 integer API.
- `classes.json` uses string keys (`"0"`, `"1"`, …) not integer keys — `jsonDecode` in Dart always returns `Map<String, dynamic>` for JSON objects.
