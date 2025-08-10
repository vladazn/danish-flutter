import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vocab.dart';
import '../../provider/state/vocab_provider.dart';
import 'form.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class VocabListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vocabNotifierProvider);
    final notifier = ref.read(vocabNotifierProvider.notifier);
    final searchQuery = ref.watch(searchQueryProvider);

    final filteredVocabs = state.vocabs.where((vocab) {
      final query = searchQuery.toLowerCase();

      final matchesDefinition = vocab.definition.toLowerCase().contains(query);
      final matchesForm = vocab.forms.any(
            (form) => form.value.toLowerCase().contains(query),
      );

      return matchesDefinition || matchesForm;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Vocabulary"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                    decoration: InputDecoration(
                      hintText: 'Search (definition or Danish word)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newVocab = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VocabFormPage()),
                    );
                    if (newVocab is Vocab) {
                      await notifier.addVocab(newVocab);
                    }
                  },
                  child: Text("Add"),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: filteredVocabs.isEmpty
                  ? Center(child: Text('No matches found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredVocabs.length,
                      itemBuilder: (context, index) {
                  final vocab = filteredVocabs[index];
                  final isPaused = vocab.pauseUntil != null &&
                      vocab.pauseUntil!.isAfter(DateTime.now());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vocab.definition,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isPaused)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pause_circle_filled,
                                        size: 16,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Paused',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            vocab.partOfSpeech,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: vocab.forms.map((form) {
                              return Chip(
                                label: Text(
                                  form.value,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                backgroundColor: Colors.teal.shade100,
                                side: BorderSide(color: Colors.teal.shade300),
                              );
                            }).toList(),
                          ),
                          if (isPaused) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 16,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Paused until: ${vocab.pauseUntil!.toLocal().toIso8601String().substring(0, 10)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VocabFormPage(existingVocab: vocab),
                                    ),
                                  );
                                  if (updated is Vocab) {
                                    await notifier.updateVocab(updated);
                                  }
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => notifier.deleteVocab(vocab.id ?? ""),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final updated = Vocab(
                                    id: vocab.id,
                                    definition: vocab.definition,
                                    partOfSpeech: vocab.partOfSpeech,
                                    forms: vocab.forms,
                                    pauseUntil: isPaused ? null : DateTime.now().add(Duration(days: 30)),
                                  );
                                  await notifier.updateVocab(updated);
                                },
                                icon: Icon(
                                  isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled,
                                ),
                                label: Text(isPaused ? 'Unpause' : 'Pause'),
                                style: TextButton.styleFrom(
                                  foregroundColor: isPaused ? Colors.green.shade700 : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
