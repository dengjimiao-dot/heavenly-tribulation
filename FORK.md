# Fork 说明

| 项 | 值 |
| --- | --- |
| 上游 | https://github.com/hetu-script/heavenly-tribulation |
| 本 fork | https://github.com/dengjimiao-dot/heavenly-tribulation |
| 维护者 | 集淼（dengjimiao-dot） |
| 游戏显示名 | 天道奇劫 |
| 包名 | heavenly_tribulation |
| MSIX publisher_display_name | 集淼 |
| MSIX identity_name | dengjimiao.heavenly_tribulation |

## 版权

- **代码**：沿用上游 MIT（见 `LICENSE`），保留原作者版权声明。
- **美术 / 音频 / 字体等非代码资产**：按上游声明，**不在 MIT 范围内**。本 fork 若对外分发，必须替换为自有或已获授权的素材。

## 依赖布局

工程通过 path 依赖同级目录中的：

- `hetu-script`
- `samsara-engine`
- `fluent_ui`
- `data_table_2`

## 二开玩法方向

已定主方案：**劫季门派**。详见：

- [docs/fork/jieji-menpai.md](docs/fork/jieji-menpai.md)
- [docs/fork/vertical-slice-tasks.md](docs/fork/vertical-slice-tasks.md)
