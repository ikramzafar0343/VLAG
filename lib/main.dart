import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutree/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'constants.dart';
import 'services/api_service.dart';
import 'utils/theme_provider.dart';
import 'views/splash/splash_screen.dart';

/// Global theme provider instance
final themeProvider = ThemeProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox(kMainBoxName);
  
  // Initialize API service
  apiService.initialize();
  
  // Google Mobile Ads initialization (non-blocking for faster startup)
  if (!kIsWeb) {
    // Initialize ads in background - don't await
    MobileAds.instance.initialize();
    MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [kTestDeviceId2, kTestDeviceId3]));
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    // Listen to theme changes and rebuild
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Update system UI overlay style based on theme
    final isDark = themeProvider.isDarkMode;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: kIsWeb ? 'VLag Create' : 'VLag',
      debugShowCheckedModeBanner: false,
      theme: VLagTheme.lightTheme,
      darkTheme: VLagTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: _analytics)],
      home: const SplashScreen(),
    );
  }
}
