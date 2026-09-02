# 竖切素材替换清单

上游美术与音频 **不在 MIT 范围内**。本 fork 若对外分发，必须换成自有或已获授权的素材。版权说明见 [FORK.md](../../FORK.md)，玩法表见 [jieji-menpai.md](jieji-menpai.md) §8。

**当前构建仍使用上游资源。** 本清单只约定竖切最低替换范围，并未在本里程碑换皮。

精简表同步放在 [assets/REPLACE_ASSETS.txt](../../assets/REPLACE_ASSETS.txt)。

## 最低替换

| 类别 | 数量级 | 策略 | 建议落点（实现时再核对） |
| --- | --- | --- | --- |
| 主角战斗精灵 | 1 套 | AI 或外包像素/立绘，统一色板 | `assets/images/battle/`、角色动画目录 |
| 敌人 | 4～6 | 简化剪影 + 换色 | `assets/images/battle/`、敌人立绘/剪影 |
| 卡牌框/底色 | 1 套 UI | 自绘九宫或 flat UI | `assets/images/battlecard/`、UI 框 |
| 据点背景 | 1 | 静态插画 | `assets/images/location/`、故乡/危门场景 |
| Boss | 1 | 重点投资 | 渡劫 Boss 立绘与战斗场景 |
| BGM | 3～5 | 免费商用库或重新生成 | `assets/audio/music/` |
| SFX | 3～5 | 免费商用库或重新生成 | `assets/audio/sound/` |

## 目录约定

- 自有素材按上表类别放进对应 `assets/images/`、`assets/audio/` 子目录，文件名先对齐现有引用再改代码。
- 代码可先用占位矩形或纯色卡背跑通逻辑，再换皮。
- 仓库若精简掉 images/audio/fonts，仍以本表与 `assets/REPLACE_ASSETS.txt` 为准，不要把上游包直接打进发行物。

## 本里程碑状态

M6 只做开始界面文案和已知问题入口。竖切皮肤替换任务保持未完成。M0 已做主菜单缺素材回退（纯色占位 + 缺 BGM 跳过），没有替换竖切美术集。
