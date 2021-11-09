import 'package:shared_preferences/shared_preferences.dart';

import 'networkFunctions.dart' as Comm;
import 'constants.dart';

/// Checks whether the login data is present within the shared preferences.
///
/// If [syncWithServer] is set to true, the login data is checked on the server.
Future<bool> checkLogin({bool syncWithServer: false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String password = prefs.getString(Constants.key_pw);
  String country = prefs.getString(Constants.key_country);
  int hospital = prefs.getInt(Constants.key_hospital);

  if(password != null && country != null && hospital != null) {
    if(syncWithServer) {
      Comm.checkCredentials(country, hospital, password, hashPassword: false).then((success) {
        return success;
      });
    } else {
      return true;
    }
  }

  return false;
}

/// Saves [country], [hospital] and [password] in shared preferences.
Future<bool> save(String country, int hospital, String password) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString(Constants.key_country, country);
  await prefs.setInt(Constants.key_hospital, hospital);
  await prefs.setString(Constants.key_pw, password);

  return true;
}