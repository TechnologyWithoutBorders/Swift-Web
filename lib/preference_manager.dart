import 'package:shared_preferences/shared_preferences.dart';

import 'networkFunctions.dart' as Comm;
import 'constants.dart';

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

Future<bool> save(String country, int hospital, String password) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  await prefs.setString(Constants.key_country, country);
  await prefs.setInt(Constants.key_hospital, hospital);
  await prefs.setString(Constants.key_pw, password);

  return true;
}