class VocabSet {
  final String id;
  final String name;
  final List<String> vocabIds;

  VocabSet({
    required this.id,
    required this.name,
    required this.vocabIds,
  });

  factory VocabSet.fromJson(Map<String, dynamic> json) {
    return VocabSet(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      vocabIds: List<String>.from(json['vocab_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vocab_ids': vocabIds,
    };
  }
}
