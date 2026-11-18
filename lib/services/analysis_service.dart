import '../data/mock_data.dart';
import '../models/analysis_result.dart';

/// Sends a recording to the analysis service and returns the result.
///
/// The app only talks to this interface. Today it is [MockAnalysisService];
/// when the FastAPI service exists, an `HttpAnalysisService` implements the
/// same interface and [analysisService] below is the only line that changes.
abstract class AnalysisService {
  Future<AnalysisResult> analyze({
    required String text,
    required String audioPath,
  });
}

/// The service the app uses.
final AnalysisService analysisService = MockAnalysisService();

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
