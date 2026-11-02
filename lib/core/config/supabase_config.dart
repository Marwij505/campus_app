// Kunci publishable boleh berada di klien. Semua hak akses dijaga RLS server.
// Secret/service_role tidak boleh ditambahkan ke berkas ini.
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://taqmosufhapstehgeonz.supabase.co',
  );
  static const key = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_XA7WINXN94dxDmABvOExIQ_JiJ_yVaP',
  );
  static Future<void> initialize() async {
    if (Uri.tryParse(url)?.scheme != 'https' ||
        !key.startsWith('sb_publishable_')) {
      throw StateError('Konfigurasi Supabase tidak valid.');
    }
    await Supabase.initialize(
      url: url,
      publishableKey: key,
      // Restart meminta login ulang; profil tetap tersimpan di server.
      authOptions: const FlutterAuthClientOptions(
        persistSession: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }
}
