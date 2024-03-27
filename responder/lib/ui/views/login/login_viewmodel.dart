import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.router.dart';
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

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

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
          'status': 'online',
        });
        _navigationService.replaceWithHomeView();
      });
    }
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
