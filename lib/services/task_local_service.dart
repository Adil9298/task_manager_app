import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/task_model.dart';

class TaskLocalService {
  final AppDatabase _appDatabase = AppDatabase.instance;

  // ---------------------------------------------------------------------------
  // GET DATABASE
  // ---------------------------------------------------------------------------

  Future<Database> get _database async {
    return await _appDatabase.database;
  }

  // ---------------------------------------------------------------------------
  // INSERT TASK
  // ---------------------------------------------------------------------------

  Future<void> insertTask(TaskModel task) async {
    final db = await _database;

    await db.insert(
      'tasks',
      _taskToMap(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // GET ALL ACTIVE TASKS FOR USER
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getTasks(
      String userId,
      ) async {
    final db = await _database;

    final result = await db.query(
      'tasks',
      where: 'userId = ? AND isDeleted = ?',
      whereArgs: [
        userId,
        0,
      ],
      orderBy: 'createdAt DESC',
    );

    return result
        .map(_mapToTask)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE TASK
  // ---------------------------------------------------------------------------

  Future<TaskModel?> getTask({
    required String userId,
    required String taskId,
  }) async {
    final db = await _database;

    final result = await db.query(
      'tasks',
      where: 'userId = ? AND id = ?',
      whereArgs: [
        userId,
        taskId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return _mapToTask(result.first);
  }

  // ---------------------------------------------------------------------------
  // UPDATE TASK
  // ---------------------------------------------------------------------------

  Future<void> updateTask(TaskModel task) async {
    final db = await _database;

    await db.update(
      'tasks',
      _taskToMap(task),
      where: 'userId = ? AND id = ?',
      whereArgs: [
        task.userId,
        task.id,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOGGLE TASK
  // ---------------------------------------------------------------------------

  Future<void> toggleTask(TaskModel task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
      isSynced: false,
      syncAction: SyncAction.update,
    );

    await updateTask(updatedTask);
  }

  // ---------------------------------------------------------------------------
  // SOFT DELETE TASK
  // ---------------------------------------------------------------------------

  Future<void> deleteTask(TaskModel task) async {
    final deletedTask = task.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
      isSynced: false,
      syncAction: SyncAction.delete,
    );

    await updateTask(deletedTask);
  }

  // ---------------------------------------------------------------------------
  // GET PENDING SYNC TASKS
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getPendingSyncTasks(
      String userId,
      ) async {
    final db = await _database;

    final result = await db.query(
      'tasks',
      where: 'userId = ? AND isSynced = ?',
      whereArgs: [
        userId,
        0,
      ],
      orderBy: 'createdAt ASC',
    );

    return result
        .map(_mapToTask)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // MARK TASK AS SYNCED
  // ---------------------------------------------------------------------------

  Future<void> markAsSynced(
      TaskModel task,
      ) async {
    final db = await _database;

    final syncedTask = task.copyWith(
      isSynced: true,
      syncAction: SyncAction.none,
    );

    await db.update(
      'tasks',
      _taskToMap(syncedTask),
      where: 'userId = ? AND id = ?',
      whereArgs: [
        task.userId,
        task.id,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // WATCH TASKS
  // ---------------------------------------------------------------------------
  //
  // sqflite itself does not provide a realtime stream like Firestore.
  // We will later let TaskProvider refresh this data after every local
  // operation and after synchronization.
  //
  // For now, this method is intentionally not a Stream.
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> refreshTasks(
      String userId,
      ) async {
    return await getTasks(userId);
  }

  // ---------------------------------------------------------------------------
  // DELETE ALL TASKS FOR USER
  // ---------------------------------------------------------------------------
  //
  // Used when a GUEST logs out.
  //
  // IMPORTANT:
  // We only delete tasks belonging to the specified user.
  // Google user's tasks are therefore never affected by another user's logout.
  // ---------------------------------------------------------------------------

  Future<void> deleteAllTasksForUser(
      String userId,
      ) async {
    final db = await _database;

    await db.delete(
      'tasks',
      where: 'userId = ?',
      whereArgs: [
        userId,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE SYNCHRONIZED DELETED TASK
  // ---------------------------------------------------------------------------
  //
  // Once a deleted task has successfully been removed/marked on Firestore,
  // we can remove the local copy.
  //
  // This prevents the SQLite database from growing indefinitely.
  // ---------------------------------------------------------------------------

  Future<void> permanentlyDeleteTask(
      TaskModel task,
      ) async {
    final db = await _database;

    await db.delete(
      'tasks',
      where: 'userId = ? AND id = ?',
      whereArgs: [
        task.userId,
        task.id,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CONVERT TASK → SQLITE MAP
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _taskToMap(
      TaskModel task,
      ) {
    return {
      'id': task.id,
      'userId': task.userId,

      'title': task.title,
      'description': task.description,

      'priority': task.priority.name,

      'dueDate': task.dueDate?.toIso8601String(),

      'isCompleted':
      task.isCompleted ? 1 : 0,

      'isDeleted':
      task.isDeleted ? 1 : 0,

      'createdAt':
      task.createdAt.toIso8601String(),

      'updatedAt':
      task.updatedAt?.toIso8601String(),

      'isSynced':
      task.isSynced ? 1 : 0,

      'syncAction':
      task.syncAction.name,
    };
  }

  // ---------------------------------------------------------------------------
  // CONVERT SQLITE MAP → TASK
  // ---------------------------------------------------------------------------

  TaskModel _mapToTask(
      Map<String, dynamic> map,
      ) {
    return TaskModel(
      id: map['id'] as String,

      userId: map['userId'] as String,

      title: map['title'] as String,

      description:
      map['description'] as String,

      priority: TaskPriority.values.firstWhere(
            (priority) =>
        priority.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),

      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(
        map['dueDate'].toString(),
      )
          : null,

      isCompleted:
      map['isCompleted'] == 1,

      isDeleted:
      map['isDeleted'] == 1,

      createdAt: DateTime.parse(
        map['createdAt'].toString(),
      ),

      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(
        map['updatedAt'].toString(),
      )
          : null,

      isSynced:
      map['isSynced'] == 1,

      syncAction: SyncAction.values.firstWhere(
            (action) =>
        action.name == map['syncAction'],
        orElse: () => SyncAction.none,
      ),
    );
  }
}