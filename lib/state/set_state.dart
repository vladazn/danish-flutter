import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab_set.dart';
import '../models/batch.dart';
import '../services/set_service.dart';

class SetState {
  final List<VocabSet> sets;
  final Batch? currentBatch;
  final bool isLoading;
  final String? error;

  SetState({
    required this.sets,
    this.currentBatch,
    required this.isLoading,
    this.error,
  });

  SetState copyWith({
    List<VocabSet>? sets,
    Batch? currentBatch,
    bool? isLoading,
    String? error,
  }) {
    return SetState(
      sets: sets ?? this.sets,
      currentBatch: currentBatch ?? this.currentBatch,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SetNotifier extends StateNotifier<SetState> {
  final SetService service;

  SetNotifier(this.service)
      : super(SetState(sets: [], isLoading: false));

  Future<void> init() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await service.getAllSets();
      state = state.copyWith(sets: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createSet(String name, List<String> vocabIds) async {
    try {
      final created = await service.createSet(name, vocabIds);
      state = state.copyWith(sets: [...state.sets, created]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSet(String setId, String name, List<String> vocabIds) async {
    try {
      await service.updateSet(setId, name, vocabIds);
      final index = state.sets.indexWhere((s) => s.id == setId);
      if (index != -1) {
        final newList = [...state.sets];
        newList[index] = VocabSet(
          id: setId,
          name: name,
          vocabIds: vocabIds,
        );
        state = state.copyWith(sets: newList);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteSet(String setId) async {
    try {
      await service.deleteSet(setId);
      final newList = state.sets.where((s) => s.id != setId).toList();
      state = state.copyWith(sets: newList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadBatchFromSet(String setId, {int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final batch = await service.getBatchFromSet(setId, limit: limit);
      state = state.copyWith(currentBatch: batch, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentBatch() {
    state = state.copyWith(currentBatch: null);
  }
}
