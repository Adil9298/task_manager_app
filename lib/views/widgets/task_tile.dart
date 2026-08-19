import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../screens/task_details_screen.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;

  const TaskTile({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        // ---------------------------------------------------------------
        // OPEN TASK DETAILS
        // ---------------------------------------------------------------

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailsScreen(
                task: task,
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---------------------------------------------------------
              // COMPLETION CHECKBOX
              // ---------------------------------------------------------

              Padding(
                padding: const EdgeInsets.only(
                  top: 2,
                  right: 12,
                ),
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) {
                    context
                        .read<TaskProvider>()
                        .toggleTask(task);
                  },
                ),
              ),

              // ---------------------------------------------------------
              // TASK CONTENT
              // ---------------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    // TITLE
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),

                    // DESCRIPTION
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),

                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ---------------------------------------------------
                    // PRIORITY + DUE DATE
                    // ---------------------------------------------------

                    Row(
                      children: [

                        _PriorityBadge(
                          priority: task.priority,
                        ),

                        if (task.dueDate != null) ...[
                          const SizedBox(width: 8),

                          _DueDateBadge(
                            dueDate: task.dueDate!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ---------------------------------------------------------
              // ARROW
              // ---------------------------------------------------------

              Padding(
                padding: const EdgeInsets.only(
                  top: 4,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PRIORITY BADGE
// =============================================================================

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String label;

    switch (priority) {
      case TaskPriority.low:
        label = 'Low';
        break;

      case TaskPriority.medium:
        label = 'Medium';
        break;

      case TaskPriority.high:
        label = 'High';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

// =============================================================================
// DUE DATE BADGE
// =============================================================================

class _DueDateBadge extends StatelessWidget {
  final DateTime dueDate;

  const _DueDateBadge({
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final due = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    );

    final isOverdue =
    due.isBefore(today);

    final isToday =
    due.isAtSameMomentAs(today);

    String label;

    if (isToday) {
      label = 'Today';
    } else {
      label =
      '${dueDate.day.toString().padLeft(2, '0')}/'
          '${dueDate.month.toString().padLeft(2, '0')}/'
          '${dueDate.year}';
    }

    final color = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isOverdue
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 13,
            color: color,
          ),

          const SizedBox(width: 5),

          Text(
            isOverdue ? 'Overdue' : label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}