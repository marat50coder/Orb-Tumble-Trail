import 'package:flutter/foundation.dart';

import 'habit.dart';

@immutable
class HabitPreset {
  const HabitPreset({
    required this.title,
    required this.iconKey,
    required this.skin,
    required this.category,
    this.dailyTarget = 1,
    this.unit = 'time',
    this.kind = HabitKind.build,
    this.description = '',
  });

  final String title;
  final String iconKey;
  final OrbSkin skin;
  final String category;
  final int dailyTarget;
  final String unit;
  final HabitKind kind;
  final String description;
}

class HabitPresets {
  const HabitPresets._();

  static const List<String> categories = <String>[
    'Body',
    'Mind',
    'Craft',
    'Home',
    'Break',
  ];

  static const List<HabitPreset> all = <HabitPreset>[
    // Body
    HabitPreset(
      title: 'Drink water',
      iconKey: 'drop',
      skin: OrbSkin.green,
      category: 'Body',
      dailyTarget: 8,
      unit: 'glass',
      description: 'Eight glasses keeps every other orb rolling faster.',
    ),
    HabitPreset(
      title: 'Workout',
      iconKey: 'barbell',
      skin: OrbSkin.orange,
      category: 'Body',
      description: 'Move with intent for at least twenty minutes.',
    ),
    HabitPreset(
      title: 'Morning run',
      iconKey: 'personSimpleRun',
      skin: OrbSkin.green,
      category: 'Body',
    ),
    HabitPreset(
      title: '10k steps',
      iconKey: 'personSimpleWalk',
      skin: OrbSkin.green,
      category: 'Body',
    ),
    HabitPreset(
      title: 'Sleep by 23:00',
      iconKey: 'moon',
      skin: OrbSkin.red,
      category: 'Body',
      description: 'A heavy orb — slow to start, but it pushes all the others.',
    ),
    HabitPreset(
      title: 'Stretch',
      iconKey: 'yinYang',
      skin: OrbSkin.purple,
      category: 'Body',
    ),
    HabitPreset(
      title: 'Take vitamins',
      iconKey: 'pill',
      skin: OrbSkin.orange,
      category: 'Body',
    ),
    HabitPreset(
      title: 'Eat clean',
      iconKey: 'carrot',
      skin: OrbSkin.green,
      category: 'Body',
    ),
    HabitPreset(
      title: 'Cold shower',
      iconKey: 'shower',
      skin: OrbSkin.green,
      category: 'Body',
    ),

    // Mind
    HabitPreset(
      title: 'Meditate',
      iconKey: 'flower',
      skin: OrbSkin.purple,
      category: 'Mind',
      dailyTarget: 1,
      description: 'Ten quiet minutes smooths the whole trail.',
    ),
    HabitPreset(
      title: 'Read',
      iconKey: 'bookOpen',
      skin: OrbSkin.purple,
      category: 'Mind',
      dailyTarget: 20,
      unit: 'page',
    ),
    HabitPreset(
      title: 'Journal',
      iconKey: 'notePencil',
      skin: OrbSkin.purple,
      category: 'Mind',
    ),
    HabitPreset(
      title: 'Gratitude',
      iconKey: 'handHeart',
      skin: OrbSkin.red,
      category: 'Mind',
      dailyTarget: 3,
      unit: 'note',
    ),
    HabitPreset(
      title: 'Learn a language',
      iconKey: 'translate',
      skin: OrbSkin.purple,
      category: 'Mind',
    ),
    HabitPreset(
      title: 'Deep work',
      iconKey: 'brain',
      skin: OrbSkin.orange,
      category: 'Mind',
      dailyTarget: 2,
      unit: 'block',
    ),

    // Craft
    HabitPreset(
      title: 'Write code',
      iconKey: 'code',
      skin: OrbSkin.orange,
      category: 'Craft',
    ),
    HabitPreset(
      title: 'Practice music',
      iconKey: 'musicNotes',
      skin: OrbSkin.purple,
      category: 'Craft',
    ),
    HabitPreset(
      title: 'Draw',
      iconKey: 'paintBrush',
      skin: OrbSkin.red,
      category: 'Craft',
    ),
    HabitPreset(
      title: 'Study',
      iconKey: 'graduationCap',
      skin: OrbSkin.orange,
      category: 'Craft',
    ),

    // Home
    HabitPreset(
      title: 'Tidy up',
      iconKey: 'broom',
      skin: OrbSkin.green,
      category: 'Home',
    ),
    HabitPreset(
      title: 'Water the plants',
      iconKey: 'leaf',
      skin: OrbSkin.green,
      category: 'Home',
    ),
    HabitPreset(
      title: 'Track spending',
      iconKey: 'wallet',
      skin: OrbSkin.orange,
      category: 'Home',
    ),
    HabitPreset(
      title: 'Save money',
      iconKey: 'piggyBank',
      skin: OrbSkin.orange,
      category: 'Home',
    ),

    // Break (quit habits)
    HabitPreset(
      title: 'No phone in bed',
      iconKey: 'deviceMobileSlash',
      skin: OrbSkin.red,
      category: 'Break',
      kind: HabitKind.quit,
      description: 'A drag orb — it slows the ones next to it.',
    ),
    HabitPreset(
      title: 'No smoking',
      iconKey: 'cigarette',
      skin: OrbSkin.red,
      category: 'Break',
      kind: HabitKind.quit,
    ),
    HabitPreset(
      title: 'No alcohol',
      iconKey: 'wine',
      skin: OrbSkin.red,
      category: 'Break',
      kind: HabitKind.quit,
    ),
    HabitPreset(
      title: 'No late coffee',
      iconKey: 'coffee',
      skin: OrbSkin.orange,
      category: 'Break',
      kind: HabitKind.quit,
    ),
  ];

  static List<HabitPreset> byCategory(String category) =>
      all.where((HabitPreset p) => p.category == category).toList();
}
