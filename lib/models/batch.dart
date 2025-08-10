import 'vocab.dart';

class Batch {
  final List<Vocab> vocabs;

  Batch({required this.vocabs});

  factory Batch.fromJson(Map<String, dynamic> json) {
    final vocabList = (json['vocabs'] as List)
        .map((item) => Vocab.fromJson(item))
        .toList();
    return Batch(vocabs: vocabList);
  }

  Map<String, dynamic> toJson() {
    return {'vocabs': vocabs.map((v) => v.toJson()).toList()};
  }
}
