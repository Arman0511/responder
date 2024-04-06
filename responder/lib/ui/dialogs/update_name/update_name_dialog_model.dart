import 'package:flutter/cupertino.dart';
import 'package:responder/app/app.bottomsheets.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:responder/services/user_service.dart';
import 'package:responder/ui/common/input_validation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class UpdateNameDialogModel extends BaseViewModel with InputValidation {
  final _userRepo = locator<UserService>();
  final _bottomSheetServ = locator<BottomSheetService>();
  final _sharedPref = locator<SharedPreferenceService>();

  TextEditingController nameTextController = TextEditingController();

  void init() async {
    setBusy(true);
    final user = await _sharedPref.getCurrentUser();
    nameTextController.text = user!.name;
    setBusy(false);
  }

  Future<void> updateName() async {
    String? nameValidation = isValidInput(nameTextController.text, "name");
    if (nameValidation == null) {
      setBusy(true);
      final response = await _userRepo.updateName(nameTextController.text);
      response.fold(
        (l) => showBottomSheet(l.message),
        (r) => showBottomSheet("Name updated successfully"),
      );
      setBusy(false);
    } else {
      showBottomSheet(nameValidation);
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
