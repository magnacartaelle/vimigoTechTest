import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vimigo_test/models/taskmodel.dart';

import '../styles.dart' as styles;
import '../models/taskmodel.dart';
import '../helpers/localstoragehandler.dart';
import '../helpers/tasksyncmanager.dart';

import 'taskdetails.dart';

///Stateful widget for displaying the task list (the first page when the app starts)
class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> with WidgetsBindingObserver {
  final _taskList = <TaskModel>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addObserver(this);
    _initialiseData();
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance!.removeObserver(this);
    stopTimerToSync();
    TaskSyncManager().stopSyncInBackground();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    //Observe, if going into background, schedule background task
    //Else, if in foreground, run timer to pull data every x minutes
    if (state == AppLifecycleState.resumed) {
      print("back from background");
      TaskSyncManager().stopSyncInBackground();
      _loadData();
      runTimerToSync();
    } else if (state == AppLifecycleState.paused) {
      print("to the background!");
      stopTimerToSync();
      TaskSyncManager().runSyncInBackground();
    }
  }

  Future<void> _initialiseData() async {
    await TaskSyncManager().initialise().then((value) => _reloadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task List"),
        actions: [
          Visibility(
            visible: true,
            child: TextButton(
                onPressed: () {
                  print("reload!");
                  _reloadData();
                },
                child: const Text(
                  "Reload",
                  style: TextStyle(color: Colors.white),
                )),
          ),
          TextButton(
              onPressed: () {
                print("clear all from db!");
                _clearData();
              },
              child: const Text(
                "Reset All",
                style: TextStyle(color: Colors.white),
              ))
        ],
      ),
      body: ListView.separated(
        itemCount: _taskList.length,
        itemBuilder: (context, itemPos) {
          return _buildTaskRow(itemPos);
        },
        separatorBuilder: (context, idx) =>
            const Divider(color: Color.fromARGB(255, 49, 49, 49)),
      ),
    );
  }

  Widget _buildTaskRow(int pos) {
    return Padding(
        padding: const EdgeInsets.only(
            left: 8.0, right: 15.0, top: 10.0, bottom: 10.0),
        child: ListTile(
          leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                    backgroundColor: _taskList[pos].getStatusColor(),
                    radius: 5.0)
              ]),
          title: Text(_taskList[pos].title, style: styles.listTitleStyle),
          subtitle:
              Text(_taskList[pos].details, style: styles.listSubtitleStyle),
          onTap: () {
            //do something
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TaskDetailsPage(selectedTask: _taskList[pos])))
                .then((value) => _loadData());
          },
        ));
  }

//Timer that runs when polling for data
  Timer? foregroundSyncTimer;

  void runTimerToSync() {
    if (foregroundSyncTimer != null) {
      return;
    }

    foregroundSyncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _reloadData();
    });
  }

  void stopTimerToSync() {
    if (foregroundSyncTimer != null) {
      foregroundSyncTimer!.cancel();
      foregroundSyncTimer = null;
    }
  }

//Data loading
  void _reloadData() async {
    stopTimerToSync();
    await TaskSyncManager().reloadAndResync().then((value) => _loadData());
    runTimerToSync();
  }

  void _loadData() {
    _taskList.clear();
    setState(() {
      _taskList.addAll(TaskSyncManager().localTaskList);
    });
  }

  void _clearData() async {
    stopTimerToSync();
    await TaskSyncManager()
        .clearLocalTaskStorage()
        .then((value) => _reloadData());
  }
}
