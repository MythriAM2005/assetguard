/// A single entry in the top-3 prediction list.
class RoomPredictionEntry {
  /// Room label, e.g. "306"
  final String room;

  /// Probability in the range [0.0, 1.0]
  final double probability;

  const RoomPredictionEntry({
    required this.room,
    required this.probability,
  });

  factory RoomPredictionEntry.fromJson(Map<String, dynamic> json) {
    return RoomPredictionEntry(
      room:        (json['room'] ?? '?').toString(),
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Probability as a formatted percentage string, e.g. "28%"
  String get probabilityPercent => '${(probability * 100).round()}%';
}

/// The full prediction response from the Python ML API.
class RoomPredictionResult {
  /// The top predicted room, e.g. "306" or "101"
  final String predictedRoom;

  /// Confidence of the top prediction in the range [0.0, 1.0]
  final double confidence;

  /// Up to 3 ranked predictions
  final List<RoomPredictionEntry> top3;

  /// Number of BSSIDs received in the request
  final int? receivedBssids;

  /// Number of BSSIDs matched with the model's features
  final int? matchedBssids;

  /// Total number of features in the model (should be 105)
  final int? modelFeatures;

  const RoomPredictionResult({
    required this.predictedRoom,
    required this.confidence,
    required this.top3,
    this.receivedBssids,
    this.matchedBssids,
    this.modelFeatures,
  });

  /// Pre-formatted confidence string, e.g. "28%"
  String get confidencePercent => '${(confidence * 100).round()}%';

  /// Parse the Python ML API `/predict-room` response.
  ///
  /// Expected JSON shape from https://wifi-server-sl6b.onrender.com:
  /// ```json
  /// {
  ///   "room": "101",
  ///   "confidence": 0.26,
  ///   "top_predictions": [
  ///     { "room": "101", "probability": 0.26 },
  ///     { "room": "306", "probability": 0.083333 },
  ///     { "room": "109", "probability": 0.08 }
  ///   ],
  ///   "received_bssids": 37,
  ///   "matched_bssids": 35,
  ///   "model_features": 105
  /// }
  /// ```
  factory RoomPredictionResult.fromJson(Map<String, dynamic> json) {
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    // Python ML API uses "top_predictions" (snake_case)
    final rawTop = json['top_predictions'] ?? json['top3'];
    final top3 = <RoomPredictionEntry>[];
    if (rawTop is List) {
      for (final entry in rawTop) {
        if (entry is Map<String, dynamic>) {
          top3.add(RoomPredictionEntry.fromJson(entry));
        }
      }
    }

    return RoomPredictionResult(
      // Python API uses "room" not "predictedRoom"
      predictedRoom:    (json['room'] ?? json['predictedRoom'] ?? 'Unknown').toString(),
      confidence:       confidence,
      top3:             top3,
      receivedBssids:   json['received_bssids'] as int?,
      matchedBssids:    json['matched_bssids'] as int?,
      modelFeatures:    json['model_features'] as int?,
    );
  }
}
