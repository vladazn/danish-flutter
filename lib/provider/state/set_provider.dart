import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/set_service.dart';
import '../../state/set_state.dart';
import 'api_provider.dart';

// Business logic wrapper
final setServiceProvider = Provider<SetService>(
  (ref) => SetService(ref.read(apiServiceProvider)),
);

// StateNotifier provider for set state
final setNotifierProvider = StateNotifierProvider<SetNotifier, SetState>((
  ref,
) {
  final service = ref.read(setServiceProvider);
  final notifier = SetNotifier(service);
  notifier.init(); // Load sets list on app init
  return notifier;
});
