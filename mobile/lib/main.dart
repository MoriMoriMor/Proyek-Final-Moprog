import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'spots_app.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const demo = bool.fromEnvironment('SPOTS_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configured = supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  if (configured && !demo) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  runApp(SpotsApp(configured: configured, demo: demo));
}
