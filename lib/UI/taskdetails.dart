import 'package:flutter/material.dart';

import '../models/taskmodel.dart';
import '../styles.dart' as styles;
import '../helpers/tasksyncmanager.dart';


///Task details page that you can update the status of the task.
///
///Task details transitions from: Not started -> In progress -> Resolved -> Closed
class TaskDetailsPage extends StatelessWidget {
  const TaskDetailsPage({required this.selectedTask, Key? key})
      : super(key: key);

  final TaskModel selectedTask;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: TaskDetails(
        selectedTask: selectedTask,
      ),
    );
  }
}

//Task Details
class TaskDetails extends StatefulWidget {
  const TaskDetails({required this.selectedTask, Key? key}) : super(key: key);

  final TaskModel selectedTask;

  @override
  State<TaskDetails> createState() => _TaskDetailsState();
}

class _TaskDetailsState extends State<TaskDetails> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(children: [
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Text(
              widget.selectedTask.title,
              style: styles.listTitleStyle,
            )),
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Text(widget.selectedTask.details,
                style: styles.listSubtitleStyle)),
        Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            child: Text(widget.selectedTask.getTaskStatusString(),
                style: styles.listSubtitleStyle)),
        Visibility(
          visible: !widget.selectedTask.getTaskIsClosed(),
          child: Center(
              child: TextButton(
                  child: const Text("Update Status", textAlign: TextAlign.center),
                  onPressed: () {
                    setState(() {
                      widget.selectedTask.updateStatusToNextStep();
                      TaskSyncManager().updateTask(widget.selectedTask);
                    });
                  })),
        )
      ], crossAxisAlignment: CrossAxisAlignment.start),
    );
  }
}
