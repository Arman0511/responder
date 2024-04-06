import 'dart:async';
import 'dart:convert';

import 'package:responder/model/admin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';

class SharedPreferenceService {
  late StreamController<User?> _userStreamController;
  late StreamController<Admin?> _adminStreamController;

  SharedPreferenceService() {
    _userStreamController = StreamController<User?>.broadcast();
    _adminStreamController = StreamController<Admin?>.broadcast();
  }
  Stream<User?> get userStream => _userStreamController.stream;
  Stream<Admin?> get adminStream => _adminStreamController.stream;

  Future<void> deleteCurrentUser() async {
    final sharedPref = await SharedPreferences.getInstance();
    sharedPref.remove("USER_KEY");

  } Future<void> deleteCurrentAdmin() async {
    final sharedPref = await SharedPreferences.getInstance();
    sharedPref.remove("ADMIN_KEY");
  }

  Future<String?> getUserId() async {
    final user = await getCurrentUser();
    if (user != null) {
      return user.uid;
    } else {
      return null;
    }
  }

  Future<String?> getAdminId() async {
    final admin = await getCurrentAdmin();
    if (admin != null) {
      return admin.uid;
    } else {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    final sharedPref = await SharedPreferences.getInstance();
    final user = sharedPref.getString("USER_KEY");
    if (user == null) return null;
    return User.fromJson(json.decode(user));
  }

  Future<Admin?> getCurrentAdmin() async {
    final sharedPref = await SharedPreferences.getInstance();
    final admin = sharedPref.getString("ADMIN_KEY");
    if (admin == null) return null;
    return Admin.fromJson(json.decode(admin));
  }

  Future<void> saveUser(User user) async {
    if (_userStreamController.isClosed) {
      _userStreamController = StreamController<User?>.broadcast();
    }
    _userStreamController.add(user);
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString("USER_KEY", jsonEncode(user.toJson()));
  }

  Future<void> saveAdmin(Admin admin) async {
    if (_adminStreamController.isClosed) {
      _adminStreamController = StreamController<Admin?>.broadcast();
    }
    _adminStreamController.add(admin);
    final sharedPref = await SharedPreferences.getInstance();
    await sharedPref.setString("ADMIN_KEY", jsonEncode(admin.toJson()));
  }

  void dispose() {
    _userStreamController.close();
    _adminStreamController.close();
  }
}
