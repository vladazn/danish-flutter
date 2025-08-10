import '../models/vocab_set.dart';
import '../models/batch.dart';
import '../api/api_service.dart';

class SetService {
  final ApiService api;

  SetService(this.api);

  Future<List<VocabSet>> getAllSets() => api.fetchVocabSets();
  Future<VocabSet> createSet(String name, List<String> vocabIds) => api.createVocabSet(name, vocabIds);
  Future<void> updateSet(String setId, String name, List<String> vocabIds) => api.updateVocabSet(setId, name, vocabIds);
  Future<Batch> getBatchFromSet(String setId, {int? limit}) => api.fetchBatchFromSet(setId, limit: limit);
  Future<void> deleteSet(String setId) => api.deleteVocabSet(setId);
}
