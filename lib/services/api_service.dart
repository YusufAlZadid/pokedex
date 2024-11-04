import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';
import '../models/evolution_chain.dart';

class ApiService {
  final String baseUrl = "https://pokeapi.co/api/v2";

  Future<List<Pokemon>> fetchPokemons({Function(double)? onProgress}) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon?limit=200'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['results'];
      List<Pokemon> pokemons = [];
      for (int i = 0; i < data.length; i++) {
        var item = data[i];
        final pokeDetails = await http.get(Uri.parse(item['url']));
        if (pokeDetails.statusCode == 200) {
          final pokemon = Pokemon.fromJson(json.decode(pokeDetails.body));
          final encounterLocations = await fetchEncounterLocations(pokemon.id);
          pokemon.encounterLocations = encounterLocations;
          pokemons.add(pokemon);
        }
        if (onProgress != null) {
          onProgress((i + 1) / data.length);
        }
      }
      return pokemons;
    } else {
      throw Exception('Failed to load Pokémon');
    }
  }

  Future<Pokemon> fetchPokemonDetails(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon/$id'));
    if (response.statusCode == 200) {
      return Pokemon.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load Pokémon details');
    }
  }

  Future<List<String>> fetchEncounterLocations(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon/$id/encounters'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<String> locations = [];
      for (var location in data) {
        locations.add(location['location_area']['name']);
      }
      return locations;
    } else {
      throw Exception('Failed to load encounter locations');
    }
  }

  Future<EvolutionChain> fetchEvolutionChain(int speciesId) async {
    final speciesResponse = await http.get(Uri.parse('$baseUrl/pokemon-species/$speciesId'));
    if (speciesResponse.statusCode == 200) {
      final speciesData = json.decode(speciesResponse.body);
      final evolutionUrl = speciesData['evolution_chain']['url'];
      final evolutionResponse = await http.get(Uri.parse(evolutionUrl));
      if (evolutionResponse.statusCode == 200) {
        return EvolutionChain.fromJson(json.decode(evolutionResponse.body));
      } else {
        throw Exception('Failed to load evolution chain');
      }
    } else {
      throw Exception('Failed to load species data');
    }
  }

  Future<String> fetchPokemonSprite(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/pokemon/$name'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['sprites']['front_default'];
    } else {
      throw Exception('Failed to load Pokémon sprite');
    }
  }
}
