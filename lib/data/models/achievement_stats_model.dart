class AchievementStatsModel {
  const AchievementStatsModel({
    this.totalNotes = 0,
    this.doneTasks = 0,
    this.activeDateKeys = const [],
  });

  final int totalNotes;
  final int doneTasks;
  final List<String> activeDateKeys;

  int get activeDays => activeDateKeys.toSet().length;

  int get currentStreak {
    final days = activeDateKeys.toSet();
    var cursor = _dateOnly(DateTime.now());
    var streak = 0;
    while (days.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get completionRate {
    final denominator = totalNotes > doneTasks ? totalNotes : doneTasks;
    if (denominator == 0) return 0;
    return doneTasks / denominator;
  }

  AchievementStatsModel recordNoteCreated([DateTime? time]) {
    return copyWith(
      totalNotes: totalNotes + 1,
      activeDateKeys: _withDate(time ?? DateTime.now()),
    );
  }

  AchievementStatsModel recordTaskCompleted([DateTime? time]) {
    return copyWith(
      doneTasks: doneTasks + 1,
      activeDateKeys: _withDate(time ?? DateTime.now()),
    );
  }

  AchievementStatsModel copyWith({
    int? totalNotes,
    int? doneTasks,
    List<String>? activeDateKeys,
  }) {
    return AchievementStatsModel(
      totalNotes: totalNotes ?? this.totalNotes,
      doneTasks: doneTasks ?? this.doneTasks,
      activeDateKeys: activeDateKeys ?? this.activeDateKeys,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalNotes': totalNotes,
    'doneTasks': doneTasks,
    'activeDateKeys': activeDateKeys,
  };

  factory AchievementStatsModel.fromJson(Map<String, dynamic> json) {
    return AchievementStatsModel(
      totalNotes: json['totalNotes'] as int? ?? 0,
      doneTasks: json['doneTasks'] as int? ?? 0,
      activeDateKeys:
          (json['activeDateKeys'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }

  List<String> _withDate(DateTime time) {
    final next = <String>{...activeDateKeys, _dateKey(time)}.toList();
    next.sort();
    return next;
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _dateKey(DateTime value) {
  final date = _dateOnly(value);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
