// Memastikan unduh dokumen pada HP memakai dialog sistem, termasuk pembatalan.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:campus_app/data/biodata_repository.dart';
import 'package:campus_app/features/profile/profile_records.dart';

import 'support/supabase_fixture.dart';

class TestSharePlatform extends SharePlatform {
  ShareParams? received;
  bool fail = false;
  @override
  Future<ShareResult> share(ShareParams params) async {
    received = params;
    if (fail) throw Exception('Native share unavailable');
    return const ShareResult('', ShareResultStatus.dismissed);
  }
}

void main() {
  final platform = TestSharePlatform();
  SharePlatform.instance = platform;
  for (final target in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      'Ekspor $target memakai byte privat, nama, dan anchor; batal aman',
      (tester) async {
        debugDefaultTargetPlatformOverride = target;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final server = SupabaseFixture();
        server.photoBytes = Uint8List.fromList('%PDF-1.4 test'.codeUnits);
        server.documentRows.add({
          'user_id': SupabaseFixture.id,
          'kind': 'ktp',
          'path': '${SupabaseFixture.id}/ktp.pdf',
          'file_name': 'KTP.pdf',
          'mime_type': 'application/pdf',
          'updated_at': 'version',
        });
        await tester.runAsync(
          () => server.client.auth.setSession('test-refresh'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfileRecords(
                  repository: BiodataRepository(server.client),
                  documents: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('KTP.pdf'));
        platform.fail = false;
        await tester.tap(find.text('KTP.pdf'));
        await tester.pumpAndSettle();
        expect(platform.received!.fileNameOverrides, ['KTP.pdf']);
        expect(platform.received!.files!.single.mimeType, 'application/pdf');
        expect(
          await platform.received!.files!.single.readAsBytes(),
          server.photoBytes,
        );
        expect(platform.received!.sharePositionOrigin!.width, greaterThan(0));
        expect(find.textContaining('Operasi gagal'), findsNothing);
        expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);
        platform.fail = true;
        await tester.tap(find.text('KTP.pdf'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Operasi gagal'), findsOneWidget);
        expect(server.documentRows, hasLength(1));
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(server.dispose);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
