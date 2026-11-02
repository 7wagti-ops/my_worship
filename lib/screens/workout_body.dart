import 'package:flutter/material.dart';
import '../models.dart';

class WorkoutBody extends StatefulWidget {
  final List<WorkoutEntry> entries;
  final WorkoutConfig config;
  final SortMode sortMode;
  final void Function(SortMode) onSortChanged;
  final VoidCallback onChanged;
  final void Function(WorkoutConfig) onConfigChanged;
  final VoidCallback onReset;

  const WorkoutBody({
    super.key,
    required this.entries,
    required this.config,
    required this.sortMode,
    required this.onSortChanged,
    required this.onChanged,
    required this.onConfigChanged,
    required this.onReset,
  });

  @override
  State<WorkoutBody> createState() => _WorkoutBodyState();
}

class _WorkoutBodyState extends State<WorkoutBody> {
  @override
  void initState() {
    super.initState();
    _applySort(widget.sortMode);
  }

  void _applySort(SortMode m) {
    switch (m) {
      case SortMode.ascending:
        widget.entries.sort((a, b) => a.entryNumber.compareTo(b.entryNumber));
        break;
      case SortMode.descending:
        widget.entries.sort((a, b) => b.entryNumber.compareTo(a.entryNumber));
        break;
      case SortMode.incompleteFirst:
        widget.entries.sort((a, b) {
          final aDone = a.isDone && !a.isRest;
          final bDone = b.isDone && !b.isRest;
          if (aDone == bDone) return a.entryNumber.compareTo(b.entryNumber);
          return aDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        widget.entries.sort((a, b) {
          final aDone = a.isDone && !a.isRest;
          final bDone = b.isDone && !b.isRest;
          if (aDone == bDone) return a.entryNumber.compareTo(b.entryNumber);
          return aDone ? -1 : 1;
        });
        break;
    }
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );

  // ═══ إدارة التمارين ═══
  Future<void> _addExercise(WorkoutEntry e) async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إضافة تمرين جديد'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'اسم التمرين (مثال: سكواد)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (res != null && res.isNotEmpty) {
      setState(() {
        e.exercises.add(res);
        _syncRoutine(e);
      });
      widget.onChanged();
    }
  }

  void _syncRoutine(WorkoutEntry entry) {
    // مزامنة التغييرات مع القالب الدوري وباقي الأيام المماثلة
    final cycleLength = widget.config.workoutDays + widget.config.restDays;
    if (cycleLength <= 0) return;
    
    final cycleIndex = (entry.entryNumber - 1) % cycleLength;
    if (cycleIndex < widget.config.workoutDays) {
      // تحديث القالب الأساسي
      widget.config.routines[cycleIndex] = List.from(entry.exercises);
      
      // تحديث باقي الأيام التي تقع في نفس النقطة من الدورة
      for (var e in widget.entries) {
        final idx = (e.entryNumber - 1) % cycleLength;
        if (idx == cycleIndex && e.entryNumber != entry.entryNumber) {
          e.exercises = List.from(entry.exercises);
        }
      }
    }
  }

  Future<void> _resetDay(WorkoutEntry e) async {
    final cycleLength = widget.config.workoutDays + widget.config.restDays;
    final cycleIndex = (e.entryNumber - 1) % cycleLength;
    if (cycleIndex < widget.config.routines.length) {
      setState(() {
        e.exercises = List.from(widget.config.routines[cycleIndex]);
        _syncRoutine(e);
      });
      widget.onChanged();
    }
  }

  Future<void> _deleteDayExercises(WorkoutEntry e) async {
    final ok = await _confirm('حذف التمارين', 'هل أنت متأكد من حذف جميع تمارين هذا اليوم؟');
    if (ok != true) return;
    setState(() {
      e.exercises.clear();
      _syncRoutine(e);
    });
    widget.onChanged();
  }

  Future<void> _resetAllPattern() async {
    final ok = await _confirm('إعادة تعيين', 'حذف جميع الأيام والبدء من جديد؟');
    if (ok != true) return;
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return _onboarding();

    final done = widget.entries.where((e) => e.isDone && !e.isRest).length;

    return Column(
      children: [
        // ═══ Header ═══
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Text(
                '${widget.config.workoutDays} تمرين / ${widget.config.restDays} راحة',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                '$done منجز',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              PopupMenuButton<SortMode>(
                icon: const Icon(Icons.sort),
                tooltip: 'ترتيب القائمة',
                onSelected: (m) {
                  widget.onSortChanged(m);
                  setState(() => _applySort(m));
                },
                itemBuilder: (_) => SortMode.values
                    .map((m) => PopupMenuItem(
                          value: m,
                          child: Row(
                            children: [
                              Icon(
                                widget.sortMode == m
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              Text(m.label),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل النمط العام',
                onPressed: _editPattern,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'خيارات متقدمة',
                onPressed: () => _showGlobalMenu(context),
              ),
            ],
          ),
        ),
        // ═══ List ═══
        Expanded(
          child: ListView.builder(
            itemCount: widget.entries.length,
            itemBuilder: (c, i) => _tile(widget.entries[i]),
          ),
        ),
        // ═══ Add ═══
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add),
              label: const Text('إضافة يوم'),
            ),
          ),
        ),
      ],
    );
  }

  void _showGlobalMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.red),
              title: const Text('إعادة تعيين التمارين من جديد'),
              subtitle: const Text('حذف جميع الأيام والبدء من الصفر'),
              onTap: () {
                Navigator.pop(context);
                _resetAllPattern();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _onboarding() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('اختر نمط التمرين', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _editPattern,
              child: const Text('ابدأ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(WorkoutEntry e) {
    final cycleLength = widget.config.workoutDays + widget.config.restDays;
    final cycleIndex = (e.entryNumber - 1) % cycleLength;
    final isWorkoutDay = cycleIndex < widget.config.workoutDays;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: e.isRest
                  ? Colors.grey[400]
                  : (e.isDone ? Colors.teal : Colors.orange[200]),
              child: Icon(
                e.isRest ? Icons.bed : (e.isDone ? Icons.check : Icons.fitness_center),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'اليوم ${e.entryNumber} - ${e.isRest ? "راحة" : "تمرين"}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: (!e.isRest && e.isDone) ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(e.entryDate, style: const TextStyle(fontSize: 11)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!e.isRest)
                  Checkbox(
                    value: e.isDone,
                    onChanged: (v) {
                      setState(() {
                        e.isDone = v ?? false;
                        if (widget.sortMode == SortMode.incompleteFirst ||
                            widget.sortMode == SortMode.completeFirst) {
                          _applySort(widget.sortMode);
                        }
                      });
                      widget.onChanged();
                    },
                  ),
                if (!e.isRest)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'add') _addExercise(e);
                      if (val == 'reset') _resetDay(e);
                      if (val == 'delete') _deleteDayExercises(e);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'add',
                        child: ListTile(
                          leading: Icon(Icons.add, color: Colors.teal),
                          title: Text('إضافة تمرين'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(Icons.refresh, color: Colors.blue),
                          title: Text('إعادة تعيين تمارين اليوم'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('حذف تمارين اليوم'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (isWorkoutDay && e.exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: e.exercises
                      .map((ex) => Chip(
                            label: Text(ex, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                            side: BorderSide(color: Colors.teal.withValues(alpha: 0.3)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),
            ),
          if (isWorkoutDay && e.exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('لا توجد تمارين لهذا اليوم، أضف تمريناً من القائمة ⋮', 
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  void _addDay() {
    final today = DateTime.now();
    final n = widget.entries.isEmpty ? 0 : widget.entries.last.entryNumber;
    final cycleLength = widget.config.workoutDays + widget.config.restDays;
    final cycleIndex = n % cycleLength;
    final isRest = cycleIndex >= widget.config.workoutDays;
    
    List<String> exercises = [];
    if (!isRest && cycleIndex < widget.config.routines.length) {
      exercises = List.from(widget.config.routines[cycleIndex]);
    }

    setState(() {
      widget.entries.add(WorkoutEntry(
        entryNumber: n + 1,
        entryDate: today.add(Duration(days: n)).toIso8601String().substring(0, 10),
        isRest: isRest,
        exercises: exercises,
      ));
      _applySort(widget.sortMode);
    });
    widget.onChanged();
  }

  Future<void> _editPattern() async {
    final w = TextEditingController(text: widget.config.workoutDays.toString());
    final r = TextEditingController(text: widget.config.restDays.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نمط التمرين'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: w,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أيام التمرين',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: r,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'أيام الراحة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final cfg = WorkoutConfig(
      workoutDays: int.tryParse(w.text) ?? 3,
      restDays: int.tryParse(r.text) ?? 1,
      routines: widget.config.routines, // الاحتفاظ بالقوالب القديمة
    );
    widget.onConfigChanged(cfg);
    setState(() {});
  }
}
