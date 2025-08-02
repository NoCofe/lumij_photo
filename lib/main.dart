import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'providers/photo_provider.dart';
import 'providers/optimized_photo_provider.dart';
import 'screens/home_screen.dart';
import 'screens/optimized_home_screen.dart';

void main() {
  runApp(const LumijPhotoApp());
}

class LumijPhotoApp extends StatelessWidget {
  const LumijPhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PhotoProvider()),
        ChangeNotifierProvider(create: (context) => OptimizedPhotoProvider()),
      ],
      child: CupertinoApp(
        title: 'Lumij Photo',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          brightness: Brightness.light,
        ),
        home: const OptimizedHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
