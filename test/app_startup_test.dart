// Inisialisasi gagal tetap memberi tindakan yang dapat dilakukan pengguna.
import 'package:campus_app/core/config/app_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Gagal menyiapkan layanan lalu mencoba ulang', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      AppStartup(
        initialize: () async {
          if (++attempts == 1) throw StateError('rincian internal');
        },
        child: const MaterialApp(home: Text('SIAKAD siap')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Layanan belum dapat disiapkan'),
      findsOneWidget,
    );
    expect(find.textContaining('rincian internal'), findsNothing);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('SIAKAD siap'), findsOneWidget);
    expect(attempts, 2);
  });
}
