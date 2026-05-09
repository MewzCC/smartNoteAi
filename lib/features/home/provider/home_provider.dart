import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/ai_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/device_utils.dart';
import '../../../data/models/achievement_stats_model.dart';
import '../../../data/models/note_model.dart';
import '../../../data/models/user_config_model.dart';
import '../../../data/repositories/achievement_stats_repository.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/enums/note_color.dart';
import '../../../shared/enums/note_priority.dart';
import '../../../shared/helpers/checklist_helper.dart';

class SmartNoteState {
  const SmartNoteState({
    required this.notes,
    required this.config,
    required this.archiveDate,
    required this.achievementStats,
    this.generatedPlans = const [],
    this.generating = false,
  });

  final List<NoteModel> notes;
  final UserConfigModel config;
  final DateTime archiveDate;
  final AchievementStatsModel achievementStats;
  final List<GeneratedPlan> generatedPlans;
  final bool generating;

  List<NoteModel> get activeNotes =>
      notes.where((note) => !note.isDeleted).toList();

  List<NoteModel> get trashNotes =>
      notes.where((note) => note.isDeleted).toList()..sort((a, b) {
        final left = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

  int get doneCount => activeNotes.where((note) => note.done).length;
  int get pendingCount => activeNotes.length - doneCount;
  int get activeDays =>
      activeNotes.map((note) => dateOnly(note.createdAt)).toSet().length;
  double get completionRate =>
      activeNotes.isEmpty ? 0 : doneCount / activeNotes.length;

  List<NoteModel> get visibleNotes =>
      [...activeNotes.where((note) => !note.isArchived)]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (a.done != b.done) return a.done ? 1 : -1;
        return _compareRecentFirst(a, b);
      });

  List<NoteModel> get archivedNotes =>
      activeNotes.where((note) => note.isArchived).toList();

  List<NoteModel> get notesOnArchiveDate {
    final selected = dateOnly(archiveDate);
    return activeNotes
        .where(
          (note) => dateOnly(
            note.reminderAt ?? note.createdAt,
          ).isAtSameMomentAs(selected),
        )
        .toList();
  }

  int get currentStreak {
    final doneDays = notes
        .where((note) => !note.isDeleted && note.done)
        .map((note) => dateOnly(note.reminderAt ?? note.createdAt))
        .toSet();
    var cursor = dateOnly(DateTime.now());
    var streak = 0;
    while (doneDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  SmartNoteState copyWith({
    List<NoteModel>? notes,
    UserConfigModel? config,
    DateTime? archiveDate,
    AchievementStatsModel? achievementStats,
    List<GeneratedPlan>? generatedPlans,
    bool? generating,
  }) {
    return SmartNoteState(
      notes: notes ?? this.notes,
      config: config ?? this.config,
      archiveDate: archiveDate ?? this.archiveDate,
      achievementStats: achievementStats ?? this.achievementStats,
      generatedPlans: generatedPlans ?? this.generatedPlans,
      generating: generating ?? this.generating,
    );
  }
}

class SmartNoteController extends Notifier<SmartNoteState> {
  final _notes = NoteRepository();
  final _user = UserRepository();
  final _ai = const AiRepository();
  final _achievementStats = AchievementStatsRepository();

  @override
  SmartNoteState build() {
    return SmartNoteState(
      notes: _notes.loadNotes(),
      config: _user.loadConfig(),
      archiveDate: DateTime.now(),
      achievementStats: _achievementStats.loadStats(),
    );
  }

  Future<void> addNote({
    required String title,
    required String content,
    DateTime? reminderAt,
    NotePriority priority = NotePriority.medium,
    NoteColor? paperColor,
    String tag = '全部',
    bool isTask = false,
    bool done = false,
    bool isPinned = false,
  }) async {
    final note = _notes.create(
      title: title,
      content: content,
      reminderAt: reminderAt,
      priority: priority,
      paperColor: paperColor,
      tag: tag,
      isTask: isTask,
      done: done,
      isPinned: isPinned,
    );
    await _persist([...state.notes, note]);
    await NotificationService.instance.schedule(note);
    await _recordNoteCreated(done && isTask);
  }

  Future<void> addGeneratedPlans() async {
    final created = state.generatedPlans.map((plan) {
      return _notes.create(
        title: plan.title,
        content: plan.content,
        reminderAt: plan.reminderAt,
        priority: plan.priority,
        paperColor: noteColorFromPriority(plan.priority),
        tag: plan.tag,
        isTask: true,
      );
    }).toList();
    await _persist([...state.notes, ...created]);
    for (final note in created) {
      await NotificationService.instance.schedule(note);
    }
    await _recordNotesCreated(created.length);
  }

  Future<void> addGeneratedPlan(
    GeneratedPlan plan, {
    DateTime? reminderAt,
    String? tag,
    bool isTask = true,
  }) async {
    final created = _notes.create(
      title: plan.title,
      content: plan.content,
      reminderAt: reminderAt ?? plan.reminderAt,
      priority: plan.priority,
      paperColor: noteColorFromPriority(plan.priority),
      tag: tag ?? plan.tag,
      isTask: isTask,
    );
    await _persist([...state.notes, created]);
    await NotificationService.instance.schedule(created);
    await _recordNoteCreated(false);
  }

  Future<void> updateNote(NoteModel note) async {
    final next = [
      for (final item in state.notes)
        if (item.id == note.id) note else item,
    ];
    await _persist(next);
    await NotificationService.instance.schedule(note);
  }

  Future<bool> toggleDone(String id) async {
    final target = state.notes.where((item) => item.id == id).firstOrNull;
    if (target == null) return false;
    final nextDone = !target.done;
    if (nextDone && !canCompleteTaskContent(target.content)) {
      return false;
    }

    final next = [
      for (final item in state.notes)
        if (item.id == id) item.copyWith(done: nextDone) else item,
    ];
    await _persist(next);
    if (nextDone) {
      await _recordTaskCompleted();
    }
    return true;
  }

  Future<void> toggleArchive(String id) async {
    final next = [
      for (final item in state.notes)
        if (item.id == id)
          item.copyWith(isArchived: !item.isArchived)
        else
          item,
    ];
    await _persist(next);
  }

  Future<void> togglePin(String id) async {
    final next = [
      for (final item in state.notes)
        if (item.id == id) item.copyWith(isPinned: !item.isPinned) else item,
    ];
    await _persist(next);
  }

  Future<void> deleteNote(String id) async {
    await NotificationService.instance.cancel(id);
    final next = [
      for (final item in state.notes)
        if (item.id == id)
          item.copyWith(
            isDeleted: true,
            deletedAt: DateTime.now(),
            isArchived: false,
          )
        else
          item,
    ];
    await _persist(next);
  }

  Future<void> restoreNote(String id) async {
    final next = [
      for (final item in state.notes)
        if (item.id == id)
          item.copyWith(isDeleted: false, clearDeletedAt: true)
        else
          item,
    ];
    await _persist(next);
  }

  Future<void> permanentlyDeleteNote(String id) async {
    await NotificationService.instance.cancel(id);
    await _persist(state.notes.where((note) => note.id != id).toList());
  }

  Future<void> saveConfig(UserConfigModel config) async {
    await _user.saveConfig(config);
    state = state.copyWith(config: config);
  }

  Future<void> addCustomTag(String tag) async {
    final value = tag.trim();
    if (value.isEmpty) return;
    final tags = <String>{...state.config.customTags, value}.toList();
    final config = state.config.copyWith(customTags: tags);
    await _user.saveConfig(config);
    state = state.copyWith(config: config);
  }

  void setArchiveDate(DateTime date) {
    state = state.copyWith(archiveDate: dateOnly(date));
  }

  Future<void> generate(String prompt) async {
    if (prompt.trim().isEmpty) return;
    state = state.copyWith(generating: true, generatedPlans: []);
    try {
      final plans = await _ai.generate(config: state.config, prompt: prompt);
      state = state.copyWith(generatedPlans: plans, generating: false);
    } catch (_) {
      state = state.copyWith(generating: false);
      rethrow;
    }
  }

  void clearGeneratedPlans() {
    state = state.copyWith(generatedPlans: []);
  }

  void removeGeneratedPlanAt(int index) {
    if (index < 0 || index >= state.generatedPlans.length) return;
    final plans = [...state.generatedPlans]..removeAt(index);
    state = state.copyWith(generatedPlans: plans);
  }

  Future<void> _persist(List<NoteModel> notes) async {
    await _notes.saveNotes(notes);
    state = state.copyWith(notes: notes);
  }

  Future<void> _recordNoteCreated(bool completedTask) async {
    var next = state.achievementStats.recordNoteCreated();
    if (completedTask) {
      next = next.recordTaskCompleted();
    }
    await _saveAchievementStats(next);
  }

  Future<void> _recordNotesCreated(int count) async {
    if (count <= 0) return;
    var next = state.achievementStats;
    for (var index = 0; index < count; index++) {
      next = next.recordNoteCreated();
    }
    await _saveAchievementStats(next);
  }

  Future<void> _recordTaskCompleted() async {
    final next = state.achievementStats.recordTaskCompleted();
    await _saveAchievementStats(next);
  }

  Future<void> _saveAchievementStats(AchievementStatsModel stats) async {
    await _achievementStats.saveStats(stats);
    state = state.copyWith(achievementStats: stats);
  }
}

final smartNoteProvider = NotifierProvider<SmartNoteController, SmartNoteState>(
  SmartNoteController.new,
);

int _compareRecentFirst(NoteModel a, NoteModel b) {
  final now = DateTime.now();
  final aTime = a.reminderAt ?? a.createdAt;
  final bTime = b.reminderAt ?? b.createdAt;
  final aFuture = !aTime.isBefore(now);
  final bFuture = !bTime.isBefore(now);
  if (aFuture != bFuture) return aFuture ? -1 : 1;
  return aFuture ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
}
