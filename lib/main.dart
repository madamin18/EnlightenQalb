import 'package:flutter/material.dart';
import 'package:testapp/pages/home_page2.dart';
import 'package:testapp/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      initialRoute: '/login', // Set the initial route to login
      routes: {
        '/login': (context) =>
            const LoginPage(), // No need to pass username initially
        '/home2': (context) => const HomePage2(),
      },
    );
  }
}
