enum SortMode { ascending, descending, incompleteFirst, completeFirst }

extension SortModeExt on SortMode {
  String get label {
    switch (this) {
      case SortMode.ascending:
        return 'تصاعدي (1 → N)';
      case SortMode.descending:
        return 'تنازلي (N → 1)';
      case SortMode.incompleteFirst:
        return 'غير المكتمل أولاً';
      case SortMode.completeFirst:
        return 'المكتمل أولاً';
    }
  }

  static SortMode fromKey(String? k) => SortMode.values.firstWhere(
        (e) => e.name == k,
        orElse: () => SortMode.incompleteFirst,
      );
}

enum TabViewMode { bottomBar, grid, topTabs }

extension TabViewModeExt on TabViewMode {
  String get label {
    switch (this) {
      case TabViewMode.bottomBar:
        return 'شريط سفلي';
      case TabViewMode.grid:
        return 'شبكة عائمة';
      case TabViewMode.topTabs:
        return 'تبويبات أعلى';
    }
  }

  String get hint {
    switch (this) {
      case TabViewMode.bottomBar:
        return 'شريط عادي أسفل الشاشة';
      case TabViewMode.grid:
        return 'واجهة رئيسية شبكية';
      case TabViewMode.topTabs:
        return 'شريط تمرير أفقي أعلى';
    }
  }

  static TabViewMode fromKey(String? k) => TabViewMode.values.firstWhere(
        (e) => e.name == k,
        orElse: () => TabViewMode.grid,
      );
}

enum ReminderFrequency { daily, alternate, weekdays, weekends, off }

extension ReminderFrequencyExt on ReminderFrequency {
  String get label {
    switch (this) {
      case ReminderFrequency.daily:
        return 'يومياً';
      case ReminderFrequency.alternate:
        return 'يوم ويوم (يوم بعد يوم)';
      case ReminderFrequency.weekdays:
        return 'أيام العمل (الاثنين - الجمعة)';
      case ReminderFrequency.weekends:
        return 'العطل (السبت - الأحد)';
      case ReminderFrequency.off:
        return 'إيقاف';
    }
  }

  static ReminderFrequency fromKey(String? k) =>
      ReminderFrequency.values.firstWhere(
        (e) => e.name == k,
        orElse: () => ReminderFrequency.daily,
      );
}

class ReminderConfig {
  bool enabled;
  int hour;
  int minute;
  ReminderFrequency freq;

  ReminderConfig({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.freq = ReminderFrequency.daily,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'freq': freq.name,
      };

  factory ReminderConfig.fromJson(Map<String, dynamic> j) => ReminderConfig(
        enabled: j['enabled'] ?? false,
        hour: j['hour'] ?? 20,
        minute: j['minute'] ?? 0,
        freq: ReminderFrequencyExt.fromKey(j['freq'] as String?),
      );
}

// ═══════════════════════════════════════════════════════════════
//  Expense (تمت إضافة العملة)
// ═══════════════════════════════════════════════════════════════
class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String currency; // 'IQD' or 'USD'

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.currency = 'IQD',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String().substring(0, 10),
        'currency': currency,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] ?? '',
        description: j['description'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        currency: j['currency'] ?? 'IQD',
      );
}

DateTime fridayOfWeek(DateTime d) {
  final diff = (d.weekday - 5 + 7) % 7;
  return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
}

class DailyTask {
  final String id;
  String title;
  int status;
  String note;

  DailyTask({
    required this.id,
    required this.title,
    this.status = 0,
    this.note = '',
  });

  bool get isDone => status == 1;
  bool get isFailed => status == 2;
  bool get isPending => status == 0;

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'status': status, 'note': note};

  factory DailyTask.fromJson(Map<String, dynamic> j) => DailyTask(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        status: (j['status'] as num?)?.toInt() ?? 0,
        note: j['note'] ?? '',
      );
}

class DailyTaskDay {
  final int dayIndex;
  final String date;
  List<DailyTask> tasks;

  DailyTaskDay({
    required this.dayIndex,
    required this.date,
    List<DailyTask>? tasks,
  }) : tasks = tasks ?? [];

  int get weekday {
    try {
      return DateTime.parse(date).weekday % 7;
    } catch (_) {
      return 0;
    }
  }

  static const _weekdayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  String get weekdayName => _weekdayNames[weekday];

  int get doneCount => tasks.where((t) => t.isDone).length;
  int get failedCount => tasks.where((t) => t.isFailed).length;
  int get pendingCount => tasks.where((t) => t.isPending).length;
  int get total => tasks.length;
  bool get allDone => tasks.isNotEmpty && doneCount == total;

  Map<String, dynamic> toJson() => {
        'day_index': dayIndex,
        'date': date,
        'tasks': tasks.map((e) => e.toJson()).toList(),
      };

  factory DailyTaskDay.fromJson(Map<String, dynamic> j) => DailyTaskDay(
        dayIndex: j['day_index'] ?? 0,
        date: j['date'] ?? '',
        tasks: (j['tasks'] as List? ?? [])
            .map((e) => DailyTask.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class Lesson {
  final String id;
  String title;
  String note;
  bool isDone;

  Lesson({
    required this.id,
    required this.title,
    this.note = '',
    this.isDone = false,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'note': note, 'is_done': isDone};

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        note: j['note'] ?? '',
        isDone: j['is_done'] ?? false,
      );
}

class LessonDay {
  final int dayOfWeek;
  List<Lesson> lessons;

  LessonDay({required this.dayOfWeek, List<Lesson>? lessons})
      : lessons = lessons ?? [];

  static const dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static const dayShortNames = [
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];

  String get dayName => dayNames[dayOfWeek];
  String get dayShortName => dayShortNames[dayOfWeek];

  int get doneCount => lessons.where((l) => l.isDone).length;
  int get total => lessons.length;
  bool get isComplete => lessons.isNotEmpty && doneCount == total;

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'lessons': lessons.map((l) => l.toJson()).toList(),
      };

  factory LessonDay.fromJson(Map<String, dynamic> j) => LessonDay(
        dayOfWeek: j['day_of_week'] ?? 0,
        lessons: (j['lessons'] as List? ?? [])
            .map((e) => Lesson.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PrayerDay {
  final int dayNumber;
  final String date;
  bool fajr, dhuhr, asr, maghrib, isha;

  PrayerDay({
    required this.dayNumber,
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
  });

  int get completed =>
      [fajr, dhuhr, asr, maghrib, isha].where((e) => e).length;
  bool get isComplete => completed == 5;

  Map<String, dynamic> toJson() => {
        'day_number': dayNumber,
        'date': date,
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory PrayerDay.fromJson(Map<String, dynamic> j) => PrayerDay(
        dayNumber: j['day_number'] ?? 0,
        date: j['date'] ?? '',
        fajr: j['fajr'] ?? false,
        dhuhr: j['dhuhr'] ?? false,
        asr: j['asr'] ?? false,
        maghrib: j['maghrib'] ?? false,
        isha: j['isha'] ?? false,
      );
}

class SectionDay {
  final int dayNumber;
  final String date;
  bool isDone;
  String note;

  SectionDay({
    required this.dayNumber,
    required this.date,
    this.isDone = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() =>
      {'day_number': dayNumber, 'date': date, 'is_done': isDone, 'note': note};

  factory SectionDay.fromJson(Map<String, dynamic> j) => SectionDay(
        dayNumber: j['day_number'] ?? 0,
        date: j['date'] ?? '',
        isDone: j['is_done'] ?? false,
        note: j['note'] ?? '',
      );
}

class Section {
  final String id;
  String name;
  String note;
  SortMode sortMode;
  List<SectionDay> days;

  Section({
    required this.id,
    required this.name,
    this.note = '',
    this.sortMode = SortMode.incompleteFirst,
    List<SectionDay>? days,
  }) : days = days ?? [];

  void applySort() {
    switch (sortMode) {
      case SortMode.ascending:
        days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        break;
      case SortMode.descending:
        days.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
        break;
      case SortMode.incompleteFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? -1 : 1;
        });
        break;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'sort_mode': sortMode.name,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        note: j['note'] ?? '',
        sortMode: SortModeExt.fromKey(j['sort_mode'] as String?),
        days: (j['days'] as List? ?? [])
            .map((e) => SectionDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class CustomTabDay {
  final int dayNumber;
  final String date;
  bool isDone;
  String note;

  CustomTabDay({
    required this.dayNumber,
    required this.date,
    this.isDone = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() =>
      {'day_number': dayNumber, 'date': date, 'is_done': isDone, 'note': note};

  factory CustomTabDay.fromJson(Map<String, dynamic> j) => CustomTabDay(
        dayNumber: j['day_number'] ?? 0,
        date: j['date'] ?? '',
        isDone: j['is_done'] ?? false,
        note: j['note'] ?? '',
      );
}

class CustomTab {
  final String id;
  String name;
  String type;
  String note;
  bool enabled;
  SortMode sortMode;
  List<CustomTabDay> days;

  CustomTab({
    required this.id,
    required this.name,
    this.type = '',
    this.note = '',
    this.enabled = true,
    this.sortMode = SortMode.incompleteFirst,
    List<CustomTabDay>? days,
  }) : days = days ?? [];

  int get doneCount => days.where((d) => d.isDone).length;

  void applySort() {
    switch (sortMode) {
      case SortMode.ascending:
        days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        break;
      case SortMode.descending:
        days.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
        break;
      case SortMode.incompleteFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? 1 : -1;
        });
        break;
      case SortMode.completeFirst:
        days.sort((a, b) {
          if (a.isDone == b.isDone) {
            return a.dayNumber.compareTo(b.dayNumber);
          }
          return a.isDone ? -1 : 1;
        });
        break;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'note': note,
        'enabled': enabled,
        'sort_mode': sortMode.name,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory CustomTab.fromJson(Map<String, dynamic> j) => CustomTab(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? '',
        note: j['note'] ?? '',
        enabled: j['enabled'] ?? true,
        sortMode: SortModeExt.fromKey(j['sort_mode'] as String?),
        days: (j['days'] as List? ?? [])
            .map((e) => CustomTabDay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class WorkoutEntry {
  final int entryNumber;
  final String entryDate;
  bool isDone;
  final bool isRest;
  List<String> exercises;
  String note;

  WorkoutEntry({
    required this.entryNumber,
    required this.entryDate,
    this.isDone = false,
    this.isRest = false,
    List<String>? exercises,
    this.note = '',
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toJson() => {
        'entry_number': entryNumber,
        'entry_date': entryDate,
        'is_done': isDone,
        'is_rest': isRest,
        'exercises': exercises,
        'note': note,
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
        entryNumber: j['entry_number'] ?? 0,
        entryDate: j['entry_date'] ?? '',
        isDone: j['is_done'] ?? false,
        isRest: j['is_rest'] ?? false,
        exercises: List<String>.from(j['exercises'] ?? []),
        note: j['note'] ?? '',
      );
}

class WorkoutConfig {
  int workoutDays;
  int restDays;
  List<List<String>> routines; // القوالب الدورية للتمارين

  WorkoutConfig({
    this.workoutDays = 3,
    this.restDays = 1,
    List<List<String>>? routines,
  }) : routines = routines ?? [];

  Map<String, dynamic> toJson() => {
        'workout_days': workoutDays,
        'rest_days': restDays,
        'routines': routines,
      };

  factory WorkoutConfig.fromJson(Map<String, dynamic> j) {
    final cfg = WorkoutConfig(
      workoutDays: j['workout_days'] ?? 3,
      restDays: j['rest_days'] ?? 1,
      routines: (j['routines'] as List? ?? [])
          .map((e) => List<String>.from(e))
          .toList(),
    );
    // تأكد أن عدد القوالب يساوي عدد أيام التمرين
    while (cfg.routines.length < cfg.workoutDays) {
      cfg.routines.add([]);
    }
    return cfg;
  }
}

class FastingEntry {
  final int entryNumber;
  final String entryDate;
  bool isDone;
  String note;

  FastingEntry({
    required this.entryNumber,
    required this.entryDate,
    this.isDone = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'entry_number': entryNumber,
        'entry_date': entryDate,
        'is_done': isDone,
        'note': note,
      };

  factory FastingEntry.fromJson(Map<String, dynamic> j) => FastingEntry(
        entryNumber: j['entry_number'] ?? 0,
        entryDate: j['entry_date'] ?? '',
        isDone: j['is_done'] ?? false,
        note: j['note'] ?? '',
      );
}

class FastingConfig {
  int totalDays;

  FastingConfig({this.totalDays = 30});

  Map<String, dynamic> toJson() => {'total_days': totalDays};

  factory FastingConfig.fromJson(Map<String, dynamic> j) =>
      FastingConfig(totalDays: j['total_days'] ?? 30);
}

class UserData {
  String? id;
  String identifier;
  String name;
  String avatarBase64;

  SortMode prayerSortMode;
  SortMode workoutSortMode;
  SortMode fastingSortMode;

  String dailyTasksStartDate;
  List<DailyTaskDay> dailyTaskDays;
  Map<String, ReminderConfig> reminders;

  String lastTabKey;
  int lessonsSelectedDay;
  int expensesViewMode;

  List<Expense> expenses;

  List<PrayerDay> prayerDays;
  List<Section> sections;
  List<CustomTab> customTabs;
  List<LessonDay> lessonDays;
  List<WorkoutEntry> workoutEntries;
  WorkoutConfig workoutConfig;
  List<FastingEntry> fastingEntries;
  FastingConfig fastingConfig;

  UserData({
    this.id,
    required this.identifier,
    this.name = '',
    this.avatarBase64 = '',
    this.prayerSortMode = SortMode.incompleteFirst,
    this.workoutSortMode = SortMode.incompleteFirst,
    this.fastingSortMode = SortMode.incompleteFirst,
    this.dailyTasksStartDate = '',
    this.lastTabKey = '',
    this.lessonsSelectedDay = -1,
    this.expensesViewMode = 0,
    List<DailyTaskDay>? dailyTaskDays,
    Map<String, ReminderConfig>? reminders,
    List<Expense>? expenses,
    List<PrayerDay>? prayerDays,
    List<Section>? sections,
    List<CustomTab>? customTabs,
    List<LessonDay>? lessonDays,
    List<WorkoutEntry>? workoutEntries,
    WorkoutConfig? workoutConfig,
    List<FastingEntry>? fastingEntries,
    FastingConfig? fastingConfig,
  })  : dailyTaskDays = dailyTaskDays ?? [],
        reminders = reminders ?? {},
        expenses = expenses ?? [],
        prayerDays = prayerDays ?? [],
        sections = sections ?? [],
        customTabs = customTabs ?? [],
        lessonDays = lessonDays ?? _emptyWeek(),
        workoutEntries = workoutEntries ?? [],
        workoutConfig = workoutConfig ?? WorkoutConfig(),
        fastingEntries = fastingEntries ?? [],
        fastingConfig = fastingConfig ?? FastingConfig();

  static List<LessonDay> _emptyWeek() =>
      List.generate(7, (i) => LessonDay(dayOfWeek: i));

  static List<LessonDay> normalizeWeek(List<LessonDay> input) {
    final map = {for (final d in input) d.dayOfWeek: d};
    return List.generate(7, (i) => map[i] ?? LessonDay(dayOfWeek: i));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifier': identifier,
        'name': name,
        'avatar_base64': avatarBase64,
        'prayer_sort_mode': prayerSortMode.name,
        'workout_sort_mode': workoutSortMode.name,
        'fasting_sort_mode': fastingSortMode.name,
        'daily_tasks_start_date': dailyTasksStartDate,
        'last_tab_key': lastTabKey,
        'lessons_selected_day': lessonsSelectedDay,
        'expenses_view_mode': expensesViewMode,
        'daily_task_days': dailyTaskDays.map((e) => e.toJson()).toList(),
        'reminders': reminders.map((k, v) => MapEntry(k, v.toJson())),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'prayer_days': prayerDays.map((e) => e.toJson()).toList(),
        'sections': sections.map((e) => e.toJson()).toList(),
        'custom_tabs': customTabs.map((e) => e.toJson()).toList(),
        'lesson_days': lessonDays.map((e) => e.toJson()).toList(),
        'workout_entries': workoutEntries.map((e) => e.toJson()).toList(),
        'workout_config': workoutConfig.toJson(),
        'fasting_entries': fastingEntries.map((e) => e.toJson()).toList(),
        'fasting_config': fastingConfig.toJson(),
      };
}
