import '../models/task_model.dart';
import '../services/task_local_service.dart';
import '../services/task_service.dart';

class TaskRepository {
  final TaskLocalService _localService;
  final TaskService _firestoreService;

  TaskRepository({
    TaskLocalService? localService,
    TaskService? firestoreService,
  })  : _localService =
      localService ?? TaskLocalService(),
        _firestoreService =
            firestoreService ?? TaskService();

  // ---------------------------------------------------------------------------
  // GET LOCAL TASKS
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getLocalTasks(
      String userId,
      ) async {
    return await _localService.getTasks(
      userId,
    );
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE LOCAL TASK
  // ---------------------------------------------------------------------------

  Future<TaskModel?> getLocalTask({
    required String userId,
    required String taskId,
  }) async {
    return await _localService.getTask(
      userId: userId,
      taskId: taskId,
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE TASK
  // ---------------------------------------------------------------------------

  Future<void> createTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    // -------------------------------------------------------------------------
    // OFFLINE
    // -------------------------------------------------------------------------
    //
    // Store the task locally and mark it as waiting for synchronization.
    //
    // -------------------------------------------------------------------------

    if (!isOnline) {
      final offlineTask = task.copyWith(
        isSynced: false,
        syncAction: SyncAction.create,
      );

      await _localService.insertTask(
        offlineTask,
      );

      return;
    }

    // -------------------------------------------------------------------------
    // ONLINE
    // -------------------------------------------------------------------------
    //
    // Save locally first.
    //
    // Local database is our immediate source for the UI.
    //
    // -------------------------------------------------------------------------

    final localTask = task.copyWith(
      isSynced: false,
      syncAction: SyncAction.create,
    );

    await _localService.insertTask(
      localTask,
    );

    try {
      // Send to Firestore.
      await _firestoreService.addTask(
        task: task,
      );

      // Firestore succeeded.
      await _localService.markAsSynced(
        localTask,
      );
    } catch (e) {
      // Keep the task locally as pending.
      //
      // The SyncService will retry it later.
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE TASK
  // ---------------------------------------------------------------------------

  Future<void> updateTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    // -------------------------------------------------------------------------
    // UPDATE LOCAL DATABASE FIRST
    // -------------------------------------------------------------------------

    final localTask = task.copyWith(
      updatedAt: DateTime.now(),
      isSynced: false,
      syncAction: SyncAction.update,
    );

    await _localService.updateTask(
      localTask,
    );

    // -------------------------------------------------------------------------
    // OFFLINE
    // -------------------------------------------------------------------------

    if (!isOnline) {
      return;
    }

    // -------------------------------------------------------------------------
    // ONLINE
    // -------------------------------------------------------------------------

    try {
      await _firestoreService.updateTask(
        task: localTask,
      );

      await _localService.markAsSynced(
        localTask,
      );
    } catch (e) {
      // Keep the local task pending.
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // TOGGLE COMPLETION
  // ---------------------------------------------------------------------------

  Future<void> toggleTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
      isSynced: false,
      syncAction: SyncAction.update,
    );

    await _localService.updateTask(
      updatedTask,
    );

    if (!isOnline) {
      return;
    }

    try {
      await _firestoreService.updateTask(
        task: updatedTask,
      );

      await _localService.markAsSynced(
        updatedTask,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE TASK
  // ---------------------------------------------------------------------------

  Future<void> deleteTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    final deletedTask = task.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
      isSynced: false,
      syncAction: SyncAction.delete,
    );

    // -------------------------------------------------------------------------
    // ALWAYS MARK DELETED LOCALLY FIRST
    // -------------------------------------------------------------------------

    await _localService.updateTask(
      deletedTask,
    );

    // -------------------------------------------------------------------------
    // OFFLINE
    // -------------------------------------------------------------------------

    if (!isOnline) {
      return;
    }

    // -------------------------------------------------------------------------
    // ONLINE
    // -------------------------------------------------------------------------

    try {
      await _firestoreService.deleteTask(
        task: deletedTask,
      );

      // Once Firestore confirms the deletion,
      // we no longer need the local deleted record.
      await _localService.permanentlyDeleteTask(
        deletedTask,
      );
    } catch (e) {
      // Keep it locally as:
      //
      // isDeleted = true
      // isSynced = false
      // syncAction = delete
      //
      // SyncService will retry it later.
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // GET PENDING SYNCHRONIZATION TASKS
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getPendingSyncTasks(
      String userId,
      ) async {
    return await _localService.getPendingSyncTasks(
      userId,
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC CREATE
  // ---------------------------------------------------------------------------

  Future<void> syncCreate(
      TaskModel task,
      ) async {
    await _firestoreService.addTask(
      task: task,
    );

    await _localService.markAsSynced(
      task,
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC UPDATE
  // ---------------------------------------------------------------------------

  Future<void> syncUpdate(
      TaskModel task,
      ) async {
    await _firestoreService.updateTask(
      task: task,
    );

    await _localService.markAsSynced(
      task,
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC DELETE
  // ---------------------------------------------------------------------------

  Future<void> syncDelete(
      TaskModel task,
      ) async {
    await _firestoreService.deleteTask(
      task: task,
    );

    await _localService.permanentlyDeleteTask(
      task,
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE ALL LOCAL TASKS FOR USER
  // ---------------------------------------------------------------------------
  //
  // Used when a guest logs out.
  //
  // Google users should NOT call this.
  //
  // ---------------------------------------------------------------------------

  Future<void> deleteAllLocalTasksForUser(
      String userId,
      ) async {
    await _localService.deleteAllTasksForUser(
      userId,
    );
  }
}