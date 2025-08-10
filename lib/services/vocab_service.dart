import '../models/vocab.dart';
import '../api/api_service.dart';

class VocabService {
  final ApiService api;

  VocabService(this.api);

  Future<List<Vocab>> getAllVocabs() => api.fetchAllVocab();
  Future<Vocab> addVocab(Vocab vocab) => api.addVocab(vocab);
  Future<Vocab> updateVocab(Vocab vocab) => api.updateVocab(vocab);
  Future<void> deleteVocab(String id) => api.deleteVocab(id);
}
