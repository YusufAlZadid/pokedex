import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'providers/favorite_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp(
        title: 'Pokedex',
        theme: ThemeData(
          primarySwatch: Colors.red,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}