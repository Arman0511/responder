import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/model/admin.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

class AdminViewModel extends BaseViewModel {
  final PageController pageController = PageController(initialPage: 0);
  final _navigationService = locator<NavigationService>();
  final _sharedPref = locator<SharedPreferenceService>();

  late Admin admin;
  late Timer timer;
  final Map<MarkerId, Marker> _markers = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? nearestFCMToken;
  String? nearestUID;
  String? userNeededHelpUid;
  Timestamp? dateAndTime;
  String? userName;
  String? formattedDateAndTime;
  String? phoneNum;
  String? responderFCMToken;
  String? userConcern;
  String? userImage;
  double? userLatitude;
  double? userLongitude;
  BuildContext? context;

  AdminViewModel(this.context);

  int currentPageIndex = 0;
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  StreamSubscription<Admin?>? streamSubscription;

  Future<QuerySnapshot<Object?>> fetchEmergencyHistory() async {
    QuerySnapshot<Object?> querySnapshot =
        await FirebaseFirestore.instance.collection('Emergency History').get();
    return querySnapshot;
  }

  Future<void> _getLocationDataOf1kmRadius() async {
    setBusy(true);

    // Get the user's current location
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    // Clear any existing markers on the map
    _markers.clear();

    // Fetch the location data from Firebase Firestore
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await _firestore.collection('responder').get();

    if (querySnapshot.docs.isEmpty) {
      print('No location data available');
      return;
    }

    double radiusInMeters = 1000; // 1km in meters

    // Iterate through the location data points, calculating the distance between the user's current location and each location data point
    for (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot
        in querySnapshot.docs) {
      double latitude = documentSnapshot.data()['latitude'];
      double longitude = documentSnapshot.data()['longitude'];
      double distance = Geolocator.distanceBetween(positionOfUser.latitude,
          positionOfUser.longitude, latitude, longitude);

      // Check if the distance is within the radius (1km)
      if (distance <= radiusInMeters) {
        // Add the responder to the map if it's within the radius
        MarkerId markerId = MarkerId(documentSnapshot.id);
        Marker marker = Marker(
          markerId: markerId,
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(
            title: 'Responder',
          ),
        );
        _markers[markerId] = marker;
      }
    }

    // Print information of responders within 1km radius
    print('Responders within 1km radius:');
    for (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot
        in querySnapshot.docs) {
      double latitude = documentSnapshot.data()['latitude'];
      double longitude = documentSnapshot.data()['longitude'];
      String name = documentSnapshot.data()['name'];
      double distance = Geolocator.distanceBetween(positionOfUser.latitude,
          positionOfUser.longitude, latitude, longitude);
      if (distance <= radiusInMeters) {
        nearestFCMToken =
            documentSnapshot.data()['fcmToken']; // Fetching FCM token
        nearestUID = documentSnapshot.data()['uid'];
        // print('Responder ID: ${documentSnapshot.id}');
        // print('Latitude: $latitude');
        // print('Longitude: $longitude');
        print('Name: $name');
        print('UID: $nearestUID');
        print('FCMtoken: $nearestFCMToken');
        // Print other information as needed
      }
    }

    // Print statement to indicate that the process is complete
    print('Location data processing is complete');

    setBusy(false);
  }

  void onNotificationClicked(Map<String, dynamic> data, bool isInForeground) {
    // Handle notification click here
    Future.delayed(const Duration(seconds: 2), () {
      showDialogBox(context!);
    });
  }

  void showDialogBox(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("User Information"),
          content: SingleChildScrollView(
            // Wrap content with SingleChildScrollView
            scrollDirection:
                Axis.horizontal, // Set scroll direction to horizontal
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userImage != null) // Check if the image is fetched
                  GestureDetector(
                    onTap: () {
                      // Show full-size image when tapped
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Image.network(
                              userImage!, // Use fetched image URL
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Close"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Image.network(
                      userImage!, // Use fetched image URL
                      width: 100, // Adjust width as needed
                      height: 100, // Adjust height as needed
                    ),
                  ),
                Text('Patient Name: $userName'),
                Text('User is need of: $userConcern'),
                Text('Phone Number: $phoneNum'),
                Text('Date: $formattedDateAndTime'),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    onPressed: () {
                      launchDialer(phoneNum!);
                    },
                    child: Text("Call"),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _openGoogleMaps(userLatitude, userLongitude);
                    // sendNotification();
                    // storeEmergencyHistory();
                  },
                  child: Text("Navigate"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _openGoogleMaps(userLatitude, userLongitude) async {
    String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$userLatitude,$userLongitude';
    await launch(googleMapsUrl);
  }

  launchDialer(String number) async {
    String url = 'tel:' + number;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Application unable to open dialer.';
    }
  }

Future<void> vibrate() async {
    // Check if the device supports vibration
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != null && hasVibrator) {
      // Vibrate for 500ms
      Vibration.vibrate(duration: 5000);
    } else {
      // Device doesn't support vibration or it's null
      print('Device does not support vibration');
    }
  }


  init() async {
    setBusy(true);
    admin = (await _sharedPref.getCurrentAdmin())!;
    streamSubscription?.cancel();
    streamSubscription = _sharedPref.adminStream.listen((userData) {
      if (userData != null) {
        admin = userData;
        rebuildUi();
      }
    });

    // // Fetch data here
    // timer =
    //     Timer.periodic(const Duration(seconds: 2), (Timer t) => fetchData());

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Set foreground notification presentation options
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
      if (message.notification != null) {
        // Handle notification payload when app is in the foreground
        onNotificationClicked(message.data, true);
        vibrate();
      }
    });

    // Listen for notification clicks when app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification payload when app is in the background
      onNotificationClicked(message.data, true);
      vibrate();
    });
    setBusy(false);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      // Handle notification payload when app is completely closed
      onNotificationClicked(message.data, true);
      vibrate();
    }
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  void onDestinationSelected(int index) {
    currentPageIndex = index;
    changePage(currentPageIndex);
  }

  void changePage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void mapCreated(GoogleMapController mapController) {
    controllerGoogleMap = mapController;
    googleMapCompleterController.complete(controllerGoogleMap);
    updateMapTheme(controllerGoogleMap!);
    // timer = Timer.periodic(
    //     const Duration(seconds: 20), (Timer t) => storeCurrentLocationOfUser());
    // fetchData();
  }

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/night_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  void onPageChanged(int index) {
    currentPageIndex = index;
    rebuildUi();
    if (index == 1) {
      // storeCurrentLocationOfUser();
      if (controllerGoogleMap != null) {
        updateMapTheme(controllerGoogleMap!);
      }
    }
  }

  void goToProfileView() {
    _navigationService.navigateToAdminProfileView();
  }
}
