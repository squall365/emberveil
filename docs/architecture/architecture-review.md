# EMBERVEIL — Architecture Review Gate (Phase 3 · Technical Foundation)

> 评审强度: FULL · 评审人: engineering-lead (程基岩 / Cheng Jiyan) · 日期: 2026-07-26
> 评审对象: `docs/architecture/main-architecture.md` + `adr/ADR-001..004`
> 上游: `design/gdd/` (index + 6 GDD), `design/art/art-bible.md` §9.4, `design/concept/game-concept.md`

---

## 判定：✅ PASS（附条件 / PASS with non-blocking conditions）

技术架构与 6 份 GDD、美术圣经 §9.4 硬约束、以及主理人 Phase 2 决策完全一致；模块归属、元素枚举/亲和值、数据驱动扩展性、Web/HTML5 预算均达标。放行进 Phase 4（pre-production），条件：(a) 调平 spike 在锁定数值前完成；(b) CI 资产审计（16MB/48色/4×1024）落地；(c) 音频为占位，待 Phase 4/6 接入。无架构级阻塞。

---

## 1. 一致性核查（架构 ↔ GDD）

### 1.1 每个 GDD 系统都有唯一归属模块
| GDD | 系统 | 归属模块 | 结果 |
|-----|------|----------|------|
| S1 | Party & Jobs | `PartyManager` | ✅ |
| S2 | Combat | `CombatController`+`BattleResolver`+`EnemyAI` | ✅ |
| S3 | Elements & Ward-Sigil | `ElementRegistry`+`WardCodex` | ✅ |
| S4 | Progression | `ProgressionManager` | ✅ |
| S5 | World Nodes | `WorldDirector` (Town+Dungeon) | ✅ |
| S6 | Save/Load | `SaveManager` | ✅ |

跨切面（SceneManager/InputManager/SaveSystem/AudioBus占位/Analytics可选）均有归属（架构 §1.1）。✅

### 1.2 元素枚举与亲和值逐字一致（关键红线）
从 `elements.md` §2 逐字抄录，架构 §3.3 引用：

- **元素枚举（单一真相源）：** `Ember, Frost, Storm, Stone, Gale, Lumen, Umbra` — 与 GDD 完全一致 ✅
- **亲和乘子：** strong = **1.5**, weak = **0.67**, neutral = **1.0** — 与 `combat.md` §2 完全一致 ✅
- **对称 7 循环：** `Ember ▸ Frost ▸ Storm ▸ Stone ▸ Gale ▸ Lumen ▸ Umbra ▸ Ember`（每个元素强克下一个、弱被上一个克）→ 无主导元素（设计红线）✅
- **共享 Ward Codex**（队伍级 Set + resonance Map）+ 每英雄 `aptitude` 门控 + 每英雄 MP — 与 elements/party/combat 一致 ✅

### 1.3 锁定的主理人决策已落实
| 决策 | 架构落实 | 结果 |
|------|----------|------|
| 每职业最多 1 个（max-1-per-job） | `PartyManager` 组队规则 | ✅ |
| 地牢 4 层 | `DungeonDef` 4 floors（world-nodes §6） | ✅ |
| 调平 spike 在锁数值前完成 | 架构 §7.1 标注为实现阻塞项（数值属数据非代码） | ✅（流程已设护栏） |
| L2–L5 不要求重构 | ADR-003 数据驱动；内容=数据文件 | ✅ |

### 1.4 美术 §9.4 硬约束映射
| 约束 | 架构落实 | 结果 |
|------|----------|------|
| 调色板 ≤48 色 | 调色板校验器（CI）+ 美术 bible §2.3 | ✅ |
| 1×128² grain + ≤4×1024² atlas + ≤16MB | 资产审计（CI 失败即阻断构建） | ✅ |
| 360×640 安全框 / ≥44px 命中区 / 响应式 | Control+Container+锚点；Underdog Stage | ✅ |
| Ward-Sigil 形状为识别通道 | `ElementRegistry` 形状优先；UI 形状+标签 | ✅ |
| Underdog Stage 构图（~58/42） | 战斗场景布局（架构 §2.3） | ✅ |
| 无 SE/IP 资产 | 管线纯原创；AudioBus 占位 | ✅ |

---

## 2. 可测试性 / 验证驱动就绪度

- 战斗为**纯函数 FSM**（ADR-002）：`resolve_action(state, action, rng)` 引用透明 → 单元测试可断言精确伤害与确定性整战（架构 §6.1–6.2）。✅
- RNG 单一真相源（`RNGService` + battle seed）→ 同 seed+动作序列产出逐字节一致日志（确定性可证）。✅
- `EventBus` 仅为 UI/反馈信号、不参与逻辑变更 → 保住单一真相源与可测性。✅
- 验证驱动策略已落地为 GUT 桩 + 集成 + 烟雾测试三级（架构 §6）；测试写在代码前。✅
- 待办：实际 `tests/` 套件在 Phase 4 编写；本阶段为策略与契约，非运行测试。⚠️（非阻塞）

---

## 3. 性能与 Web 预算可行性

- 预算表（架构 §5）覆盖首屏、帧预算、draw call、纹理 atlas、内存上限、调色板、视口，全部对齐 art-bible §9.4。✅
- 渲染器选 `gl_compatibility`（WebGL2）→ 低端面覆盖广；美术方向本就依赖明度+平涂而非复杂 shader，契合。✅
- 单线程 Web：架构已规定协程/`yield` 异步、对象池避免热路径 GC。✅
- **风险**：预算靠 CI 审计强制，否则易被静默突破（见 checklist + 风险 #1）。⚠️（已有缓解：资产审计工具）

---

## 4. 可扩展性（L2–L5 免重构）

- ADR-003 内容即数据：L2 加职业/地牢、L3 大地图/Driftwing、L4 剧情、L5 后日谈 = **新增数据文件，零代码改动**。✅
- 存档迁移（ADR-004）支持 `RunState` 字段随内容增长而向前迁移，旧档不坏。✅
- `CombatController` 非 autoload、按战实例化 → boss 阶段/L2 AI 可在不触碰全局状态下扩展。✅

---

## 5. 原创 IP 合规

- 管线全原创：Ward-Sigil 几何语言、Underdog Stage 构图、软圆×硬几何双语法、原创职业名/世界词。✅
- 无 SE/FF1 精灵、UI 布局、像素字体、水晶图标、商标进入管线。✅
- `AudioBus` 仅占位；音频资产待 Phase 4/6 由 audio-director 以原创供给。✅
- 标题 EMBERVEIL 等为工作名，发布前过 IP clearance（Phase 1 已登记为发布门控）。⚠️（非本阶段阻塞）

---

## 6. CONCERNS（非阻塞）

1. **调平 spike 待完成**（设计+工程）：数值为初稿；架构已就绪，但实现战斗数值前必须锁定 ATK/DEF/MAG/RES/SPD、XP 曲线、法术威力/消耗、variance、AI 激进度（lead 决策 §5.5；phase2 CONCERN）。
2. **CI 资产审计工具**须在美术导入前就位，否则 16MB/48色/4×1024 上限可能被静默突破。
3. **音频未启动**：`AudioBus` 占位；audio-director 待 Phase 4/6 定义 sfx/music 事件表。
4. **仓库暂无 `CLAUDE.md`**：技术偏好（引擎版本/语言）待主理人补；本架构默认 Godot 4 最新稳定版、GDScript 为主。

---

## 7. 已知风险与缓解

| 风险 | 缓解 |
|---|---|
| Web/HTML5 内存 & draw-call 预算（16MB 纹理、4×1024 atlas、360×640、44px） | CI 资产审计 + 调色板校验器，超限即阻断构建（checklist） |
| 确定性纪律松懈（逻辑漏读全局 RNG） | lint 禁止 `combat/`+`battle/` 内 `randi/randf/OS.rand`；EventBus 仅做通知 |
| 调平未定导致不好玩 | spike 在锁数值前完成；Phase 5 烟雾 + Phase 6 playtest 验证 |
| 单存档误覆盖 | New Run 二次确认 + 仅安全节点写盘 |
| 跨 Phase 架构漂移 | 本架构评审门控校验 ADR 与 GDD 契约一致（持续） |

---

## 8. 决议

Phase 3 架构 **PASS（附条件）**。进入 **Phase 4 · 预生产（pre-production）** 前须满足
`phase4-readiness-checklist.md` 全部就绪项（脚手架、autoload 接线、战斗 FSM 烟雾通过、存档读写验证、资产管线遵守 48色/16MB 预算）。
