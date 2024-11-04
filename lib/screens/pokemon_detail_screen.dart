import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../models/evolution_chain.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class PokemonDetailScreen extends StatefulWidget {
  final int pokemonId;

  PokemonDetailScreen({required this.pokemonId});

  @override
  _PokemonDetailScreenState createState() => _PokemonDetailScreenState();
}
class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  late Future<Pokemon> _pokemonDetails;
  late Future<EvolutionChain> _evolutionChain;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _pokemonDetails = _fetchDetails();
  }

  Future<Pokemon> _fetchDetails() async {
    final pokemon = await _apiService.fetchPokemonDetails(widget.pokemonId);
    final encounterLocations = await _apiService.fetchEncounterLocations(widget.pokemonId);
    pokemon.encounterLocations = encounterLocations;
    _evolutionChain = _apiService.fetchEvolutionChain(pokemon.id);
    return pokemon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pokédex',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<Pokemon>(
        future: _pokemonDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final pokemon = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: pokemon.artwork,
                        height: 200,
                        width: 200,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        pokemon.name.toUpperCase(),
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSectionHeader('Height'),
                    _buildInfoText('${pokemon.height / 10} m'),
                    _buildSectionHeader('Weight'),
                    _buildInfoText('${pokemon.weight / 10} kg'),
                    _buildSectionHeader('Base Experience'),
                    _buildInfoText('${pokemon.baseExperience}'),
                    _buildSectionHeader('Abilities'),
                    _buildInfoText(pokemon.abilities.join(', ')),
                    _buildSectionHeader('Types'),
                    _buildInfoText(pokemon.types.join(', ')),
                    _buildSectionHeader('Encounter Locations'),
                    _buildInfoText(pokemon.encounterLocations.join(', ')),
                    SizedBox(height: 16),
                    _buildSectionHeader('Sprites'),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSpriteImage(pokemon.sprites['front_default']),
                        _buildSpriteImage(pokemon.sprites['back_default']),
                        _buildSpriteImage(pokemon.sprites['front_shiny']),
                        _buildSpriteImage(pokemon.sprites['back_shiny']),
                      ],
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final player = AudioPlayer();
                          player.play(UrlSource(pokemon.cryUrl));
                        },
                        child: Text(
                          'Play Cry',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSectionHeader('Evolution Chain'),
                    FutureBuilder<EvolutionChain>(
                      future: _evolutionChain,
                      builder: (context, evolutionSnapshot) {
                        if (evolutionSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (evolutionSnapshot.hasError) {
                          return Center(child: Text('Error: ${evolutionSnapshot.error}'));
                        } else if (evolutionSnapshot.hasData) {
                          final evolutionChain = evolutionSnapshot.data!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: evolutionChain.chain.map((stage) {
                              bool isCurrent = stage.speciesName == pokemon.name;
                              return _buildEvolutionStage(stage, isCurrent);
                            }).toList(),
                          );
                        } else {
                          return Center(child: Text('No evolution data available'));
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoText(String info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        info,
        style: GoogleFonts.poppins(
          textStyle: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildSpriteImage(String? url) {
    return Expanded(
      child: CachedNetworkImage(
        imageUrl: url ?? '',
        height: 100,
        width: 100,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    );
  }

  Widget _buildEvolutionStage(EvolutionStage stage, bool isCurrent) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? Colors.blue : Colors.transparent,
              width: 3.0,
            ),
          ),
          child: FutureBuilder<String>(
            future: _apiService.fetchPokemonSprite(stage.speciesName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Icon(Icons.error);
              } else if (snapshot.hasData) {
                return CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  height: 100,
                  width: 100,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                );
              } else {
                return Icon(Icons.error);
              }
            },
          ),
        ),
        SizedBox(height: 8),
        Text(
          stage.speciesName,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}