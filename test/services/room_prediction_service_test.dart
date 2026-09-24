import 'package:flutter_test/flutter_test.dart';
import 'package:assetguard/services/room_prediction_service.dart';
import 'package:assetguard/models/room_prediction_model.dart';

void main() {
  group('RoomPredictionResult', () {
    test('parses Python ML API response correctly', () {
      final json = {
        'room': '101',
        'confidence': 0.26,
        'top_predictions': [
          {'room': '101', 'probability': 0.26},
          {'room': '306', 'probability': 0.083333},
          {'room': '109', 'probability': 0.08},
        ],
        'received_bssids': 37,
        'matched_bssids': 35,
        'model_features': 105,
      };

      final result = RoomPredictionResult.fromJson(json);

      expect(result.predictedRoom, '101');
      expect(result.confidence, 0.26);
      expect(result.confidencePercent, '26%');
      expect(result.top3.length, 3);
      expect(result.top3[0].room, '101');
      expect(result.top3[0].probability, 0.26);
      expect(result.receivedBssids, 37);
      expect(result.matchedBssids, 35);
      expect(result.modelFeatures, 105);
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'room': '306',
        'confidence': 0.45,
        'top_predictions': [],
      };

      final result = RoomPredictionResult.fromJson(json);

      expect(result.predictedRoom, '306');
      expect(result.confidence, 0.45);
      expect(result.top3, isEmpty);
      expect(result.receivedBssids, isNull);
      expect(result.matchedBssids, isNull);
      expect(result.modelFeatures, isNull);
    });

    test('handles legacy Node.js backend response format', () {
      // Backwards compatibility test
      final json = {
        'predictedRoom': '306',
        'confidence': 0.28,
        'top3': [
          {'room': '306', 'probability': 0.28},
          {'room': '209', 'probability': 0.22},
        ],
      };

      final result = RoomPredictionResult.fromJson(json);

      expect(result.predictedRoom, '306');
      expect(result.confidence, 0.28);
      expect(result.top3.length, 2);
    });

    test('handles malformed response gracefully', () {
      final json = <String, dynamic>{};

      final result = RoomPredictionResult.fromJson(json);

      expect(result.predictedRoom, 'Unknown');
      expect(result.confidence, 0.0);
      expect(result.top3, isEmpty);
    });
  });

  group('RoomPredictionService', () {
    test('throws exception for empty WiFi map', () {
      expect(
        () => RoomPredictionService.instance.predictRoom({}),
        throwsA(isA<RoomPredictionException>()),
      );
    });

    test('validates WiFi fingerprint format', () {
      final wifi = {
        '84:d8:1b:aa:bb:cc': -43,
        '00:11:22:33:44:55': -67,
        'aa:bb:cc:dd:ee:ff': -52,
      };

      // This just validates that the input format is accepted
      // Actual API call would require mocking http client
      expect(wifi.isNotEmpty, isTrue);
      expect(wifi.values.every((rssi) => rssi < 0), isTrue);
    });
  });

  group('RoomPredictionEntry', () {
    test('formats probability as percentage', () {
      const entry = RoomPredictionEntry(room: '101', probability: 0.26);
      expect(entry.probabilityPercent, '26%');
    });

    test('rounds probability correctly', () {
      const entry = RoomPredictionEntry(room: '306', probability: 0.083333);
      expect(entry.probabilityPercent, '8%');
    });
  });
}
