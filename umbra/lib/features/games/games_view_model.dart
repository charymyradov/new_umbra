import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog.dart';
import '../../state/toast_controller.dart';

class GamesState {
  const GamesState({this.featured = 0, this.open});

  /// Index into [games] of the featured card.
  final int featured;

  /// Expanded game card, if any.
  final String? open;

  Game get featuredGame => games[featured % games.length];
}

class GamesViewModel extends Notifier<GamesState> {
  @override
  GamesState build() => const GamesState();

  void feature(int i) => state = GamesState(featured: i % games.length, open: state.open);

  /// Swipe on the featured card: positive steps forward.
  void step(int delta) => feature((state.featured + delta + games.length) % games.length);

  void toggle(String id) => state = GamesState(featured: state.featured, open: state.open == id ? null : id);

  void play(Game g) => ref.read(toastProvider.notifier).show('${g.name} is coming soon');
}

final gamesViewModelProvider = NotifierProvider.autoDispose<GamesViewModel, GamesState>(GamesViewModel.new);
