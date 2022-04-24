import 'dart:io';

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
