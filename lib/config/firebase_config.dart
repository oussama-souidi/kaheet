import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

/// Initializes Firebase for the application.
/// Loads .env credentials first, then initializes Firebase.
/// This function should be called in main() before runApp().
Future<void> initializeFirebase() async {
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
