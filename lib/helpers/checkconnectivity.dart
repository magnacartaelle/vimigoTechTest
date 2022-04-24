import 'dart:io';

///Class with a static method to check the device's connectivity using lookup.
class ConnectivityClass {
  static Future<bool> checkIfHasInternetConnection() async {
    try {
      final response = await InternetAddress.lookup("www.google.com");

      print((response.isNotEmpty) ? "Has internet" : "No internet");
      return response.isNotEmpty;
    } on SocketException catch (e) {
      print("No internet.");
      return false;
    }
  }
}
