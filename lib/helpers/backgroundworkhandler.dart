import 'package:flutter/widgets.dart';
import 'package:background_fetch/background_fetch.dart' as bgfetch;

///This class primarily deals with scheduling and managing background fetching setups
///
///At present, it caters to only ONE taskName / ID which is 'com.transistorsoft.fetch'
///The class also deals directly with the background_fetch package which wraps and manages
///native background fetching / processing. 
///This class is also made as a singleton
class BackgroundWorkHandler {
  static final BackgroundWorkHandler _instance =
      BackgroundWorkHandler._internal();

  final _tasks = <String, Function>{};
  final _taskName = "com.transistorsoft.fetch";

  factory BackgroundWorkHandler() {
    return _instance;
  }

  BackgroundWorkHandler._internal();

  Future<void> initialise() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

///Register a background task with the corresponding callback upon background fetch trigger
  Future<void> registerBackgroundTask(Function callback) async {
    int status = await bgfetch.BackgroundFetch.configure(
        bgfetch.BackgroundFetchConfig(
            minimumFetchInterval: 15,
            startOnBoot: false,
            stopOnTerminate: false,
            enableHeadless: false,
            requiredNetworkType: bgfetch.NetworkType.NONE,
            requiresCharging: false,
            requiresDeviceIdle: false), (String taskId) async {
      print("BackgroundFetch received $taskId");
      callback();
      bgfetch.BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      print("BackgroundFetch timed out for $taskId");
      bgfetch.BackgroundFetch.finish(taskId);
    });

    print("Background fetch configured and started with status $status");
  }

///Reschedules a background task manually using the same callback
  Future<void> repeatBackgroundTask() async {
    bgfetch.BackgroundFetch.start().then((status) {
      print("Background fetch restarted with status $status");
    });
  }

//Unschedules and stops a background task
  Future<void> unregisterBackgroundTask() async {
    bgfetch.BackgroundFetch.stop(_taskName).then((status) {
      print("Background fetch stopped with status $status");
    });
  }
}
