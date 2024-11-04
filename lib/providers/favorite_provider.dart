import 'package:flutter/foundation.dart';
import '../models/pokemon.dart';

class FavoriteProvider with ChangeNotifier {
  final List<Pokemon> _favorites = [];

  List<Pokemon> get favorites => _favorites;

  void addFavorite(Pokemon pokemon) {
    _favorites.add(pokemon);
    notifyListeners();
  }

  void removeFavorite(Pokemon pokemon) {
    _favorites.remove(pokemon);
    notifyListeners();
  }

  bool isFavorite(Pokemon pokemon) {
    return _favorites.contains(pokemon);
  }
}
