# EMBERVEIL — Phase 1 设计评审门控 (Design Review Gate)

> 评审强度: FULL · 评审人: 主理人（游承峰）· 日期: 2026-07-26
> 评审对象: `design/concept/game-concept.md` + `design/art/art-bible.md`

## 判定: ✅ PASS（CONCERNS 非阻塞）

两份产物齐全、原创 IP 合规、设计↔美术一致，达到进入 Phase 2 的条件。存在若干非阻塞关注项，已登记为风险与缓解。

## 一致性核查（设计 ↔ 美术）

| 检查项 | 结果 |
|---|---|
| 主色调性（Ember Dusk 选定，其余仅作环境/状态变体） | ✅ 一致 |
| 4 个 MVP 职业（Vanguard / Channeler / Skirmisher / Warden）美术给出原创剪影 | ✅ 一致 |
| 7 元素 → Ward-Sigil 原创符号语言（形状为识别通道，色盲安全） | ✅ 一致 |
| "cozy-but-epic 手作奇幻" 调性 | ✅ 一致 |
| limited-palette vector + 像素纹理 渲染方向 | ✅ 一致 |
| 视觉锚点 §6.4 规避项 → 美术 §9.2 重写为原创替代 | ✅ 一致 |

## 原创 IP 合规

- 两份文档均设硬护栏：不复制 Square Enix / FF1 精灵图、UI 布局、像素字体、水晶图标、商标。
- 原创替代：Ward-Sigils（几何符文）、Underdog Stage 构图、软圆×硬几何双语法、原创职业名与世界词（Veyra / Driftwing）。
- 无受保护资产进入管线。✅

## CONCERNS（非阻塞）

1. **MVP 体量偏大**：垂直切片含 4 职业 + 回合战斗 + 1 城镇 + 1 地牢 + 4 元素 + Godot HTML5 构建 + 教学。建议 Phase 2 前为每个 MVP 特性定严格 DoD 与时间盒，防范范围 creep。
2. **标题/命名待 IP clearance**：EMBERVEIL 等为工作名，公开发布前需过商标/标题核查。登记为发布门控项（非 Phase 1 阻塞）。
3. **音频方向未启动**：audio-director 尚未介入。full 评审下音频是体验一环，登记为 Phase 4 / Phase 6 前向依赖。
4. **玩法数值/平衡未定**：属 Phase 2 系统 GDD 范畴，本阶段不要求。

## 已知风险与缓解

| 风险 | 缓解 |
|---|---|
| MVP 范围失控 | Phase 2 起逐系统 GDD + 严格 DoD；先锁垂直切片最小可玩，再扩 L2–L5 |
| 标题侵权 | 发布前 trademark / title clearance；保留备选名 |
| 小视口可读性 / 性能 | 美术已定 360×640 安全框、48 色上限、16MB 纹理预算、44px 命中区；工程落地时校验 |
| 色盲可辨（Gale 青 / Stone 苔绿相邻） | 形状为唯一识别通道 + 色盲辅助开关（美术 §9.1） |
| 音频断层 | Phase 4 介入 audio-director，定音乐基调与音效事件表 |

## 决议

Phase 1 通过，进入 **Phase 2 · 系统设计**：由 design-strategist 做系统拆解与依赖排序 → 逐系统 GDD（每系统八节）→ 跨 GDD 一致性 / 设计理论评审。
