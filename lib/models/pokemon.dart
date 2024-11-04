class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final int baseExperience;
  final List<String> abilities;
  final List<String> types;
  final Map<String, String> sprites;
  final String cryUrl;
  List<String> encounterLocations;
  String artwork; // Added field for official artwork

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.baseExperience,
    required this.abilities,
    required this.types,
    required this.sprites,
    required this.cryUrl,
    required this.encounterLocations,
    required this.artwork,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    List<String> abilities = [];
    for (var ability in json['abilities']) {
      abilities.add(ability['ability']['name']);
    }

    List<String> types = [];
    for (var type in json['types']) {
      types.add(type['type']['name']);
    }

    Map<String, String> sprites = {};
    sprites['front_default'] = json['sprites']['front_default'];
    sprites['back_default'] = json['sprites']['back_default'];
    sprites['front_shiny'] = json['sprites']['front_shiny'];
    sprites['back_shiny'] = json['sprites']['back_shiny'];

    return Pokemon(
      id: json['id'],
      name: json['name'],
      height: json['height'],
      weight: json['weight'],
      baseExperience: json['base_experience'],
      abilities: abilities,
      types: types,
      sprites: sprites,
      cryUrl: 'https://pokemoncries.com/cries/${json['id']}.mp3',
      encounterLocations: [],
      artwork: json['sprites']['other']['official-artwork']['front_default'] ?? '', // Initialize with official artwork
    );
  }
}
