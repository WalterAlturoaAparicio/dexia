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
