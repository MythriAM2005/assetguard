import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/room_prediction_model.dart';
import '../utils/api_config.dart';

/// Calls the Python ML API directly to predict the current room from a
/// Wi-Fi fingerprint.
///
/// Flutter → Python ML API POST /predict-room (DIRECT)
///
/// Previously routed through Node.js backend, now calls ML server directly
/// for better performance and to match the deployed architecture.
class RoomPredictionService {
  RoomPredictionService._();
  static final RoomPredictionService instance = RoomPredictionService._();

  /// Predict the room from a map of { bssid: rssiDbm }.
  ///
  /// [wifi] must contain at least one entry.
  ///
  /// Throws [RoomPredictionException] on network errors, HTTP errors, or when
  /// the ML service is unavailable.
  Future<RoomPredictionResult> predictRoom(Map<String, int> wifi) async {
    if (wifi.isEmpty) {
      throw const RoomPredictionException(
        'No Wi-Fi access points available. Scan first.',
      );
    }

    debugPrint('[RoomPrediction] Requesting prediction for ${wifi.length} BSSIDs');
    debugPrint('[RoomPrediction] ML API: ${ApiConfig.mlBaseUrl}');

    final url = Uri.parse('${ApiConfig.mlBaseUrl}/predict-room');
    
    // The Python FastAPI endpoint expects: { "wifi": { bssid: rssi } }
    final requestBody = {'wifi': wifi};

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            ApiConfig.mlTimeout,
            onTimeout: () => throw const RoomPredictionException(
              'Room prediction timed out. The ML service may be waking up (Render cold start). Please try again.',
            ),
          );

      debugPrint('[RoomPrediction] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[RoomPrediction] Raw response: $data');
        return RoomPredictionResult.fromJson(data);
      } else if (response.statusCode >= 500) {
        throw RoomPredictionException(
          'ML server error (HTTP ${response.statusCode}). Please try again.',
        );
      } else if (response.statusCode == 404) {
        throw const RoomPredictionException(
          'ML prediction endpoint not found. Please check API configuration.',
        );
      } else {
        final body = response.body;
        debugPrint('[RoomPrediction] Error response: $body');
        throw RoomPredictionException(
          'Room prediction failed (HTTP ${response.statusCode})',
        );
      }
    } on SocketException catch (e) {
      debugPrint('[RoomPrediction] Network error: $e');
      throw const RoomPredictionException(
        'Cannot reach the ML service. Check your network connection.',
      );
    } on RoomPredictionException {
      rethrow;
    } catch (e) {
      debugPrint('[RoomPrediction] Unexpected error: $e');
      throw RoomPredictionException('Unexpected error: $e');
    }
  }
}

/// Exception for room prediction errors.
class RoomPredictionException implements Exception {
  final String message;
  const RoomPredictionException(this.message);

  @override
  String toString() => message;
}
