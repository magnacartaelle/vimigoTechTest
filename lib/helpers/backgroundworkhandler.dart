import 'package:flutter/widgets.dart';
import 'package:background_fetch/background_fetch.dart' as bgfetch;

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

  Future<void> repeatBackgroundTask() async {
    bgfetch.BackgroundFetch.start().then((status) {
      print("Background fetch restarted with status $status");
    });
  }

  Future<void> unregisterBackgroundTask() async {
    bgfetch.BackgroundFetch.stop(_taskName).then((status) {
      print("Background fetch stopped with status $status");
    });
  }

  void callbackDispatcher(String taskname) async {
    if (_tasks.containsKey(taskname)) {
      _tasks['taskName'];
      bgfetch.BackgroundFetch.finish(taskname);
    }
  }
}
