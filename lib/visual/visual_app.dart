import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'visual_router.dart';

class VisualApp extends StatelessWidget {
  const VisualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Alianca Visual',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routes: visualRoutes,
      initialRoute: VisualRoutes.selectChurch,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
