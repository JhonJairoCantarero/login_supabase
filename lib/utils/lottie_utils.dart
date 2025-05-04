import 'dart:math';

class LottieUtils {
  // Lista de animaciones disponibles
  static final List<String> animations = [
    'assets/lotties/Animation - 1745609576976.json',
    'assets/lotties/Animation - 1745609625667.json',
    'assets/lotties/Animation - 1745609680532.json',
    'assets/lotties/Animation - 1745609769527.json',
    'assets/lotties/Animation - 1745609837064.json',
    'assets/lotties/Animation - 1745609884762.json',
    'assets/lotties/Animation - 1745609904853.json',
    'assets/lotties/Animation - 1745609954961.json',
  ];

  // Obtener una animación aleatoria
  static String getRandomAnimation() {
    final random = Random();
    return animations[random.nextInt(animations.length)];
  }
} 