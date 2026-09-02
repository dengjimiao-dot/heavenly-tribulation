import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import '../common.dart';
import 'mainmenu_widgets.dart';
import '../../widgets/ui_overlay.dart';
import '../../data/game.dart';
import '../../global.dart';

class MainMenuScene extends Scene {
  static const _menuBgmFile = 'chinese-oriental-tune-06-12062.mp3';

  MainMenuScene()
      : super(
          id: Scenes.mainmenu,
          bgm: engine.bgm,
          bgmFile: _menuBgmFile,
          bgmVolume: engine.config.musicVolume,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  void onStart([dynamic arguments = const {}]) async {
    // Scene plays BGM in onStart (before onLoad). Skip if the mp3 is gone
    // so a slim/no-audio pack does not throw.
    if (bgmFile != null) {
      final ok = await GameData.tryLoadAsset('assets/audio/music/$bgmFile');
      if (!ok) {
        bgmFile = null;
      }
    }
    try {
      await super.onStart(arguments);
    } catch (e) {
      engine.warning('menu bgm skipped: $e');
      bgmFile = null;
    }

    if (arguments['reset'] == true || GameData.game['saveName'] != 'debug') {
      // 创建一个空游戏存档并初始化一些数据，这主要是为了在主菜单快速测试和debug相关功能，并不会保存
      // 真正开始游戏后还会再执行一遍，
      await GameData.createGame(
        'debug',
        seed: DateTime.now().millisecondsSinceEpoch,
      );
      // GameData.isGameCreated = false;
      await engine.hetu.invoke(
        'generateHero',
        namespace: 'debug',
        namedArgs: {
          'level': 10,
          'rank': 0,
        },
      );
      arguments['reset'] = false;
      engine.setSceneArguments(id, arguments);
    } else {
      engine.hetu.invoke('rejuvenate', namespace: 'Player');
    }
    gameState.reset();
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
        MainMenuWidgets(),
        GameUIOverlay(
          showJournal: false,
          actions: [
            DebugButton(),
          ],
        ),
      ],
    );
  }
}
