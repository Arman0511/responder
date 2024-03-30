import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/model/user.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeViewModel extends BaseViewModel {
  final PageController pageController = PageController(initialPage: 0);
  final _snackbarService = locator<SnackbarService>();
  final _sharedPref = locator<SharedPreferenceService>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  StreamSubscription<User?>? streamSubscription;

  // NotificationService notificationService = NotificationService();
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
  late Timer timer;
  String? userNeededHelpUid;
  Timestamp? dateAndTime;
  String? userName;
  String? formattedDateAndTime;
  


  BuildContext? context;

  HomeViewModel(this.context);



void onNotificationClicked(Map<String, dynamic> message, BuildContext context) {
  // Handle notification click here
  Future.delayed(const Duration(seconds: 2), () {
    showDialogBox(context);
  });
}

Future<void> fetchData() async {
  try {
    // First, fetch user ID
    await fetchUserIdFromUserNeededHelp();

    // Then, fetch user name using the fetched user ID
     userName = await fetchUserDetails();
    
    // Now you can use userName or perform any other actions with the fetched data
    if (userName != null) {
    } else {
      print('User name not found.');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}


Future<void> fetchUserIdFromUserNeededHelp() async {
  try {
    // Get a reference to the "responder" collection
    CollectionReference responderCollection = FirebaseFirestore.instance.collection('responder');

    // Get a reference to the document within the "responder" collection
    DocumentReference docRef = responderCollection.doc(user.uid);

    // Get a reference to the "userNeededHelp" subcollection
    CollectionReference userNeededHelpCollection = docRef.collection('userNeededHelp');

    // Query documents ordered by timestamp in descending order (most recent first) and limit the result to 1
    QuerySnapshot querySnapshot = await userNeededHelpCollection.orderBy('timestamp', descending: true).limit(1).get();

    // Check if there are any documents returned
    if (querySnapshot.docs.isNotEmpty) {
      // Access the first document and get the "userId" field
      userNeededHelpUid = querySnapshot.docs.first.get('userId');
      print('User ID: $userNeededHelpUid');
    } else {
      print('No documents found in the "userNeededHelp" subcollection.');
    }
  } catch (e) {
    print('Error fetching user ID: $e');
  }
}


Future<String?> fetchUserDetails() async {
  try {
    // Get a reference to the "user" collection
    CollectionReference userCollection = FirebaseFirestore.instance.collection('users');

    // Get a reference to the document within the "user" collection
    DocumentSnapshot docSnapshot = await userCollection.doc(userNeededHelpUid).get();

    // Check if the document exists
    if (docSnapshot.exists) {
      // Retrieve the "name" and "timestamp" fields from the document
      dateAndTime = docSnapshot.get('timestamp');
      userName = docSnapshot.get('name');
      userLatitude = docSnapshot.get('latitude');
      userLongitude = docSnapshot.get('longitude');
    
     

      // Convert the Timestamp to a DateTime and format it
      DateTime dateTime = dateAndTime!.toDate();
      String formattedDateAndTime = DateFormat.yMd().add_jm().format(dateTime);

      return '$userName | $formattedDateAndTime | $userLatitude | $userLongitude'; // Combine the two strings and return them
    } else {
      print('Document does not exist in the "user" collection.');
      return null;
    }
  } catch (e) {
    print('Error fetching user name: $e');
    return null;
  }
}

Future<void> _openGoogleMaps(userLatitude, userLongitude) async {
  String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$userLatitude,$userLongitude';
  await launch(googleMapsUrl);
}



void showDialogBox(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Dialog Box"),
        content: SingleChildScrollView( // Wrap content with SingleChildScrollView
          scrollDirection: Axis.horizontal, // Set scroll direction to horizontal
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('User: $userName'),
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
                    Navigator.of(context).pop();
                    // Add your navigation logic here for "Navigate" button
                  },
                  child: Text("Call"),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                      _openGoogleMaps(userLatitude, userLongitude);                },
                child: Text("Navigate"),
              ),
              
            ],
          ),
        ],
      );
    },
  );
}









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

  // Fetch data here
    timer = Timer.periodic(
        const Duration(seconds: 2), (Timer t) => fetchData());

  _firebaseMessaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Handle incoming messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Handle foreground messages
    if (message.notification != null) {
      // Handle notification payload when app is in the foreground
      onNotificationClicked(message.data, context!);
    }
  });

  // Handle notification clicks when app is in the background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Handle notification payload when app is in the background
    onNotificationClicked(message.data, context!);
  });

  setBusy(false);
}

  // void _showUserLocation() async {
  //   try {
  //     // Get the user's location data from Firestore
  //     DocumentSnapshot<Map<String, dynamic>>? userLocationSnapshot =
  //         await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(FirebaseAuth.instance.currentUser?.uid)
  //             .get();

  //     if (userLocationSnapshot.exists) {
  //       // Extract the location data as Map<String, dynamic>
  //       Map<String, dynamic> locationData = userLocationSnapshot!.data()!;

  //       // Extract the latitude and longitude from the location data
  //       userLatitude = locationData['location']['latitude'];
  //       userLongitude = locationData['location']['longitude'];

  //       // Create a Google Map widget and set the initial camera position to the user's location
  //       // Code for creating Google Map widget and setting initial camera position should be added here
  //     } else {
  //       print('User location data not found.');
  //     }
  //   } catch (error) {
  //     print('Error fetching user location: $error');
  //     // Handle error appropriately
  //   }
  // }

  Future<void> storeCurrentLocationOfUser() async {
    setBusy(true);

    // Get current position of the user
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    // Get current date and time
    DateTime currentDateTime = DateTime.now();

    // Store the location data in Firestore along with date and time
    await FirebaseFirestore.instance
        .collection('responder')
        .doc(user.uid)
        .update({
      'latitude': positionOfUser.latitude,
      'longitude': positionOfUser.longitude,
      'timestamp': Timestamp.fromDate(currentDateTime),
    });

    // Animate camera to user's current position
    LatLng positionOfUserInLatLang = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
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
    timer = Timer.periodic(
        const Duration(seconds: 20), (Timer t) => storeCurrentLocationOfUser());
        // fetchData();
      
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

  @override
  void dispose() {
    timer.cancel();
    streamSubscription?.cancel();
    super.dispose();
  }

  void incrementCounter() {}

  void showBottomSheet() {}
}
