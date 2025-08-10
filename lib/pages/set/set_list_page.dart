import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vocab_set.dart';
import '../../provider/state/set_provider.dart';
import '../../state/set_state.dart';
import 'create_set_page.dart';
import 'set_detail_page.dart';

class SetListPage extends ConsumerWidget {
  const SetListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setState = ref.watch(setNotifierProvider);
    final setNotifier = ref.read(setNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Sets'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setNotifier.init(),
          ),
        ],
      ),
      body: _buildBody(context, setState, setNotifier, ref),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSetPage()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Set',
      ),
    );
  }

  Widget _buildBody(BuildContext context, SetState setState, SetNotifier setNotifier, WidgetRef ref) {
    if (setState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (setState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading sets',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              setState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setNotifier.init(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (setState.sets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No vocabulary sets yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first set to get started!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateSetPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Set'),
            ),
          ],
        ),
      );
    }

          return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: setState.sets.length,
        itemBuilder: (context, index) {
          final set = setState.sets[index];
          return _buildSetCard(context, set, ref);
        },
      );
  }

  Widget _buildSetCard(BuildContext context, VocabSet vocabSet, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SetDetailPage(vocabSet: vocabSet),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vocabSet.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${vocabSet.vocabIds.length} words',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                  ),
                  onPressed: () => _showDeleteDialog(context, vocabSet, ref),
                  tooltip: 'Delete Set',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VocabSet vocabSet, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Set'),
          content: Text(
            'Are you sure you want to delete "${vocabSet.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSet(context, vocabSet, ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSet(BuildContext context, VocabSet vocabSet, WidgetRef ref) {
    final setNotifier = ref.read(setNotifierProvider.notifier);
    setNotifier.deleteSet(vocabSet.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Set "${vocabSet.name}" deleted'),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // Note: Undo functionality would require additional state management
            // For now, just show a message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Undo not available. Please recreate the set if needed.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
