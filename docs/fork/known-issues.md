# 已知问题（劫季门派 Demo）

这是竖切 Demo，不是可对外发行的完整版本。主菜单「已知问题」按钮列出同一份说明。反馈请开 GitHub Issues：

https://github.com/dengjimiao-dot/heavenly-tribulation/issues

## 美术与音频仍是上游资源

代码是 MIT，美术、音频、字体等非代码资产不在 MIT 范围内。当前构建仍使用上游素材，**对外分发前必须替换**。版权约束见 [FORK.md](../../FORK.md)，竖切最低替换清单见 [replace-assets.md](replace-assets.md) 与 [assets/REPLACE_ASSETS.txt](../../assets/REPLACE_ASSETS.txt)。

## 仙命 3选1 是占位

季末会弹出仙命三选一，并把选项记进 `game.flags.jieji.xianming`。没有真正改构筑、被动或功法数值。功法点与弟子羁绊会随存档留下，仙命本身还没有玩法效果。

## 战斗中存档可能跳过季末收尾

渡劫 Boss 开战时会把 `jieji.fighting` 设为 true。`trySettleJieji` 见到这个标记会直接 return。若在战斗中途存档并退出，再读档时可能跳过剩余的季末结算（仙命、收尾标记清理等）。Demo 里尽量把渡劫打完再存。

## 本机 local-exec 不稳定

Grok Bot 连到用户电脑上的 local-exec 不稳定。开发、改代码、提 PR 请走 GitHub 仓库，不要依赖本机直连会话。

## 业力、秘境、劫季都是竖切品质

M1 到 M5 能跑通主循环（劫季计时、铸牌斋、秘境锁卡组、12 张业力牌、季末渡劫或迁徙）。数值、事件覆盖、表现和存档边界都还薄，不应当成成品系统。

## 缺素材回退：主菜单与 Flame 精灵

缺图时主菜单背景和标题会改用纯色占位，「劫季门派 · Demo」文案仍在。缺 BGM 会跳过，不抛错。

局内 Flame 精灵加载（引擎 card/tilemap/UI 组件，以及游戏侧 `Sprite.load` / `Flame.images.load`）缺文件时会回退到占位图（优先 `assets/images/fork/placeholder.png`，否则引擎自带 64x64 PNG），并打警告日志，不再立刻崩溃。这不是换皮：缺图处仍是棕色占位，竖切美术集未替换。

仍可能崩溃的路径：部分 Flutter `DecorationImage` / `AssetImage` / `Avatar` 等未包 `errorBuilder` 的 Widget（例如据点卡、时辰图、NPC 列表箭头、战前图标），以及 `Flame.images.fromCache`（富文本图标）在缓存未命中时。

## 尚未做的包装

- 竖切皮肤替换（主角战斗精灵、敌人、卡框、据点背景、Boss、BGM/SFX）仍未换。
