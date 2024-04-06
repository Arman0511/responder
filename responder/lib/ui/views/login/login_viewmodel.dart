import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.dialogs.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/model/user.dart';
import 'package:responder/services/authentication_service.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:responder/ui/common/input_validation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';

class LoginViewModel extends BaseViewModel with InputValidation {
  final _navigationService = locator<NavigationService>();
  final _authenticationService = locator<AuthenticationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _sharedPref = locator<SharedPreferenceService>();
  final _dialogService = locator<DialogService>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Position? currentPositionOfUser;
  late User user;
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  Future<void> logIn() async {
    if (validateInput()) {
      setBusy(true);
      final response = await _authenticationService.login(
          email: emailController.text, password: passwordController.text);
      setBusy(false);
      response.fold((l) {
        showBottomSheet(l.message);
      }, (user) async {
        await _sharedPref.saveUser(user);
        // Generate FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        // Update Firestore document with the FCM token and status
        await FirebaseFirestore.instance
            .collection('responder')
            .doc(user.uid)
            .update({
          'fcmToken': fcmToken,
        });
        storeCurrentLocationOfUser();
        _navigationService.replaceWithHomeView();
      });
    }
  }

  void showadminLoginDialog() async {
    await _dialogService.showCustomDialog(
      variant: DialogType.adminLogin,
    );
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

  bool validateInput() {
    String? emailValidation = isValidEmail(emailController.text);
    String? passwordValidation = isValidPassword(passwordController.text);

    if (emailValidation == null) {
      if (passwordValidation == null) {
        return true;
      } else {
        showBottomSheet(passwordValidation);
        return false;
      }
    } else {
      showBottomSheet(emailValidation);
      return false;
    }
  }

  void showBottomSheet(String description) {
    _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.inputValidation,
      title: "Invalid Credential",
      description: description,
    );
  }

  void goToSignUp() {
    _navigationService.navigateToUserSignUpView();
  }

  void goToForgotPassword() {
    _navigationService.navigateToForgotPasswordViewView();
  }
}
