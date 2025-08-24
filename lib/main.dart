import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/firebase_options.dart';
import 'services/order_service.dart';
import 'services/theme_provider.dart'; // Theme provider for Dark Mode
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OrderService>(create: (_) => OrderService(), lazy: false), // ✅ Ensure OrderService is ready
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // ✅ Dark Mode Provider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
            initialRoute: '/',
            routes: {
              '/': (context) => LoginScreen(),  // ❌ Removed 'const'
              '/main': (context) => MainScreen(),
              '/cart': (context) => MainScreen(initialIndex: 2),
            },
          );
        },
      ),
    );
  }
}
