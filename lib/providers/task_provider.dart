import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/task_controller.dart';
import '../models/task_model.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

enum TaskFilter {
  all,
  completed,
  pending,
}

enum TaskSort {
  dueDate,
  priority,
}

class TaskProvider extends ChangeNotifier {
  final TaskController _taskController;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  TaskProvider({
    TaskController? taskController,
    ConnectivityService? connectivityService,
    SyncService? syncService,
  })  : _taskController =
      taskController ?? TaskController(),
        _connectivityService =
            connectivityService ??
                ConnectivityService(),
        _syncService =
            syncService ?? SyncService();

  // ===========================================================================
  // STATE
  // ===========================================================================

  List<TaskModel> _tasks = [];

  String? _currentUserId;

  bool _isLoading = false;
  bool _isAdding = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isSyncing = false;

  bool _isOnline = false;

  String? _errorMessage;

  TaskFilter _filter = TaskFilter.all;

  TaskSort _sort = TaskSort.dueDate;

  String _searchQuery = '';

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  /// All locally stored tasks.
  List<TaskModel> get allTasks {
    return List.unmodifiable(_tasks);
  }

  /// Tasks after search + filter + sorting.
  ///
  /// This is what the UI should display.
  List<TaskModel> get visibleTasks {
    return _filteredAndSortedTasks;
  }

  /// Kept for convenience/backward compatibility.
  List<TaskModel> get tasks {
    return _filteredAndSortedTasks;
  }

  bool get isLoading => _isLoading;

  bool get isAdding => _isAdding;

  bool get isUpdating => _isUpdating;

  bool get isDeleting => _isDeleting;

  bool get isSyncing => _isSyncing;

  bool get isOnline => _isOnline;

  bool get isOffline => !_isOnline;

  String? get errorMessage => _errorMessage;

  TaskFilter get filter => _filter;

  TaskSort get sort => _sort;

  String get searchQuery => _searchQuery;

  bool get hasTasks => _tasks.isNotEmpty;

  bool get hasVisibleTasks =>
      _filteredAndSortedTasks.isNotEmpty;

  int get totalCount => _tasks.length;

  int get completedCount {
    return _tasks
        .where((task) => task.isCompleted)
        .length;
  }

  int get pendingCount {
    return _tasks
        .where((task) => !task.isCompleted)
        .length;
  }

  int get unsyncedCount {
    return _tasks
        .where((task) => !task.isSynced)
        .length;
  }

  // ===========================================================================
  // LOAD TASKS
  // ===========================================================================

  Future<void> loadTasks(
      String userId,
      ) async {
    _currentUserId = userId;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // -----------------------------------------------------------------------
      // CHECK INTERNET
      // -----------------------------------------------------------------------

      _isOnline =
      await _connectivityService.isOnline();

      // -----------------------------------------------------------------------
      // LOAD LOCAL SQLITE DATA FIRST
      // -----------------------------------------------------------------------
      //
      // This makes the application offline-first.
      //
      // The UI does not wait for Firestore.
      //
      // -----------------------------------------------------------------------

      _tasks =
      await _taskController.getTasks(
        userId,
      );

      notifyListeners();

      // -----------------------------------------------------------------------
      // INITIALIZE SYNC SERVICE
      // -----------------------------------------------------------------------

      await _syncService.initialize(
        userId,
      );

      // -----------------------------------------------------------------------
      // SYNC IF ONLINE
      // -----------------------------------------------------------------------

      if (_isOnline) {
        await syncTasks(
          notify: false,
        );

        // Reload SQLite after sync.
        _tasks =
        await _taskController.getTasks(
          userId,
        );
      }
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // ADD TASK
  // ===========================================================================

  Future<void> addTask({
    required String userId,
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
  }) async {
    _isAdding = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _isOnline =
      await _connectivityService.isOnline();

      final task = TaskModel(
        id: _generateTaskId(),
        userId: userId,

        title: title,
        description: description,

        priority: priority,
        dueDate: dueDate,

        isCompleted: false,
        isDeleted: false,

        createdAt: DateTime.now(),
        updatedAt: null,

        isSynced: false,
        syncAction: SyncAction.create,
      );

      // -----------------------------------------------------------------------
      // REPOSITORY
      // -----------------------------------------------------------------------

      await _taskController.addTask(
        task,
        isOnline: _isOnline,
      );

      // -----------------------------------------------------------------------
      // RELOAD LOCAL DATA
      // -----------------------------------------------------------------------

      _tasks =
      await _taskController.getTasks(
        userId,
      );

      // -----------------------------------------------------------------------
      // SYNC
      // -----------------------------------------------------------------------

      if (_isOnline) {
        await syncTasks(
          notify: false,
        );

        _tasks =
        await _taskController.getTasks(
          userId,
        );
      }
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      rethrow;
    } finally {
      _isAdding = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // UPDATE TASK
  // ===========================================================================

  Future<void> updateTask({
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
  }) async {
    _isUpdating = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _isOnline =
      await _connectivityService.isOnline();

      final updatedTask =
      task.copyWith(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        updatedAt: DateTime.now(),
        isSynced: false,
        syncAction: _getUpdateSyncAction(
          task,
        ),
      );

      await _taskController.updateTask(
        updatedTask,
        isOnline: _isOnline,
      );

      _tasks =
      await _taskController.getTasks(
        task.userId,
      );

      if (_isOnline) {
        await syncTasks(
          notify: false,
        );

        _tasks =
        await _taskController.getTasks(
          task.userId,
        );
      }
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      rethrow;
    } finally {
      _isUpdating = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // TOGGLE COMPLETION
  // ===========================================================================

  Future<void> toggleTask(
      TaskModel task,
      ) async {
    _errorMessage = null;

    try {
      _isOnline =
      await _connectivityService.isOnline();

      await _taskController.toggleTask(
        task,
        isOnline: _isOnline,
      );

      _tasks =
      await _taskController.getTasks(
        task.userId,
      );

      if (_isOnline) {
        await syncTasks(
          notify: false,
        );

        _tasks =
        await _taskController.getTasks(
          task.userId,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      notifyListeners();

      rethrow;
    }
  }

  // ===========================================================================
  // DELETE TASK
  // ===========================================================================

  Future<void> deleteTask(
      TaskModel task,
      ) async {
    _isDeleting = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _isOnline =
      await _connectivityService.isOnline();

      await _taskController.deleteTask(
        task,
        isOnline: _isOnline,
      );

      _tasks =
      await _taskController.getTasks(
        task.userId,
      );

      if (_isOnline) {
        await syncTasks(
          notify: false,
        );

        _tasks =
        await _taskController.getTasks(
          task.userId,
        );
      }
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      rethrow;
    } finally {
      _isDeleting = false;

      notifyListeners();
    }
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void setSearchQuery(
      String query,
      ) {
    _searchQuery = query;

    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';

    notifyListeners();
  }

  // ===========================================================================
  // FILTER
  // ===========================================================================

  void setFilter(
      TaskFilter filter,
      ) {
    _filter = filter;

    notifyListeners();
  }

  // ===========================================================================
  // SORT
  // ===========================================================================

  void setSort(
      TaskSort sort,
      ) {
    _sort = sort;

    notifyListeners();
  }

  // ===========================================================================
  // FILTER + SEARCH + SORT
  // ===========================================================================

  List<TaskModel> get _filteredAndSortedTasks {
    List<TaskModel> result =
    List<TaskModel>.from(_tasks);

    // -------------------------------------------------------------------------
    // SEARCH
    // -------------------------------------------------------------------------

    final query =
    _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((task) {
        final title =
        task.title.toLowerCase();

        final description =
        task.description.toLowerCase();

        return title.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // -------------------------------------------------------------------------
    // FILTER
    // -------------------------------------------------------------------------

    switch (_filter) {
      case TaskFilter.all:
        break;

      case TaskFilter.completed:
        result = result
            .where(
              (task) => task.isCompleted,
        )
            .toList();

        break;

      case TaskFilter.pending:
        result = result
            .where(
              (task) => !task.isCompleted,
        )
            .toList();

        break;
    }

    // -------------------------------------------------------------------------
    // SORT
    // -------------------------------------------------------------------------

    switch (_sort) {
      case TaskSort.dueDate:
        result.sort(
              (a, b) {
            // No due date → move to bottom.
            if (a.dueDate == null &&
                b.dueDate == null) {
              return 0;
            }

            if (a.dueDate == null) {
              return 1;
            }

            if (b.dueDate == null) {
              return -1;
            }

            return a.dueDate!
                .compareTo(b.dueDate!);
          },
        );

        break;

      case TaskSort.priority:
        result.sort(
              (a, b) {
            return _priorityValue(
              b.priority,
            ).compareTo(
              _priorityValue(
                a.priority,
              ),
            );
          },
        );

        break;
    }

    return result;
  }

  // ===========================================================================
  // PRIORITY VALUE
  // ===========================================================================

  int _priorityValue(
      TaskPriority priority,
      ) {
    switch (priority) {
      case TaskPriority.low:
        return 1;

      case TaskPriority.medium:
        return 2;

      case TaskPriority.high:
        return 3;
    }
  }

  // ===========================================================================
  // SYNC
  // ===========================================================================

  Future<void> syncTasks({
    bool notify = true,
  }) async {
    if (_currentUserId == null) {
      return;
    }

    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    if (notify) {
      notifyListeners();
    }

    try {
      _isOnline =
      await _connectivityService.isOnline();

      if (!_isOnline) {
        return;
      }

      await _syncService.sync(
        _currentUserId!,
      );

      _tasks =
      await _taskController.getTasks(
        _currentUserId!,
      );
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);
    } finally {
      _isSyncing = false;

      if (notify) {
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // REFRESH LOCAL TASKS
  // ===========================================================================

  Future<void> refreshTasks() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      _tasks =
      await _taskController.getTasks(
        _currentUserId!,
      );

      notifyListeners();
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      notifyListeners();
    }
  }

  // ===========================================================================
  // CLEAR LOCAL TASKS
  // ===========================================================================
  //
  // Used specifically for guest logout.
  //
  // IMPORTANT:
  // This does NOT delete Firestore tasks.
  // It only removes the local SQLite data.
  //
  // ===========================================================================

  Future<void> clearLocalTasks(
      String userId,
      ) async {
    try {
      await _taskController
          .deleteAllLocalTasksForUser(
        userId,
      );

      _tasks = _tasks
          .where(
            (task) => task.userId != userId,
      )
          .toList();

      notifyListeners();
    } catch (e) {
      _errorMessage =
          _cleanErrorMessage(e);

      notifyListeners();

      rethrow;
    }
  }

  // ===========================================================================
  // CLEAR PROVIDER
  // ===========================================================================

  Future<void> clearTasks() async {
    _tasks = [];

    _currentUserId = null;

    _searchQuery = '';

    _filter = TaskFilter.all;

    _sort = TaskSort.dueDate;

    _errorMessage = null;

    await _syncService.dispose();

    notifyListeners();
  }

  // ===========================================================================
  // UPDATE SYNC ACTION
  // ===========================================================================

  SyncAction _getUpdateSyncAction(
      TaskModel task,
      ) {
    // If this task was created offline and has
    // not reached Firestore yet, keep it as CREATE.
    //
    // Example:
    //
    // Create offline
    //     ↓
    // syncAction = create
    //
    // Edit offline
    //     ↓
    // still CREATE
    //
    // The latest version will be uploaded
    // when synchronization happens.

    if (task.syncAction ==
        SyncAction.create &&
        !task.isSynced) {
      return SyncAction.create;
    }

    return SyncAction.update;
  }

  // ===========================================================================
  // GENERATE TASK ID
  // ===========================================================================

  String _generateTaskId() {
    final now =
    DateTime.now();

    return '${now.microsecondsSinceEpoch}_'
        '${now.millisecondsSinceEpoch}';
  }

  // ===========================================================================
  // ERROR MESSAGE
  // ===========================================================================

  String _cleanErrorMessage(
      Object error,
      ) {
    final message =
    error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _syncService.dispose();

    super.dispose();
  }
}