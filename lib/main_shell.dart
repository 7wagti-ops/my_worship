import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'models.dart';
import 'providers/settings_provider.dart';
import 'providers/sync_provider.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'widgets/app_drawer.dart';
import 'widgets/shimmer_image.dart';
import 'screens/prayer_body.dart';
import 'screens/workout_body.dart';
import 'screens/fasting_body.dart';
import 'screens/custom_tab_body.dart';
import 'screens/lessons_body.dart';
import 'screens/daily_tasks_body.dart';
import 'screens/expenses_body.dart';
import 'duration_screen.dart';

class MainShell extends StatefulWidget {
  final UserData user;
  final VoidCallback onLogout;

  const MainShell({super.key, required this.user, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  UserData get user => widget.user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoOpen());
  }

  void _changed() {
    setState(() {});
    context.read<SyncService>().schedulePush(user);
  }

  void _selectTab(int i) {
    if (_index == i) return;
    final s = context.read<SettingsProvider>();
    final tabs = _buildTabs(s);
    if (i < 0 || i >= tabs.length) return;
    setState(() => _index = i);
    user.lastTabKey = tabs[i].key;
    context.read<SyncService>().schedulePush(user);
  }

  // ═══ فتح آخر صفحة محفوظة ═══
  void _maybeAutoOpen() {
    if (!mounted) return;
    final s = context.read<SettingsProvider>();
    if (!s.autoOpenLastTab) return;
    final key = user.lastTabKey;
    if (key.isEmpty) return;

    final tabs = _buildTabs(s);
    final idx = tabs.indexWhere((t) => t.key == key);
    if (idx < 0) return;

    if (s.tabViewMode == TabViewMode.grid) {
      _openTab(tabs[idx], idx);
    } else {
      setState(() => _index = idx);
    }
  }

  List<_Tab> _buildTabs(SettingsProvider s) {
    final t = AppLocalizations.of(context);
    return <_Tab>[
      if (s.showLessons)
        _Tab('lessons', 'الدروس', Icons.menu_book, _lessons()),
      if (s.showDailyTasks)
        _Tab('daily_tasks', 'المهام اليومية', Icons.task_alt, _dailyTasks()),
      if (s.showExpenses)
        _Tab('expenses', 'المصرف الأسبوعي',
            Icons.account_balance_wallet, _expenses()),
      if (s.showWorkout)
        _Tab('workout', t.t('workout'), Icons.fitness_center, _workout()),
      for (final ct in user.customTabs.where((e) => e.enabled))
        _Tab(
          'custom_${ct.id}',
          ct.name,
          Icons.bookmark_outline,
          CustomTabBody(tab: ct, onChanged: _changed),
        ),
      if (s.showPrayer)
        _Tab('prayer', t.t('prayer'), Icons.mosque, _prayer()),
      if (s.showFasting)
        _Tab('fasting', t.t('fasting'), Icons.nights_stay, _fasting()),
    ];
  }

  IconData _iconForTab(String key) {
    if (key == 'lessons') return Icons.menu_book;
    if (key == 'daily_tasks') return Icons.task_alt;
    if (key == 'expenses') return Icons.account_balance_wallet;
    if (key == 'workout') return Icons.fitness_center;
    if (key == 'prayer') return Icons.mosque;
    if (key == 'fasting') return Icons.nights_stay;
    return Icons.bookmark;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();
    final tabs = _buildTabs(s);

    if (tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).t('app_name'))),
        body: const Center(child: Text('لا توجد تبويبات مفعّلة')),
      );
    }

    final safeIndex = (_index >= 0 && _index < tabs.length) ? _index : 0;

    switch (s.tabViewMode) {
      case TabViewMode.grid:
        return _buildGridHome(tabs, sync);
      case TabViewMode.bottomBar:
        return _buildBottomBar(tabs, sync, safeIndex);
      case TabViewMode.topTabs:
        return _buildTopTabs(tabs, sync, safeIndex);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  الشبكة الرئيسية
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGridHome(List<_Tab> tabs, SyncProvider sync) {
    final primary = Theme.of(context).colorScheme.primary;
    ImageProvider? avatar;
    if (user.avatarBase64.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user.avatarBase64));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('وقتي',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_syncIcon(sync.status)),
            tooltip: 'مزامنة الآن',
            onPressed: () => context.read<SyncService>().pushNow(user),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(
          user: user, onLogout: widget.onLogout, onChanged: _changed),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: primary.withValues(alpha: 0.08),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: primary.withValues(alpha: 0.2),
                      backgroundImage: avatar,
                      child: avatar == null
                          ? Text(
                              user.name.isEmpty ? '؟' : user.name[0],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('مرحباً بك',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 12)),
                          Text(
                            user.name.isEmpty ? 'مستخدم' : user.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('الأقسام',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tabs.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemCount: tabs.length,
              itemBuilder: (_, i) => _floatingTile(tabs[i], i),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _floatingTile(_Tab tab, int index) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openTab(tab, index),
          child: Stack(
            children: [
              Positioned(
                top: -4,
                right: -4,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: Colors.grey[600],
                  tooltip: 'إعدادات التذكير',
                  onPressed: () =>
                      _editReminder(context, tab.key, tab.label),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerHeroImage(
                      imageUrl: '',
                      heroTag: 'tab_${tab.key}_$index',
                      size: 52,
                      fallbackIcon: _iconForTab(tab.key),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        tab.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTab(_Tab tab, int index) {
    user.lastTabKey = tab.key;
    context.read<SyncService>().schedulePush(user);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // العودة للشبكة = امسح آخر تبويب
                user.lastTabKey = '';
                context.read<SyncService>().schedulePush(user);
                Navigator.pop(ctx);
              },
            ),
            title: Row(
              children: [
                ShimmerHeroImage(
                  imageUrl: '',
                  heroTag: 'tab_${tab.key}_$index',
                  size: 28,
                  fallbackIcon: _iconForTab(tab.key),
                ),
                const SizedBox(width: 8),
                Text(tab.label),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'إعدادات التذكير',
                onPressed: () =>
                    _editReminder(context, tab.key, tab.label),
              ),
              Consumer<SyncProvider>(
                builder: (_, sync, __) => IconButton(
                  icon: Icon(_syncIcon(sync.status)),
                  tooltip: 'مزامنة الآن',
                  onPressed: () => context.read<SyncService>().pushNow(user),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: tab.body,
        ),
      ),
    );
  }

  Future<void> _editReminder(
      BuildContext context, String key, String title) async {
    final current = user.reminders[key] ?? ReminderConfig();
    bool enabled = current.enabled;
    TimeOfDay time = TimeOfDay(hour: current.hour, minute: current.minute);
    ReminderFrequency freq = current.freq;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('تذكير: $title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('تفعيل التذكير'),
                  value: enabled,
                  onChanged: (v) => setS(() => enabled = v),
                ),
                if (enabled) ...[
                  ListTile(
                    title: const Text('الوقت'),
                    trailing: Text(time.format(ctx)),
                    onTap: () async {
                      final t = await showTimePicker(
                          context: ctx, initialTime: time);
                      if (t != null) setS(() => time = t);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReminderFrequency>(
                    initialValue: freq,
                    decoration: const InputDecoration(
                        labelText: 'التكرار', border: OutlineInputBorder()),
                    items: ReminderFrequency.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setS(() => freq = v);
                    },
                  ),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    user.reminders[key] = ReminderConfig(
      enabled: enabled,
      hour: time.hour,
      minute: time.minute,
      freq: freq,
    );

    if (enabled) {
      await NotificationService.scheduleSectionReminder(
        key: key,
        title: title,
        cfg: user.reminders[key]!,
      );
    } else {
      await NotificationService.cancelSectionReminders(key);
    }
    _changed();
  }

  // ═══════════════════════════════════════════════════════════════
  //  الشريط السفلي
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar(List<_Tab> tabs, SyncProvider sync, int idx) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[idx].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () =>
                _editReminder(context, tabs[idx].key, tabs[idx].label),
          ),
          IconButton(
            icon: Icon(_syncIcon(sync.status)),
            onPressed: () => context.read<SyncService>().pushNow(user),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(
          user: user, onLogout: widget.onLogout, onChanged: _changed),
      body: IndexedStack(
        index: idx,
        children: tabs.map((t) => t.body).toList(),
      ),
      bottomNavigationBar: _CustomBottomBar(
        tabs: tabs,
        current: idx,
        onSelect: _selectTab,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  التبويبات العلوية
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTopTabs(List<_Tab> tabs, SyncProvider sync, int idx) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[idx].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () =>
                _editReminder(context, tabs[idx].key, tabs[idx].label),
          ),
          IconButton(
            icon: Icon(_syncIcon(sync.status)),
            onPressed: () => context.read<SyncService>().pushNow(user),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: tabs.length,
              itemBuilder: (_, i) {
                final selected = i == idx;
                return GestureDetector(
                  onTap: () => _selectTab(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? primary
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tabs[i].icon,
                          size: 16,
                          color: selected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                selected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      drawer: AppDrawer(
          user: user, onLogout: widget.onLogout, onChanged: _changed),
      body: IndexedStack(
        index: idx,
        children: tabs.map((t) => t.body).toList(),
      ),
    );
  }

  IconData _syncIcon(SyncStatus s) {
    switch (s) {
      case SyncStatus.ok:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.fail:
        return Icons.cloud_off;
      default:
        return Icons.cloud_queue;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  Widget _prayer() => PrayerBody(
        days: user.prayerDays,
        sortMode: user.prayerSortMode,
        onSortChanged: (m) {
          user.prayerSortMode = m;
          _changed();
        },
        onChanged: _changed,
        onAddDay: () async {
          final d = await showDurationScreen(context);
          if (d == null) return;
          final start = user.prayerDays.isEmpty
              ? 0
              : user.prayerDays
                  .map((e) => e.dayNumber)
                  .reduce((a, b) => a > b ? a : b);
          final today = DateTime.now();
          for (var i = 0; i < d; i++) {
            user.prayerDays.add(PrayerDay(
              dayNumber: start + i + 1,
              date: today
                  .add(Duration(days: start + i))
                  .toIso8601String()
                  .substring(0, 10),
            ));
          }
          _changed();
        },
      );

  Widget _lessons() => LessonsBody(
        lessonDays: user.lessonDays,
        initialDay: user.lessonsSelectedDay,
        onDayChanged: (d) {
          user.lessonsSelectedDay = d;
          context.read<SyncService>().schedulePush(user);
        },
        onChanged: _changed,
      );

  Widget _dailyTasks() => DailyTasksBody(user: user, onChanged: _changed);

  Widget _expenses() => ExpensesBody(user: user, onChanged: _changed);

  Widget _workout() => WorkoutBody(
        entries: user.workoutEntries,
        config: user.workoutConfig,
        sortMode: user.workoutSortMode,
        onSortChanged: (m) {
          user.workoutSortMode = m;
          _changed();
        },
        onChanged: _changed,
        onConfigChanged: (cfg) {
          user.workoutConfig = cfg;
          user.workoutEntries.clear();
          _generateWorkout();
          _changed();
        },
        onReset: () {
          user.workoutEntries.clear();
          _generateWorkout();
          _changed();
        },
      );

  Widget _fasting() => FastingBody(
        entries: user.fastingEntries,
        sortMode: user.fastingSortMode,
        onSortChanged: (m) {
          user.fastingSortMode = m;
          _changed();
        },
        onChanged: _changed,
        onSetup: (n) {
          user.fastingEntries.clear();
          final today = DateTime.now();
          for (var i = 0; i < n; i++) {
            user.fastingEntries.add(FastingEntry(
              entryNumber: i + 1,
              entryDate: today
                  .add(Duration(days: i))
                  .toIso8601String()
                  .substring(0, 10),
            ));
          }
          _changed();
        },
      );

  void _generateWorkout() {
    final cfg = user.workoutConfig;
    if (cfg.workoutDays <= 0) return;
    final today = DateTime.now();
    
    // التأكد من وجود القوالب
    while (cfg.routines.length < cfg.workoutDays) {
      cfg.routines.add([]);
    }

    for (var i = 0; i < 60; i++) {
      final cycleLength = cfg.workoutDays + cfg.restDays;
      final cycleIndex = i % cycleLength;
      final isRest = cycleIndex >= cfg.workoutDays;
      
      List<String> exercises = [];
      if (!isRest && cycleIndex < cfg.routines.length) {
        exercises = List.from(cfg.routines[cycleIndex]);
      }

      user.workoutEntries.add(WorkoutEntry(
        entryNumber: i + 1,
        entryDate:
            today.add(Duration(days: i)).toIso8601String().substring(0, 10),
        isRest: isRest,
        exercises: exercises,
      ));
    }
  }
}

class _Tab {
  final String key;
  final String label;
  final IconData icon;
  final Widget body;
  _Tab(this.key, this.label, this.icon, this.body);
}

class _CustomBottomBar extends StatelessWidget {
  final List<_Tab> tabs;
  final int current;
  final void Function(int) onSelect;

  const _CustomBottomBar({
    required this.tabs,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: tabs.length,
            itemBuilder: (_, i) {
              final selected = i == current;
              return InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 22,
                        color: selected ? primary : Colors.grey,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          color: selected ? primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
