import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'localstoragehandler.dart';
import 'backgroundworkhandler.dart';
import 'checkconnectivity.dart';

import '../models/taskmodel.dart';
import '../apiconstants.dart' as apiconstants;

class TaskSyncManager {
  static final TaskSyncManager _instance = TaskSyncManager._internal();

  late final localTaskList = <TaskModel>[];
  late final _pendingSyncList = <String>[];

  bool _isSyncing = false;

  final _localStorage = LocalStorageHandler();
  final _tableName = "tasks";
  final _pendingUpdatesName = "pendingtasks";

  factory TaskSyncManager() {
    return _instance;
  }

  TaskSyncManager._internal();

  Future<void> initialise() async {
    await _localStorage.initialiseDatabase().then((value) => _localStorage
        .initialiseTable(_tableName)
        .then((value) => getTaskList()));

//get shared prefs here
    final sharedPrefs = await SharedPreferences.getInstance();
    final pendingPrefs =
        sharedPrefs.getStringList(_pendingUpdatesName) ?? <String>[];

    _pendingSyncList.addAll(pendingPrefs);

    await BackgroundWorkHandler().initialise();
  }

  Future<void> getTaskList() async {
    var taskList = await _localStorage.getDataFromTable(_tableName);
    localTaskList.clear();
    localTaskList.addAll(taskList);
  }

  Future<void> loadRemoteTaskList() async {
    if (_isSyncing) {
      return Future.value();
    }

    _isSyncing = true;
    const taskListURL = apiconstants.baseURL + "/tasks";
    final response = await http.get(Uri.parse(taskListURL));

    print(response.body);
    final dataList = json.decode(response.body) as List;
    final remoteList = <TaskModel>[];

    for (final item in dataList) {
      final id = item['id'];
      final title = item['title'];
      final details = item['details'];
      final status = item['status'];
      final assigneeId = item['assigneeId'];
      final isCompleted = item['isCompleted'];
      final taskObj = TaskModel(
          id: id,
          title: title,
          details: details,
          status: status,
          assigneeId: assigneeId,
          isCompleted: isCompleted);

      remoteList.add(taskObj);
    }

//Get the current local list
    final localList = await _localStorage.getDataFromTable(_tableName);
    final itemsToRemove = <TaskModel>[];
    itemsToRemove.addAll(localList);

//Do the comparison
    //If remote = 0, local should result in 0
    //If local is 0. local may not result in 0. Need to check remote.

    // if (localList.length < remoteList.length) {
    for (final remoteItem in remoteList) {
      await _localStorage.insertDataIntoTable(_tableName, remoteItem);
    }
    // } else {
    for (final localItem in localList) {
      for (final remoteItem in remoteList) {
        if (localItem.id == remoteItem.id) {
          remoteItem.status = localItem
              .status; //Assuming this is the change the user has made to this item while offline.
          itemsToRemove.remove(localItem);
          await _localStorage.updateDataInTable(_tableName, remoteItem);
          break;
        }
      }
    }

    for (final removeItem in itemsToRemove) {
      await _localStorage.removeDataFromTable(_tableName, removeItem);

      if (_pendingSyncList.contains(removeItem.id)) {
        _pendingSyncList.remove(removeItem.id);
      }
    }
    // }

    _isSyncing = false;
    print("HOLD UP");

    return Future.value();
  }

  Future<void> updateTask(TaskModel task) async {
    await _localStorage.updateDataInTable(_tableName, task);
    getTaskList();

    final hasConnection =
        await ConnectivityClass.checkIfHasInternetConnection();

    if (hasConnection) {
      updateTaskToRemote(task);
    } else {
      _pendingSyncList.add(task.id);

      final sharedPrefs = await SharedPreferences.getInstance();
      sharedPrefs.setStringList(_pendingUpdatesName, _pendingSyncList);
      //shared prefs save here
    }
  }

  Future<void> checkAnyPendingToUpdate() async {
    print("There are ${_pendingSyncList.length} updates to sync up");
    for (final item in localTaskList) {
      if (_pendingSyncList.contains(item.id)) {
        await updateTaskToRemote(item);
        _pendingSyncList.remove(item.id);
      }
    }

    //Update shared prefs.
    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setStringList(_pendingUpdatesName, _pendingSyncList);
  }

  Future<void> updateTaskToRemote(TaskModel task) async {
    //call API
    final urlString = apiconstants.baseURL + "tasks/${task.id}";
    final response = await http.put(Uri.parse(urlString),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(task.toMap(isLocalStorage: false)));

    print(response.body);
    final responseData = json.decode(response.body) as Map<String, dynamic>;
    final taskObjResponse = TaskModel.fromMap(responseData);
  }

  Future<void> clearLocalTaskStorage() async {
    await _localStorage.clearTable(_tableName);
    final sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.remove(_pendingUpdatesName);
    return;
  }

  Future<void> reloadAndResync() async {
    print("reload and resync");

//If got internet, call API
//If no internet, ignore, use local copy first.
    if (await ConnectivityClass.checkIfHasInternetConnection()) {
      await loadRemoteTaskList().then((value) => checkAnyPendingToUpdate());
      //TODO: Check if got any pending tasks to update.
    }
    await getTaskList();
  }

  //Background task
  void stopSyncInBackground() async {
    await BackgroundWorkHandler().unregisterBackgroundTask();
    print("cancelled background task sync?");
  }

  void runSyncInBackground() {
    BackgroundWorkHandler().registerBackgroundTask(() async {
      print("background task sync?");

      if (await ConnectivityClass.checkIfHasInternetConnection()) {
        await loadRemoteTaskList();
      }
      await getTaskList();
      await BackgroundWorkHandler().repeatBackgroundTask();
    });
  }
}
