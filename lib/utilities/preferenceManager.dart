import 'package:shared_preferences/shared_preferences.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/constants.dart';

/// Checks whether the login data is present within the shared preferences and returns the current role.
///
/// If [syncWithServer] is set to true, the login data is checked against the server.
Future<String> checkLogin({bool syncWithServer: false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? password = prefs.getString(Constants.key_pw);
  String? country = prefs.getString(Constants.key_country);
  String? role = prefs.getString(Constants.key_role);
  int? hospital = prefs.getInt(Constants.key_hospital);

  if(password != null && country != null && role != null && hospital != null) {
    if(syncWithServer) {
      return await Comm.checkCredentials(country, hospital, password, hashPassword: false);
    } else {
      return role;
    }
  }

  return Constants.role_invalid;
}

/// Saves [country], [hospital], [role] and [password] in shared preferences.
Future<bool> save(String country, int hospital, String role, String password) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString(Constants.key_country, country);
  await prefs.setInt(Constants.key_hospital, hospital);
  await prefs.setString(Constants.key_role, role);
  await prefs.setString(Constants.key_pw, password);

  return true;
}

Future<bool> selectUser(int user) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setInt(Constants.key_user, user);

  return true;
}

Future<void> clear() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  prefs.clear();
}

Future<void> logout() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();

  prefs.remove(Constants.key_role);
  prefs.remove(Constants.key_pw);
}

Future<String?> getPassword() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString(Constants.key_pw);
}

Future<String?> getCountry() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString(Constants.key_country);
}

Future<int?> getHospital() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getInt(Constants.key_hospital);
}

Future<String?> getRole() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString(Constants.key_role);
}

Future<int?> getUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getInt(Constants.key_user);
}