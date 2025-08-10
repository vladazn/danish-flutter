import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/vocab.dart';
import '../../models/vocab_set.dart';
import '../../provider/state/set_provider.dart';

class PracticeSetPage extends ConsumerStatefulWidget {
  final VocabSet vocabSet;

  const PracticeSetPage({super.key, required this.vocabSet});

  @override
  ConsumerState<PracticeSetPage> createState() => _PracticeSetPageState();
}

class _PracticeSetPageState extends ConsumerState<PracticeSetPage> {
  final _random = Random();
  final _controller = TextEditingController();

  List<_FormSession> fullQueue = [];
  List<_FormSession> formQueue = [];
  _FormSession? currentSession;

  bool isLoading = true;
  bool sessionComplete = false;

  bool showCorrectAnswer = false;
  String lastCorrectAnswer = '';

  final Map<String, int> mistakeCounter = {};
  final Set<String> firstTryCorrect = {};

  @override
  void initState() {
    super.initState();
    _loadSetVocabulary();
  }

  Future<void> _loadSetVocabulary() async {
    setState(() => isLoading = true);

    try {
      // Get the vocabulary batch from the set using the API
      final setService = ref.read(setServiceProvider);
      final batch = await setService.getBatchFromSet(widget.vocabSet.id);

      if (batch.vocabs.isEmpty) {
        setState(() {
          isLoading = false;
          sessionComplete = true;
        });
        return;
      }

      final entries = <_FormSession>[];
      for (final vocab in batch.vocabs) {
        for (final form in vocab.forms) {
          final vocabWithSingleForm = Vocab(
            id: vocab.id,
            partOfSpeech: vocab.partOfSpeech,
            definition: vocab.definition,
            forms: [form],
            pauseUntil: vocab.pauseUntil,
          );
          entries.add(_FormSession(vocab: vocabWithSingleForm, form: form));
        }
      }

      setState(() {
        fullQueue = entries.toList();
        formQueue = entries.toList();
        currentSession = _pickRandomSession();
        isLoading = false;
      });

              // Animation setup complete
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading set vocabulary: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  _FormSession? _pickRandomSession() {
    if (formQueue.isEmpty) return null;
    return formQueue[_random.nextInt(formQueue.length)];
  }

  bool _isAnswerCorrect(String guess, String correct) {
    final normalizedGuess = guess.toLowerCase().trim();
    final normalizedCorrect = correct.toLowerCase().trim();
    
    // Check if the guess matches the full correct answer
    if (normalizedGuess == normalizedCorrect) {
      return true;
    }
    
    // Check if the correct answer contains a slash and has exactly 2 parts
    if (normalizedCorrect.contains('/')) {
      final parts = normalizedCorrect.split('/');
      if (parts.length == 2) {
        // Accept any of the individual parts or the full answer
        return normalizedGuess == parts[0].trim() || 
               normalizedGuess == parts[1].trim() || 
               normalizedGuess == normalizedCorrect;
      }
    }
    
    return false;
  }

  void _submitAnswer() {
    if (currentSession == null) return;

    final guess = _controller.text.trim();
    final correct = currentSession!.form.value.trim();

    if (_isAnswerCorrect(guess, correct)) {
      if (!currentSession!.hasMistake) {
        firstTryCorrect.add(currentSession!.uniqueKey);
      }

      // Success feedback

      setState(() {
        if (!showCorrectAnswer) {
          formQueue.remove(currentSession);
        }
        _controller.clear();
        showCorrectAnswer = false;
        lastCorrectAnswer = '';

        if (formQueue.isEmpty) {
          _finishSession();
        } else {
          currentSession = _pickRandomSession();
        }
      });
    } else {
      // Incorrect
      setState(() {
        mistakeCounter[currentSession!.uniqueKey] =
            (mistakeCounter[currentSession!.uniqueKey] ?? 0) + 1;
        currentSession!.hasMistake = true;
        showCorrectAnswer = true;
        lastCorrectAnswer = correct;
      });
    }
  }

  void _finishSession() {
    setState(() {
      sessionComplete = true;
    });
  }

  void _repeatSession() {
    setState(() {
      sessionComplete = false;
      mistakeCounter.clear();
      firstTryCorrect.clear();
      _controller.clear();
      showCorrectAnswer = false;
      lastCorrectAnswer = '';
      formQueue = fullQueue.toList();
      currentSession = _pickRandomSession();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Practice: ${widget.vocabSet.name}"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'Loading vocabulary...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (sessionComplete) {
      return _buildResultsPage();
    }

    if (currentSession == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Practice: ${widget.vocabSet.name}"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'No active word',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return _buildPracticePage();
  }

  Widget _buildPracticePage() {
    final session = currentSession!;
    final progress = (fullQueue.length - formQueue.length) / fullQueue.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Practice: ${widget.vocabSet.name}"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress section
                _buildProgressSection(),
                const SizedBox(height: 20),
                
                // Question card
                _buildQuestionCard(session),
                const SizedBox(height: 20),
                
                // Answer input
                _buildAnswerInput(),
                const SizedBox(height: 16),
                
                // Dictionary lookup button
                _buildDictionaryButton(session),
                const SizedBox(height: 16),
                
                // Submit button
                _buildSubmitButton(),
                
                // Correct answer display
                if (showCorrectAnswer) ...[
                  const SizedBox(height: 16),
                  _buildCorrectAnswerDisplay(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${fullQueue.length - formQueue.length} of ${fullQueue.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${formQueue.length}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(_FormSession session) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.form.form,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.translate,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              session.vocab.definition,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onSubmitted: (_) => _submitAnswer(),
          decoration: InputDecoration(
            hintText: 'Your answer',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildDictionaryButton(_FormSession session) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          String cleanedValue = session.form.value;
          if (cleanedValue.toLowerCase().startsWith('en ') ||
              cleanedValue.toLowerCase().startsWith('et ')) {
            cleanedValue = cleanedValue.substring(3);
          }
          final url = 'https://ordnet.dk/ddo/ordbog?query=${Uri.encodeComponent(cleanedValue)}';
          launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault, webOnlyWindowName: "_blank");
        },
        icon: Icon(
          Icons.language,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          'Look up on ordnet.dk',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        child: Text(
          'Submit Answer',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCorrectAnswerDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.red.shade600,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Correct answer: $lastCorrectAnswer',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    final totalMistakes = mistakeCounter.values.fold(0, (a, b) => a + b);
    final totalQuestions = fullQueue.length;
    final correctFirstTry = firstTryCorrect.length;
    final accuracy = totalQuestions > 0 ? (correctFirstTry / totalQuestions * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Results: ${widget.vocabSet.name}'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Results header
                _buildResultsHeader(accuracy),
                const SizedBox(height: 24),
                
                // Stats grid
                _buildStatsGrid(totalQuestions, correctFirstTry, totalMistakes, accuracy),
                const SizedBox(height: 24),
                
                // Mistakes list or perfect score
                mistakeCounter.isNotEmpty
                    ? _buildMistakesList()
                    : _buildPerfectScore(),
                
                // Show first-try correct words if there are any
                if (firstTryCorrect.isNotEmpty && mistakeCounter.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildFirstTryCorrectList(),
                ],
                
                const SizedBox(height: 24),
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(String accuracy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            double.parse(accuracy) >= 90 ? Icons.celebration : Icons.emoji_events,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You achieved $accuracy% accuracy',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int totalQuestions, int correctFirstTry, int totalMistakes, String accuracy) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Questions',
          totalQuestions.toString(),
          Icons.quiz,
          Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          'First Try Correct',
          correctFirstTry.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Total Mistakes',
          totalMistakes.toString(),
          Icons.error,
          Colors.red,
        ),
        _buildStatCard(
          'Accuracy',
          '$accuracy%',
          Icons.analytics,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMistakesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Words with Mistakes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      '${mistakeCounter.length} word${mistakeCounter.length > 1 ? 's' : ''} need${mistakeCounter.length > 1 ? '' : 's'} review',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Mistakes list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
            itemCount: mistakeCounter.length,
            itemBuilder: (context, index) {
              final entry = mistakeCounter.entries.elementAt(index);
              final session = _FormSession.fromKey(entry.key, fullQueue);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Word form type badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              session?.form.form ?? 'Unknown',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Definition
                          Text(
                            session?.vocab.definition ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Correct answer
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Correct: ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                session?.form.value ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Mistake count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Mistake count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${entry.value} mistake${entry.value > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
          },
        ),
      ],
    );
  }

  Widget _buildPerfectScore() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: 64,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Perfect Score!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All words answered correctly on the first try!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFirstTryCorrectList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Words Answered Correctly on First Try',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      '${firstTryCorrect.length} word${firstTryCorrect.length > 1 ? 's' : ''} mastered!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // First-try correct words list
        SizedBox(
          height: 120, // Fixed height for this section
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: firstTryCorrect.length,
            itemBuilder: (context, index) {
              final key = firstTryCorrect.elementAt(index);
              final session = _FormSession.fromKey(key, fullQueue);
              
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word form type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session?.form.form ?? 'Unknown',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Definition (truncated if too long)
                      Text(
                        session?.vocab.definition ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Correct answer
                      Text(
                        session?.form.value ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _repeatSession(),
            icon: const Icon(Icons.replay),
            label: const Text('Repeat Session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Sets'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSession {
  final Vocab vocab;
  final VocabForm form;
  bool hasMistake = false;
  int mistakes = 0;

  _FormSession({required this.vocab, required this.form});

  String get uniqueKey => '${vocab.id} ${form.form} ${form.value}';

  static _FormSession? fromKey(String key, List<_FormSession> fallbackPool) {
    for (final session in fallbackPool) {
      if (session.uniqueKey == key) return session;
    }
    return null;
  }
}
