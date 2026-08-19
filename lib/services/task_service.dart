import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // TASK COLLECTION
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _taskCollection(
      String uid,
      ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks');
  }

  // ---------------------------------------------------------------------------
  // ADD TASK
  // ---------------------------------------------------------------------------

  Future<void> addTask({
    required TaskModel task,
  }) async {
    try {
      await _taskCollection(task.userId)
          .doc(task.id)
          .set(
        _toFirestore(task),
      );
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Failed to add task.',
      );
    } catch (e) {
      throw Exception(
        'Failed to add task.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET TASKS
  // ---------------------------------------------------------------------------
  //
  // This method is useful when we explicitly want to fetch Firestore data.
  //
  // IMPORTANT:
  // The TaskProvider does NOT use this as its primary task stream anymore.
  // SQLite is the local source used by the UI.
  //
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getTasks(
      String uid,
      ) async {
    try {
      final snapshot = await _taskCollection(uid)
          .where(
        'isDeleted',
        isEqualTo: false,
      )
          .orderBy(
        'createdAt',
        descending: true,
      )
          .get();

      return snapshot.docs
          .map(
            (doc) => _fromFirestore(
          doc.data(),
          doc.id,
        ),
      )
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Failed to fetch tasks.',
      );
    } catch (e) {
      throw Exception(
        'Failed to fetch tasks.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE TASK
  // ---------------------------------------------------------------------------

  Future<TaskModel?> getTask({
    required String uid,
    required String taskId,
  }) async {
    try {
      final document = await _taskCollection(uid)
          .doc(taskId)
          .get();

      if (!document.exists) {
        return null;
      }

      final data = document.data();

      if (data == null) {
        return null;
      }

      return _fromFirestore(
        data,
        document.id,
      );
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Failed to fetch task.',
      );
    } catch (e) {
      throw Exception(
        'Failed to fetch task.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE TASK
  // ---------------------------------------------------------------------------

  Future<void> updateTask({
    required TaskModel task,
  }) async {
    try {
      await _taskCollection(task.userId)
          .doc(task.id)
          .update(
        _toFirestore(task),
      );
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Failed to update task.',
      );
    } catch (e) {
      throw Exception(
        'Failed to update task.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SOFT DELETE TASK
  // ---------------------------------------------------------------------------
  //
  // We keep the Firestore document but mark it deleted.
  //
  // This matches your existing architecture:
  //
  // isDeleted = true
  //
  // The normal task query only displays:
  //
  // isDeleted = false
  //
  // ---------------------------------------------------------------------------

  Future<void> deleteTask({
    required TaskModel task,
  }) async {
    try {
      final deletedTask = task.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );

      await _taskCollection(task.userId)
          .doc(task.id)
          .update(
        _toFirestore(deletedTask),
      );
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Failed to delete task.',
      );
    } catch (e) {
      throw Exception(
        'Failed to delete task.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CHECK TASK EXISTS
  // ---------------------------------------------------------------------------

  Future<bool> taskExists({
    required String uid,
    required String taskId,
  }) async {
    try {
      final document = await _taskCollection(uid)
          .doc(taskId)
          .get();

      return document.exists;
    } on FirebaseException catch (e) {
      throw Exception(
        e.message ?? 'Failed to check task.',
      );
    } catch (e) {
      throw Exception(
        'Failed to check task.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE → TASK MODEL
  // ---------------------------------------------------------------------------

  TaskModel _fromFirestore(
      Map<String, dynamic> data,
      String documentId,
      ) {
    return TaskModel(
      id: documentId,

      userId: data['userId']?.toString() ?? '',

      title: data['title']?.toString() ?? '',

      description:
      data['description']?.toString() ?? '',

      priority: TaskPriority.values.firstWhere(
            (priority) =>
        priority.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),

      dueDate: _timestampToDateTime(
        data['dueDate'],
      ),

      isCompleted:
      data['isCompleted'] == true,

      isDeleted:
      data['isDeleted'] == true,

      createdAt:
      _timestampToDateTime(
        data['createdAt'],
      ) ??
          DateTime.now(),

      updatedAt:
      _timestampToDateTime(
        data['updatedAt'],
      ),

      // Data coming from Firestore has successfully
      // reached the server.
      isSynced: true,

      syncAction: SyncAction.none,
    );
  }

  // ---------------------------------------------------------------------------
  // TASK MODEL → FIRESTORE
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toFirestore(
      TaskModel task,
      ) {
    return {
      'id': task.id,

      'userId': task.userId,

      'title': task.title,

      'description': task.description,

      'priority': task.priority.name,

      'dueDate': task.dueDate == null
          ? null
          : Timestamp.fromDate(
        task.dueDate!,
      ),

      'isCompleted': task.isCompleted,

      'isDeleted': task.isDeleted,

      'createdAt': Timestamp.fromDate(
        task.createdAt,
      ),

      'updatedAt': task.updatedAt == null
          ? null
          : Timestamp.fromDate(
        task.updatedAt!,
      ),
    };
  }

  // ---------------------------------------------------------------------------
  // TIMESTAMP → DATETIME
  // ---------------------------------------------------------------------------

  DateTime? _timestampToDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}