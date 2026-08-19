import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailsScreen> createState() =>
      _TaskDetailsScreenState();
}

class _TaskDetailsScreenState
    extends State<TaskDetailsScreen> {

  // ===========================================================================
  // DELETE CONFIRMATION
  // ===========================================================================

  Future<void> _confirmDelete() async {
    final theme = Theme.of(context);

    final shouldDelete =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Delete Task',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'Are you sure you want to delete this task? '
                'This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                theme.colorScheme.error,
                foregroundColor:
                theme.colorScheme.onError,
              ),

              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true ||
        !mounted) {
      return;
    }

    await _deleteTask();
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> _deleteTask() async {
    final provider =
    context.read<TaskProvider>();

    try {
      await provider.deleteTask(
        widget.task,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(
                Icons
                    .check_circle_outline_rounded,
                color: Colors.white,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  provider.isOnline
                      ? 'Task deleted successfully.'
                      : 'Task deleted offline. '
                      'The change will sync later.',
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        provider.errorMessage ??
            'Failed to delete task.',
      );
    }
  }

  // ===========================================================================
  // TOGGLE COMPLETION
  // ===========================================================================

  Future<void> _toggleCompletion() async {
    final provider =
    context.read<TaskProvider>();

    try {
      await provider.toggleTask(
        widget.task,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          content: Row(
            children: [
              Icon(
                widget.task.isCompleted
                    ? Icons
                    .radio_button_unchecked_rounded
                    : Icons
                    .check_circle_outline_rounded,
                color: Colors.white,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  widget.task.isCompleted
                      ? 'Task marked as pending.'
                      : 'Task marked as completed.',
                ),
              ),
            ],
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        provider.errorMessage ??
            'Failed to update task.',
      );
    }
  }

  // ===========================================================================
  // EDIT
  // ===========================================================================

  Future<void> _editTask() async {
    final result =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TaskFormScreen(
              task: widget.task,
            ),
      ),
    );

    if (result == true &&
        mounted) {
      setState(() {});
    }
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  void _showError(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          backgroundColor:
          Theme.of(context)
              .colorScheme
              .error,

          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }

  // ===========================================================================
  // FORMAT DATE
  // ===========================================================================

  String _formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Not set';
    }

    final day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  // ===========================================================================
  // FORMAT DATE + TIME
  // ===========================================================================

  String _formatDateTime(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Not available';
    }

    final day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    final hour =
    date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute =
    date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}  '
        '$hour:$minute';
  }

  // ===========================================================================
  // PRIORITY LABEL
  // ===========================================================================

  String _priorityLabel(
      TaskPriority priority,
      ) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';

      case TaskPriority.medium:
        return 'Medium';

      case TaskPriority.high:
        return 'High';
    }
  }

  // ===========================================================================
  // PRIORITY ICON
  // ===========================================================================

  IconData _priorityIcon(
      TaskPriority priority,
      ) {
    switch (priority) {
      case TaskPriority.low:
        return Icons
            .keyboard_arrow_down_rounded;

      case TaskPriority.medium:
        return Icons.remove_rounded;

      case TaskPriority.high:
        return Icons
            .keyboard_arrow_up_rounded;
    }
  }

  // ===========================================================================
  // PRIORITY COLOR
  // ===========================================================================

  Color _priorityColor(
      BuildContext context,
      TaskPriority priority,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    switch (priority) {
      case TaskPriority.low:
        return colors.primary;

      case TaskPriority.medium:
        return colors.tertiary;

      case TaskPriority.high:
        return colors.error;
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final provider =
    context.watch<TaskProvider>();

    final isDeleting =
        provider.isDeleting;

    return Scaffold(
      backgroundColor:
      colors.surface,

      // =======================================================================
      // APP BAR
      // =======================================================================

      appBar: AppBar(
        backgroundColor:
        colors.surface,

        elevation: 0,

        leading: IconButton(
          tooltip: 'Back',

          onPressed: isDeleting
              ? null
              : () {
            Navigator.pop(
              context,
            );
          },

          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Task Details',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Edit Task',

            onPressed:
            isDeleting
                ? null
                : _editTask,

            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),

          PopupMenuButton<String>(
            enabled: !isDeleting,

            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              }
            },

            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',

                child: Row(
                  children: [
                    Icon(
                      Icons
                          .delete_outline_rounded,
                      color:
                      colors.error,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    const Text(
                      'Delete Task',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // =======================================================================
      // BODY
      // =======================================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 700,
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // =============================================================
                  // STATUS
                  // =============================================================

                  _StatusCard(
                    task: widget.task,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =============================================================
                  // TASK INFORMATION
                  // =============================================================

                  Container(
                    width: double.infinity,

                    padding:
                    const EdgeInsets.all(
                      22,
                    ),

                    decoration:
                    BoxDecoration(
                      color: colors
                          .surfaceContainerLow,

                      borderRadius:
                      BorderRadius.circular(
                        22,
                      ),

                      border:
                      Border.all(
                        color: colors
                            .outlineVariant,
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [

                        // TITLE
                        Text(
                          widget.task.title,

                          style: theme
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight:
                            FontWeight.w700,
                            height: 1.2,
                            decoration: widget
                                .task
                                .isCompleted
                                ? TextDecoration
                                .lineThrough
                                : null,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // DESCRIPTION
                        Text(
                          widget.task.description,

                          style: theme
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                            color: colors
                                .onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // PRIORITY
                        _InfoRow(
                          icon: _priorityIcon(
                            widget.task.priority,
                          ),

                          title: 'Priority',

                          value:
                          _priorityLabel(
                            widget.task.priority,
                          ),

                          iconColor:
                          _priorityColor(
                            context,
                            widget.task
                                .priority,
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // DUE DATE
                        _InfoRow(
                          icon: Icons
                              .calendar_today_rounded,

                          title:
                          'Due Date',

                          value:
                          _formatDate(
                            widget.task.dueDate,
                          ),

                          iconColor:
                          colors.primary,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // CREATED
                        _InfoRow(
                          icon: Icons
                              .add_circle_outline_rounded,

                          title:
                          'Created',

                          value:
                          _formatDateTime(
                            widget.task
                                .createdAt,
                          ),

                          iconColor:
                          colors.primary,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // UPDATED
                        _InfoRow(
                          icon: Icons
                              .update_rounded,

                          title:
                          'Last Updated',

                          value:
                          _formatDateTime(
                            widget.task
                                .updatedAt,
                          ),

                          iconColor:
                          colors.secondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =============================================================
                  // SYNC INFORMATION
                  // =============================================================

                  _SyncCard(
                    task: widget.task,
                    isOnline:
                    provider.isOnline,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =============================================================
                  // COMPLETE BUTTON
                  // =============================================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 52,

                    child: FilledButton.icon(
                      onPressed:
                      isDeleting
                          ? null
                          : _toggleCompletion,

                      icon: Icon(
                        widget.task
                            .isCompleted
                            ? Icons
                            .radio_button_unchecked_rounded
                            : Icons
                            .check_circle_outline_rounded,
                      ),

                      label: Text(
                        widget.task
                            .isCompleted
                            ? 'Mark as Pending'
                            : 'Mark as Completed',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // =============================================================
                  // EDIT BUTTON
                  // =============================================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 52,

                    child:
                    OutlinedButton.icon(
                      onPressed:
                      isDeleting
                          ? null
                          : _editTask,

                      icon: const Icon(
                        Icons.edit_outlined,
                      ),

                      label: const Text(
                        'Edit Task',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // =============================================================
                  // DELETE BUTTON
                  // =============================================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 52,

                    child:
                    OutlinedButton.icon(
                      style:
                      OutlinedButton
                          .styleFrom(
                        foregroundColor:
                        colors.error,

                        side: BorderSide(
                          color: colors
                              .error,
                        ),
                      ),

                      onPressed:
                      isDeleting
                          ? null
                          : _confirmDelete,

                      icon: isDeleting
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          colors.error,
                        ),
                      )
                          : const Icon(
                        Icons
                            .delete_outline_rounded,
                      ),

                      label: Text(
                        isDeleting
                            ? 'Deleting...'
                            : 'Delete Task',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STATUS CARD
// =============================================================================

class _StatusCard extends StatelessWidget {
  final TaskModel task;

  const _StatusCard({
    required this.task,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final completed =
        task.isCompleted;

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: completed
            ? colors.primaryContainer
            : colors.secondaryContainer,

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration:
            BoxDecoration(
              color: completed
                  ? colors.primary
                  : colors.secondary,

              shape: BoxShape.circle,
            ),

            child: Icon(
              completed
                  ? Icons
                  .check_rounded
                  : Icons
                  .schedule_rounded,

              color: completed
                  ? colors.onPrimary
                  : colors.onSecondary,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                Text(
                  completed
                      ? 'Completed'
                      : 'Pending',

                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  completed
                      ? 'This task has been completed.'
                      : 'This task is waiting to be completed.',

                  style: theme
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// INFO ROW
// =============================================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,

          decoration: BoxDecoration(
            color: iconColor
                .withValues(
              alpha: 0.10,
            ),

            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),

          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,

            children: [
              Text(
                title,

                style: theme
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,

                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SYNC CARD
// =============================================================================

class _SyncCard
    extends StatelessWidget {
  final TaskModel task;
  final bool isOnline;

  const _SyncCard({
    required this.task,
    required this.isOnline,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colors =
        theme.colorScheme;

    final synced =
        task.isSynced;

    final icon =
    synced
        ? Icons.cloud_done_rounded
        : Icons.cloud_upload_rounded;

    final title =
    synced
        ? 'Synchronized'
        : 'Waiting for synchronization';

    final subtitle =
    synced
        ? 'This task is synchronized with the server.'
        : isOnline
        ? 'This task will be synchronized shortly.'
        : 'You are offline. Changes will sync when connection returns.';

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors
            .surfaceContainerLow,

        borderRadius:
        BorderRadius.circular(
          16,
        ),

        border:
        Border.all(
          color: colors
              .outlineVariant,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: synced
                ? colors.primary
                : colors.tertiary,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                Text(
                  title,

                  style: theme
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,

                  style: theme
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                    color: colors
                        .onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}