import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/vocab_service.dart';
import '../../state/vocab_state.dart';
import 'api_provider.dart';

// Business logic wrapper
final vocabServiceProvider = Provider<VocabService>(
  (ref) => VocabService(ref.read(apiServiceProvider)),
);

// StateNotifier provider for vocab state
final vocabNotifierProvider = StateNotifierProvider<VocabNotifier, VocabState>((
  ref,
) {
  final service = ref.read(vocabServiceProvider);
  final notifier = VocabNotifier(service);
  notifier.init(); // Load vocab list on app init
  return notifier;
});
