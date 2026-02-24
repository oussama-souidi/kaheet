import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initializes Firebase for the application
/// This function should be called in main() before runApp()
Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
