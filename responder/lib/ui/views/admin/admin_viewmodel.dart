import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
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
late Timer fetchDataTimer;
  final Map<MarkerId, Marker> _markers = {};
  Map<MarkerId, Marker> get markers => _markers;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? nearestFCMToken;
  String? nearestUID;
  String? userNeededHelpUid;
  String? nearestResponderUid;

Timestamp? responderdateAndTime;
String? responderformattedDAndT;
  String? responderuserName;
  String? responderformattedDateAndTime;
  String? responderphoneNum;
  String? responderFCMToken;
  String? responderuserConcern;
  String? responderuserImage;
  double? responderuserLatitude;
  double? responderuserLongitude;




  Timestamp? dateAndTime;
  String? userName;
  String? formattedDateAndTime;
  String? phoneNum;
  String? userFCMToken;
  String? userConcern;
  String? userSituation;
  String? userImage;
  String? userSituationPhoto;
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
  
 Future<List<DocumentSnapshot<Map<String, dynamic>>>> fetchUsersCollection() async {
  QuerySnapshot<Object?> querySnapshot = await FirebaseFirestore.instance.collection('users').get();
  return querySnapshot.docs.cast<DocumentSnapshot<Map<String, dynamic>>>().toList();
}

Future<List<DocumentSnapshot<Map<String, dynamic>>>> fetchRespondersCollection() async {
  QuerySnapshot<Object?> querySnapshot = await FirebaseFirestore.instance.collection('responder').get();
  return querySnapshot.docs.cast<DocumentSnapshot<Map<String, dynamic>>>().toList();
}

Future<void> updateUserData(String documentId, Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('responder')
          .doc(documentId)
          .update(updatedData);
      // Data updated successfully
    } catch (e) {
      // Handle error
      print('Error updating user data: $e');
      throw e; // Throw the error to be handled by the caller
    }
  }
  

Future<void> deleteUserData(String documentId) async {
  try {
    // Get the user ID
    String userId = FirebaseAuth.instance.currentUser!.uid;
    
    // Delete user's data from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(documentId)
        .delete();

    // Delete user's authentication account
    await FirebaseAuth.instance.currentUser?.delete();

  } catch (e) {
    print('Error deleting user data: $e');
    throw 'Failed to delete user data.';
  }
  rebuildUi();
}Future<void> deleteResponderData(String documentId) async {
  try {
    // Get the user ID
    String userId = FirebaseAuth.instance.currentUser!.uid;
    
    // Delete user's data from Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(documentId)
        .delete();

    // Delete user's authentication account
    await FirebaseAuth.instance.currentUser?.delete();

  } catch (e) {
    print('Error deleting user data: $e');
    throw 'Failed to delete user data.';
  }
  rebuildUi();
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
      String name = documentSnapshot.data()['name'];
      double distance = Geolocator.distanceBetween(positionOfUser.latitude,
          positionOfUser.longitude, latitude, longitude);

      // Check if the distance is within the radius (1km)
      if (distance <= radiusInMeters) {
        // Add the responder to the map if it's within the radius
        MarkerId markerId = MarkerId(documentSnapshot.id);
        Marker marker = Marker(
          markerId: markerId,
          position: LatLng(latitude, longitude),
          infoWindow:InfoWindow(
            title: name,
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


    
    Future<void> fetchData() async {
  try {
    // First, fetch user ID
    await fetchUserIdFromUserNeededHelp();

    // Then, fetch user name using the fetched user ID
    await fetchUserDetails();

    // Fetch responder details
    await fetchResponderDetails();

    // Fetch location data within 1km radius
    // await _getLocationDataOf1kmRadius();

    // Print statement to indicate that the process is complete
    print('Location data processing is complete');

    setBusy(false);
  } catch (e) {
    print('Error fetching data: $e');
  }
}

 Future<String?> fetchResponderDetails() async{ 
     try {
      // Get a reference to the "user" collection
      CollectionReference responderCollection =
          FirebaseFirestore.instance.collection('responder');

    // Get a reference to the document within the "user" collection
      DocumentSnapshot docSnapshot =
          await responderCollection.doc(nearestResponderUid).get();

          if (docSnapshot.exists) {
        // Retrieve other fields as you were doing before
        responderdateAndTime = docSnapshot.get('timestamp');
        responderuserName = docSnapshot.get('name');
        responderphoneNum = docSnapshot.get('phonenumber');
        responderuserImage = docSnapshot.get('image');
        responderFCMToken = docSnapshot.get('fcmToken');
        responderuserLatitude = docSnapshot.get('latitude');
        responderuserLongitude = docSnapshot.get('longitude');

        // Convert the Timestamp to a DateTime and format it
        DateTime dateTime = responderdateAndTime!.toDate();
        responderformattedDAndT = DateFormat.yMd().add_jm().format(dateTime);
           
       print('Responder Name: $responderuserName');

        return responderuserName;
      } else {
        print('Document does not exist in the "responder" collection.');
        return null;
      }
     }catch (e) {
      print('Error fetching user details: $e');
      return null;

 }}

    Future<String?> fetchUserDetails() async {
  try {
    // Get a reference to the "user" collection
    CollectionReference userCollection =
        FirebaseFirestore.instance.collection('users');

    // Get a reference to the document within the "user" collection
    DocumentSnapshot docSnapshot =
        await userCollection.doc(userNeededHelpUid).get();

    // Check if the document exists
    if (docSnapshot.exists) {
      // Retrieve other fields as you were doing before
      dateAndTime = docSnapshot.get('timestamp');
      userName = docSnapshot.get('name');
      phoneNum = docSnapshot.get('phonenumber');
      userImage = docSnapshot.get('image');
      userSituationPhoto = docSnapshot.get('situationPhoto');
      userFCMToken = docSnapshot.get('fcmToken');
      userLatitude = docSnapshot.get('latitude');
      userLongitude = docSnapshot.get('longitude');
      userSituation = docSnapshot.get('situation');

      // Create a unique string identifier for the marker
      String markerIdValue = 'users_$userNeededHelpUid';
      MarkerId markerId = MarkerId(markerIdValue);
      Marker marker = Marker(
        markerId: markerId,
        position: LatLng(userLatitude!, userLongitude!),
        infoWindow: InfoWindow(
          title: userName,
        ),
      );
      _markers[markerId] = marker;

      // Handle the array field userConcern
      List<dynamic>? userConcernList = docSnapshot.get('concerns');
      if (userConcernList!= null) {
        // Join concerns into a single string
        userConcern = userConcernList.join(', ');
      } else {
        userConcern = ''; // or any default value if null is not acceptable
      }

      // Convert the Timestamp to a DateTime and format it
      DateTime dateTime = dateAndTime!.toDate();
      formattedDateAndTime = DateFormat.yMd().add_jm().format(dateTime);

      // Print the userName
      print('User Name: $userName');

      return userName;
    } else {
      print('Document does not exist in the "users" collection.');
      return null;
    }
  } catch (e) {
    print('Error fetching user details: $e');
  }
  return null;
}



    Future<void> fetchUserIdFromUserNeededHelp() async {
    try {
      // Get a reference to the "responder" collection
      CollectionReference adminCollection =
          FirebaseFirestore.instance.collection('admin');

      // Get a reference to the document within the "responder" collection
      DocumentReference docRef = adminCollection.doc(admin.uid);

      // Get a reference to the "userNeededHelp" subcollection
      CollectionReference userNeededHelpCollection =
          docRef.collection('userNeededHelp');
 CollectionReference nearestResponderCollection =
          docRef.collection('nearestResponder');

      // Query documents ordered by timestamp in descending order (most recent first) and limit the result to 1
      QuerySnapshot querySnapshot = await userNeededHelpCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get(); 
      QuerySnapshot querySnapshotResponder = await nearestResponderCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // Check if there are any documents returned
      if (querySnapshot.docs.isNotEmpty) {
        // Access the first document and get the "userId" field
        userNeededHelpUid = querySnapshot.docs.first.get('userId');
        print('User ID from Admin: $userNeededHelpUid');
      } 
       if (querySnapshotResponder.docs.isNotEmpty) {
        // Access the first document and get the "userId" field
        nearestResponderUid = querySnapshotResponder.docs.first.get('userId');
        print('User ID: $nearestResponderUid');
      } else {
        print('No documents found in the "userNeededHelp" subcollection.');
      }
    } catch (e) {
      print('Error fetching user ID: $e');
    }
  }


  void onNotificationClicked(Map<String, dynamic> data, bool isInForeground) {
    // Handle notification click here
    Future.delayed(const Duration(seconds: 2), () {
      showDialogBox(context!);
    });
  }
void onNotificationClickedResponder(Map<String, dynamic> data, bool isInForeground) {
    // Handle notification click here
    Future.delayed(const Duration(seconds: 2), () {
      showDialogBoxResponder(context!);
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
          scrollDirection: Axis.vertical, // Change scroll direction to vertical
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
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
                    width: double.infinity, // Set width to fill available space
                    height: 200, // Adjust height as needed
                    fit: BoxFit.cover, // Ensure image covers the area
                  ),
                ),
              Text('Patient Name: $userName'),
              Text('User is in need of: $userConcern'),
              Text('User Situation: $userSituation'),
              if (userSituationPhoto != null) // Check if the photo exists
                GestureDetector(
                  onTap: () {
                    // Show full-size photo when tapped
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Image.network(
                            userSituationPhoto!, // Use fetched photo URL
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
                    userSituationPhoto!, // Use fetched photo URL
                    width: double.infinity, // Set width to fill available space
                    height: 200, // Adjust height as needed
                    fit: BoxFit.cover, // Ensure image covers the area
                  ),
                ),
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
void showDialogBoxResponder(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("User Information"),
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical, // Change scroll direction to vertical
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
            children: [
              if (responderuserImage != null) // Check if the image is fetched
                GestureDetector(
                  onTap: () {
                    // Show full-size image when tapped
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Image.network(
                            responderuserImage!, // Use fetched image URL
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
                    responderuserImage!, // Use fetched image URL
                    width: double.infinity, // Set width to fill available space
                    height: 200, // Adjust height as needed
                    fit: BoxFit.cover, // Ensure image covers the area
                  ),
                ),
              Text('Patient Name: $responderuserName'),
              Text('Phone Number: $responderphoneNum'),
              Text('Date: $responderformattedDateAndTime'),
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
                  _openGoogleMaps(responderuserLatitude, responderuserLongitude);
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

      await fetchData();
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
    // Check the notification title
    String notificationTitle = message.notification!.title ?? "";

    // Execute corresponding functions based on the notification title
    if (notificationTitle == "Someone is in distress") {
      onNotificationClicked(message.data, true);
    } else if (notificationTitle == "Responder Arrived in the Destination") {
      onNotificationClickedResponder(message.data, true);
    }

    // Fetch data and vibrate in both cases
    fetchData();
    vibrate();
  }
});
    // Listen for notification clicks when app is in the background
   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Check the notification title
  String notificationTitle = message.notification!.title ?? "";

  // Execute corresponding functions based on the notification title
  if (notificationTitle == "Someone is in distress") {
    onNotificationClicked(message.data, true);
  } else if (notificationTitle == "Responder Arrived in the Destination") {
    onNotificationClickedResponder(message.data, true);
  }

  // Fetch data and vibrate in both cases
  fetchData();
  vibrate();
});
    setBusy(false);
  }

 Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) {
    // Check the notification title
    String notificationTitle = message.notification!.title ?? "";

    // Execute corresponding functions based on the notification title
    if (notificationTitle == "Someone is in distress") {
      onNotificationClicked(message.data, true);
    } else if (notificationTitle == "Responder Arrived in the Destination") {
      onNotificationClickedResponder(message.data, true);
    }

    // Fetch data and vibrate in both cases
    fetchData();
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
   }

  void updateMapTheme(GoogleMapController controller) {
    getJsonFileFromThemes("themes/night_style.json")
        .then((value) => setGoogleMapStyle(value, controller));
  }

  void onPageChanged(int index) {
    currentPageIndex = index;
    rebuildUi();
    if (index == 1) {
      if (controllerGoogleMap != null) {
        updateMapTheme(controllerGoogleMap!);

      }
    }
  }

  void goToProfileView() {
    _navigationService.navigateToAdminProfileView();
  }

  Future<void> showNearestResponder() async {
      fetchData();
      showDialogBox(context!);
    }
    
  void markNearestResponder() {
      
    }

  

  
}
