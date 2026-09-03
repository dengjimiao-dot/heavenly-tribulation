import '../data/game.dart';
import 'logic.dart';

/// 劫季门派：按游戏内月份解析当前天象，并提供战斗/掉落修正。
final class SeasonLogic {
  static String currentId = 'thunder';
  static String currentName = '雷月';
  static String currentDescription = '';
  static Map<String, dynamic> currentMods = const {};

  /// 季末结算待弹出（劫季刚切换，尚未走完 trySettleJieji）。
  static bool pendingSettlement = false;

  /// 刚结束的劫季 id（thunder/mist/blood），写入存档 flags 的同时留一份静态备份。
  static String? pendingEndedSeasonId;

  /// 时间流逝对话框正在推进，避免中途弹结算。
  static bool timeflowActive = false;

  /// trySettleJieji 正在执行，防止重入。
  static bool settlementInFlight = false;

  /// 血酒：本场英雄造成伤害 +0.06。开战时从 flags.jieji.restBloodFury 锁入，打完清掉。
  static bool restBloodFuryThisFight = false;

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

  static dynamic _jiejiFlags() {
    try {
      final flags = GameData.flags ?? GameData.game?['flags'];
      if (flags == null) return null;
      var jieji = flags['jieji'];
      if (jieji == null) {
        jieji = <String, dynamic>{
          'curseSlots': <dynamic>[],
          'shards': <dynamic>[],
          'gongfa': <dynamic>[],
        };
        flags['jieji'] = jieji;
      }
      return jieji;
    } catch (_) {
      return null;
    }
  }

  static int get curseCount {
    try {
      final jieji = _jiejiFlags();
      if (jieji == null) return 0;
      final slots = jieji['curseSlots'];
      if (slots == null) return 0;
      final n = slots.length as int;
      if (n < 0) return 0;
      if (n > 3) return 3;
      return n;
    } catch (_) {
      return 0;
    }
  }

  static List<String> _listStringIds(dynamic raw) {
    final ids = <String>[];
    if (raw == null) return ids;
    try {
      if (raw is Iterable) {
        for (final e in raw) {
          final s = e?.toString();
          if (s != null && s.isNotEmpty && s != 'null') ids.add(s);
        }
        return ids;
      }
      final n = raw.length as int;
      for (var i = 0; i < n; i++) {
        final s = raw[i]?.toString();
        if (s != null && s.isNotEmpty && s != 'null') ids.add(s);
      }
    } catch (_) {}
    return ids;
  }

  static List<String> _seasonalShardIds() {
    final ids = <String>[];
    try {
      final jieji = _jiejiFlags();
      if (jieji == null) return ids;
      final raw = jieji['shards'];
      if (raw == null) return ids;
      void take(dynamic e) {
        if (e == null) return;
        String? id;
        try {
          if (e is Map) {
            id = e['id']?.toString();
          } else {
            id = e['id']?.toString();
          }
        } catch (_) {
          id = e.toString();
        }
        if (id != null && id.isNotEmpty && id != 'null') ids.add(id);
      }

      if (raw is Iterable) {
        for (final e in raw) {
          take(e);
        }
        return ids;
      }
      final n = raw.length as int;
      for (var i = 0; i < n; i++) {
        take(raw[i]);
      }
    } catch (_) {}
    return ids;
  }

  static List<String> _permanentGongfaIds() {
    try {
      return _listStringIds(_jiejiFlags()?['gongfa']);
    } catch (_) {
      return const [];
    }
  }

  /// 当季残页 + 永久功法，同一 id 只算一次。
  static Set<String> heldGongfaIds() {
    return {..._permanentGongfaIds(), ..._seasonalShardIds()};
  }

  static bool holdsGongfa(String id) => heldGongfaIds().contains(id);

  /// HUD「功N」：当季残页数 + 永久功法数。
  static int get gongfaHeldCount {
    try {
      return _permanentGongfaIds().length + _seasonalShardIds().length;
    } catch (_) {
      return 0;
    }
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
      restorePendingFromFlags();
      // 同步到存档对象，供 Hetu 脚本读取（隐藏任务刷新权重等）
      try {
        final g = GameData.game;
        if (g != null) {
          g['jieji'] = {
            'seasonId': currentId,
            'seasonName': currentName,
            'daysRemaining': daysRemainingInSeason,
            'mods': currentMods,
            'hiddenQuestMul': _mod('hiddenQuestMul',
                _mod('stealthEventMul', _mod('wildEncounterMul', 1.0))),
            'lootMul': lootMul,
            'wildEncounterMul': wildEncounterMul,
            'cardCostJitter': cardCostJitter,
            'lifeStealBonus': lifeStealBonus,
            'tribulationStrictness': tribulationStrictness,
            'curseCount': curseCount,
            'gongfaCount': gongfaHeldCount,
            'pendingSettle': pendingSettlement,
            'xianming': xianming,
            'xianmingSeason': _jiejiFlags()?['xianmingSeason'],
          };
        }
      } catch (_) {}
      return;
    }
  }

  /// 从存档 flags 恢复季末待结算。pending 与 lastSettled 不一致才排队。
  static void restorePendingFromFlags() {
    try {
      final jieji = _jiejiFlags();
      if (jieji == null) return;
      final pending = jieji['pendingEndedSeasonId']?.toString();
      final settled = jieji['lastSettledSeasonId']?.toString();
      if (pending != null && pending.isNotEmpty && pending != settled) {
        pendingEndedSeasonId = pending;
        pendingSettlement = true;
      } else {
        pendingSettlement = false;
      }
    } catch (_) {}
  }

  /// 在 refreshFromCalendar 之后调用。previousSeasonId 为刷新前的 currentId。
  static void queueSettlementIfEnded(String previousSeasonId) {
    if (GameData.hero == null) return;
    final jieji = _jiejiFlags();
    if (jieji == null) return;

    final newId = currentId;
    if (previousSeasonId != newId) {
      final settled = jieji['lastSettledSeasonId']?.toString();
      if (settled != previousSeasonId) {
        pendingEndedSeasonId = previousSeasonId;
        jieji['pendingEndedSeasonId'] = previousSeasonId;
        jieji['endedTribulationStrictness'] =
            _strictnessForSeason(previousSeasonId);
        pendingSettlement = true;
      }
      // 新季入季天象征兆：在旧季结算排队之后标记，不替代 trySettleJieji。
      queueSeasonStartOmen(newId);
      return;
    }

    // 季末最后一天余日为 0 时也结算一次（当前公式末日通常仍为 1）。
    if (daysRemainingInSeason == 0) {
      final settled = jieji['lastSettledSeasonId']?.toString();
      if (settled == newId) return;
      pendingEndedSeasonId = newId;
      jieji['pendingEndedSeasonId'] = newId;
      jieji['endedTribulationStrictness'] = _strictnessForSeason(newId);
      pendingSettlement = true;
    }
  }

  /// 入季天象征兆：每个 seasonId 只弹一次。
  static void queueSeasonStartOmen(String seasonId) {
    if (GameData.hero == null) return;
    final jieji = _jiejiFlags();
    if (jieji == null) return;
    if (seasonId.isEmpty) return;
    final last = jieji['lastOmenSeasonId']?.toString();
    if (last == seasonId) return;
    jieji['pendingOmenSeasonId'] = seasonId;
  }

  static double _mod(String key, [double fallback = 1.0]) {
    final v = currentMods[key];
    if (v is num) return v.toDouble();
    return fallback;
  }

  static double _strictnessForSeason(String seasonId) {
    for (final raw in GameData.seasons) {
      if (raw is! Map) continue;
      if (raw['id']?.toString() != seasonId) continue;
      final mods = raw['mods'];
      if (mods is Map && mods['tribulationStrictness'] is num) {
        return (mods['tribulationStrictness'] as num).toDouble();
      }
    }
    return 1.0;
  }

  static double get damageDealtMul => _mod('damageDealtMul');
  static double get damageTakenMul => _mod('damageTakenMul');
  static double get wildEncounterMul {
    var m = _mod('wildEncounterMul');
    if (holdsGongfa('gongfa_mist')) {
      m -= 0.15;
      if (m < 0.3) m = 0.3;
    }
    if (m < 0) return 0.0;
    return m;
  }

  static double get lifeStealBonus {
    var v = _mod('lifeStealBonus', 0.0);
    if (holdsGongfa('gongfa_blood')) {
      v += 0.05;
    }
    return v;
  }
  static double get tribulationStrictness => _mod('tribulationStrictness');

  static int get cardCostJitter {
    final v = currentMods['cardCostJitter'];
    if (v is num) return v.round();
    return 0;
  }

  static String? get xianming {
    try {
      return _jiejiFlags()?['xianming']?.toString();
    } catch (_) {
      return null;
    }
  }

  static bool get xianmingActiveThisSeason {
    try {
      final jieji = _jiejiFlags();
      if (jieji == null) return false;
      final season = jieji['xianmingSeason']?.toString();
      return season != null && season.isNotEmpty && season == currentId;
    } catch (_) {
      return false;
    }
  }

  static double get lootMul {
    var m = _mod('lootMul');
    if (xianmingActiveThisSeason && xianming == 'xianming_nurture') {
      m += 0.15;
    }
    if (holdsGongfa('gongfa_harvest')) {
      m += 0.12;
    }
    return m < 0 ? 0.0 : m;
  }

  /// 农田/产地作物（药材、粮食）吃劫季掉落乘区；雷月额外更肥。
  static const cropMaterialIds = {'herb', 'grain'};
  static const thunderCropProduceBonus = 0.35;

  static int scaleProduceAmount(int amount, String materialId) {
    if (amount <= 0) return 0;
    if (!cropMaterialIds.contains(materialId)) return amount;
    var mul = lootMul;
    if (currentId == 'thunder') {
      mul += thunderCropProduceBonus;
    }
    final n = (amount * mul).round();
    return n < 0 ? 0 : n;
  }

  /// 对伤害详情写入乘区3（正气/戾气旁路的额外乘区），保持与原公式兼容。
  /// 诅咒槽额外提高英雄承伤：每层 +0.05。
  static void applyBattleDamageMods(dynamic damageDetails,
      {required bool selfIsHero}) {
    damageDetails['percentageChange3'] ??= 0.0;
    if (currentMods.isNotEmpty) {
      // 英雄造成伤害用 dealt；英雄受伤用 taken（selfIsHero 表示受伤方是英雄）
      final mul = selfIsHero ? damageTakenMul : damageDealtMul;
      // mul 1.15 => +0.15 on percentageChange3
      damageDetails['percentageChange3'] += (mul - 1.0);
    }
    if (selfIsHero && curseCount > 0) {
      damageDetails['percentageChange3'] += curseCount * 0.05;
    }
    if (xianmingActiveThisSeason) {
      if (selfIsHero && xianming == 'xianming_guard') {
        damageDetails['percentageChange3'] -= 0.08;
      }
      if (!selfIsHero && xianming == 'xianming_break') {
        damageDetails['percentageChange3'] += 0.10;
      }
    }
    if (!selfIsHero && holdsGongfa('gongfa_thunder')) {
      damageDetails['percentageChange3'] += 0.08;
    }
    if (selfIsHero && holdsGongfa('gongfa_guard')) {
      damageDetails['percentageChange3'] -= 0.06;
    }
    if (!selfIsHero) {
      if (!restBloodFuryThisFight) {
        try {
          final jieji = _jiejiFlags();
          if (jieji != null && jieji['restBloodFury'] == true) {
            restBloodFuryThisFight = true;
            jieji['restBloodFury'] = false;
          }
        } catch (_) {}
      }
      if (restBloodFuryThisFight) {
        damageDetails['percentageChange3'] += 0.06;
      }
    }
  }

  static void beginRestBloodFuryFight() {
    restBloodFuryThisFight = false;
    try {
      final jieji = _jiejiFlags();
      if (jieji == null) return;
      if (jieji['restBloodFury'] == true) {
        restBloodFuryThisFight = true;
        jieji['restBloodFury'] = false;
      }
    } catch (_) {}
  }

  static void endRestBloodFuryFight() {
    restBloodFuryThisFight = false;
  }

  static String hudLine() {
    if (GameData.seasons.isEmpty) return '';
    var line = '$currentName · 余$daysRemainingInSeason日';
    if (pendingSettlement || daysRemainingInSeason <= 3) {
      line += ' · 劫季到期';
    }
    if (curseCount > 0) {
      line += ' · 咒$curseCount';
    }
    if (gongfaHeldCount > 0) {
      line += ' · 功$gongfaHeldCount';
    }
    if (xianmingActiveThisSeason) {
      final xm = xianming;
      if (xm == 'xianming_guard') {
        line += ' · 守故城';
      } else if (xm == 'xianming_break') {
        line += ' · 破天劫';
      } else if (xm == 'xianming_nurture') {
        line += ' · 养门徒';
      }
    }
    return line;
  }
}
