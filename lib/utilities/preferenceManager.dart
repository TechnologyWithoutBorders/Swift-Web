import 'package:shared_preferences/shared_preferences.dart';

import 'package:teog_swift/utilities/networkFunctions.dart' as Comm;
import 'package:teog_swift/utilities/constants.dart';

/// Checks whether the login data is present within the shared preferences and returns the current role.
///
/// If [syncWithServer] is set to true, the login data is checked against the server.
Future<String> checkLogin({bool syncWithServer: false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? password = prefs.getString(Constants.keyPw);
  String? country = prefs.getString(Constants.keyCountry);
  String? role = prefs.getString(Constants.keyRole);
  int? hospital = prefs.getInt(Constants.keyHospital);

  if(password != null && country != null && role != null && hospital != null) {
    if(syncWithServer) {
      return await Comm.checkCredentials(country, hospital, password, hashPassword: false);
    } else {
      return role;
    }
  }

  return Constants.roleInvalid;
}

/// Saves [country], [hospital], [role] and [password] in shared preferences.
Future<bool> save(String country, int hospital, String role, String password) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString(Constants.keyCountry, country);
  await prefs.setInt(Constants.keyHospital, hospital);
  await prefs.setString(Constants.keyRole, role);
  await prefs.setString(Constants.keyPw, password);

  return true;
}

Future<bool> selectUser(int user) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setInt(Constants.keyUser, user);

  return true;
}

Future<void> clear() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  prefs.clear();
}

Future<void> logout() async{
  SharedPreferences prefs = await SharedPreferences.getInstance();

  prefs.remove(Constants.keyRole);
  prefs.remove(Constants.keyPw);
}

Future<String?> getPassword() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString(Constants.keyPw);
}

Future<String?> getCountry() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString(Constants.keyCountry);
}

Future<int?> getHospital() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getInt(Constants.keyHospital);
}

Future<String?> getRole() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getString(Constants.keyRole);
}

Future<int?> getUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  return prefs.getInt(Constants.keyUser);
}