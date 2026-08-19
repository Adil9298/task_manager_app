import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({
    super.key,
    this.task,
  });

  bool get isEditMode => task != null;

  @override
  State<TaskFormScreen> createState() =>
      _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  // ===========================================================================
  // FORM
  // ===========================================================================

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  TaskPriority _selectedPriority =
      TaskPriority.medium;

  DateTime? _selectedDueDate;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _titleController = TextEditingController(
      text: task?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );

    _selectedPriority =
        task?.priority ?? TaskPriority.medium;

    _selectedDueDate = task?.dueDate;
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // DATE PICKER
  // ===========================================================================

  Future<void> _selectDueDate() async {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    DateTime initialDate =
        _selectedDueDate ?? today;

    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(
        now.year + 10,
        now.month,
        now.day,
      ),
      helpText: 'Select due date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDueDate = pickedDate;
    });
  }

  // ===========================================================================
  // CLEAR DATE
  // ===========================================================================

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  Future<void> _saveTask() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider =
    context.read<AuthProvider>();

    final user =
        authProvider.currentUser;

    if (user == null) {
      _showErrorSnackBar(
        'User session not found.',
      );
      return;
    }

    final taskProvider =
    context.read<TaskProvider>();

    try {
      if (widget.isEditMode) {
        // ===============================================================
        // UPDATE
        // ===============================================================

        await taskProvider.updateTask(
          task: widget.task!,
          title: _titleController.text.trim(),
          description:
          _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );
        Navigator.pop(
          context,
          true,
        );
      } else {
        // ===============================================================
        // CREATE
        // ===============================================================

        await taskProvider.addTask(
          userId: user.uid,
          title: _titleController.text.trim(),
          description:
          _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        );
      }

      if (!mounted) {
        return;
      }

      final wasOnline =
          taskProvider.isOnline;

      Navigator.pop(
        context,
        true,
      );

      // Show the message after returning to the
      // previous screen.
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.isEditMode
                      ? wasOnline
                      ? 'Task updated successfully.'
                      : 'Task updated offline. Changes will sync later.'
                      : wasOnline
                      ? 'Task created successfully.'
                      : 'Task saved offline. It will sync later.',
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

      _showErrorSnackBar(
        taskProvider.errorMessage ??
            'Something went wrong. Please try again.',
      );
    }
  }

  // ===========================================================================
  // ERROR SNACKBAR
  // ===========================================================================

  void _showErrorSnackBar(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
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
  // DATE FORMAT
  // ===========================================================================

  String _formatDate(DateTime date) {
    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
        return Icons.keyboard_arrow_down_rounded;

      case TaskPriority.medium:
        return Icons.remove_rounded;

      case TaskPriority.high:
        return Icons.keyboard_arrow_up_rounded;
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final taskProvider =
    context.watch<TaskProvider>();

    final isSaving =
    widget.isEditMode
        ? taskProvider.isUpdating
        : taskProvider.isAdding;

    return PopScope(
      canPop: !isSaving,

      child: Scaffold(
        backgroundColor:
        theme.colorScheme.surface,

        // =====================================================================
        // APP BAR
        // =====================================================================

        appBar: AppBar(
          backgroundColor:
          theme.colorScheme.surface,
          elevation: 0,

          title: Text(
            widget.isEditMode
                ? 'Edit Task'
                : 'Create Task',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          leading: IconButton(
            tooltip: 'Back',

            onPressed: isSaving
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
        ),

        // =====================================================================
        // BODY
        // =====================================================================

        body: SafeArea(
          child: Form(
            key: _formKey,

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
                    maxWidth: 680,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      // ========================================================
                      // HEADER
                      // ========================================================

                      Text(
                        widget.isEditMode
                            ? 'Update your task'
                            : 'Create a new task',
                        style: theme
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        widget.isEditMode
                            ? 'Make changes to the task details below.'
                            : 'Add the details you need to stay organized.',
                        style: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(
                        height: 26,
                      ),

                      // ========================================================
                      // BASIC DETAILS
                      // ========================================================

                      _SectionCard(
                        title: 'Task Details',
                        subtitle:
                        'Give your task a clear title and description.',
                        child: Column(
                          children: [

                            // --------------------------------------------------
                            // TITLE
                            // --------------------------------------------------

                            TextFormField(
                              controller:
                              _titleController,

                              enabled: !isSaving,

                              textCapitalization:
                              TextCapitalization
                                  .sentences,

                              textInputAction:
                              TextInputAction.next,

                              maxLength: 100,

                              decoration:
                              const InputDecoration(
                                labelText:
                                'Title',
                                hintText:
                                'Enter task title',
                                prefixIcon:
                                Icon(
                                  Icons
                                      .title_rounded,
                                ),
                              ),

                              validator:
                                  (value) {
                                final text =
                                    value?.trim() ??
                                        '';

                                if (text.isEmpty) {
                                  return 'Task title is required';
                                }

                                if (text.length <
                                    3) {
                                  return 'Title must be at least 3 characters';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            // --------------------------------------------------
                            // DESCRIPTION
                            // --------------------------------------------------

                            TextFormField(
                              controller:
                              _descriptionController,

                              enabled: !isSaving,

                              textCapitalization:
                              TextCapitalization
                                  .sentences,

                              maxLines: 5,

                              maxLength: 500,

                              decoration:
                              const InputDecoration(
                                labelText:
                                'Description',
                                hintText:
                                'Describe what needs to be done',
                                alignLabelWithHint:
                                true,
                                prefixIcon:
                                Padding(
                                  padding:
                                  EdgeInsets.only(
                                    bottom: 76,
                                  ),
                                  child: Icon(
                                    Icons
                                        .notes_rounded,
                                  ),
                                ),
                              ),

                              validator:
                                  (value) {
                                final text =
                                    value?.trim() ??
                                        '';

                                if (text.isEmpty) {
                                  return 'Description is required';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ========================================================
                      // PRIORITY
                      // ========================================================

                      _SectionCard(
                        title: 'Priority',
                        subtitle:
                        'Choose the importance of this task.',
                        child: Row(
                          children: [
                            Expanded(
                              child:
                              _PriorityOption(
                                priority:
                                TaskPriority
                                    .low,
                                label:
                                _priorityLabel(
                                  TaskPriority
                                      .low,
                                ),
                                icon:
                                _priorityIcon(
                                  TaskPriority
                                      .low,
                                ),
                                selected:
                                _selectedPriority ==
                                    TaskPriority
                                        .low,
                                enabled:
                                !isSaving,
                                onTap: () {
                                  setState(() {
                                    _selectedPriority =
                                        TaskPriority
                                            .low;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                              _PriorityOption(
                                priority:
                                TaskPriority
                                    .medium,
                                label:
                                _priorityLabel(
                                  TaskPriority
                                      .medium,
                                ),
                                icon:
                                _priorityIcon(
                                  TaskPriority
                                      .medium,
                                ),
                                selected:
                                _selectedPriority ==
                                    TaskPriority
                                        .medium,
                                enabled:
                                !isSaving,
                                onTap: () {
                                  setState(() {
                                    _selectedPriority =
                                        TaskPriority
                                            .medium;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child:
                              _PriorityOption(
                                priority:
                                TaskPriority
                                    .high,
                                label:
                                _priorityLabel(
                                  TaskPriority
                                      .high,
                                ),
                                icon:
                                _priorityIcon(
                                  TaskPriority
                                      .high,
                                ),
                                selected:
                                _selectedPriority ==
                                    TaskPriority
                                        .high,
                                enabled:
                                !isSaving,
                                onTap: () {
                                  setState(() {
                                    _selectedPriority =
                                        TaskPriority
                                            .high;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ========================================================
                      // DUE DATE
                      // ========================================================

                      _SectionCard(
                        title: 'Due Date',
                        subtitle:
                        'Set an optional deadline for this task.',
                        child: _DueDateSelector(
                          selectedDate:
                          _selectedDueDate,
                          enabled:
                          !isSaving,
                          onSelect:
                          _selectDueDate,
                          onClear:
                          _clearDueDate,
                          formatDate:
                          _formatDate,
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ========================================================
                      // OFFLINE INDICATOR
                      // ========================================================

                      if (taskProvider.isOffline)
                        Container(
                          width:
                          double.infinity,
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),

                          decoration:
                          BoxDecoration(
                            color: theme
                                .colorScheme
                                .surfaceContainerLow,

                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),

                            border:
                            Border.all(
                              color: theme
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),

                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .cloud_off_rounded,
                                size: 18,
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Text(
                                  'You are offline. Your changes will be saved locally and synchronized when the connection returns.',
                                  style: theme
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (taskProvider.isOffline)
                        const SizedBox(
                          height: 16,
                        ),

                      // ========================================================
                      // SAVE BUTTON
                      // ========================================================

                      SizedBox(
                        width:
                        double.infinity,
                        height: 54,

                        child: FilledButton(
                          onPressed:
                          isSaving
                              ? null
                              : _saveTask,

                          child: isSaving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2.5,
                            ),
                          )
                              : Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              Icon(
                                widget
                                    .isEditMode
                                    ? Icons
                                    .save_rounded
                                    : Icons
                                    .add_task_rounded,
                              ),

                              const SizedBox(
                                width: 9,
                              ),

                              Text(
                                widget
                                    .isEditMode
                                    ? 'Save Changes'
                                    : 'Create Task',
                                style:
                                const TextStyle(
                                  fontSize:
                                  16,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION CARD
// =============================================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: theme
            .colorScheme
            .surfaceContainerLow,

        borderRadius:
        BorderRadius.circular(20),

        border: Border.all(
          color: theme
              .colorScheme
              .outlineVariant,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: theme
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            subtitle,
            style: theme
                .textTheme
                .bodySmall
                ?.copyWith(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          child,
        ],
      ),
    );
  }
}

// =============================================================================
// PRIORITY OPTION
// =============================================================================

class _PriorityOption
    extends StatelessWidget {
  final TaskPriority priority;
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _PriorityOption({
    required this.priority,
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return InkWell(
      onTap: enabled ? onTap : null,

      borderRadius:
      BorderRadius.circular(14),

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 180,
        ),

        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),

        decoration: BoxDecoration(
          color: selected
              ? theme
              .colorScheme
              .primaryContainer
              : theme
              .colorScheme
              .surface,

          borderRadius:
          BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? theme
                .colorScheme
                .primary
                : theme
                .colorScheme
                .outlineVariant,

            width:
            selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                  ? theme
                  .colorScheme
                  .onPrimaryContainer
                  : theme
                  .colorScheme
                  .onSurfaceVariant,
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              label,
              style: theme
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? theme
                    .colorScheme
                    .onPrimaryContainer
                    : theme
                    .colorScheme
                    .onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DUE DATE SELECTOR
// =============================================================================

class _DueDateSelector
    extends StatelessWidget {
  final DateTime? selectedDate;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onClear;
  final String Function(DateTime)
  formatDate;

  const _DueDateSelector({
    required this.selectedDate,
    required this.enabled,
    required this.onSelect,
    required this.onClear,
    required this.formatDate,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return InkWell(
      onTap:
      enabled ? onSelect : null,

      borderRadius:
      BorderRadius.circular(14),

      child: Container(
        width: double.infinity,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        decoration: BoxDecoration(
          borderRadius:
          BorderRadius.circular(14),

          border: Border.all(
            color: theme
                .colorScheme
                .outlineVariant,
          ),
        ),

        child: Row(
          children: [
            Icon(
              Icons
                  .calendar_today_rounded,
              color: theme
                  .colorScheme
                  .primary,
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
                    selectedDate == null
                        ? 'No due date'
                        : formatDate(
                      selectedDate!,
                    ),
                    style: theme
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    selectedDate == null
                        ? 'Optional'
                        : 'Task deadline',
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            if (selectedDate != null)
              IconButton(
                tooltip:
                'Remove due date',

                onPressed:
                enabled ? onClear : null,

                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            else
              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}