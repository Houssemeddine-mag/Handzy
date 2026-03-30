/// Represents a single hand landmark point from MediaPipe
class HandLandmark {
  final int id;
  final double x;
  final double y;
  final double z;

  HandLandmark({
    required this.id,
    required this.x,
    required this.y,
    required this.z,
  });

  factory HandLandmark.fromMap(Map<dynamic, dynamic> map) {
    return HandLandmark(
      id: map['id'] as int,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      z: (map['z'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'z': z,
    };
  }

  @override
  String toString() => 'HandLandmark(id: $id, x: $x, y: $y, z: $z)';
}

/// MediaPipe Hand Landmark indices
class LandmarkIndex {
  static const int wrist = 0;
  static const int thumbCMC = 1;
  static const int thumbMCP = 2;
  static const int thumbIP = 3;
  static const int thumbTip = 4;
  static const int indexMCP = 5;
  static const int indexPIP = 6;
  static const int indexDIP = 7;
  static const int indexTip = 8;
  static const int middleMCP = 9;
  static const int middlePIP = 10;
  static const int middleDIP = 11;
  static const int middleTip = 12;
  static const int ringMCP = 13;
  static const int ringPIP = 14;
  static const int ringDIP = 15;
  static const int ringTip = 16;
  static const int pinkyMCP = 17;
  static const int pinkyPIP = 18;
  static const int pinkyDIP = 19;
  static const int pinkyTip = 20;
}

/// Represents a complete set of hand landmarks
class HandLandmarks {
  final List<HandLandmark> landmarks;
  final DateTime timestamp;

  HandLandmarks({
    required this.landmarks,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory HandLandmarks.fromList(List<dynamic> list) {
    return HandLandmarks(
      landmarks: list.map((e) => HandLandmark.fromMap(e as Map)).toList(),
    );
  }

  HandLandmark? getLandmark(int index) {
    if (index < 0 || index >= landmarks.length) return null;
    return landmarks.firstWhere(
      (l) => l.id == index,
      orElse: () => landmarks[index],
    );
  }

  HandLandmark get wrist => landmarks[LandmarkIndex.wrist];
  HandLandmark get thumbTip => landmarks[LandmarkIndex.thumbTip];
  HandLandmark get indexTip => landmarks[LandmarkIndex.indexTip];
  HandLandmark get middleTip => landmarks[LandmarkIndex.middleTip];
  HandLandmark get ringTip => landmarks[LandmarkIndex.ringTip];
  HandLandmark get pinkyTip => landmarks[LandmarkIndex.pinkyTip];

  @override
  String toString() => 'HandLandmarks(${landmarks.length} landmarks)';
}
