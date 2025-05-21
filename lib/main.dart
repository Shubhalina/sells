import 'package:flutter/material.dart';
import 'package:sells/screens/Feedback_Screen.dart';
import 'package:sells/screens/OffersNegotiationsPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

import 'screens/UserProfilePage.dart'; // Keep the correct case used in your project
import 'screens/paymentscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mtueuowmcuzpfoftvsjz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10dWV1b3dtY3V6cGZvZnR2c2p6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY3MjU4OTIsImV4cCI6MjA2MjMwMTg5Mn0.4IcazXBe98nkDOwBg0KDBtH7wjAsecZIVSKxdVDMdyc',
  );
  runApp(const RebuyApp());
}

class RebuyApp extends StatelessWidget {
  const RebuyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rebuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'GoogleSans', primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/payment': (context) => const PaymentScreen(
          subtotal: 229.99,
          deliveryFee: 5.00,
          tax: 15.00,
        ),
        '/user_profile': (context) => const UserProfileScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/offers_negotiations': (context) => const OffersNegotiationsPage(
          productId: '12345', // Replace with actual product ID
        ),
      },
    );
  }
}
