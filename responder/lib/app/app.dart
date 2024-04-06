import 'package:responder/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:responder/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:responder/ui/views/home/home_view.dart';
import 'package:responder/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:responder/ui/views/login/login_view.dart';

import '../services/authentication_service.dart';
import '../services/shared_pref_service.dart';
import 'package:responder/ui/views/user_sign_up/user_sign_up_view.dart';
import 'package:responder/ui/views/forgot_password_view/forgot_password_view_view.dart';
import 'package:responder/ui/views/profile_view/profile_view_view.dart';

import 'package:responder/ui/dialogs/update_profile_image/update_profile_image_dialog.dart';
import 'package:responder/ui/dialogs/update_name/update_name_dialog.dart';
import 'package:responder/ui/dialogs/update_email/update_email_dialog.dart';
import 'package:responder/ui/dialogs/update_password/update_password_dialog.dart';
import 'package:responder/ui/bottom_sheets/input_validation/input_validation_sheet.dart';
import 'package:responder/services/firebase_messaging_sevice_service.dart';
import 'package:responder/services/notification_service.dart';
import 'package:responder/services/user_service.dart';
import 'package:responder/services/internet_service.dart';
import 'package:responder/services/image_service.dart';
import 'package:responder/ui/views/admin/admin_view.dart';
import 'package:responder/ui/dialogs/admin_login/admin_login_dialog.dart';
import 'package:responder/ui/views/admin_signup/admin_signup_view.dart';
import 'package:responder/ui/views/admin_signup/admin_signup_view.dart';
import 'package:responder/ui/views/admin_profile/admin_profile_view.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: LoginView),
    MaterialRoute(page: UserSignUpView),
    MaterialRoute(page: ForgotPasswordViewView),
    MaterialRoute(page: ProfileViewView),

    MaterialRoute(page: AdminView),
    MaterialRoute(page: AdminSignupView),
    MaterialRoute(page: AdminSignupView),
    MaterialRoute(page: AdminProfileView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: AuthenticationService),
    LazySingleton(classType: SharedPreferenceService),
    LazySingleton(classType: FirebaseMessagingSeviceService),
    LazySingleton(classType: NotificationService),
    LazySingleton(classType: UserService),
    LazySingleton(classType: InternetService),
    LazySingleton(classType: ImageService),
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
    StackedDialog(classType: AdminLoginDialog),
// @stacked-dialog
  ],
)
class App {}
