import 'package:flutter/cupertino.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/services/authentication_service.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../model/user.dart';
import '../../common/input_validation.dart';

class UpdateEmailDialogModel extends BaseViewModel with InputValidation {
  final _bottomSheetServ = locator<BottomSheetService>();
  final _sharedPref = locator<SharedPreferenceService>();
  final _authServ = locator<AuthenticationService>();

  late User user;

  TextEditingController newEmailTextController = TextEditingController();
  TextEditingController passwordTextController = TextEditingController();

  void init() async {
    setBusy(true);
    user = (await _sharedPref.getCurrentUser())!;
    setBusy(false);
  }

  Future<void> changeEmail() async {
    String? emailValidation = isValidEmail(newEmailTextController.text);
    String? passwordValidation = isValidPassword(passwordTextController.text);
    if (emailValidation == null) {
      if (passwordValidation == null) {
        setBusy(true);
        final response = await _authServ.updateEmail(
          currentEmail: user.email,
          newEmail: newEmailTextController.text,
          password: passwordTextController.text,
        );
        response.fold(
          (l) => showBottomSheet(l.message),
          (r) => showBottomSheet("Email changed successfully"),
        );
        setBusy(false);
      } else {
        showBottomSheet(passwordValidation);
      }
    } else {
      showBottomSheet(emailValidation);
    }
  }

  void showBottomSheet(String description) {
    _bottomSheetServ.showCustomSheet(
      variant: BottomSheetType.notice,
      title: "Notice",
      description: description,
    );
  }
}
