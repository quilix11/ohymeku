import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import 'character_selection_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'vocabulary_screen.dart';
import 'meku_screen.dart';
import '../widgets/meku_avatar.dart';
import '../widgets/ohymeku_design.dart';
import 'settings_screen.dart';
import 'practice_screen.dart';
import 'placement_screen.dart';
import 'generation_screen.dart';
import '../services/meku_service.dart';
import '../models/meku_route.dart';
import '../models/scenario.dart';
import '../widgets/dictionary_sheet.dart';
import 'reading_screen.dart';
import 'reader_screen.dart';
import 'game_screen.dart';
import 'journey_screen.dart';

class MainScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  const MainScreen({super.key, required this.settings, required this.progress});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  bool _journey = true;
  final _visited = <int>{0};
  late final MekuService _meku;
  String? _wordDeck;
  bool _wordAll = false;
  int _wordRequest = 0;
  @override
  void initState() {
    super.initState();
    _meku = MekuService(widget.settings, widget.progress);
    _meku.load();
  }

  @override
  void dispose() {
    _meku.dispose();
    super.dispose();
  }

  void _navigate(String destination) {
    if (!mounted) return;
    if (destination == 'journey' || destination == 'conversations') {
      setState(() {
        _journey = destination == 'journey';
        _index = 0;
        _visited.add(0);
      });
      return;
    }
    const tabs = {'conversations': 0, 'words': 1, 'progress': 2, 'profile': 3};
    if (tabs.containsKey(destination)) {
      _select(tabs[destination]!);
      return;
    }
    final Widget screen;
    switch (destination) {
      case 'reading':
        screen =
            ReadingScreen(settings: widget.settings, progress: widget.progress);
      case 'settings':
        screen = SettingsScreen(settings: widget.settings);
      case 'practice':
        screen = PracticeScreen(
            settings: widget.settings, progress: widget.progress);
      case 'placement':
        screen = PlacementScreen(
            settings: widget.settings, progress: widget.progress, retake: true);
      case 'generation':
        if (widget.settings.offlineMode) return;
        screen = GenerationScreen(
          boss: false,
          level: widget.settings.effectiveLevel,
          interests: widget.settings.interests,
          count: widget.settings.cardCount,
          onSave: (result, topic, level, warm) => widget.settings.vocabulary
              .addGenerated(result['cards'], '$topic · $level'),
        );
      case 'character_generation':
        if (widget.settings.offlineMode) return;
        screen = GenerationScreen(
            boss: true,
            level: widget.settings.effectiveLevel,
            interests: widget.settings.interests,
            onSave: (result, topic, level, warm) async {
              await widget.settings
                  .addGeneratedScenario(result, topic, level, warm);
            });
      default:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  bool _mekuOpen = false;
  bool _route(MekuRoute route) {
    if (!mounted) return false;
    final args = route.arguments;
    Widget screen;
    switch (route.destination) {
      case 'review_words':
        setState(() {
          _wordDeck = args['deck'] == 'all' ? null : args['deck'] as String?;
          _wordAll = args['all'] == true;
          _wordRequest++;
          _index = 1;
          _visited.add(1);
        });
        return true;
      case 'start_conversation':
        final matches = [...Scenario.all, ...widget.settings.customScenarios]
            .where((s) => (s.customId ?? s.character.name) == args['id']);
        if (matches.isEmpty || widget.settings.offlineMode) return false;
        final s = matches.first;
        screen = GameScreen(
            settings: widget.settings,
            progress: widget.progress,
            character: s.character,
            scenario: s);
      case 'dictionary':
        showDictionary(context, widget.settings, word: args['word'] as String);
        return true;
      case 'reading':
        screen = ReadingScreen(
            settings: widget.settings,
            progress: widget.progress,
            initialQuery: args['query'] as String? ?? '');
      case 'read_article':
        final article = widget.settings.reading.byId(args['id'] as String);
        if (article == null) return false;
        screen = ReaderScreen(
            settings: widget.settings,
            progress: widget.progress,
            article: article);
      default:
        return false;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    return true;
  }

  Future<void> _openMeku() async {
    if (_mekuOpen) return;
    _mekuOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: FractionallySizedBox(
            heightFactor: .92,
            child: MekuScreen(
              meku: _meku,
              onClose: () => Navigator.of(sheetContext).pop(),
              navigate: (destination) {
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                _navigate(destination);
              },
              route: (route) {
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                return _route(route);
              },
            )),
      ),
    );
    _mekuOpen = false;
  }

  void _select(int index) {
    if (_index == index) return;
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), c = theme.colorScheme;
    final large = MediaQuery.textScalerOf(context).scale(16) > 21;
    return ListenableBuilder(
        listenable: Listenable.merge([widget.progress, _meku]),
        builder: (context, _) => Scaffold(
              appBar: AppBar(
                title: Text('ohymeku',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800, fontSize: 24)),
                actions: [
                  if (_journey && _index == 0)
                    IconButton(
                        tooltip: 'Налаштування',
                        onPressed: () => _navigate('settings'),
                        icon: const Icon(Icons.tune_rounded)),
                  if (!_journey || _index != 0)
                    IconButton(
                        tooltip: 'Карта рівнів',
                        onPressed: () => _navigate('journey'),
                        icon: const Icon(Icons.route_rounded)),
                  Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: large
                          ? IconButton.filledTonal(
                              key: const Key('meku_launcher'),
                              tooltip: 'Поговорити з Meku',
                              onPressed: _openMeku,
                              icon:
                                  MekuAvatar(size: 28, emotion: _meku.emotion))
                          : TextButton.icon(
                              key: const Key('meku_launcher'),
                              onPressed: _openMeku,
                              icon:
                                  MekuAvatar(size: 28, emotion: _meku.emotion),
                              label: const Text('Meku'))),
                ],
              ),
              body: SilkBackground(
                  child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: IndexedStack(index: _index, children: [
                          if (_visited.contains(0))
                            RepaintBoundary(
                                child: _journey
                                    ? JourneyScreen(
                                        settings: widget.settings,
                                        progress: widget.progress,
                                        onConversations: () =>
                                            _navigate('conversations'))
                                    : CharacterSelectionScreen(
                                        settings: widget.settings,
                                        progress: widget.progress,
                                        onReading: () => _navigate('reading'),
                                        onWords: () => _select(1)))
                          else
                            const SizedBox.shrink(),
                          if (_visited.contains(1))
                            RepaintBoundary(
                                child: VocabularyScreen(
                                    settings: widget.settings,
                                    progress: widget.progress,
                                    initialDeck: _wordDeck,
                                    reviewAll: _wordAll,
                                    requestNonce: _wordRequest,
                                    active: _index == 1))
                          else
                            const SizedBox.shrink(),
                          if (_visited.contains(2))
                            RepaintBoundary(
                                child: ProgressScreen(
                                    progress: widget.progress,
                                    onStart: () => _select(0)))
                          else
                            const SizedBox.shrink(),
                          if (_visited.contains(3))
                            RepaintBoundary(
                                child: ProfileScreen(
                                    settings: widget.settings,
                                    progress: widget.progress))
                          else
                            const SizedBox.shrink(),
                        ]),
                      )))),
              bottomNavigationBar: Material(
                  color: c.surface,
                  child: Container(
                      decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: c.outlineVariant, width: 1.5))),
                      child: SafeArea(
                          top: false,
                          child: Center(
                              heightFactor: 1,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 720),
                                child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(children: [
                                      _tab(0, Icons.home_outlined, 'Головна',
                                          large),
                                      _tab(1, Icons.style_outlined, 'Слова',
                                          large),
                                      _tab(2, Icons.insights_outlined,
                                          'Прогрес', large),
                                      _tab(3, Icons.person_outline_rounded,
                                          'Профіль', large),
                                    ])),
                              ))))),
            ));
  }

  Widget _tab(int index, IconData icon, String label, bool large) {
    final c = Theme.of(context).colorScheme;
    final selected = _index == index;
    return Expanded(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
                selected: selected,
                button: true,
                label: label,
                child: Tooltip(
                    message: label,
                    child: Material(
                        color: selected ? c.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _select(index),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon,
                                        color: selected
                                            ? c.onPrimary
                                            : c.onSurfaceVariant),
                                    if (!large) ...[
                                      const SizedBox(height: 4),
                                      Text(label,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: selected
                                                  ? c.onPrimary
                                                  : c.onSurfaceVariant)),
                                    ],
                                  ])),
                        ))))));
  }
}
