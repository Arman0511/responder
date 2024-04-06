import 'package:flutter/material.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:responder/methods/common_methods.dart';
import 'package:responder/services/authentication_service.dart';
import 'package:responder/ui/common/app_constants.dart';
import 'package:responder/ui/common/app_exception_constants.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class AdminSignupViewModel extends BaseViewModel {
  final phoneNumTextController = TextEditingController();
  final nameTextController = TextEditingController();
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  final _authenticationService = locator<AuthenticationService>();
  final _navigatorService = locator<NavigationService>();
  final _snackBarService = locator<SnackbarService>();
  CommonMethods cmethods = CommonMethods();

  bool obscureText = true;

  void visibility() {
    obscureText = !obscureText;
    notifyListeners();
  }

  Future<void> signupPressed() async {
    // Retrieve the current BuildContext
    BuildContext? context =
        locator<NavigationService>().navigatorKey?.currentContext!;

    // Check connectivity
    await cmethods.checkConnectivity(context!);

    final verifyForm = validateForm();
    if (verifyForm != null) {
      _snackBarService.showSnackbar(message: verifyForm);
    } else {
      setBusy(true);
      final response = await _authenticationService.adminSignup(
        nameTextController.text,
        emailTextController.text,
        passwordTextController.text,
        phoneNumTextController.text,
      );

      setBusy(false);

      response.fold((l) {
        _snackBarService.showSnackbar(message: l.message);
      }, (r) {
        _snackBarService.showSnackbar(
            message: AppConstants.accountCreatedText,
            duration: const Duration(seconds: 2));
        _navigatorService.replaceWithAdminView();
      });
    }
  }

  String? validateForm() {
    if (nameTextController.text.isEmpty &&
        emailTextController.text.isEmpty &&
        passwordTextController.text.isEmpty) {
      return AppExceptionConstants.emptyEmailNamePass;
    } else if (nameTextController.text.isEmpty &&
        emailTextController.text.isEmpty) {
      return AppExceptionConstants.emptyEmailName;
    } else if (nameTextController.text.isEmpty &&
        passwordTextController.text.isEmpty) {
      return AppExceptionConstants.emptyNamePass;
    } else if (emailTextController.text.isEmpty &&
        passwordTextController.text.isEmpty) {
      return AppExceptionConstants.emptyEmailPass;
    } else if (nameTextController.text.isEmpty) {
      return AppExceptionConstants.emptyName;
    } else if (emailTextController.text.isEmpty) {
      return AppExceptionConstants.emptyEmail;
    } else if (passwordTextController.text.isEmpty) {
      return AppExceptionConstants.emptyPassword;
    } else {
      return null;
    }
  }
}
