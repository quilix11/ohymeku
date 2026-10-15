import '../models/journey_level.dart';
import '../models/journey_story.dart';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/progress_service.dart';
import 'character_selection_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'vocabulary_screen.dart';
import 'meku_screen.dart';
import '../widgets/air_navigation.dart';
import '../widgets/app_icon.dart';
import '../widgets/profile_avatar.dart';
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
import 'chronicles_screen.dart';
import 'journey_chat_sheet.dart';
import '../widgets/app_menu.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  final SettingsService settings;
  final ProgressService progress;
  const MainScreen({super.key, required this.settings, required this.progress});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tabFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380), value: 1);
  final _shell = GlobalKey<ScaffoldState>();
  int _index = 0;
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
    _tabFade.dispose();
    _meku.dispose();
    super.dispose();
  }

  void _navigate(String destination) {
    if (!mounted) return;
    if (destination == 'journey' || destination == 'conversations') {
      setState(() {
        _index = 0;
        _visited.add(0);
      });
      if (destination == 'conversations') {
        showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => SizedBox(
                height: MediaQuery.sizeOf(context).height * .9,
                child: Scaffold(
                    appBar: AppBar(title: const Text('Персонажі й ситуації')),
                    body: CharacterSelectionScreen(
                        settings: widget.settings,
                        progress: widget.progress,
                        onReading: () => _navigate('reading'),
                        onWords: () => _select(1)))));
      }
      return;
    }
    const tabs = {'conversations': 0, 'words': 1, 'progress': 2, 'profile': 3};
    if (tabs.containsKey(destination)) {
      _select(tabs[destination]!);
      return;
    }
    final Widget screen;
    switch (destination) {
      case 'chronicles':
        screen = ChroniclesScreen(
            settings: widget.settings, progress: widget.progress);
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
        if (widget.settings.offlineMode) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Генерація потребує інтернету. Вимкни офлайн-режим у налаштуваннях.')));
          return;
        }
        screen = GenerationScreen(
          boss: false,
          level: widget.settings.effectiveLevel,
          interests: widget.settings.interests,
          count: widget.settings.cardCount,
          onSave: (result, topic, level, warm) => widget.settings.vocabulary
              .addGenerated(result['cards'], '$topic · $level'),
        );
      case 'character_generation':
        if (widget.settings.offlineMode) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Генерація потребує інтернету. Вимкни офлайн-режим у налаштуваннях.')));
          return;
        }
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
        final matches = [
          ...Scenario.all,
          ...journeyLevels.where((l) => l.boss).expand(freeJourneyScenes),
          ...widget.settings.customScenarios
        ].where((s) => (s.customId ?? s.character.name) == args['id']);
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
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppVisuals.radiusCard))),
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
    if (!MediaQuery.disableAnimationsOf(context)) _tabFade.forward(from: .25);
    setState(() {
      _index = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
        listenable: Listenable.merge([widget.progress, _meku]),
        builder: (context, _) => Scaffold(
              key: _shell,
              extendBody: true,
              drawer: AppMenu(
                  settings: widget.settings,
                  progress: widget.progress,
                  close: () => _shell.currentState?.closeDrawer(),
                  navigate: _navigate,
                  chat: (boss) => showJourneyChats(
                      context, boss, widget.settings, widget.progress),
                  dictionary: () => showDictionary(context, widget.settings),
                  meku: _openMeku),
              appBar: AppBar(
                leading: IconButton(
                    key: const Key('app_menu_button'),
                    tooltip: 'Меню застосунку',
                    onPressed: () => _shell.currentState?.openDrawer(),
                    icon: const AppIcon(AppIconKind.menu)),
                title: Text('ohymeku',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        letterSpacing: -.4)),
                actions: [
                  IconButton(
                      tooltip: 'Профіль',
                      onPressed: () => _select(3),
                      icon: ProfileAvatar(
                          avatar: widget.progress.avatar,
                          color: widget.progress.avatarColor,
                          size: 30)),
                  const SizedBox(width: 8),
                ],
              ),
              body: SilkBackground(
                  child: SafeArea(
                      top: false,
                      bottom: true,
                      child: Center(
                          child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: FadeTransition(
                            opacity: _tabFade
                                .drive(CurveTween(curve: Curves.easeOutCubic)),
                            child: IndexedStack(index: _index, children: [
                              if (_visited.contains(0))
                                RepaintBoundary(
                                    child: JourneyScreen(
                                        settings: widget.settings,
                                        progress: widget.progress))
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
                            ])),
                      )))),
              bottomNavigationBar: AirNavigation(
                selectedIndex: _index,
                onSelect: _select,
                onMeku: _openMeku,
                emotion: _meku.emotion,
                onSettings: () => _navigate('settings'),
              ),
            ));
  }
}
