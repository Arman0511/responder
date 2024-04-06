import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/services/authentication_service.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:responder/ui/common/input_validation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AdminLoginDialogModel extends BaseViewModel with InputValidation {
  final _bottomSheetServ = locator<BottomSheetService>();
  final _sharedPref = locator<SharedPreferenceService>();
  final _authServ = locator<AuthenticationService>();
  final _navigationService = locator<NavigationService>();

  TextEditingController emailTextController = TextEditingController();
  TextEditingController passwordTextController = TextEditingController();

  Future<void> logIn() async {
    if (validateInput()) {
      setBusy(true);
      final response = await _authServ.adminlogin(
          email: emailTextController.text,
          password: passwordTextController.text);
      setBusy(false);
      response.fold((l) {
        showBottomSheet(l.message);
      }, (admin) async {
        await _sharedPref.saveAdmin(admin);
        // Generate FCM token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        // Update Firestore document with the FCM token and status
        await FirebaseFirestore.instance
            .collection('admin')
            .doc(admin.uid)
            .update({
          'fcmToken': fcmToken,
        });
        // storeCurrentLocationOfUser();
        _navigationService.replaceWithAdminView();
      });
    }
  }

  bool validateInput() {
    String? emailValidation = isValidEmail(emailTextController.text);
    String? passwordValidation = isValidPassword(passwordTextController.text);

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
    _bottomSheetServ.showCustomSheet(
      variant: BottomSheetType.inputValidation,
      title: "Invalid Credential",
      description: description,
    );
  }

  void adminview() {
    _navigationService.replaceWithAdminSignupView();
  }
}
