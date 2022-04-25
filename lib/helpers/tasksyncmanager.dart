import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'localstoragehandler.dart';
import 'backgroundworkhandler.dart';
import 'checkconnectivity.dart';

import '../models/taskmodel.dart';
import '../apiconstants.dart' as apiconstants;

///Class that deals with tasks entirely. Basically a middle-man that interacts with the front end
///and the helpers
///
///Essentially calls APIs, talks to the localstorage helper, background handler and check connectivity as well.
///Also a singleton
class TaskSyncManager {
  static final TaskSyncManager _instance = TaskSyncManager._internal();

  late final localTaskList = <TaskModel>[];
  late final _pendingSyncList = <String>[];

  //To prevent...race conditions
  bool _isSyncing = false;

  final _localStorage = LocalStorageHandler();

  //Some const names used within this class only
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

    //Extract shared prefs here for any previously unupdated tasks from the device.
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

  //Load the task list via API
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

    //Compare local and remote copy.
    //Ideally, remote copies usually mean the latest and complete version
    //IDs that no longer exist in the remote copy should be removed from the local

    for (final remoteItem in remoteList) {
      await _localStorage.insertDataIntoTable(_tableName, remoteItem);
    }
    for (final localItem in localList) {
      for (final remoteItem in remoteList) {
        if (localItem.id == remoteItem.id) {
          remoteItem.status = localItem
              .status; //Assuming this is as one of the change the user has made to this item while offline.
          itemsToRemove.remove(localItem);
          await _localStorage.updateDataInTable(_tableName, remoteItem);
          break;
        }
      }
    }

    //Remove the IDs that can no longer be found in the remote list
    //Also remove the IDs if they are actually due for update to server.
    for (final removeItem in itemsToRemove) {
      await _localStorage.removeDataFromTable(_tableName, removeItem);

      if (_pendingSyncList.contains(removeItem.id)) {
        _pendingSyncList.remove(removeItem.id);
      }
    }

    _isSyncing = false;

    return Future.value();
  }

  Future<void> updateTask(TaskModel task) async {
    await _localStorage.updateDataInTable(_tableName, task);
    getTaskList();

    final hasConnection =
        await ConnectivityClass.checkIfHasInternetConnection();

    //Check for connection, if no connection then throw into a pending list.
    //else, directly make the change to server.
    if (hasConnection) {
      updateTaskToRemote(task);
    } else {
      _pendingSyncList.add(task.id);

      //Update to player prefs (in case the device crashes or if user kills the app)
      final sharedPrefs = await SharedPreferences.getInstance();
      sharedPrefs.setStringList(_pendingUpdatesName, _pendingSyncList);
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

  ///Call API to update task status.
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
  }

  ///Clear local storage (clean reset of things)
  Future<void> clearLocalTaskStorage() async {
    await _localStorage.clearTable(_tableName);

    _pendingSyncList.clear();
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

  ///To stop background task scheduling
  void stopSyncInBackground() async {
    await BackgroundWorkHandler().unregisterBackgroundTask();
    print("cancelled background task sync?");
  }

  ///To start background task scheduling
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
