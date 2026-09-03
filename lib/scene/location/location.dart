import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/hover_info.dart';

import '../../ui.dart';
import '../../global.dart';
import '../../data/game.dart';
import '../../logic/logic.dart';
import '../../data/common.dart';
import '../../state/states.dart';
import '../world/widgets/drop_menu.dart';
import '../cursor_state.dart';
import 'character_visit.dart';
import 'package:samsara/utils/safe_flame_image.dart';

class LocationScene extends Scene with HasCursorState {
  LocationScene({required this.location})
      : super(
          id: location['id'],
          // bgmFile: 'vietnam-bamboo-flute-143601.mp3',
          // bgmVolume: GameConfig.musicVolume,
        );
  final menuController = fluent.FlyoutController();

  late final SpriteComponent2 _backgroundComponent;

  final dynamic location;
  dynamic sect;

  late final PiledZone siteList;

  FutureOr<void> Function()? onEnterScene;

  void openResidenceList() async {
    dynamic city = location;
    if (city['category'] != 'city') {
      city = GameData.getLocation(city['atCityId']);
    }
    if (city == null) return;
    final List residingCharacterIds = city['residents'] ?? [];
    if (residingCharacterIds.isNotEmpty) {
      final List characterIds = residingCharacterIds.toList();
      bool heroResidesHere = false;
      final heroId = GameData.hero['id'];
      if (characterIds.contains(heroId)) {
        characterIds.remove(heroId);
        heroResidesHere = true;
      }
      final selectedId = await CharacterVisitDialog.show(
        context: engine.context,
        characterIds: characterIds,
        heroResidesHere: heroResidesHere,
      );
      // 这里不知为何flutter明明Pop的是Null，传过来却变成了bool，只好用类型判断是否选择了角色
      if (selectedId is String) {
        final homeSiteId = '${selectedId}_$kLocationKindHome';
        final homeSiteData = GameData.getLocation(homeSiteId);
        GameLogic.tryEnterLocation(homeSiteData);
      }
    } else {
      dialog.pushDialog(
        'hint_visitEmptyVillage',
        isHero: true,
      );
      await dialog.execute();
    }
  }

  void _onPreviewSiteCard() {
    cursorState = MouseCursorState.click;
    engine.context.read<HoverContentState>().hide();
  }

  void _onUnpreviewSiteCard() {
    cursorState = MouseCursorState.normal;
  }

  bool _isHeroHomeCity([dynamic loc]) {
    loc ??= location;
    final hero = GameData.hero;
    if (hero == null) return false;
    if (loc['id'] == hero['homeLocationId']) return true;
    if (loc['id'] == hero['homeSiteId']) return true;
    final homeLoc = GameData.getLocation(hero['homeLocationId']);
    if (homeLoc != null && homeLoc['atCityId'] == loc['id']) return true;
    final homeSite = GameData.getLocation(hero['homeSiteId']);
    if (homeSite != null && homeSite['atCityId'] == loc['id']) return true;
    return false;
  }

  bool _cityHasResidenceSite(dynamic city) {
    final siteIds = city['siteIds'];
    if (siteIds is! Iterable) return false;
    for (final siteId in siteIds) {
      final siteData = GameData.getLocation(siteId);
      if (siteData != null && siteData['kind'] == 'residence') return true;
    }
    return false;
  }

  void _addRecruitAidCard() {
    final recruitCard = GameData.createSiteCard(
      spriteId: 'location/card/residence.png',
      title: engine.locale('recruitJiejiAid'),
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    recruitCard.onTap = (button, position) async {
      await GameLogic.heroRecruitJiejiAid(location);
    };
    siteList.tryAddCard(recruitCard);
    world.add(recruitCard);
  }

  void _addPatrolJiejiCard() {
    final patrolCard = GameData.createSiteCard(
      spriteId: 'location/card/residence.png',
      title: engine.locale('patrolJiejiResidence'),
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    patrolCard.onTap = (button, position) async {
      await GameLogic.heroPatrolJiejiResidence(location);
    };
    siteList.tryAddCard(patrolCard);
    world.add(patrolCard);
  }

  void _addRestJiejiCard() {
    final restCard = GameData.createSiteCard(
      spriteId: 'location/card/bed.png',
      title: engine.locale('restJiejiSite'),
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    restCard.onTap = (button, position) async {
      await GameLogic.heroRestJiejiSite(location);
    };
    siteList.tryAddCard(restCard);
    world.add(restCard);
  }

  void _addStudyJiejiCard() {
    final studyCard = GameData.createSiteCard(
      spriteId: 'location/card/library.png',
      title: engine.locale('studyJiejiHome'),
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    studyCard.onTap = (button, position) async {
      await GameLogic.heroStudyJiejiHome(location);
    };
    siteList.tryAddCard(studyCard);
    world.add(studyCard);
  }

  void _addFeastJiejiCard() {
    final feastCard = GameData.createSiteCard(
      spriteId: 'location/card/hotel.png',
      title: engine.locale('feastJiejiHotel'),
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    feastCard.onTap = (button, position) async {
      await GameLogic.heroFeastJiejiHotel(location);
    };
    siteList.tryAddCard(feastCard);
    world.add(feastCard);
  }

  void _addVisitResidenceCard() {
    final visitCard = GameData.createSiteCard(
      spriteId: 'location/card/residence.png',
      title: engine.locale('visitResidence'),
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    visitCard.onTap = (button, position) {
      openResidenceList();
    };
    siteList.tryAddCard(visitCard);
    world.add(visitCard);
  }

  void _loadSites() {
    for (final siteCard in siteList.cards) {
      siteCard.removeFromParent();
    }
    siteList.cards.clear();

    // 一些纯功能性的场景内互动对象，不在数据中，而是硬编码
    switch (location['kind']) {
      case 'home':
        if (location['managerId'] == GameData.hero['id']) {
          final restCard = GameData.createSiteCard(
            spriteId: 'location/card/bed.png',
            title: engine.locale('rest'),
            onPreviewed: _onPreviewSiteCard,
            onUnpreviewed: _onUnpreviewSiteCard,
          );
          restCard.onTap = (button, position) {
            GameLogic.heroRest(location);
          };
          siteList.tryAddCard(restCard);

          world.add(restCard);
          final depositCard = GameData.createSiteCard(
            spriteId: 'location/card/depositBox.png',
            title: engine.locale('depositBox'),
            onPreviewed: _onPreviewSiteCard,
            onUnpreviewed: _onUnpreviewSiteCard,
          );
          depositCard.onTap = (button, position) {
            GameLogic.openDepositBox(location);
          };
          siteList.tryAddCard(depositCard);
          world.add(depositCard);
          _addRecruitAidCard();
          _addPatrolJiejiCard();
          _addRestJiejiCard();
          _addStudyJiejiCard();
        }
      case 'residence':
        _addRecruitAidCard();
        _addPatrolJiejiCard();
        _addVisitResidenceCard();
      case 'cityhall':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/bed.png',
          title: engine.locale('guestRoom'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.heroRest(location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
      case 'daostele':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/daostele.png',
          title: engine.locale('meditate'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractDaoStele(sect, location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
      case 'exparray':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/exparray.png',
          title: engine.locale('meditate'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractExpArray(sect, location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
      case 'library':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/carddesk.png',
          title: engine.locale('cardlibrary'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractCardLibraryDesk(sect: sect, location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
        final consultCard = GameData.createSiteCard(
          spriteId: 'location/card/library.png',
          title: engine.locale('consultXianming'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        consultCard.onTap = (button, position) async {
          await GameLogic.heroConsultXianming(location);
        };
        siteList.tryAddCard(consultCard);
        world.add(consultCard);
      case 'hotel':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/bed.png',
          title: engine.locale('guestRoom'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.heroRest(location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
        _addRestJiejiCard();
        _addFeastJiejiCard();
      case 'workshop':
        final workbenchCard = GameData.createSiteCard(
          spriteId: 'location/card/workshop.png',
          title: engine.locale('workbench'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        workbenchCard.onTap = (button, position) async {
          GameLogic.onInteractWorkbench(location: location);
        };
        siteList.tryAddCard(workbenchCard);
        world.add(workbenchCard);
        final craftCard = GameData.createSiteCard(
          spriteId: 'location/card/workshop.png',
          title: engine.locale('craftJiejiWeapon'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        craftCard.onTap = (button, position) async {
          await GameLogic.heroCraftJiejiWeapon(location);
        };
        siteList.tryAddCard(craftCard);
        world.add(craftCard);
      case 'alchemylab':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/alchemylab.png',
          title: engine.locale('alchemy_furnace'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) async {
          GameLogic.onInteractAlchemyFurnace(location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
        final brewCard = GameData.createSiteCard(
          spriteId: 'location/card/alchemylab.png',
          title: engine.locale('brewPotionCard'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        brewCard.onTap = (button, position) async {
          await GameLogic.heroBrewPotionCard(location);
        };
        siteList.tryAddCard(brewCard);
        world.add(brewCard);
        final tasteCard = GameData.createSiteCard(
          spriteId: 'location/card/alchemylab.png',
          title: engine.locale('tasteJiejiPotion'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        tasteCard.onTap = (button, position) async {
          await GameLogic.heroTasteJiejiPotion(location);
        };
        siteList.tryAddCard(tasteCard);
        world.add(tasteCard);
      case 'runelab':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/runelab.png',
          title: engine.locale('runelab_workbench'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) async {
          GameLogic.onInteractRunelabWorkbench(location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
        final scribeCard = GameData.createSiteCard(
          spriteId: 'location/card/runelab.png',
          title: engine.locale('scribeJiejiTalisman'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        scribeCard.onTap = (button, position) async {
          await GameLogic.heroScribeJiejiTalisman(location);
        };
        siteList.tryAddCard(scribeCard);
        world.add(scribeCard);
        final pasteCard = GameData.createSiteCard(
          spriteId: 'location/card/runelab.png',
          title: engine.locale('pasteJiejiTalisman'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        pasteCard.onTap = (button, position) async {
          await GameLogic.heroPasteJiejiTalisman(location);
        };
        siteList.tryAddCard(pasteCard);
        world.add(pasteCard);
      case 'arena':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/arena.png',
          title: engine.locale('arenaChallenge'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractArena(location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
      case 'dungeon':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/dungeon.png',
          title: engine.locale('dungeon'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractDungeonEntrance(sect: sect, location: location);
        };
        siteList.tryAddCard(siteCard);
        world.add(siteCard);
      case 'divinationaltar':
        final omenCard = GameData.createSiteCard(
          spriteId: 'location/card/divinationaltar.png',
          title: engine.locale('consultJiejiStars'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        omenCard.onTap = (button, position) async {
          await GameLogic.heroConsultJiejiStars(location);
        };
        siteList.tryAddCard(omenCard);
        world.add(omenCard);
      case 'psychictemple':
        final psychicCard = GameData.createSiteCard(
          spriteId: 'location/card/psychictemple.png',
          title: engine.locale('consultJiejiPsychic'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        psychicCard.onTap = (button, position) async {
          await GameLogic.heroConsultJiejiPsychic(location);
        };
        siteList.tryAddCard(psychicCard);
        world.add(psychicCard);
      case 'theurgytemple':
        final theurgyCard = GameData.createSiteCard(
          spriteId: 'location/card/theurgytemple.png',
          title: engine.locale('invokeJiejiTheurgy'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        theurgyCard.onTap = (button, position) async {
          await GameLogic.heroInvokeJiejiTheurgy(location);
        };
        siteList.tryAddCard(theurgyCard);
        world.add(theurgyCard);
      case 'tattooshop':
        final tattooCard = GameData.createSiteCard(
          spriteId: 'location/card/tattooshop.png',
          title: engine.locale('inkJiejiTattoo'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        tattooCard.onTap = (button, position) async {
          await GameLogic.heroInkJiejiTattoo(location);
        };
        siteList.tryAddCard(tattooCard);
        world.add(tattooCard);
      default:
        for (final siteId in location['siteIds']) {
          final siteData = GameData.getLocation(siteId);
          final siteCard = GameData.createSiteCardByData(
            siteData,
            onPreviewed: _onPreviewSiteCard,
            onUnpreviewed: _onUnpreviewSiteCard,
          );
          siteCard.onTap = (button, position) {
            if (kLocationSiteKinds.contains(siteCard.data['kind'])) {
              GameLogic.tryEnterLocation(siteCard.data);
            } else {
              engine.hetu.invoke('onWorldEvent', positionalArgs: [
                'onInteractLocationObject',
                siteCard.data,
                location,
              ]);
            }
          };
          siteList.tryAddCard(siteCard);
          world.add(siteCard);
        }
    }

    if (location['category'] == 'city' && !_cityHasResidenceSite(location)) {
      final siteCard = GameData.createSiteCard(
        spriteId: 'location/card/residence.png',
        title: engine.locale('residence'),
        onPreviewed: _onPreviewSiteCard,
        onUnpreviewed: _onUnpreviewSiteCard,
      );
      siteCard.onTap = (button, position) async {
        if (_isHeroHomeCity()) {
          dialog.pushSelection('residenceHome', [
            {
              'text': 'recruitJiejiAid',
              'description': 'hint_recruitJiejiAid_description',
            },
            {
              'text': 'patrolJiejiResidence',
              'description': 'hint_patrolJiejiResidence_description',
            },
            'visitResidence',
            'cancel',
          ]);
          await dialog.execute();
          final selected = dialog.checkSelected('residenceHome');
          if (selected == 'recruitJiejiAid') {
            await GameLogic.heroRecruitJiejiAid(location);
            return;
          }
          if (selected == 'patrolJiejiResidence') {
            await GameLogic.heroPatrolJiejiResidence(location);
            return;
          }
          if (selected != 'visitResidence') return;
        }
        openResidenceList();
      };
      siteList.tryAddCard(siteCard);
      world.add(siteCard);
    }

    siteList.sortCards(animated: false);

    // siteList.sortCards(animated: false, reversed: true);
  }

  @override
  void onLoad() async {
    super.onLoad();

    final sectId = location['sectId'];
    if (sectId != null) {
      sect = GameData.getSect(sectId);
    }

    _backgroundComponent = SpriteComponent2(
      sprite: await loadFlameSprite(location['background']),
      size: size,
    );
    _backgroundComponent.onTapDown = (button, position) {
      engine.context.read<HoverContentState>().hide();
    };
    world.add(_backgroundComponent);

    siteList = PiledZone(
      position: GameUI.siteListPosition,
      pileStyle: PileStyle.queue,
      piledCardSize: GameUI.siteCardSize,
      pileOffset: Vector2(GameUI.siteCardSize.x / 2, 0),
      spreadOnFocus: true,
      spreadMargin: GameUI.siteCardSize.x / 2,
    );
    world.add(siteList);

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    exit.onTap = (_, __) async {
      final result = await engine.hetu.invoke('onWorldEvent',
          positionalArgs: ['onBeforeExitLocation', location]);
      if (result == true) return;
      final worldId = location['worldId'];
      if (worldId != null) {
        final left = location['worldPosition']['left'];
        final top = location['worldPosition']['top'];
        assert(left != null && top != null,
            'Location ${location['id']} 缺少 worldPosition 数据');
        engine.hetu.invoke(
          'setCharacterWorldPosition',
          positionalArgs: [
            GameData.hero,
            location['worldPosition']['left'],
            location['worldPosition']['top'],
          ],
          namedArgs: {
            'worldId': location['worldId'],
          },
        );
      }
      engine.popScene(clearCache: true);
    };
    world.add(exit);

    engine.hetu.interpreter.bindExternalFunction('World::updateLocationSites',
        ({positionalArgs, namedArgs}) => _loadSites(),
        override: true);

    if (location['category'] == 'city') {
      try {
        engine.hetu.invoke('ensureHomeResidence');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeLibrary');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeDivinationAltar');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeArrayLab');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeIllusionAltar');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomePsychicTemple');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeTheurgyTemple');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeTattooShop');
      } catch (_) {}
      try {
        engine.hetu.invoke('ensureHomeWorkshop');
      } catch (_) {}
      try {
        await engine.hetu.invoke('tryJiejiCityRumor', positionalArgs: [location]);
      } catch (_) {}
    }
    _loadSites();
  }

  @override
  void onStart([dynamic arguments = const {}]) {
    super.onStart(arguments);

    engine.context.read<HoverContentState>().hide();
    engine.context.read<ViewPanelState>().clearAll();

    engine.hetu.assign('location', location);

    final onEnterSceneCallback = arguments['onEnterScene'];
    if (onEnterSceneCallback != null) {
      if (onEnterSceneCallback is FutureOr<void> Function()) {
        onEnterScene = onEnterSceneCallback;
      } else {
        engine.warning(
            'LocationScene: onEnterScene 必须是 FutureOr<void> Function(), 当前类型: ${onEnterSceneCallback.runtimeType}');
      }
    }
  }

  @override
  void onMount() async {
    super.onMount();

    await onEnterScene?.call();

    engine.info('玩家进入了 ${location['name']}');
    await GameLogic.onAfterEnterLocation(location);

    gameState.clearTerrain();
    gameState.updateDungeon();
    gameState.updateActiveJournals();
    gameState.updateDatetime();

    gameState.updateLocation(location);
    final npcs = GameData.getNpcsAtLocation(location);
    gameState.updateNpcs(npcs);
  }

  @override
  void onEnd() {
    super.onEnd();

    engine.hetu.assign('location', null);
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        GameUIOverlay(
          showNpcs: true,
          showJournal: true,
          actions: [DropMenuButton()],
        ),
      ],
    );
  }
}
