import 'package:flutter/material.dart';

class TaskModel {
  late String id;
  late String title;
  late String details;
  late int status;
  late int assigneeId;
  late bool isCompleted;

  late bool isNewUpdate = false;

  TaskModel(
      {required this.id,
      required this.title,
      required this.details,
      required this.status,
      required this.assigneeId,
      required this.isCompleted});

  TaskModel.fromMap(Map<String, dynamic> map) {
    id = map['id'].toString();
    title = map['title'];
    details = map['details'];
    status = map['status'];
    assigneeId = map['assigneeId'];
    isCompleted = (map['isCompleted'] == 1) ? true : false;
  }

  Map<String, dynamic> toMap({bool isLocalStorage = true}) {
    return {
      'id': id,
      'title': title,
      'details': details,
      'status': status,
      'assigneeId': assigneeId,
      'isCompleted': (isLocalStorage ? ((isCompleted) ? 1 : 0) : isCompleted)
    };
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, details: $details, status: $status, assigneeId: $assigneeId, isCompleted: $isCompleted';
  }

  String getTaskStatusString() {
    switch (status) {
      case 1:
        return "Not started";
      case 2:
        return "In Progress";
      case 3:
        return "Resolved";
      default:
        return "Closed";
    }
  }

  Color getStatusColor() {
    Color color = Colors.blue;
    switch (status) {
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.yellow;
        break;
      case 3:
        color = Colors.green;
        break;
    }

    return color;
  }

  bool getTaskIsClosed() {
    return status == 0;
  }

  void updateStatusToNextStep() {
    status = (status + 1) % 4;
  }
}
