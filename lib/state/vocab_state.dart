import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab.dart';
import '../services/vocab_service.dart';

class VocabState {
  final List<Vocab> vocabs;
  final bool isLoading;

  VocabState({required this.vocabs, required this.isLoading});

  VocabState copyWith({List<Vocab>? vocabs, bool? isLoading}) {
    return VocabState(
      vocabs: vocabs ?? this.vocabs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class VocabNotifier extends StateNotifier<VocabState> {
  final VocabService service;

  VocabNotifier(this.service)
      : super(VocabState(vocabs: [], isLoading: false));

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await service.getAllVocabs();
      state = state.copyWith(vocabs: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addVocab(Vocab vocab) async {
    final created = await service.addVocab(vocab);
    state = state.copyWith(vocabs: [...state.vocabs, created]);
  }

  Future<void> updateVocab(Vocab vocab) async {
    final updated = await service.updateVocab(vocab);
    final index = state.vocabs.indexWhere((v) => v.id == updated.id);
    if (index != -1) {
      final newList = [...state.vocabs];
      newList[index] = updated;
      state = state.copyWith(vocabs: newList);
    }
  }

  Future<void> deleteVocab(String id) async {
    await service.deleteVocab(id);
    state = state.copyWith(vocabs: state.vocabs.where((v) => v.id != id).toList());
  }
}
