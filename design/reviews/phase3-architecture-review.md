# EMBERVEIL — Phase 3 架构评审门控（主理人视角）

> 评审强度: FULL · 评审人: 主理人 游承峰 · 日期: 2026-07-26
> 评审对象: `docs/architecture/`（main-architecture.md + adr/ADR-001..004 + architecture-review.md + phase4-readiness-checklist.md）对照 `design/art/accessibility.md`、`design/art/art-bible.md` §9.4、`design/gdd/`
> 注: engineering-lead 已出具 `architecture-review.md` 自评 PASS（附条件）；本文件为主理人独立门控，额外覆盖**跨成员一致性**维度。

---

## 判定：✅ PASS（附条件）

技术架构与 6 份 GDD、美术圣经 §9.4、Phase 2 主理人决策完全一致；4 条 ADR 决策记录规范；Web/HTML5 预算映射到位；原创 IP 合规。放行进 Phase 4（预制作），须满足 `phase4-readiness-checklist.md` 全部 ⛔ 阻塞项。

---

## 1. 一致性核查（主理人复核）

### 1.1 架构 ↔ GDD / 美术圣经（已确认）
- 模块↔GDD 一对一归属、元素枚举/亲和 1.5·0.67 逐字一致、共享 Ward Codex、Underdog Stage 构图、48 色/16MB/360×640/44px 硬约束映射 —— 全部 ✅（与 engineering-lead 评审 §1 一致）。
- ADR-001/002/003/004 决策、后果、备选、校验齐全 ✅。

### 1.2 架构 ↔ 可访问性分级（**主理人补充维度**）
可访问性分级 §4 给工程列了 9 条硬约束。逐条比对主架构 §1.1 / checklist：

| 可访问性 §4 约束 | 架构落实 | 结果 |
|------|------|------|
| Settings 菜单含 Reduced-Motion / Text-Scale / Colorblind-Assist | §1.1 SettingsManager 覆盖 | ✅（部分） |
| **Control Remap（KB+触屏重映射）** | §1.1 跨切面**无 InputManager**；checklist B 未列输入重映射 | ⚠️ **缺口** |
| **Dyslexia-Friendly Font 开关** | SettingsManager 未显式列 | ⚠️ 缺口 |
| **Subtitle 设置** | 未显式列 | ⚠️ 缺口 |
| **Audio/Visual 奇偶开关** | 未显式列（AudioBus 仅占位） | ⚠️ 缺口 |
| **High-Contrast 主题（Comprehensive）** | 未显式列 | ⚠️ 缺口 |
| 44px / 360×640 / 响应式 | §2.3 / §5 覆盖 | ✅ |
| Ward-Sigil 形状优先 | §2.3 / §3 覆盖 | ✅ |
| prefers-reduced-motion 默认 | §1.1 / §7 覆盖 | ✅ |
| 性能守卫联动 a11y | §5 覆盖 | ✅ |
| 管线 lint 拒 FF1/SE | §IP 合规覆盖 | ✅ |

**结论**：架构对可访问性"基础"层（44px、形状通道、reduced-motion、text-scale、colorblind）已落实，但**未显式覆盖 Standard/Comprehensive 的玩家开关全集**（Control Remap、Dyslexia Font、Subtitle、A/V 奇偶、High-Contrast）。

### 1.3 原创 IP 合规
全管线原创；AudioBus 占位；标题 clearance 已登记为发布门控 ✅。

---

## 2. CONCERNS（非阻塞，须在 Phase 4 解决）

承接 engineering-lead 的 4 条（调平 spike / CI 资产审计 / 音频占位 / CLAUDE.md），主理人补充 2 条跨成员一致性缺口：

5. **SettingsManager 须对齐可访问性 §4 全开关清单**：在 Phase 4 UX 规格阶段，把 Control Remap、Dyslexia-Friendly Font、Subtitle、Audio/Visual 奇偶、High-Contrast 这 5 个开关显式写入 SettingsManager 契约与存档 settings schema（main-architecture §4 schemaVersion 的 settings 块目前只有 colorblindAssist/reducedMotion/textScale）。
6. **补输入重映射机制**：可访问性分级要求 Basic 有 fixed KB+触屏映射、Standard 可 remap，但主架构 §1.1 跨切面缺 InputManager。Phase 4 须补 Godot `InputMap` 动态重绑定方案（或明确由 SettingsManager 托管重映射表），否则 Control Remap 无障碍项落空。

---

## 3. 已知风险与缓解

| 风险 | 缓解 |
|------|------|
| Web/HTML5 预算被静默突破 | CI 资产审计 + 调色板校验器（checklist E） |
| 确定性纪律松懈 | lint 禁 combat/battle 全局 RNG（ADR-002） |
| 调平未定 → 不好玩 | spike 在锁数值前完成（checklist H） |
| 可访问性开关遗漏 | CONCERN #5/#6 在 Phase 4 UX 规格补齐 |
| 单存档误覆盖 | New Run 二次确认 + 仅安全节点写盘（S6） |

---

## 4. 决议

Phase 3 架构 **PASS（附条件）**。进入 **Phase 4 · 预制作** 前须：
1. `phase4-readiness-checklist.md` 全部 ⛔ 阻塞项转 ✅；
2. 主理人 CONCERN #5/#6 在 Phase 4 UX 规格阶段写入 SettingsManager 契约与输入重映射方案；
3. engineering-lead 4 条 CONCERN 有负责人与时限。

放行。
