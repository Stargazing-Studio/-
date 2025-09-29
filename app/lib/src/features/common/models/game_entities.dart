import 'package:collection/collection.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.realm,
    required this.guild,
    required this.factionReputation,
    required this.attributes,
    required this.techniques,
    required this.achievements,
    required this.ascensionProgress,
  });

  final String id;
  final String name;
  final String realm;
  final String guild;
  final Map<String, int> factionReputation;
  final Map<String, num> attributes;
  final List<TechniqueSummary> techniques;
  final List<String> achievements;
  final AscensionProgress ascensionProgress;

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      realm: json['realm'] as String,
      guild: json['guild'] as String,
      factionReputation: Map<String, int>.from(
        (json['faction_reputation'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toInt()),
        ),
      ),
      attributes: (json['attributes'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as num)),
      techniques: (json['techniques'] as List<dynamic>)
          .map((item) =>
              TechniqueSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      achievements:
          List<String>.from(json['achievements'] as List<dynamic>),
      ascensionProgress: AscensionProgress.fromJson(
        json['ascension_progress'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'realm': realm,
      'guild': guild,
      'faction_reputation': factionReputation,
      'attributes': attributes,
      'techniques': techniques.map((technique) => technique.toJson()).toList(),
      'achievements': achievements,
      'ascension_progress': ascensionProgress.toJson(),
    };
  }
}

class TechniqueSummary {
  const TechniqueSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.mastery,
    required this.synergies,
  });

  final String id;
  final String name;
  final TechniqueType type;
  final int mastery;
  final List<String> synergies;

  factory TechniqueSummary.fromJson(Map<String, dynamic> json) {
    return TechniqueSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      type: techniqueTypeFromJson(json['type'] as String),
      mastery: (json['mastery'] as num).toInt(),
      synergies: List<String>.from(json['synergies'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': techniqueTypeToJson(type),
      'mastery': mastery,
      'synergies': synergies,
    };
  }
}

enum TechniqueType { core, combat, support, movement }

TechniqueType techniqueTypeFromJson(String value) {
  switch (value) {
    case 'core':
      return TechniqueType.core;
    case 'combat':
      return TechniqueType.combat;
    case 'support':
      return TechniqueType.support;
    case 'movement':
      return TechniqueType.movement;
    default:
      return TechniqueType.core;
  }
}

String techniqueTypeToJson(TechniqueType value) {
  switch (value) {
    case TechniqueType.core:
      return 'core';
    case TechniqueType.combat:
      return 'combat';
    case TechniqueType.support:
      return 'support';
    case TechniqueType.movement:
      return 'movement';
  }
}

class AscensionProgress {
  const AscensionProgress({
    required this.stage,
    required this.score,
    required this.nextMilestone,
  });

  final String stage;
  final int score;
  final String nextMilestone;

  factory AscensionProgress.fromJson(Map<String, dynamic> json) {
    return AscensionProgress(
      stage: json['stage'] as String,
      score: (json['score'] as num).toInt(),
      nextMilestone: json['next_milestone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'score': score,
      'next_milestone': nextMilestone,
    };
  }
}

class Companion {
  const Companion({
    required this.id,
    required this.name,
    required this.role,
    required this.personality,
    required this.bondLevel,
    required this.skills,
    required this.mood,
    required this.fatigue,
    required this.traits,
  });

  final String id;
  final String name;
  final CompanionRole role;
  final String personality;
  final int bondLevel;
  final List<String> skills;
  final String mood;
  final int fatigue;
  final List<String> traits;

  factory Companion.fromJson(Map<String, dynamic> json) {
    return Companion(
      id: json['id'] as String,
      name: json['name'] as String,
      role: companionRoleFromJson(json['role'] as String),
      personality: json['personality'] as String,
      bondLevel: (json['bond_level'] as num).toInt(),
      skills: List<String>.from(json['skills'] as List<dynamic>),
      mood: json['mood'] as String,
      fatigue: (json['fatigue'] as num).toInt(),
      traits: List<String>.from(json['traits'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': companionRoleToJson(role),
      'personality': personality,
      'bond_level': bondLevel,
      'skills': skills,
      'mood': mood,
      'fatigue': fatigue,
      'traits': traits,
    };
  }
}

enum CompanionRole { attendant, guardian, scout, alchemist }

CompanionRole companionRoleFromJson(String value) {
  switch (value) {
    case 'attendant':
      return CompanionRole.attendant;
    case 'guardian':
      return CompanionRole.guardian;
    case 'scout':
      return CompanionRole.scout;
    case 'alchemist':
      return CompanionRole.alchemist;
    default:
      return CompanionRole.guardian;
  }
}

String companionRoleToJson(CompanionRole value) {
  switch (value) {
    case CompanionRole.attendant:
      return 'attendant';
    case CompanionRole.guardian:
      return 'guardian';
    case CompanionRole.scout:
      return 'scout';
    case CompanionRole.alchemist:
      return 'alchemist';
  }
}

class SecretRealm {
  const SecretRealm({
    required this.id,
    required this.name,
    required this.tier,
    required this.schedule,
    required this.environment,
    required this.recommendedPower,
    required this.dynamicEvents,
  });

  final String id;
  final String name;
  final int tier;
  final String schedule;
  final Map<String, num> environment;
  final int recommendedPower;
  final List<String> dynamicEvents;

  factory SecretRealm.fromJson(Map<String, dynamic> json) {
    return SecretRealm(
      id: json['id'] as String,
      name: json['name'] as String,
      tier: (json['tier'] as num).toInt(),
      schedule: json['schedule'] as String,
      environment: (json['environment'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as num)),
      recommendedPower: (json['recommended_power'] as num).toInt(),
      dynamicEvents:
          List<String>.from(json['dynamic_events'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tier': tier,
      'schedule': schedule,
      'environment': environment,
      'recommended_power': recommendedPower,
      'dynamic_events': dynamicEvents,
    };
  }
}

class AscensionChallenge {
  const AscensionChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.requirements,
    required this.rewards,
  });

  final String id;
  final String title;
  final String difficulty;
  final List<String> requirements;
  final List<String> rewards;

  factory AscensionChallenge.fromJson(Map<String, dynamic> json) {
    return AscensionChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      requirements:
          List<String>.from(json['requirements'] as List<dynamic>),
      rewards: List<String>.from(json['rewards'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'difficulty': difficulty,
      'requirements': requirements,
      'rewards': rewards,
    };
  }
}

class PillRecipe {
  const PillRecipe({
    required this.id,
    required this.name,
    required this.grade,
    required this.baseEffects,
    required this.materials,
    required this.difficulty,
  });

  final String id;
  final String name;
  final String grade;
  final List<String> baseEffects;
  final List<RecipeMaterial> materials;
  final int difficulty;

  factory PillRecipe.fromJson(Map<String, dynamic> json) {
    return PillRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      grade: json['grade'] as String,
      baseEffects:
          List<String>.from(json['base_effects'] as List<dynamic>),
      materials: (json['materials'] as List<dynamic>)
          .map((item) => RecipeMaterial.fromJson(item as Map<String, dynamic>))
          .toList(),
      difficulty: (json['difficulty'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'base_effects': baseEffects,
      'materials': materials.map((item) => item.toJson()).toList(),
      'difficulty': difficulty,
    };
  }
}

class RecipeMaterial {
  const RecipeMaterial({
    required this.name,
    required this.quantity,
    required this.origin,
  });

  final String name;
  final int quantity;
  final String origin;

  factory RecipeMaterial.fromJson(Map<String, dynamic> json) {
    return RecipeMaterial(
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      origin: json['origin'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'origin': origin,
    };
  }
}

class ChronicleLog {
  const ChronicleLog({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.summary,
    required this.tags,
  });

  final String id;
  final String title;
  final DateTime timestamp;
  final String summary;
  final List<String> tags;

  factory ChronicleLog.fromJson(Map<String, dynamic> json) {
    return ChronicleLog(
      id: json['id'] as String,
      title: json['title'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      summary: json['summary'] as String,
      tags: List<String>.from(json['tags'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'summary': summary,
      'tags': tags,
    };
  }
}

extension IterableAverage on Iterable<num> {
  double get average => isEmpty ? 0 : sum / length;
}
