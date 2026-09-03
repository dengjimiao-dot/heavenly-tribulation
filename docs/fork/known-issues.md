# 已知问题（劫季门派 Demo）

这是竖切 Demo，不是可对外发行的完整版本。主菜单「已知问题」按钮列出同一份说明。反馈请开 GitHub Issues：

https://github.com/dengjimiao-dot/heavenly-tribulation/issues

## 美术与音频仍是上游资源

代码是 MIT，美术、音频、字体等非代码资产不在 MIT 范围内。当前构建仍使用上游素材，**对外分发前必须替换**。版权约束见 [FORK.md](../../FORK.md)，竖切最低替换清单见 [replace-assets.md](replace-assets.md) 与 [assets/REPLACE_ASSETS.txt](../../assets/REPLACE_ASSETS.txt)。

## 仙命已有当季效果，仍不是完整构筑轴

季末三选一（守故城 / 破天劫 / 养门徒）会写入 `game.flags.jieji.xianming` 与 `xianmingSeason`，效力只在接下来这一季，下次选择会覆盖。

- 守故城：下一次迁徙跳过城市规模 -2，并多留一处据点；当季英雄受伤约减 8%。
- 破天劫：当季造成伤害约加 10%；下一次渡劫 Boss 不再额外加 10 级。
- 养门徒：立刻给劳工、铜钱和一枚牌胚；当季掉落倍率再加 15%。

功法碎片（当季残页）可从赶路硬选择和黑市匣掉落，季末可铭刻 1 枚入 `gongfa`（最多 3）。弟子羁绊仍未做。仙命也还不是「三选一卡组轴」。

## 渡劫中途存档会继续收尾

渡劫 Boss 开战仍会把 `jieji.fighting` 设为 true。`trySettleJieji` 见到这个标记会返回 `deferred`，Dart 侧不再因此清掉 `pendingSettlement`。读档时如果 `pendingEndedSeasonId` 与 `lastSettledSeasonId` 不一致会重新排队；若标记着 fighting 却不在战斗场景，会清掉 fighting 再走仙命结算。仍可能漏掉的情况：战斗回调本身崩溃、或存档损坏导致 flags 丢失。

## 本机 local-exec 不稳定

Grok Bot 连到用户电脑上的 local-exec 不稳定。开发、改代码、提 PR 请走 GitHub 仓库，不要依赖本机直连会话。

## 业力、秘境、劫季都是竖切品质

M1 到 M5 能跑通主循环（劫季计时、铸牌斋、秘境锁卡组、12 张业力牌、季末渡劫或迁徙）。数值、事件覆盖、表现和存档边界都还薄，不应当成成品系统。

## 缺素材回退：主菜单、Flame 精灵与 Flutter Widget

缺图时主菜单背景和标题会改用纯色占位，「劫季门派 · Demo」文案仍在。缺 BGM 会跳过，不抛错。

局内 Flame 精灵加载（引擎 card/tilemap/UI 组件，以及游戏侧 `Sprite.load` / `Flame.images.load`）缺文件时会回退到占位图（优先 `assets/images/fork/placeholder.png`，否则引擎自带 64x64 PNG），并打警告日志，不再立刻崩溃。这不是换皮：缺图处仍是棕色占位，竖切美术集未替换。

Flutter 侧 `Image` / 原 `DecorationImage` 位图（据点卡、物品格、时辰图、NPC 箭头、战前图标、头像等）已改走 `SafeAssetImage` 的 `errorBuilder`，缺图时退回棕色占位，不再立刻崩溃。`DecorationImage` 没有 `errorBuilder`，这些位置改为 Stack 里铺 `SafeAssetImage`。

仍可能崩溃的路径：`Flame.images.fromCache`（富文本图标）在缓存未命中时，以及 SpriteSheet 实际尺寸与 64x64 占位不一致时。

## 尚未做的包装

- 竖切皮肤替换（主角战斗精灵、敌人、卡框、据点背景、Boss、BGM/SFX）仍未换。
