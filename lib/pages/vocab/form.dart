import 'package:flutter/material.dart';
import '../../models/vocab.dart';
import '../../widgets/vocab/tabs.dart';

class VocabFormPage extends StatefulWidget {
  final Vocab? existingVocab;

  const VocabFormPage({super.key, this.existingVocab});

  @override
  _VocabFormPageState createState() => _VocabFormPageState();
}

class _VocabFormPageState extends State<VocabFormPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['noun', 'verb', 'numeral', 'pronoun', 'question', 'adverb'];
  String selectedTab = 'noun';

  final TextEditingController _definitionController = TextEditingController();
  List<VocabForm> _formEntries = [];
  DateTime? _pauseUntil;

  @override
  void initState() {
    super.initState();

    if (widget.existingVocab != null) {
      final vocab = widget.existingVocab!;
      _definitionController.text = vocab.definition;
      selectedTab = vocab.partOfSpeech.toLowerCase();
      _formEntries = List<VocabForm>.from(vocab.forms);
      _pauseUntil = vocab.pauseUntil;
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.index = _tabs.indexOf(selectedTab);
    _tabController.addListener(() {
      setState(() {
        selectedTab = _tabs[_tabController.index];
      });
    });
  }

  void _updateField(String form, String value) {
    final index = _formEntries.indexWhere((entry) => entry.form == form);
    if (index != -1) {
      _formEntries[index] = VocabForm(
        id: _formEntries[index].id,
        form: form,
        value: value,
      );
    } else {
      _formEntries.add(VocabForm(form: form, value: value));
    }
  }

  bool _hasAnyFieldFilled(String tab) {
    final expectedFields = VocabTabForm.getFieldsForTab(tab);
    return _formEntries
        .where((entry) => expectedFields.contains(entry.form))
        .any((entry) => entry.value.trim().isNotEmpty);
  }

  void _submitForm() {
    if (_definitionController.text.trim().isEmpty &&
        !_hasAnyFieldFilled(selectedTab)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Definition or at least one field is required"),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final filteredForms = _formEntries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList();

    final vocab = Vocab(
      id: widget.existingVocab?.id,
      definition: _definitionController.text.trim(),
      partOfSpeech: selectedTab,
      forms: filteredForms,
      pauseUntil: _pauseUntil,
    );

    Navigator.pop(context, vocab);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabFields = VocabTabForm.getFieldsForTab(selectedTab);
    final currentValues = {
      for (var field in tabFields)
        field: _formEntries
            .firstWhere(
              (entry) => entry.form == field,
          orElse: () => VocabForm(form: field, value: ''),
        )
            .value
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful app bar with gradient
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: null,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      theme.colorScheme.primary.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: _tabs.map((tab) => Tab(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(tab.toUpperCase()),
                ),
              )).toList(),
            ),
          ),
          
          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Definition section
                  _buildSectionCard(
                    title: 'Definition',
                    subtitle: 'Enter the English definition or meaning',
                    icon: Icons.translate,
                    color: Colors.blue,
                    child: TextField(
                      controller: _definitionController,
                      decoration: InputDecoration(
                        hintText: 'e.g., House, Run, Beautiful...',
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
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Danish forms section
                  _buildSectionCard(
                    title: 'Danish Forms',
                    subtitle: 'Enter the Danish word forms for $selectedTab',
                    icon: Icons.language,
                    color: Colors.green,
                    child: VocabTabForm(
                      selectedTab: selectedTab,
                      fieldValues: currentValues,
                      onChanged: (form, value) => setState(() {
                        _updateField(form, value);
                      }),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Pause controls section
                  _buildSectionCard(
                    title: 'Learning Schedule',
                    subtitle: 'Control when this word appears in study sessions',
                    icon: Icons.schedule,
                    color: Colors.orange,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _pauseUntil = DateTime.now().add(const Duration(days: 30));
                                  });
                                },
                                icon: const Icon(Icons.pause_circle_filled),
                                label: const Text("Pause for 1 Month"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_pauseUntil != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _pauseUntil = null;
                                    });
                                  },
                                  icon: const Icon(Icons.play_circle_filled),
                                  label: const Text("Resume Learning"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade300,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_pauseUntil != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "Paused until: ${_pauseUntil!.toLocal().toString().substring(0, 16)}",
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save, size: 24),
                      label: Text(
                        widget.existingVocab != null ? "Update Word" : "Save New Word",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
