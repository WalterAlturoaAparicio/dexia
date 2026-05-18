class BirdClass {
  final int index;
  final String id;
  final String nombre;
  final String cientifico;

  const BirdClass({
    required this.index,
    required this.id,
    required this.nombre,
    required this.cientifico,
  });

  Map<String, dynamic> toMap() => {
        'index': index,
        'id': id,
        'nombre': nombre,
        'cientifico': cientifico,
      };

  factory BirdClass.fromMap(Map<String, dynamic> m) => BirdClass(
        index: m['index'] as int,
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        cientifico: m['cientifico'] as String,
      );
}

class Prediction {
  final BirdClass ave;
  final double confianza;

  const Prediction({required this.ave, required this.confianza});
}

class ResultadoInferencia {
  final List<Prediction> top3;
  final Duration tiempoInferencia;

  const ResultadoInferencia({
    required this.top3,
    required this.tiempoInferencia,
  });
}

/// Un avistamiento guardado localmente (RF08 + RF05).
class Avistamiento {
  final int? id;
  final String imagenPath;
  final String especieNombre;
  final String especieCientifico;
  final String especieId;
  final double confianza;
  final DateTime fechaHora;
  final bool synced;

  // RF05 – Georreferenciación
  final double? latitud;
  final double? longitud;
  final String? direccion; // reverse-geocode opcional (futuro)

  const Avistamiento({
    this.id,
    required this.imagenPath,
    required this.especieNombre,
    required this.especieCientifico,
    required this.especieId,
    required this.confianza,
    required this.fechaHora,
    this.synced = false,
    this.latitud,
    this.longitud,
    this.direccion,
  });

  bool get tieneUbicacion => latitud != null && longitud != null;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'imagenPath': imagenPath,
        'especieNombre': especieNombre,
        'especieCientifico': especieCientifico,
        'especieId': especieId,
        'confianza': confianza,
        'fechaHora': fechaHora.toIso8601String(),
        'synced': synced ? 1 : 0,
        'latitud': latitud,
        'longitud': longitud,
        'direccion': direccion,
      };

  factory Avistamiento.fromMap(Map<String, dynamic> m) => Avistamiento(
        id: m['id'] as int?,
        imagenPath: m['imagenPath'] as String,
        especieNombre: m['especieNombre'] as String,
        especieCientifico: m['especieCientifico'] as String,
        especieId: m['especieId'] as String,
        confianza: (m['confianza'] as num).toDouble(),
        fechaHora: DateTime.parse(m['fechaHora'] as String),
        synced: (m['synced'] as int) == 1,
        latitud: m['latitud'] as double?,
        longitud: m['longitud'] as double?,
        direccion: m['direccion'] as String?,
      );

  Avistamiento copyWith({
    bool? synced,
    int? id,
    double? latitud,
    double? longitud,
    String? direccion,
  }) =>
      Avistamiento(
        id: id ?? this.id,
        imagenPath: imagenPath,
        especieNombre: especieNombre,
        especieCientifico: especieCientifico,
        especieId: especieId,
        confianza: confianza,
        fechaHora: fechaHora,
        synced: synced ?? this.synced,
        latitud: latitud ?? this.latitud,
        longitud: longitud ?? this.longitud,
        direccion: direccion ?? this.direccion,
      );
}
