import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'hide User;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/model/user.dart';
import 'package:responder/notification_service.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final PageController pageController = PageController(initialPage: 0);
  final _snackbarService = locator<SnackbarService>();
  final _sharedPref = locator<SharedPreferenceService>();
  StreamSubscription<User?>? streamSubscription;

  NotificationService notificationService = NotificationService();
  Position? currentPositionOfUser;
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  // final LocalNotifications _localNotifications = LocalNotifications();
  final _navigationService = locator<NavigationService>();
  int currentPageIndex = 0;
  double? userLatitude;
  double? userLongitude;

  bool btnMedSelected = false;
  bool btnFireSelected = false;
  bool btnPoliceSelected = false;

  get counterLabel => null;
  late User user;

  init() async {
    setBusy(true);
    user = (await _sharedPref.getCurrentUser())!;
    streamSubscription?.cancel();
    streamSubscription = _sharedPref.userStream.listen((userData) {
      if (userData != null) {
        user = userData;
        rebuildUi();
      }
    });
    setBusy(false);
  }

 void _showUserLocation() async {
  try {
    // Get the user's location data from Firestore
    DocumentSnapshot<Map<String, dynamic>>? userLocationSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (userLocationSnapshot.exists) {
      // Extract the location data as Map<String, dynamic>
      Map<String, dynamic> locationData = userLocationSnapshot!.data()!;

      // Extract the latitude and longitude from the location data
      userLatitude = locationData['location']['latitude'];
      userLongitude = locationData['location']['longitude'];

      // Create a Google Map widget and set the initial camera position to the user's location
      // Code for creating Google Map widget and setting initial camera position should be added here
    } else {
      print('User location data not found.');
    }
  } catch (error) {
    print('Error fetching user location: $error');
    // Handle error appropriately
  }
}



Future<void> storeCurrentLocationOfUser() async {
  setBusy(true);

  // Get current position of the user
  Position positionOfUser = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation);
  currentPositionOfUser = positionOfUser;

  // Convert current position to LatLng
  LatLng positionOfUserInLatLang = LatLng(
      currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

  // Get current date and time
  DateTime currentDateTime = DateTime.now();

  // Store the location data in Firestore along with date and time
  await FirebaseFirestore.instance.collection('responder').doc(user.uid).update({
    'location': GeoPoint(positionOfUser.latitude, positionOfUser.longitude),
    'timestamp': Timestamp.fromDate(currentDateTime),
  });

  // Animate camera to user's current position
  CameraPosition cameraPosition =
      CameraPosition(target: positionOfUserInLatLang, zoom: 15);
  controllerGoogleMap!
      .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

  setBusy(false);
}


  // getCurrentLiveLocationOfUser() async {
  //   Position positionOfUser = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.bestForNavigation);
  //   currentPositionOfUser = positionOfUser;

  //   LatLng positionOfUserInLatLang = LatLng(
  //       currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
  //   CameraPosition cameraPosition =
  //       CameraPosition(target: positionOfUserInLatLang, zoom: 15);
  //   controllerGoogleMap!
  //       .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  //   rebuildUi();
  //   print("Created Map");
  // }

  void initState() {
    notificationService.requestNotificationPermission();
  }

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/night_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  setGoogleMapStyle(String googleMapStyle, GoogleMapController controller) {
    controller.setMapStyle(googleMapStyle);
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  void mapCreated(GoogleMapController mapController) {
    controllerGoogleMap = mapController;
    googleMapCompleterController.complete(controllerGoogleMap);
    updateMapTheme(controllerGoogleMap!);
    storeCurrentLocationOfUser();
    // _showUserLocation();
    
  }

  void goToProfileView() {
    _navigationService.navigateToProfileViewView();
  }

  void onPageChanged(int index) {
  currentPageIndex = index;
  rebuildUi();
  if (index == 1) {
    storeCurrentLocationOfUser();
    if (controllerGoogleMap != null) {
      updateMapTheme(controllerGoogleMap!);
    }
  } 
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

 




  void incrementCounter() {}

  void showBottomSheet() {}
}
