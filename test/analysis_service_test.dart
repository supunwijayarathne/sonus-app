import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:sonus_app/models/analysis_result.dart';
import 'package:sonus_app/services/analysis_service.dart';

/// The JSON the FastAPI service returns (CLAUDE.md), for "මල" heard as "මර".
const _serviceJson = {
  'quality': {'ok': true, 'reason': null, 'duration_s': 0.84},
  'expected': ['m', 'a', 'l', 'ə'],
  'predicted': ['m', 'a', 'r', 'ə'],
  'ops': [
    {'op': 'match', 'expected': 'm', 'predicted': 'm', 'position': 0},
    {'op': 'match', 'expected': 'a', 'predicted': 'a', 'position': 1},
    {'op': 'sub', 'expected': 'l', 'predicted': 'r', 'position': 2},
    {'op': 'match', 'expected': 'ə', 'predicted': 'ə', 'position': 3},
  ],
  'match_percent': 75.0,
  'model_version': 'mms300m-L12-bilstm-ctc',
  'g2p_version': 'inv-v1.1+cff96fb2',
};

void main() {
  late String audioPath;

  setUp(() {
    final dir = Directory.systemTemp.createTempSync('sonus_test');
    audioPath = '${dir.path}/attempt.wav';
    File(audioPath).writeAsBytesSync([82, 73, 70, 70]); // contents don't matter here
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  HttpAnalysisService service(MockClientHandler handler) => HttpAnalysisService(
    Uri.parse('http://10.0.2.2:8000'),
    client: MockClient(handler),
  );

  test('uploads the recording and the text, reads the result', () async {
    late http.Request sent;
    final s = service((request) async {
      sent = request;
      return http.Response.bytes(
        utf8.encode(jsonEncode(_serviceJson)),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final result = await s.analyze(text: 'මල', audioPath: audioPath);

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'http://10.0.2.2:8000/analyze');
    final body = utf8.decode(sent.bodyBytes);
    expect(body, contains('name="audio"'));
    expect(body, contains('name="text"'));
    expect(body, contains('මල'));

    expect(result.matchPercent, 75.0);
    expect(result.predicted, ['m', 'a', 'r', 'ə']);
    final sub = result.ops.singleWhere((o) => o.isDifference);
    expect(sub.kind, OpKind.sub);
    expect((sub.expected, sub.predicted), ('l', 'r'));
  });

  test('server error: a friendly message', () async {
    final s = service((_) async => http.Response('{"detail":"x"}', 422));
    await expectLater(
      s.analyze(text: 'abc', audioPath: audioPath),
      throwsA(
        isA<AnalysisException>().having(
          (e) => e.message,
          'message',
          AnalysisException.failed,
        ),
      ),
    );
  });

  test('no server: asks to check the connection', () async {
    final s = service((_) async => throw const SocketException('refused'));
    await expectLater(
      s.analyze(text: 'මල', audioPath: audioPath),
      throwsA(
        isA<AnalysisException>().having(
          (e) => e.message,
          'message',
          AnalysisException.unreachable,
        ),
      ),
    );
  });

  test('a reply that is not the result JSON', () async {
    final s = service((_) async => http.Response('<html>', 200));
    await expectLater(
      s.analyze(text: 'මල', audioPath: audioPath),
      throwsA(isA<AnalysisException>()),
    );
  });
}
