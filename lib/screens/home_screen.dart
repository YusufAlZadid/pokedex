import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Import for clipboard functionality
import '../models/pokemon.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';
import 'pokemon_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Pokemon> _pokemons = [];
  List<Pokemon> _filteredPokemons = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSearching = false;
  double _progress = 0.0;
  final TextEditingController _searchController = TextEditingController();
  late ApiService _apiService;
  late GeminiService _geminiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _geminiService = GeminiService();
    _fetchPokemons();
  }

  void _fetchPokemons() async {
    try {
      final pokemons = await _apiService.fetchPokemons(onProgress: (progress) {
        setState(() {
          _progress = progress;
        });
      });
      setState(() {
        _pokemons = pokemons;
        _filteredPokemons = pokemons;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
    }
  }

  void _filterPokemons(String query) {
    final filteredPokemons = _pokemons.where((pokemon) {
      final nameLower = pokemon.name.toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    setState(() {
      _filteredPokemons = filteredPokemons;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredPokemons = _pokemons;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final result = await _geminiService.identifyPokemon(pickedFile.path);
      _navigateToPokemonDetail(result);
    }
  }

  void _navigateToPokemonDetail(String responseText) {
    final pokemonName = _extractPokemonName(responseText);

    final matchedPokemon = _pokemons.firstWhere(
          (pokemon) => pokemon.name.toLowerCase() == pokemonName.toLowerCase(),
      orElse: () => Pokemon(
        id: -1,
        name: '',
        height: 0,
        weight: 0,
        baseExperience: 0,
        abilities: [],
        types: [],
        sprites: {},
        cryUrl: '',
        encounterLocations: [],
        artwork: '',
      ),
    );

    if (matchedPokemon.id != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PokemonDetailScreen(pokemonId: matchedPokemon.id),
        ),
      );
    } else {
      _showErrorDialog(responseText);
    }
  }

  String _extractPokemonName(String responseText) {
    final patterns = [
      RegExp(r'\b(?:This is|That pokemon is|It is|The Pokémon is)\s+(\w+)\b', caseSensitive: false),
      RegExp(r'\b(?:This looks like|It looks like|Appears to be|Looks like)\s+(\w+)\b', caseSensitive: false),
      RegExp(r'\b(?:Identified as|Recognized as)\s+(\w+)\b', caseSensitive: false)
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(responseText);
      if (match != null) {
        return match.group(1)!.replaceAll('.', '');
      }
    }

    return responseText.replaceAll('.', '');
  }

  void _showErrorDialog(String responseText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pokémon not found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Response from Gemini:'),
            SizedBox(height: 10),
            SelectableText(responseText, style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: responseText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Response copied to clipboard')),
              );
            },
            child: Text('Copy Response'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Pokémon',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _filterPokemons,
        )
            : Text('Pokedex'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _progress),
            SizedBox(height: 20),
            Text('Loading Pokémon... ${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      )
          : _hasError
          ? Center(child: Text('Error: $_errorMessage'))
          : GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _filteredPokemons.length,
        itemBuilder: (context, index) {
          final pokemon = _filteredPokemons[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PokemonDetailScreen(pokemonId: pokemon.id),
                ),
              );
            },
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'pokemon-${pokemon.id}',
                      child: CachedNetworkImage(
                        imageUrl: pokemon.artwork,
                        height: 100,
                        width: 100,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      pokemon.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: pokemon.types.map((type) {
                        return Container(
                          margin: EdgeInsets.only(right: 4.0),
                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type.toUpperCase(),
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}