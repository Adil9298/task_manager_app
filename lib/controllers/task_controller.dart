import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskController {
  final TaskRepository _taskRepository;

  TaskController({
    TaskRepository? taskRepository,
  }) : _taskRepository =
      taskRepository ?? TaskRepository();

  // ---------------------------------------------------------------------------
  // GET LOCAL TASKS
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getTasks(
      String userId,
      ) async {
    return await _taskRepository.getLocalTasks(
      userId,
    );
  }

  // ---------------------------------------------------------------------------
  // GET SINGLE TASK
  // ---------------------------------------------------------------------------

  Future<TaskModel?> getTask({
    required String userId,
    required String taskId,
  }) async {
    return await _taskRepository.getLocalTask(
      userId: userId,
      taskId: taskId,
    );
  }

  // ---------------------------------------------------------------------------
  // ADD TASK
  // ---------------------------------------------------------------------------

  Future<void> addTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    await _taskRepository.createTask(
      task,
      isOnline: isOnline,
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE TASK
  // ---------------------------------------------------------------------------

  Future<void> updateTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    await _taskRepository.updateTask(
      task,
      isOnline: isOnline,
    );
  }

  // ---------------------------------------------------------------------------
  // TOGGLE TASK
  // ---------------------------------------------------------------------------

  Future<void> toggleTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    await _taskRepository.toggleTask(
      task,
      isOnline: isOnline,
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE TASK
  // ---------------------------------------------------------------------------

  Future<void> deleteTask(
      TaskModel task, {
        required bool isOnline,
      }) async {
    await _taskRepository.deleteTask(
      task,
      isOnline: isOnline,
    );
  }

  // ---------------------------------------------------------------------------
  // PENDING SYNC TASKS
  // ---------------------------------------------------------------------------

  Future<List<TaskModel>> getPendingSyncTasks(
      String userId,
      ) async {
    return await _taskRepository.getPendingSyncTasks(
      userId,
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC CREATE
  // ---------------------------------------------------------------------------

  Future<void> syncCreate(
      TaskModel task,
      ) async {
    await _taskRepository.syncCreate(task);
  }

  // ---------------------------------------------------------------------------
  // SYNC UPDATE
  // ---------------------------------------------------------------------------

  Future<void> syncUpdate(
      TaskModel task,
      ) async {
    await _taskRepository.syncUpdate(task);
  }

  // ---------------------------------------------------------------------------
  // SYNC DELETE
  // ---------------------------------------------------------------------------

  Future<void> syncDelete(
      TaskModel task,
      ) async {
    await _taskRepository.syncDelete(task);
  }

  // ---------------------------------------------------------------------------
  // DELETE ALL LOCAL TASKS
  // ---------------------------------------------------------------------------

  Future<void> deleteAllLocalTasksForUser(
      String userId,
      ) async {
    await _taskRepository
        .deleteAllLocalTasksForUser(userId);
  }
}