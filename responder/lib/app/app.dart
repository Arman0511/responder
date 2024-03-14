import 'package:responder/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:responder/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:responder/ui/views/home/home_view.dart';
import 'package:responder/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:responder/ui/views/login/login_view.dart';
import 'package:responder/ui/views/responder_homepage/responder_homepage_view.dart';

import '../services/authentication_service.dart';
import '../services/shared_pref_service.dart';
import 'package:responder/ui/views/user_sign_up/user_sign_up_view.dart';
import 'package:responder/ui/views/message_view/message_view_view.dart';
import 'package:responder/ui/views/forgot_password_view/forgot_password_view_view.dart';
import 'package:responder/ui/views/profile_view/profile_view_view.dart';

import 'package:responder/ui/dialogs/update_profile_image/update_profile_image_dialog.dart';
import 'package:responder/ui/dialogs/update_name/update_name_dialog.dart';
import 'package:responder/ui/dialogs/update_email/update_email_dialog.dart';
import 'package:responder/ui/dialogs/update_password/update_password_dialog.dart';
import 'package:responder/ui/bottom_sheets/input_validation/input_validation_sheet.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: ResponderHomepageView),
    MaterialRoute(page: UserSignUpView),
    MaterialRoute(page: MessageViewView),
    MaterialRoute(page: ForgotPasswordViewView),
    MaterialRoute(page: ProfileViewView),

// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: AuthenticationService),
    LazySingleton(classType: SharedPreferenceService),


    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    StackedBottomsheet(classType: InputValidationSheet),
// @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    StackedDialog(classType: UpdateProfileImageDialog),
    StackedDialog(classType: UpdateNameDialog),
    StackedDialog(classType: UpdateEmailDialog),
    StackedDialog(classType: UpdatePasswordDialog),
// @stacked-dialog
  ],
)
class App {}
