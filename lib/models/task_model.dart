enum TaskPriority {
  low,
  medium,
  high,
}

enum SyncAction {
  none,
  create,
  update,
  delete,
}

class TaskModel {
  final String id;
  final String userId;

  final String title;
  final String description;

  final TaskPriority priority;
  final DateTime? dueDate;

  final bool isCompleted;
  final bool isDeleted;

  final DateTime createdAt;
  final DateTime? updatedAt;

  // Local synchronization information
  final bool isSynced;
  final SyncAction syncAction;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.isCompleted,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    required this.syncAction,
  });

  // ---------------------------------------------------------------------------
  // FROM JSON
  // ---------------------------------------------------------------------------

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',

      title: json['title'] ?? '',
      description: json['description'] ?? '',

      priority: TaskPriority.values.firstWhere(
            (priority) => priority.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),

      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,

      isCompleted: json['isCompleted'] ?? false,
      isDeleted: json['isDeleted'] ?? false,

      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      ) ??
          DateTime.now(),

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(
        json['updatedAt'].toString(),
      )
          : null,

      isSynced: json['isSynced'] ?? true,

      syncAction: SyncAction.values.firstWhere(
            (action) => action.name == json['syncAction'],
        orElse: () => SyncAction.none,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TO JSON
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,

      'title': title,
      'description': description,

      'priority': priority.name,

      'dueDate': dueDate?.toIso8601String(),

      'isCompleted': isCompleted,
      'isDeleted': isDeleted,

      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),

      'isSynced': isSynced,
      'syncAction': syncAction.name,
    };
  }

  // ---------------------------------------------------------------------------
  // COPY WITH
  // ---------------------------------------------------------------------------

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskPriority? priority,

    Object? dueDate = _notProvided,

    bool? isCompleted,
    bool? isDeleted,

    DateTime? createdAt,

    Object? updatedAt = _notProvided,

    bool? isSynced,
    SyncAction? syncAction,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,

      title: title ?? this.title,
      description: description ?? this.description,

      priority: priority ?? this.priority,

      dueDate: dueDate == _notProvided
          ? this.dueDate
          : dueDate as DateTime?,

      isCompleted: isCompleted ?? this.isCompleted,
      isDeleted: isDeleted ?? this.isDeleted,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt == _notProvided
          ? this.updatedAt
          : updatedAt as DateTime?,

      isSynced: isSynced ?? this.isSynced,
      syncAction: syncAction ?? this.syncAction,
    );
  }
}

// -----------------------------------------------------------------------------
// COPY WITH SENTINEL
// -----------------------------------------------------------------------------

const Object _notProvided = Object();