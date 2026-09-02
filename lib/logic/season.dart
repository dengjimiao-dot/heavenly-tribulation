import '../data/game.dart';
import 'logic.dart';

/// 劫季门派：按游戏内月份解析当前天象，并提供战斗/掉落修正。
final class SeasonLogic {
  static String currentId = 'thunder';
  static String currentName = '雷月';
  static String currentDescription = '';
  static Map<String, dynamic> currentMods = const {};

  static int get dayIndexInYear {
    // month/day are 1-based after calculateTimestamp
    return (GameLogic.month - 1) * 30 + GameLogic.day;
  }

  static int get daysRemainingInSeason {
    final seasons = GameData.seasons;
    if (seasons.isEmpty) return 0;
    final months = (currentSeasonEntry?['months'] as List?)?.cast<num>() ?? [];
    if (months.isEmpty) return 0;
    final lastMonth = months.last.toInt();
    final endDay = lastMonth * 30;
    final remain = endDay - dayIndexInYear + 1;
    return remain < 0 ? 0 : remain;
  }

  static Map<String, dynamic>? get currentSeasonEntry {
    for (final s in GameData.seasons) {
      if (s is Map && s['id'] == currentId) {
        return Map<String, dynamic>.from(s);
      }
    }
    return null;
  }

  /// 根据 GameLogic.month 刷新当前劫季。应在 calculateTimestamp 之后调用。
  static void refreshFromCalendar() {
    final list = GameData.seasons;
    if (list.isEmpty) return;
    final m = GameLogic.month;
    for (final raw in list) {
      if (raw is! Map) continue;
      final months = (raw['months'] as List?) ?? const [];
      final hit = months.any((e) => (e as num).toInt() == m);
      if (!hit) continue;
      currentId = raw['id']?.toString() ?? currentId;
      currentName = raw['name']?.toString() ?? currentName;
      currentDescription = raw['description']?.toString() ?? '';
      final mods = raw['mods'];
      currentMods = mods is Map
          ? Map<String, dynamic>.from(mods)
          : <String, dynamic>{};
      // 同步到存档对象，供 Hetu 脚本读取（隐藏任务刷新权重等）
      try {
        final g = GameData.game;
        if (g != null) {
          g['jieji'] = {
            'seasonId': currentId,
            'seasonName': currentName,
            'daysRemaining': daysRemainingInSeason,
            'mods': currentMods,
            'hiddenQuestMul': _mod('hiddenQuestMul', _mod('stealthEventMul', _mod('wildEncounterMul', 1.0))),
          };
        }
      } catch (_) {}
      return;
    }
  }

  static double _mod(String key, [double fallback = 1.0]) {
    final v = currentMods[key];
    if (v is num) return v.toDouble();
    return fallback;
  }

  static double get damageDealtMul => _mod('damageDealtMul');
  static double get damageTakenMul => _mod('damageTakenMul');
  static double get lootMul => _mod('lootMul');

  /// 对伤害详情写入乘区3（正气/戾气旁路的额外乘区），保持与原公式兼容。
  static void applyBattleDamageMods(dynamic damageDetails, {required bool selfIsHero}) {
    if (currentMods.isEmpty) return;
    damageDetails['percentageChange3'] ??= 0.0;
    // 英雄造成伤害用 dealt；英雄受伤用 taken（selfIsHero 表示受伤方是英雄）
    final mul = selfIsHero ? damageTakenMul : damageDealtMul;
    // mul 1.15 => +0.15 on percentageChange3
    damageDetails['percentageChange3'] += (mul - 1.0);
  }

  static String hudLine() {
    if (GameData.seasons.isEmpty) return '';
    return '$currentName · 余$daysRemainingInSeason日';
  }
}
