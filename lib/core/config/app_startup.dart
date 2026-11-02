// Menampilkan kemajuan dan kesempatan mencoba ulang saat layanan gagal disiapkan.
import 'package:flutter/material.dart';

import '../app_theme.dart';

class AppStartup extends StatefulWidget {
  const AppStartup({super.key, required this.initialize, required this.child});
  final Future<void> Function() initialize;
  final Widget child;

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late Future<void> _ready = widget.initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return widget.child;
      }
      // Pesan tidak menampilkan rincian konfigurasi atau data token dari exception.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!snapshot.hasError) const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      snapshot.hasError
                          ? 'Layanan belum dapat disiapkan. Periksa koneksi dan konfigurasi aplikasi.'
                          : 'Menyiapkan SIAKAD…',
                      textAlign: TextAlign.center,
                    ),
                    if (snapshot.hasError) ...[
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => setState(() {
                          _ready = widget.initialize();
                        }),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
