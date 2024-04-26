import 'package:responder/services/authentication_service.dart';
import 'package:responder/services/shared_pref_service.dart';
import 'package:stacked/stacked.dart';
import 'package:responder/app/app.locator.dart';
import 'package:responder/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _authService = locator<AuthenticationService>();
  final _sharedPref = locator<SharedPreferenceService>();

  // Place anything here that needs to happen before we get into the application
  Future runStartupLogic() async {
    await Future.delayed(const Duration(seconds: 3));

    // This is where you can make decisions on where your app should navigate when
    // you have custom startup logic

    if (_authService.isLoggedIn && await _sharedPref.getCurrentUser() != null) {
      _navigationService.replaceWithHomeView();
    } 
    else if(_authService.isLoggedIn && await _sharedPref.getCurrentAdmin() != null) {
      _navigationService.replaceWithAdminView();
    }
     else {
      _navigationService.replaceWithLoginView();
    }
  }
}
