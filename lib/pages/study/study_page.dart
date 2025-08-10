import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/vocab.dart';
import '../../provider/state/api_provider.dart';

class StudyPage extends ConsumerStatefulWidget {
  const StudyPage({super.key});

  @override
  ConsumerState<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends ConsumerState<StudyPage> {
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
    _loadBatch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBatch() async {
    setState(() => isLoading = true);

    final api = ref.read(apiServiceProvider);
    final batch = await api.fetchBatch();

    final entries = <_FormSession>[];
    for (final vocab in batch.vocabs) {
      for (final form in vocab.forms) {
        final vocabWithSingleForm = Vocab(
          id: vocab.id,
          partOfSpeech: vocab.partOfSpeech,
          definition: vocab.definition,
          forms: [form],
        );
        entries.add(_FormSession(vocab: vocabWithSingleForm, form: form));
      }
    }

    setState(() {
      fullQueue = entries.toList();
      formQueue = entries.toList();
      currentSession = _pickRandomSession();
      isLoading = false;
      sessionComplete = false;
      mistakeCounter.clear();
      firstTryCorrect.clear();
      _controller.clear();
      showCorrectAnswer = false;
      lastCorrectAnswer = '';
    });
  }

  _FormSession _pickRandomSession() {
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

  Future<void> _finishSession() async {
    sessionComplete = true;

    final api = ref.read(apiServiceProvider);
    final vocabsWithoutMistakes = _getFirstTryCorrectSessions();
    final vocabsWithMistakes = _getWithMistakesSessions();

    await api.submitBatchResult(
      _extractUniqueVocabs(vocabsWithoutMistakes),
      _extractUniqueVocabs(vocabsWithMistakes),
    );

    setState(() {});
  }

  List<_FormSession> _getFirstTryCorrectSessions() {
    return firstTryCorrect
        .map((key) {
          return _FormSession.fromKey(key, fullQueue);
        })
        .whereType<_FormSession>()
        .toList();
  }

  List<_FormSession> _getWithMistakesSessions() {
    return fullQueue
        .where((session) => !firstTryCorrect.contains(session.uniqueKey))
        .toList();
  }

  List<Vocab> _extractUniqueVocabs(List<_FormSession> sessions) {
    final vocabSet = <String, Vocab>{};
    for (final session in sessions) {
      if (session.vocab.id != null) {
        vocabSet[session.vocab.id!] = session.vocab;
      }
    }
    return vocabSet.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (sessionComplete) {
      return _buildResultsPage();
    }

    if (currentSession == null) {
      return _buildNoActiveWordScreen();
    }

    return _buildStudyPage();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              SizedBox(height: 24),
              Text(
                'Loading Study Session...',
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildStudyPage() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${fullQueue.length - formQueue.length + 1} of ${fullQueue.length}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (fullQueue.length - formQueue.length) / fullQueue.length,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressSection(),
                const SizedBox(height: 16),
                _buildQuestionCard(),
                const SizedBox(height: 12),
                _buildAnswerInput(),
                if (showCorrectAnswer) ...[
                  const SizedBox(height: 12),
                  _buildCorrectAnswerDisplay(),
                ],
                const SizedBox(height: 16),
                _buildSubmitButton(),
                const SizedBox(height: 20), // Add bottom padding for better scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = (fullQueue.length - formQueue.length) / fullQueue.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
              Icon(
                Icons.timeline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${fullQueue.length - formQueue.length} of ${fullQueue.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (currentSession == null) return const SizedBox.shrink();
    
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
                  currentSession!.form.form,
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
              currentSession!.vocab.definition,
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
    return Container(
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
          TextField(
            controller: _controller,
            autofocus: true,
            onSubmitted: (_) => _submitAnswer(),
            decoration: InputDecoration(
              hintText: 'Your answer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _buildDictionaryButton(),
        ],
      ),
    );
  }

  Widget _buildDictionaryButton() {
    if (currentSession == null) return const SizedBox.shrink();
    
    return ElevatedButton.icon(
      onPressed: () {
        String cleanedValue = currentSession!.form.value;
        if (cleanedValue.toLowerCase().startsWith('en ') ||
            cleanedValue.toLowerCase().startsWith('et ')) {
          cleanedValue = cleanedValue.substring(3);
        }
        final url = 'https://ordnet.dk/ddo/ordbog?query=${Uri.encodeComponent(cleanedValue)}';
        launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault, webOnlyWindowName: "_blank");
      },
      icon: const Icon(Icons.language, size: 18),
      label: const Text('Look up on ordnet.dk'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        foregroundColor: Colors.blue.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCorrectAnswerDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  lastCorrectAnswer,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _submitAnswer,
        icon: const Icon(Icons.send, size: 24),
        label: const Text(
          'Submit Answer',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
        title: const Text('Session Complete!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                _buildResultsHeader(totalQuestions, correctFirstTry, totalMistakes, accuracy),
                const SizedBox(height: 24),
                _buildStatsGrid(totalQuestions, correctFirstTry, totalMistakes, accuracy),
                const SizedBox(height: 24),
                
                // Mistakes list or perfect score
                mistakeCounter.isNotEmpty
                    ? _buildMistakesList()
                    : _buildPerfectScore(),
                
                // Show first-try correct words if there are any
                if (firstTryCorrect.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildFirstTryCorrectList(),
                ],
                
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int totalQuestions, int correctFirstTry, int totalMistakes, String accuracy) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Summary',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Great job completing your study session!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int totalQuestions, int correctFirstTry, int totalMistakes, String accuracy) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Questions', totalQuestions.toString(), Icons.quiz, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('First Try Correct', correctFirstTry.toString(), Icons.check_circle, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMistakesList() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Words to Review',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        '${mistakeCounter.length} word${mistakeCounter.length > 1 ? 's' : ''} need${mistakeCounter.length > 1 ? '' : 's'} practice',
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
              
              if (session == null) return const SizedBox.shrink();
              
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              session.form.form,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Definition
                          Text(
                            session.vocab.definition,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Correct answer with check icon
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade600,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  session.form.value,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildPerfectScore() {
    return Container(
      padding: const EdgeInsets.all(32),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: 40,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Perfect Score! 🎉',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'All words answered correctly on the first try!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.green.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFirstTryCorrectList() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                
                if (session == null) return const SizedBox.shrink();
                
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
                            session.form.form,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Definition (truncated if too long)
                        Text(
                          session.vocab.definition,
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
                          session.form.value,
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
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _loadBatch(),
            icon: const Icon(Icons.refresh, size: 24),
            label: const Text(
              'Study Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 4,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home, size: 24),
            label: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 4,
              shadowColor: Colors.grey.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveWordScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Study Vocabulary"),
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
              Icon(
                Icons.school,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No active word',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
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
