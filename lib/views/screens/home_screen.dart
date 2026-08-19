import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/views/screens/task_form_screen.dart';

import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  // ---------------------------------------------------------------------------
  // LOAD TASKS
  // ---------------------------------------------------------------------------

  void _loadTasks() {
    final authProvider =
    context.read<AuthProvider>();

    final user =
        authProvider.currentUser;

    if (user == null) {
      return;
    }

    context
        .read<TaskProvider>()
        .loadTasks(user.uid);
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> _showLogoutDialog() async {
    final authProvider =
    context.read<AuthProvider>();

    final isGuest =
        authProvider.isGuest;

    final shouldLogout =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),

          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onErrorContainer,
                ),
              ),

              const SizedBox(width: 14),

              const Text(
                'Logout',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),

          content: Text(
            isGuest
                ? 'You are using a guest account. '
                'Logging out will permanently remove '
                'your locally stored tasks from this device.'
                : 'Are you sure you want to '
                'logout from your account?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
              height: 1.5,
            ),
          ),

          actionsPadding:
          const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20,
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),

            const SizedBox(width: 8),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                Theme.of(context)
                    .colorScheme
                    .error,
                foregroundColor:
                Theme.of(context)
                    .colorScheme
                    .onError,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child:
              const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    if (!mounted) return;

    final taskProvider =
    context.read<TaskProvider>();

    // -------------------------------------------------------------------------
    // GUEST DATA
    // -------------------------------------------------------------------------

    if (isGuest) {
      final uid =
          authProvider.currentUser?.uid;

      if (uid != null) {
        await taskProvider
            .clearLocalTasks(uid);
      }
    }

    // -------------------------------------------------------------------------
    // AUTH LOGOUT
    // -------------------------------------------------------------------------

    final success =
    await authProvider.signOut();

    if (!mounted) return;

    if (!success) {
      _showErrorSnackBar(
        authProvider.errorMessage ??
            'Unable to logout.',
      );

      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR SNACKBAR
  // ---------------------------------------------------------------------------

  void _showErrorSnackBar(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final authProvider =
    context.watch<AuthProvider>();

    final taskProvider =
    context.watch<TaskProvider>();

    final user =
        authProvider.currentUser;

    return Scaffold(
      backgroundColor:
      theme.colorScheme.surface,

      // =======================================================================
      // APP BAR
      // =======================================================================

      appBar: AppBar(
        backgroundColor:
        theme.colorScheme.surface,
        elevation: 0,

        titleSpacing: 20,

        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'My Tasks',
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              'Stay organized, stay productive',
              style: theme
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),

        actions: [
          // -------------------------------------------------------------------
          // LOGOUT
          // -------------------------------------------------------------------

          Padding(
            padding:
            const EdgeInsets.only(
              right: 12,
            ),
            child: IconButton(
              tooltip: 'Logout',
              onPressed:
              authProvider.isLoading
                  ? null
                  : _showLogoutDialog,
              icon: const Icon(
                Icons.logout_rounded,
              ),
            ),
          ),
        ],
      ),

      // =======================================================================
      // FAB
      // =======================================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Task',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =======================================================================
      // BODY
      // =======================================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadTasks();

            await Future.delayed(
              const Duration(
                milliseconds: 500,
              ),
            );
          },

          child: CustomScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),

            slivers: [

              // ===============================================================
              // USER HEADER
              // ===============================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    0,
                  ),
                  child: _UserHeader(
                    name:
                    user?.name ?? 'User',
                    email:
                    user?.email ?? '',
                    photoUrl:
                    user?.photoUrl,
                    isGuest:
                    user?.isGuest ?? false,
                  ),
                ),
              ),

              // ===============================================================
              // SYNC STATUS
              // ===============================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    0,
                  ),
                  child:
                  _SyncStatusCard(
                    taskProvider:
                    taskProvider,
                  ),
                ),
              ),

              // ===============================================================
              // SEARCH
              // ===============================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    0,
                  ),
                  child:
                  _SearchField(
                    onChanged:
                    taskProvider
                        .setSearchQuery,
                  ),
                ),
              ),

              // ===============================================================
              // FILTERS
              // ===============================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    0,
                  ),
                  child:
                  _FilterSection(
                    selectedFilter:
                    taskProvider
                        .filter,
                    onFilterChanged:
                    taskProvider
                        .setFilter,
                  ),
                ),
              ),

              // ===============================================================
              // TASK SUMMARY
              // ===============================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    12,
                  ),
                  child:
                  _TaskSummary(
                    total:
                    taskProvider
                        .visibleTasks
                        .length,
                    completed:
                    taskProvider
                        .completedCount,
                    pending:
                    taskProvider
                        .pendingCount,
                  ),
                ),
              ),

              // ===============================================================
              // LOADING
              // ===============================================================

              if (taskProvider.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child:
                    CircularProgressIndicator(),
                  ),
                )

              // ===============================================================
              // EMPTY
              // ===============================================================

              else if (taskProvider
                  .visibleTasks
                  .isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child:
                  _EmptyTaskState(
                    hasSearch:
                    taskProvider
                        .searchQuery
                        .isNotEmpty,
                    onAddTask:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TaskFormScreen(),
                      ),
                    ),
                  ),
                )

              // ===============================================================
              // TASK LIST
              // ===============================================================

              else
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    110,
                  ),
                  sliver:
                  SliverList.builder(
                    itemCount:
                    taskProvider
                        .visibleTasks
                        .length,

                    itemBuilder:
                        (context, index) {
                      final task =
                      taskProvider
                          .visibleTasks[
                      index];

                      return Padding(
                        padding:
                        const EdgeInsets
                            .only(
                          bottom: 10,
                        ),
                        child:
                        TaskTile(
                          task: task,
                        ),
                      );
                    },
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
// USER HEADER
// =============================================================================

class _UserHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final bool isGuest;

  const _UserHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isGuest,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Container(
      padding:
      const EdgeInsets.all(18),

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

      child: Row(
        children: [

          // -------------------------------------------------------------------
          // PROFILE IMAGE
          // -------------------------------------------------------------------

          Container(
            width: 54,
            height: 54,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme
                  .colorScheme
                  .primaryContainer,
            ),

            child: ClipOval(
              child: photoUrl != null &&
                  photoUrl!
                      .isNotEmpty
                  ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) {
                  return Icon(
                    Icons.person_rounded,
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                  );
                },
              )
                  : Icon(
                isGuest
                    ? Icons
                    .person_outline_rounded
                    : Icons
                    .person_rounded,
                color: theme
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // -------------------------------------------------------------------
          // USER DETAILS
          // -------------------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  'Hello, $name',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                if (isGuest)
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color: theme
                          .colorScheme
                          .secondaryContainer,
                      borderRadius:
                      BorderRadius.circular(
                        8,
                      ),
                    ),
                    child: Text(
                      'Guest Account',
                      style: theme
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .onSecondaryContainer,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
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
        ],
      ),
    );
  }
}

// =============================================================================
// SEARCH FIELD
// =============================================================================

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.onChanged,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return TextField(
      onChanged: onChanged,

      textInputAction:
      TextInputAction.search,

      decoration:
      InputDecoration(
        hintText:
        'Search tasks...',

        prefixIcon: const Icon(
          Icons.search_rounded,
        ),

        filled: true,

        fillColor: theme
            .colorScheme
            .surfaceContainerLow,

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide:
          BorderSide.none,
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme
                .colorScheme
                .outlineVariant,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme
                .colorScheme
                .primary,
            width: 1.5,
          ),
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          vertical: 16,
        ),
      ),
    );
  }
}

// =============================================================================
// FILTER
// =============================================================================

// enum TaskFilter {
//   all,
//   pending,
//   completed,
// }

class _FilterSection extends StatelessWidget {
  final TaskFilter selectedFilter;
  final ValueChanged<TaskFilter>
  onFilterChanged;

  const _FilterSection({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SingleChildScrollView(
      scrollDirection:
      Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            icon:
            Icons.list_alt_rounded,
            selected:
            selectedFilter ==
                TaskFilter.all,
            onSelected: () =>
                onFilterChanged(
                  TaskFilter.all,
                ),
          ),

          const SizedBox(width: 8),

          _FilterChip(
            label: 'Pending',
            icon:
            Icons.pending_actions_rounded,
            selected:
            selectedFilter ==
                TaskFilter.pending,
            onSelected: () =>
                onFilterChanged(
                  TaskFilter.pending,
                ),
          ),

          const SizedBox(width: 8),

          _FilterChip(
            label: 'Completed',
            icon:
            Icons.check_circle_outline_rounded,
            selected:
            selectedFilter ==
                TaskFilter.completed,
            onSelected: () =>
                onFilterChanged(
                  TaskFilter.completed,
                ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return ChoiceChip(
      selected: selected,
      onSelected: (_) =>
          onSelected(),

      avatar: Icon(
        icon,
        size: 17,
      ),

      label: Text(label),

      labelStyle: TextStyle(
        fontWeight:
        selected
            ? FontWeight.w600
            : FontWeight.w500,
      ),

      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),

      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme
            .colorScheme
            .outlineVariant,
      ),
    );
  }
}

// =============================================================================
// TASK SUMMARY
// =============================================================================

class _TaskSummary extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;

  const _TaskSummary({
    required this.total,
    required this.completed,
    required this.pending,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        Text(
          '$total ${total == 1 ? 'Task' : 'Tasks'}',
          style: theme
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        const Spacer(),

        _SummaryItem(
          icon:
          Icons.pending_actions_rounded,
          value: pending,
          label: 'Pending',
        ),

        const SizedBox(width: 16),

        _SummaryItem(
          icon:
          Icons.check_circle_outline_rounded,
          value: completed,
          label: 'Done',
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),

        const SizedBox(width: 5),

        Text(
          '$value $label',
          style: theme
              .textTheme
              .labelMedium
              ?.copyWith(
            color: theme
                .colorScheme
                .onSurfaceVariant,
            fontWeight:
            FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SYNC STATUS
// =============================================================================

class _SyncStatusCard extends StatelessWidget {
  final TaskProvider taskProvider;

  const _SyncStatusCard({
    required this.taskProvider,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    // This is intentionally based on the
    // Provider's current sync state.
    //
    // We'll connect the actual ConnectivityService
    // and SyncService state here next.

    final isSyncing =
        taskProvider.isSyncing;

    final isOffline =
        taskProvider.isOffline;

    final IconData icon;

    final String message;

    if (isSyncing) {
      icon =
          Icons.sync_rounded;
      message =
      'Syncing your tasks...';
    } else if (isOffline) {
      icon =
          Icons.cloud_off_rounded;
      message =
      'Offline mode • Changes will sync later';
    } else {
      icon =
          Icons.cloud_done_rounded;
      message =
      'All tasks are synchronized';
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),

      decoration: BoxDecoration(
        color: theme
            .colorScheme
            .surfaceContainerLow,

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
          if (isSyncing)
            SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color: theme
                    .colorScheme
                    .primary,
              ),
            )
          else
            Icon(
              icon,
              size: 19,
              color: isOffline
                  ? theme
                  .colorScheme
                  .onSurfaceVariant
                  : theme
                  .colorScheme
                  .primary,
            ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: theme
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _EmptyTaskState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAddTask;

  const _EmptyTaskState({
    required this.hasSearch,
    required this.onAddTask,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [

            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: theme
                    .colorScheme
                    .primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch
                    ? Icons.search_off_rounded
                    : Icons
                    .checklist_rounded,
                size: 38,
                color: theme
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              hasSearch
                  ? 'No tasks found'
                  : 'No tasks yet',
              textAlign:
              TextAlign.center,
              style: theme
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              hasSearch
                  ? 'Try searching with a different keyword.'
                  : 'Create your first task and start getting things done.',
              textAlign:
              TextAlign.center,
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

            if (!hasSearch) ...[
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: onAddTask,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text('Create Task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}