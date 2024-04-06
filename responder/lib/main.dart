import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:relative_time/relative_time.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.dialogs.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/services/notification_service.dart';

import 'package:stacked_services/stacked_services.dart';
import 'package:vibration/vibration.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request for notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Firebase messaging setup successful');

    // Get the token
    String? token = await messaging.getToken();
    print('Firebase Messaging Token: $token');

    // Configure notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      // Vibrate the device
      Vibration.vibrate(duration: 1500);

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');

      // Stop vibration when notification is clicked
      Vibration.cancel();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Request notification permission for web
  if (kIsWeb) {
    await FirebaseMessaging.instance.requestPermission();
  }

  // Request location permission if not granted
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    print(
        'Location permission is permanently denied, please enable it from the settings.');
  }

  // Initialize a FlutterLocalNotificationsPlugin object
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidInitializationSettings);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  setupLocator();
  setupDialogUi();
  setupBottomSheetUi();

  // Run the app
  runApp(const MainApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');

  // Vibrate the device
  Vibration.vibrate(duration: 1500, repeat: -1);

  // Handle your background message here
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.rubikTextTheme()),
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [
        StackedService.routeObserver,
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        RelativeTimeLocalizations.delegate,
      ],
    );
  }
}
