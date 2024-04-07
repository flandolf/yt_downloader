import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yt_downloader/dark_provider.dart';
import 'package:yt_downloader/home_screen.dart';

bool isDark = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Retrieve SharedPreferences instance
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Retrieve isDark value from SharedPreferences, default to false if not found
  bool isDark = prefs.getBool('isDark') ?? false;

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => DarkProvider(isDark)),
    ],
    child: const MainApp(),
  ));
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Provider.of<DarkProvider>(context).isDark
                    ? Brightness.dark
                    : Brightness.light),
            useMaterial3: true),
        home: const HomeScreen());
  }
}
