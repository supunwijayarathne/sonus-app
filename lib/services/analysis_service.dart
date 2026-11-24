import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/mock_data.dart';
import '../models/analysis_result.dart';

/// Sends a recording to the analysis service and returns the result.
///
/// The app only talks to this interface: [HttpAnalysisService] calls the
/// FastAPI service (`../sonus/service/`), [MockAnalysisService] returns canned
/// results (widget tests, or `--dart-define=ANALYSIS_URL=mock`).
abstract class AnalysisService {
  /// Throws [AnalysisException] when no result could be produced.
  Future<AnalysisResult> analyze({
    required String text,
    required String audioPath,
  });
}

/// The service the app uses. Set in main(); tests keep the mock.
AnalysisService analysisService = MockAnalysisService();

/// Where the analysis service runs. The Android emulator reaches the laptop
/// at 10.0.2.2. A real phone needs the laptop's address on the same Wi-Fi:
///   flutter run --dart-define=ANALYSIS_URL=http://192.168.1.20:8000
const analysisUrl = String.fromEnvironment(
  'ANALYSIS_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// The service named by [analysisUrl] ("mock" = no server).
AnalysisService analysisServiceFromConfig() => analysisUrl == 'mock'
    ? MockAnalysisService()
    : HttpAnalysisService(Uri.parse(analysisUrl));

/// A recording that could not be analysed, with a message for the user.
class AnalysisException implements Exception {
  const AnalysisException(this.message);

  final String message;

  static const unreachable =
      'The analysis service could not be reached. Please check your '
      'connection and record again.';
  static const failed =
      'The recording could not be analysed. Please record again.';

  @override
  String toString() => message;
}

/// `POST /analyze` (multipart: the recording file + the Sinhala text).
class HttpAnalysisService implements AnalysisService {
  HttpAnalysisService(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  /// The model runs on a CPU (~3 s per recording); allow for a slow network.
  static const timeout = Duration(seconds: 60);

  @override
  Future<AnalysisResult> analyze({
    required String text,
    required String audioPath,
  }) async {
    final request = http.MultipartRequest('POST', baseUrl.resolve('/analyze'))
      ..fields['text'] = text
      ..files.add(await http.MultipartFile.fromPath('audio', audioPath));

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      );
    } catch (_) {
      // No server, no network, or too slow.
      throw const AnalysisException(AnalysisException.unreachable);
    }
    if (response.statusCode != 200) {
      throw const AnalysisException(AnalysisException.failed);
    }
    try {
      // The body is UTF-8 (IPA symbols such as ə); decode it explicitly.
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return AnalysisResult.fromJson(Map<String, dynamic>.from(json as Map));
    } catch (_) {
      throw const AnalysisException(AnalysisException.failed);
    }
  }
}

/// Returns canned results (same JSON as the real service) after a short delay.
class MockAnalysisService implements AnalysisService {
  @override
  Future<AnalysisResult> analyze({
    required String text,
    required String audioPath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return AnalysisResult.fromJson(MockData.analysisJsonFor(text));
  }
}
