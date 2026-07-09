import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCRo63Ekq5SNnY8Fk32UDyAT8xrInbxzTI',
        authDomain: 'mediremind-15aba.firebaseapp.com',
        projectId: 'mediremind-15aba',
        storageBucket: 'mediremind-15aba.firebasestorage.app',
        messagingSenderId: '848066454181',
        appId: '1:848066454181:web:000000000000000000000000', // placeholder — see note below
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRemind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}
