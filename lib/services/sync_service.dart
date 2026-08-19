import 'dart:async';

import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import 'connectivity_service.dart';

class SyncService {
  final TaskRepository _taskRepository;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;

  bool _isSyncing = false;

  SyncService({
    TaskRepository? taskRepository,
    ConnectivityService? connectivityService,
  })  : _taskRepository =
      taskRepository ?? TaskRepository(),
        _connectivityService =
            connectivityService ?? ConnectivityService();

  // ---------------------------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------------------------

  Future<void> initialize(String userId) async {
    // Check the current connection immediately.
    final isOnline =
    await _connectivityService.isOnline();

    if (isOnline) {
      await sync(userId);
    }

    // Listen for future connectivity changes.
    _connectivitySubscription =
        _connectivityService.connectionStream.listen(
              (isOnline) async {
            if (!isOnline) {
              return;
            }

            await sync(userId);
          },
        );
  }

  // ---------------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------------

  Future<void> sync(String userId) async {
    // Prevent two sync operations from running
    // at the same time.
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      final isOnline =
      await _connectivityService.isOnline();

      if (!isOnline) {
        return;
      }

      final pendingTasks =
      await _taskRepository.getPendingSyncTasks(
        userId,
      );

      if (pendingTasks.isEmpty) {
        return;
      }

      for (final task in pendingTasks) {
        try {
          await _syncTask(task);
        } catch (e) {
          // Do not stop the entire synchronization process
          // if one task fails.
          //
          // The failed task remains unsynced and will
          // be retried during the next synchronization.
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC SINGLE TASK
  // ---------------------------------------------------------------------------

  Future<void> _syncTask(
      TaskModel task,
      ) async {
    switch (task.syncAction) {
      case SyncAction.create:
        await _taskRepository.syncCreate(task);
        break;

      case SyncAction.update:
        await _taskRepository.syncUpdate(task);
        break;

      case SyncAction.delete:
        await _taskRepository.syncDelete(task);
        break;

      case SyncAction.none:
      // Nothing needs to be synchronized.
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // MANUAL SYNC
  // ---------------------------------------------------------------------------

  Future<void> syncNow(String userId) async {
    await sync(userId);
  }

  // ---------------------------------------------------------------------------
  // STOP LISTENING
  // ---------------------------------------------------------------------------

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();

    _connectivitySubscription = null;

    await _connectivityService.dispose();
  }
}