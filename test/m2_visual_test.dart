import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_app/core/app_theme.dart';
import 'package:campus_app/features/academic/academic_page.dart';

import 'm2_academic_test.dart' show FixtureAcademicRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'SpaceMono',
    )..addFont(rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'))).load();
    await (FontLoader('PressStart2P')
          ..addFont(rootBundle.load('assets/fonts/PressStart2P-Regular.ttf')))
        .load();
  });
  for (final size in [
    const Size(320, 800),
    const Size(800, 1000),
    const Size(1280, 900),
  ]) {
    testWidgets('M2 responsive pages at $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FixtureAcademicRepository();
      for (final tab in academicDestinations) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.data,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: boundary,
              child: AcademicPage(
                key: ValueKey(tab),
                repository: repository,
                initialTab: tab,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab scrolled');
        if (['Jadwal Kuliah', 'KRS', 'Pembayaran'].contains(tab)) {
          await tester.runAsync(() async {
            final picture =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = File(
              'build/m2-visual/${tab.replaceAll(' ', '-')}-${size.width.toInt()}.png',
            );
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
