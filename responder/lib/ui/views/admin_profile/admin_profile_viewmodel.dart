import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.dialogs.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/methods/common_methods.dart';
import 'package:responder/model/admin.dart';
import 'package:responder/services/authentication_service.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:responder/ui/constants/app_png.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';


XFile? imageFile;
String urlOfUploadedImage = "";

class AdminProfileViewModel extends BaseViewModel {

   CommonMethods cmethods = CommonMethods();
  final _dialogService = locator<DialogService>();
  final _authService = locator<AuthenticationService>();
  final _bottomSheetServ = locator<BottomSheetService>();
  final _navigationService = locator<NavigationService>();
  final _sharedPref = locator<SharedPreferenceService>();

  StreamSubscription<Admin?>? streamSubscription;

  late Admin admin;

  ImageProvider getImage() {
    if (admin.image == null) return const AssetImage(AppPng.AppAvatarPath);
    return NetworkImage(admin.image!);
  }


void init() async {
    setBusy(true);
    admin = (await _sharedPref.getCurrentAdmin())!;
    streamSubscription?.cancel();
    streamSubscription = _sharedPref.adminStream.listen((userData) {
      if (userData != null) {
        admin = userData;
        rebuildUi();
      }
    });
    setBusy(false);
  }

  void showUploadPictureDialog() async {
    await _dialogService.showCustomDialog(
      variant: DialogType.updateProfileImage,
    );
  }

  void showUpdateNameDialog() async {
    await _dialogService.showCustomDialog(
      variant: DialogType.updateName,
    );
  }

  void showUpdatePasswordDialog() async {
    await _dialogService.showCustomDialog(
      variant: DialogType.updatePassword,
    );
  }
  
  void showCreateAccount() async {
    _navigationService.replaceWithAdminSignupView();
  }

  Future<void> logOut() async {
    setBusy(true);
    final response = await _authService.logoutAdmin();
    setBusy(false);

    response.fold((l) {
      showBottomSheet(l.message);
    }, (r) async {
      await FirebaseFirestore.instance
          .collection('admin')
          .doc(admin.uid)
          .update({
        'status': 'offline',
      });
      _navigationService.popRepeated(1);
      _navigationService.replaceWithLoginView();
    });
  }

  void showBottomSheet(String description) {
    _bottomSheetServ.showCustomSheet(
      variant: BottomSheetType.notice,
      title: "Error",
      description: description,
    );
  }

  void showUpdateEmailDialog() async {
    await _dialogService.showCustomDialog(
      variant: DialogType.updateEmail,
    );
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }
}
