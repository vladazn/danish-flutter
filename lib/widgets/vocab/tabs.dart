import 'package:flutter/material.dart';

class VocabTabForm extends StatelessWidget {
  final String selectedTab;
  final Map<String, String> fieldValues;
  final void Function(String from, String value) onChanged;

  const VocabTabForm({
    super.key,
    required this.selectedTab,
    required this.fieldValues,
    required this.onChanged,
  });

  static const Map<String, List<String>> _fieldsPerTab = {
    'noun': ['indefinite_singular', 'indefinite_plural'],
    'verb': ['present', 'past'],
    'adjective': ['positive'],
    'numeral': ['cardinal', 'ordinal', 'multiplicative', 'fractional'],
    'pronoun': ['personal', 'possessive'],
    'question': ['question'],
    'adverb': ['adverb']
  };

  static List<String> getFieldsForTab(String tab) {
    return _fieldsPerTab[tab] ?? [];
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'indefinite_singular':
        return 'Indefinite Singular';
      case 'indefinite_plural':
        return 'Indefinite Plural';
      case 'present':
        return 'Present Tense';
      case 'past':
        return 'Past Tense';
      case 'cardinal':
        return 'Cardinal Number';
      case 'ordinal':
        return 'Ordinal Number';
      case 'multiplicative':
        return 'Multiplicative';
      case 'fractional':
        return 'Fractional';
      case 'personal':
        return 'Personal Form';
      case 'possessive':
        return 'Possessive Form';
      case 'question':
        return 'Question Word';
      case 'positive':
        return 'Positive Form';
      case 'adverb':
        return 'Adverb Form';
      default:
        return field.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
        ).join(' ');
    }
  }

  String _getFieldHint(String field) {
    switch (field) {
      case 'indefinite_singular':
        return 'e.g., hus (house)';
      case 'indefinite_plural':
        return 'e.g., huse (houses)';
      case 'present':
        return 'e.g., løber (runs)';
      case 'past':
        return 'e.g., løb (ran)';
      case 'cardinal':
        return 'e.g., fem (five)';
      case 'ordinal':
        return 'e.g., femte (fifth)';
      case 'multiplicative':
        return 'e.g., femdobbelte (fivefold)';
      case 'fractional':
        return 'e.g., femtedel (fifth)';
      case 'personal':
        return 'e.g., jeg (I)';
      case 'possessive':
        return 'e.g., min (my)';
      case 'question':
        return 'e.g., hvad (what)';
      case 'positive':
        return 'e.g., stor (big)';
      case 'adverb':
        return 'e.g., hurtigt (quickly)';
      default:
        return 'Enter Danish word...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fields = getFieldsForTab(selectedTab);

    return Column(
      children: fields.map((field) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getFieldDisplayName(field),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: _getFieldHint(field),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.edit,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                controller: TextEditingController(text: fieldValues[field] ?? '')
                  ..selection = TextSelection.collapsed(
                    offset: (fieldValues[field]?.length ?? 0),
                  ),
                onChanged: (val) => onChanged(field, val),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
