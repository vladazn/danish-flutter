import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vocab_set.dart';
import '../../provider/state/vocab_provider.dart';
import '../../provider/state/set_provider.dart';

final createSetSearchQueryProvider = StateProvider<String>((ref) => '');
final selectedVocabIdsProvider = StateProvider<Set<String>>((ref) => {});

class CreateSetPage extends ConsumerStatefulWidget {
  final bool isEditing;
  final VocabSet? existingSet;

  const CreateSetPage({
    super.key,
    this.isEditing = false,
    this.existingSet,
  });

  @override
  ConsumerState<CreateSetPage> createState() => _CreateSetPageState();
}

class _CreateSetPageState extends ConsumerState<CreateSetPage> {
  final TextEditingController _setNameController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingSet != null) {
      _setNameController.text = widget.existingSet!.name;
      // Pre-select existing vocabulary
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedVocabIdsProvider.notifier).state = 
            Set<String>.from(widget.existingSet!.vocabIds);
      });
    }
  }

  @override
  void dispose() {
    _setNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabState = ref.watch(vocabNotifierProvider);
    final searchQuery = ref.watch(createSetSearchQueryProvider);
    final selectedVocabIds = ref.watch(selectedVocabIdsProvider);

    // Filter out paused vocabulary and apply search
    final availableVocabs = vocabState.vocabs.where((vocab) {
      // Only show non-paused vocabulary
      if (vocab.pauseUntil != null && 
          vocab.pauseUntil!.isAfter(DateTime.now())) {
        return false;
      }

      // Apply search filter
      final query = searchQuery.toLowerCase();
      if (query.isEmpty) return true;

      final matchesDefinition = vocab.definition.toLowerCase().contains(query);
      final matchesForm = vocab.forms.any(
        (form) => form.value.toLowerCase().contains(query),
      );

      return matchesDefinition || matchesForm;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Set' : 'Create New Set'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (selectedVocabIds.isNotEmpty)
            Text(
              '${selectedVocabIds.length} selected',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Set name input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _setNameController,
              decoration: const InputDecoration(
                labelText: 'Set Name',
                hintText: 'Enter a name for your vocabulary set',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => ref.read(createSetSearchQueryProvider.notifier).state = value,
              decoration: const InputDecoration(
                hintText: 'Search vocabulary (definition or Danish word)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Vocabulary list
          if (vocabState.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: availableVocabs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isEmpty 
                                ? 'No available vocabulary found'
                                : 'No matches found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search terms',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableVocabs.length,
                      itemBuilder: (context, index) {
                        final vocab = availableVocabs[index];
                        final isSelected = selectedVocabIds.contains(vocab.id);
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? Colors.teal.shade50 : null,
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                final currentSelected = ref.read(selectedVocabIdsProvider);
                                if (value == true) {
                                  ref.read(selectedVocabIdsProvider.notifier).state = 
                                      {...currentSelected, vocab.id!};
                                } else {
                                  ref.read(selectedVocabIdsProvider.notifier).state = 
                                      currentSelected.difference({vocab.id!});
                                }
                              },
                            ),
                            title: Text(
                              vocab.definition,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vocab.partOfSpeech),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: vocab.forms.map((form) {
                                    return Chip(
                                      label: Text(
                                        form.value,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Colors.teal.shade100,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Toggle selection on tap
                              final currentSelected = ref.read(selectedVocabIdsProvider);
                              if (currentSelected.contains(vocab.id)) {
                                ref.read(selectedVocabIdsProvider.notifier).state = 
                                    currentSelected.difference({vocab.id!});
                              } else {
                                ref.read(selectedVocabIdsProvider.notifier).state = 
                                    {...currentSelected, vocab.id!};
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
      // Floating submit button
      floatingActionButton: selectedVocabIds.isNotEmpty && _setNameController.text.trim().isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isCreating ? null : _createSet,
              label: _isCreating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing 
                      ? 'Update Set (${selectedVocabIds.length})'
                      : 'Create Set (${selectedVocabIds.length})'),
              icon: _isCreating ? null : const Icon(Icons.check),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Future<void> _createSet() async {
    final setName = _setNameController.text.trim();
    final selectedVocabIds = ref.read(selectedVocabIdsProvider);
    
    if (setName.isEmpty || selectedVocabIds.isEmpty) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final setNotifier = ref.read(setNotifierProvider.notifier);
      
      if (widget.isEditing && widget.existingSet != null) {
        // Update existing set
        await setNotifier.updateSet(
          widget.existingSet!.id,
          setName,
          selectedVocabIds.toList(),
        );
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Set "$setName" updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new set
        await setNotifier.createSet(setName, selectedVocabIds.toList());
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Set "$setName" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // Clear selection
      ref.read(selectedVocabIdsProvider.notifier).state = {};
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${widget.isEditing ? 'updating' : 'creating'} set: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
