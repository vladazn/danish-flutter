class Vocab {
  final String? id;
  final String definition;
  final String partOfSpeech;
  final List<VocabForm> forms;
  final DateTime? pauseUntil;

  Vocab({
    this.id,
    required this.definition,
    required this.partOfSpeech,
    required this.forms,
    this.pauseUntil,
  });

  factory Vocab.fromJson(Map<String, dynamic> json) {
    return Vocab(
      id: json['id'],
      definition: json['definition'] ?? '',
      partOfSpeech: json['part_of_speech'] ?? 'unknown',
      pauseUntil: json['pause_until'] != null
          ? DateTime.tryParse(json['pause_until'])
          : null,
      forms: (json['forms'] as List<dynamic>? ?? [])
          .map((item) => VocabForm.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'definition': definition,
      'part_of_speech': partOfSpeech,
      'forms': forms.map((form) => form.toJson()).toList(),
      if (pauseUntil != null)
        'pause_until': pauseUntil!.toUtc().toIso8601String(),
    };
  }
}

class VocabForm {
  final String? id;
  final String form;
  final String value;

  VocabForm({this.id, required this.form, required this.value});

  factory VocabForm.fromJson(Map<String, dynamic> json) {
    return VocabForm(
      id: json['id'],
      form: json['form'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'form': form, 'value': value};
  }
}


