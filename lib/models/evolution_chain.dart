class EvolutionChain {
  final List<EvolutionStage> chain;

  EvolutionChain({required this.chain});

  factory EvolutionChain.fromJson(Map<String, dynamic> json) {
    List<EvolutionStage> chain = [];
    var current = json['chain'];
    do {
      List<String> evolvesTo = [];
      for (var evolution in current['evolves_to']) {
        evolvesTo.add(evolution['species']['name']);
      }
      chain.add(EvolutionStage(
          speciesName: current['species']['name'],
          evolvesTo: evolvesTo,
          spriteUrl: '' // We'll fetch this later
      ));
      current = current['evolves_to'].isNotEmpty ? current['evolves_to'][0] : null;
    } while (current != null);
    return EvolutionChain(chain: chain);
  }
}

class EvolutionStage {
  final String speciesName;
  final List<String> evolvesTo;
  String spriteUrl; // Added spriteUrl field

  EvolutionStage({required this.speciesName, required this.evolvesTo, required this.spriteUrl});
}
