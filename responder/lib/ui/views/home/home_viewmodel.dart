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
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';

class HomeViewModel extends BaseViewModel {
  final PageController pageController = PageController(initialPage: 0);
  final _snackbarService = locator<SnackbarService>();
  final _sharedPref = locator<SharedPreferenceService>();
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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
  String? phoneNum;
  String? responderFCMToken;
  String? userConcern;
  String? userImage;
  String? userSituationPhoto;
  String? userSituation;

  BuildContext? context;

  HomeViewModel(this.context);

  void sendNotification() async {
    // Check if nearestFCMToken is not null before sending the notification
    if (responderFCMToken != null) {
      final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
      await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAApeeRKFQ:APA91bG2STzaKtq-pwEZQA6nAdzkbFwGqz80bvaF-wM4I1uQIIDOO8pYKz2kIEyPoJEZW3pn6oHrtARdewwttGkVS18gaf1380kC7LpFltrTNKO2FXCZJ5bPX8Ruq9k0LexXudcjaf9I', // Your FCM server key
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': '',
              'title': 'Responder is On The Way!!!',
              'android_channel_id':
                  'your_channel_id', // Required for Android 8.0 and above
              'alert': 'standard', // Set to 'standard' to show a dialog box
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'screen': 'dialog_box', // Screen to open in receiver app
            },
            'to': responderFCMToken, // Receiver's FCM token
          },
        ),
      );
    } else {
      print('Nearest responder FCM token is null. Cannot send notification.');
    }
  }
  Future<void> sendNotificationAdmin(BuildContext context) async {
  // Get a reference to the admin collection
  CollectionReference adminCollection =
      FirebaseFirestore.instance.collection('admin');

  // Query for documents in the admin collection
  QuerySnapshot adminSnapshot = await adminCollection.get();

  // Iterate through each document in the collection
  adminSnapshot.docs.forEach((adminDocument) async {
    // Extract the 'fcmToken' field from the document data
    var data = adminDocument.data() as Map<String, dynamic>;
    if (data.containsKey('fcmToken')) {
      String fcmToken = data['fcmToken'];

      // Check if FCM token is not null before sending the notification
      final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
      var response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAApeeRKFQ:APA91bG2STzaKtq-pwEZQA6nAdzkbFwGqz80bvaF-wM4I1uQIIDOO8pYKz2kIEyPoJEZW3pn6oHrtARdewwttGkVS18gaf1380kC7LpFltrTNKO2FXCZJ5bPX8Ruq9k0LexXudcjaf9I', // Your FCM server key
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': '',
              'title': 'Responder Arrived in the Destination',
              'android_channel_id': 'your_channel_id', // Required for Android 8.0 and above
              'alert': 'standard', // Set to 'standard' to show a dialog box
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'screen': 'dialog_box', // Screen to open in receiver app
            },
            'to': fcmToken, // Receiver's FCM token
          },
        ),
      );

      // Check if the notification is sent successfully
      if (response.statusCode == 200) {
        // Show a success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Notification sent successfully!'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  });
}


  void onNotificationClicked(Map<String, dynamic> data, bool isInForeground) {
    // Handle notification click here
    Future.delayed(const Duration(seconds: 2), () {
      showDialogBox(context!);
    });
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
      CollectionReference responderCollection =
          FirebaseFirestore.instance.collection('responder');

      // Get a reference to the document within the "responder" collection
      DocumentReference docRef = responderCollection.doc(user.uid);

      // Get a reference to the "userNeededHelp" subcollection
      CollectionReference userNeededHelpCollection =
          docRef.collection('userNeededHelp');

      // Query documents ordered by timestamp in descending order (most recent first) and limit the result to 1
      QuerySnapshot querySnapshot = await userNeededHelpCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

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

  Future<QuerySnapshot<Object?>> fetchEmergencyHistory() async {
    QuerySnapshot<Object?> querySnapshot =
        await FirebaseFirestore.instance.collection('Emergency History').get();
    return querySnapshot;
  }

  Future<void> storeEmergencyHistory() async {
    try {
      // Get a reference to the "Emergency History" collection
      CollectionReference emergencyHistoryCollection =
          FirebaseFirestore.instance.collection('Emergency History');

      // Create a new document in the "Emergency History" collection with a generated document ID
      await emergencyHistoryCollection.add({
        'userName': userName,
        'phoneNum': phoneNum,
        'userImage': userImage,
        'situation':userSituation,
        'situationPhoto':userSituationPhoto,
        'responderFCMToken': responderFCMToken,
        'userLatitude': userLatitude,
        'userLongitude': userLongitude,
        'formattedDateAndTime': formattedDateAndTime,
        'userConcern': userConcern,
        
        // Add any other fields you want to store in the emergency history
      });

      print('Emergency history stored successfully.');
    } catch (e) {
      print('Error storing emergency history: $e');
    }
  }

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
        responderFCMToken = docSnapshot.get('fcmToken');
        userLatitude = docSnapshot.get('latitude');
        userLongitude = docSnapshot.get('longitude');
        userSituation = docSnapshot.get('situation');
        

        // Handle the array field userConcern
        List<dynamic>? userConcernList = docSnapshot.get('concerns');
        if (userConcernList != null) {
          // Join concerns into a single string
          userConcern = userConcernList.join(', ');
        } else {
          userConcern = ''; // or any default value if null is not acceptable
        }

        // Convert the Timestamp to a DateTime and format it
        DateTime dateTime = dateAndTime!.toDate();
        formattedDateAndTime = DateFormat.yMd().add_jm().format(dateTime);

        return userName;
      } else {
        print('Document does not exist in the "user" collection.');
        return null;
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
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
                    width: 100, // Adjust width as needed
                    height: 100, // Adjust height as needed
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
                  sendNotification();
                  storeEmergencyHistory();
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
    timer = Timer.periodic(
        const Duration(seconds: 20), (Timer t) => storeCurrentLocationOfUser());

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
        fetchData();
        vibrate();
      }
    });

    // Listen for notification clicks when app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification payload when app is in the background
      onNotificationClicked(message.data, true);
      fetchData();
      vibrate();
    });
    setBusy(false);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    if (message.notification != null) {
      // Handle notification payload when app is completely closed
      onNotificationClicked(message.data, true);
      fetchData();
      vibrate();
    }
  }

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

  void initState() {}

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
