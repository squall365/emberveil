# EMBERVEIL — Sprint 1 QA Plan（质量保障计划）

> **Owner:** quality-lead（严守真 / Yan Soujin） · **Date:** 2026-07-26
> **Sprint:** Phase 5 · Sprint 1（制作期起点，foundation-only）
> **Engine/Platform:** Godot 4（HTML5/WebGL2），Web/小游戏，纯离线单机
> **下游消费者：** engineering-lead（实现 + CI）、主理人（放行回顾）
> **依据文档：**
> - `production/sprint-1-plan.md`（§5 退出标准）
> - `production/epics/epic-01..08.md`（E1–E8 定义与验收）
> - `docs/architecture/main-architecture.md`、`docs/architecture/phase4-readiness-checklist.md`、`docs/architecture/adr/ADR-002`、`ADR-004`
> - `design/reviews/phase4-gate.md`（主理人决策 3.1/3.2/3.3 + CONCERNS 1–5）
> - `design/ux/ux-spec.md` §3/§4/§6/§7
> - `tests/`（GUT 脚手架）、`tools/`（asset_audit.py / palette_validator.gd / content_lint.py）、`.github/workflows/ci.yml`

---

## 0. 质量策略摘要（读前必读）

Sprint 1 是**地基冲刺**：只落 E1 脚手架 → E2 Autoloads → E4 Save/Load → E3 战斗 FSM（结构+确定性+5 命令）→ E7 测试 harness + CI → E5/E6 审计/数据桩。**战斗数值是占位**（ADR-003），平衡由 E8 spike 在 Sprint 2+ 锁定，不在本冲刺验证"好玩"。

QA 角色在本冲刺只产出**测试策略与规格**（不写游戏代码）。本计划对齐 `docs/architecture/phase4-readiness-checklist.md` 的 **A/B/C/D ⛔ 项**，逐条给出"怎么验、用什么脚本/用例、通过判据"，并把它们映射到 CI 五道闸与现有 `tests/` 脚手架。

> ⚠️ **Sprint 1 起始态实测**：截至本计划撰写，`content/`、`assets/`、`addons/`、`project.godot`、`export_presets.cfg`、`CLAUDE.md` 均**尚未落地**（仅 `tests/`、`tools/`、`production/`、`docs/`、`design/` 存在）。因此下文所有 ⛔ 验证方法目前"由 `tests/` 中的 **stub** 对标，待实现到达即成为回归门"。功能未实现前，其 ⛔ 项判为 **CONCERNS/NOT-YET**（非正式失败），实现到达后由对应用例钉死。

---

## 1. Phase 4 门控 A/B/C/D ⛔ 验证方法

> 每条给出：**验证手段**（方法/工具）、**脚本/用例**（对齐 `tests/` 脚手架文件名）、**通过判据**。
> "已有 stub" = 该文件已存在于 `tests/` 并对标目标 API；"待建" = 本计划建议新增。

### 1.1 Checklist A — Project Scaffold

| ID | ⛔ 项（原文） | 验证手段 | 脚本 / 用例 | 通过判据 |
|----|----|----|----|----|
| A1 | Godot 4 latest-stable 项目；`project.godot` 含 `renderer/rendering_method=gl_compatibility` | CI：`godot --headless --path . --quit` 退出 0；`ConfigFile` 读取并断言含 `gl_compatibility`（CI 第 1 步 + 一份 `tests/qa/ci_assert_project.gd` 或 shell grep） | `.github/workflows/ci.yml` 第 1 步；建议补充 `tools/check_project_cfg.py`（grep `gl_compatibility`） | ① headless 退出码=0 且无 import error；② `project.godot` 含 `gl_compatibility`（CI 红线） |
| A2 | `CLAUDE.md` 记载引擎版本、GDScript-primary、GDExtension-escape-hatch 政策 | CI/本地 lint：文件存在、非空、包含 `main-architecture.md` 引用、含引擎版本串 `4.3` | 建议 `tools/check_claude_md.py`（或复用 GUT `test_project_docs.gd`） | ① 文件存在且字节数>0；② 含 `docs/architecture/main-architecture.md`；③ 含引擎版本（`GODOT_VERSION=4.3`） |
| A3* | Export preset HTML5/WebGL2；CI 头less 启动到 Title | CI：构建 Web 导出产物含 `index.html` + `.wasm`/`.pck`；headless 日志出现 `TITLE_REACHED`（或当前场景==Title） | `.github/workflows/ci.yml` 第 1 步（Boot→Title） | ① 产物含 `index.html` 与 wasm/pck；② headless 在超时内到达 Title（无 error） |
| A4* | Repo 布局：`src/`、`content/`、 `tests/`（GUT）、`docs/architecture/` | CI 断言四个根目录存在；`git status` 在 headless 跑完后无 `.godot/` 残留 | 建议 `tools/check_layout.py` | ① 四目录均存在；② headless 后无 `.godot/` 未跟踪改动 |

> \* A3/A4 在 `epic-01` 中标记 ⛔、且 Sprint 1 退出标准按全部 E1-A..D 处理，但 `phase4-readiness-checklist.md` 的 A 段**仅 A1/A2 标 ⛔**。该分歧见 §7 OQ3，验证方法仍照常覆盖。

### 1.2 Checklist B — Autoloads Wired

| ID | ⛔ 项 | 验证手段 | 脚本 / 用例 | 通过判据 |
|----|----|----|----|----|
| B1 | `SettingsManager` 加载并应用可访问性（colorblind-assist / reduced-motion / text-scale 100–125%） | 单测：默认加载 + 存储值应用；集成：boot 在 Title 构建前应用 settings | **待建** `tests/unit/test_settings_manager.gd`（对标 `emberveil.settings.v1` 全局键权威 + `RunState.settings` 镜像，见 phase4-gate 3.1）；smoke `test_boot_to_save.gd` 已覆盖 boot-applies-settings | ① `load()` 无存储返默认、有存储应用之；② `text_scale` clamp∈[1.0,1.25]、`reduced_motion` 默认 false；③ smoke 断言 Title 构建前 settings 已生效 |
| B2 | `RNGService` 可种子化 PRNG，唯一随机源 | 单测：同 seed ⇒ 1000 抽序列相同；`next_variance()`∈[0.9,1.1]；lint：无全局 RNG | **待建** `tests/unit/test_rng_service.gd`；CI RNG lint | ① 同 seed 抽 1000 次逐位相等；② variance 全部∈[0.9,1.1]；③ `src/combat`+`src/battle` 无 `randi/randf/OS.rand` |
| B3 | `EventBus` 类型化信号；**handler 内不变更逻辑状态** | 单测：emit `combat_action_resolved` 不改变 `BattleState`；代码评审：handler 无 `BattleState` 变更 | **待建** `tests/unit/test_eventbus_purity.gd` | ① emit 前后 `BattleState` 逐字段相等；② 评审确认无逻辑副作用（架构 §2.4 硬规则） |
| B4 | `AssetRegistry` 加载 `content/` 为 def 表；缺/重 id 快速失败 | 集成：加载全部 MVP def（E6）零缺/重；单测：重复 id ⇒ 抛错并指明 offending id | **待建** `tests/integration/test_assetregistry_load.gd`；CI content-lint 协同 | ① 全 MVP def 零缺失/重复；② 重复 id 抛错且含违规 id；③ 与 content_lint 的"重复"定义一致 |
| B5 | `ElementRegistry` + `WardCodex` 由数据构建；亲和矩阵精确（1.5/0.67/1.0） | 单测：symmetry 7-cycle；re-attune 幂等 | **已有 stub** `tests/unit/test_affinity.gd`；**待建** `tests/unit/test_ward_codex.gd` | ① `affinity("Ember","Frost")==1.5` / `("Frost","Ember")==0.67` / 中性==1.0；② 每元素恰强 1 / 弱 1（对称环）；③ 同 sigil 重复 attune ⇒ Codex 不变 |
| B6 | `SaveManager`+`PartyManager`+`ProgressionManager` 若存在 RunState 则加载 | 单测：Party 拒绝 2nd 同 job；派生属性重算=base+growth*level+装备（不双存）；集成：combat_ended(win) ⇒ Progression 记 XP | **待建** `tests/unit/test_party_manager.gd`、`tests/unit/test_progression_manager.gd`；**待建** `tests/integration/test_save_load_roundtrip.gd`（覆盖 combat_ended→XP） | ① `assign(jobId)` 拒绝重复 job；② 派生属性重算式成立且序列化无派生字段；③ `combat_ended(win)` 触发 XP/升级 |

### 1.3 Checklist C — Combat Determinism（ADR-002）

| ID | ⛔ 项 | 验证手段 | 脚本 / 用例 | 通过判据 |
|----|----|----|----|----|
| C1 | `BattleResolver.resolve_action(state, action, rng)` 为纯函数 | 单测：固定输入 Attack/Elemental 等于手算；dmg≥1、HP 地板 0；输入 state 不变、返回新 state | **已有 stub** `tests/unit/test_combat_math.gd`；**待建** `tests/unit/test_battle_resolver_pure.gd` | ① 公式逐字匹配 combat.md §2（含亲和 1.5/0.67/1.0、variance pinned）；② dmg 永≥1、HP 永≥0；③ `resolve_action` 后入参 `state` 未变异 |
| C2 | FSM 各相可达：`PreBattle→PlayerSelect→ResolveAction→Animate→CheckEnd→(loop|PostBattle)` | 单测：队列按 SPD 降序、同 SPD tie-break slot 升、仍平用 seeded 序；`turnPointer` 跳过 HP≤0 | **待建** `tests/unit/test_combat_fsm_phases.gd` | ① 全相可从 `PreBattle` 抵达 `PostBattle`；② 队列序符合规则；③ 死亡单位被跳过（无对死者的动作）；④ 全 Defend 死锁由 enemy escalation 解开（见 §7 OQ7） |
| C3 | 单测：固定 seed + 动作脚本 ⇒ 确定性 win/lose + 相同 log | 集成：同 (seed, action list) ⇒ 相同序列化 outcome hash | **已有 stub** `tests/integration/test_combat_fsm_determinism.gd` | ① 两遍同 (seed,actions) ⇒ `log` 哈希相同且结果相同；② 不同 seed ⇒ 不同 variance 抽（证明确为 seeded 而非常量） |
| C4 | Lint 通过：combat/+battle/ 内无 `randi/randf/OS.rand` | CI grep | `.github/workflows/ci.yml` 第 6 步（RNG lint） | ① 注入 `randi()` ⇒ 流水线失败；② 干净树通过 |

### 1.4 Checklist D — Save / Load Verified（ADR-004）

| ID | ⛔ 项 | 验证手段 | 脚本 / 用例 | 通过判据 |
|----|----|----|----|----|
| D1 | Serialize→deserialize 往返等于原 `RunState` | 单测：往返 deep-equal；派生属性不存储 | **已有 stub** `tests/unit/test_save_roundtrip.gd`（`test_serialize_deserialize_roundtrip`、`test_derived_stats_not_stored`） | ① `deserialize(serialize(s))` 深等于 `s`；② 序列化串不含 `maxHP`/`ATK` 等派生键 |
| D2 | `schemaVersion` 迁移 v1→v2 转换旧档 | 单测：v1 fixture → 合法 v2（必填字段齐全/默认）；CI 覆盖每步 | `tests/unit/test_save_roundtrip.gd`（`test_migration_v1_to_current`）；**待扩展**每步独立用例 | ① v1 转为 CURRENT 且所有必填字段存在/默认；② 每步往返可 CI 复现 |
| D3 | `checksum`（CRC32）校验；篡改 / `schemaVersion>CURRENT` ⇒ 拒绝 + 提示 | 单测：篡改 checksum ⇒ `load` 返 `null`+错误旗；版本超前 ⇒ 拒（无部分恢复）；合法 ⇒ 正常 | `tests/unit/test_save_roundtrip.gd`（`test_checksum_tamper_refused`、`test_forward_version_refused`） | ① 篡改 ⇒ `res.ok=false` 且 `error=="CHECKSUM_MISMATCH"`；② 超前 ⇒ `error=="VERSION_AHEAD"` 且绝不部分恢复；③ 合法 checksum ⇒ 正常加载 |
| D4 | 仅安全节点写盘（Town-enter/floor-clear/sigil-attune/quest-complete）；战斗中**不持久化** | 集成：战斗中写盘为 no-op/被拦；quit 中战斗回到战前安全点 | **待建** `tests/integration/test_safe_node_write.gd`；smoke `test_boot_to_save.gd` | ① 唯一公开写盘 `save_at_safe_node()`；② 战斗中调用不落盘；③ reload 回到战前安全点且 `battleState` 缺席 |
| D5 | 单槽；`New Run` 需确认对话框 | 单测：`new_run()` 未确认被拒、确认后覆盖单槽；UI：无存档时 Continue 隐藏 | **待建** `tests/unit/test_save_single_slot.gd`；smoke 覆盖 Continue 显隐 | ① 未确认 `new_run()` 拒绝；② 确认后覆盖单槽；③ 无存档时 `Continue` 灰显/隐藏 |

> Sprint 1 退出标准中另有 **E（资产管线）/ G（测试 harness）** 为 ⛔ 项，其验证见 §5 CI 五道闸映射与 §6 IP 护栏；本 §1 按要求聚焦 A/B/C/D。

---

## 2. Sprint 1 测试矩阵（Epic × 测试类型）

> 对齐 `tests/` 现有脚手架（`unit/`、`integration/`、`smoke/`）。"已有 stub" 表示文件已存在对标 API；"待建" 表示本计划建议新增（实现到达即钉死为回归门）。
> 资产审计列指向 `tools/` + `content/` 静态检查，非 GUT 用例。

| Epic | 单测（unit/） | 集成（integration/） | 烟雾（smoke/） | 资产审计（tools/ + content） |
|------|----|----|----|----|
| **E1 脚手架** | （CI）`project.godot` gl_compatibility grep；`CLAUDE.md` lint | — | `test_boot_to_save.gd` 步骤 1–2（Boot→Title） | — |
| **E2 Autoloads** | `test_affinity.gd`(B5) · `test_ward_codex.gd`(B5,待建) · `test_settings_manager.gd`(B1,待建) · `test_rng_service.gd`(B2,待建) · `test_eventbus_purity.gd`(B3,待建) · `test_party_manager.gd`(B6,待建) · `test_progression_manager.gd`(B6,待建) | `test_autoload_init_order.gd`(B 全部 init 顺序,待建) · `test_assetregistry_load.gd`(B4,待建) · `test_save_load_roundtrip.gd`(B6+E4,待建) | `test_boot_to_save.gd`（boot 应用 settings=B1） | — |
| **E3 战斗 FSM** | `test_combat_math.gd`(C1,已有) · `test_battle_resolver_pure.gd`(C1 副作用,待建) · `test_combat_fsm_phases.gd`(C2,待建) | `test_combat_fsm_determinism.gd`(C3,已有) · `test_combat_deadlock.gd`(C2 死锁/escalation,待建,见 OQ7) · `test_enemyai.gd`(E3-E,待建) | `test_boot_to_save.gd` 步骤 6（combat win） | **RNG lint**（C4，CI） |
| **E4 Save/Load** | `test_save_roundtrip.gd`(D1/D2/D3,已有) · `test_save_single_slot.gd`(D5,待建) | `test_safe_node_write.gd`(D4,待建) · `test_save_load_roundtrip.gd`(D1/D4,待建) | `test_boot_to_save.gd` 步骤 4/7（Town/Dungeon safe-node save） | — |
| **E5 资产管线** | `test_viewport_layout.gd`(E3 360×640/44px,待建,见 OQ7) | — | — | `asset_audit.py`(E atlas/预算) · `palette_validator.gd`(E 调色板≤48) |
| **E6 数据驱动** | `test_content_load.gd`(F MVP defs,待建) | — | — | `content_lint.py`(F 完整性,**当前不完整见 OQ1/OQ2**) |
| **E7 测试 harness** | — | — | `test_boot_to_save.gd`(G smoke,已有) | GUT 基础设施（G，CI 第 2 步） |

**GUT 文件名对齐说明**
- 保留现有：`test_affinity.gd`、`test_save_roundtrip.gd`、`test_combat_math.gd`、`test_combat_fsm_determinism.gd`、`test_boot_to_save.gd`。
- 新增（建议，实现到达前为待建）：`test_ward_codex.gd`、`test_settings_manager.gd`、`test_rng_service.gd`、`test_eventbus_purity.gd`、`test_party_manager.gd`、`test_progression_manager.gd`、`test_battle_resolver_pure.gd`、`test_combat_fsm_phases.gd`、`test_combat_deadlock.gd`、`test_enemyai.gd`、`test_save_single_slot.gd`、`test_autoload_init_order.gd`、`test_assetregistry_load.gd`、`test_save_load_roundtrip.gd`、`test_safe_node_write.gd`、`test_viewport_layout.gd`、`test_content_load.gd`。
- 新增 CI 辅助（建议）：`tools/check_project_cfg.py`（A1）、`tools/check_claude_md.py`（A2）、`tools/check_layout.py`（A4）。

---

## 3. Sprint 1 回归风险

> 即"本冲刺改动可能引入的回归点"，每条给：风险面、触发场景、检测手段、缓解。

### R1 — Settings schema 扩展破坏旧存档反序列化（最高风险）
- **面**：phase4-gate 决策 3.1 将 settings 扩展为 `controlRemap/subtitle/dyslexiaFont/highContrast/audioVisualParity/musicVolume`，且 `emberveil.settings.v1` 全局键权威 + `RunState.settings` 镜像。
- **触发**：一份 v1 存档的 `settings` 块仍是**旧 5 字段**形态；新代码按扩展 schema 反序列化时缺字段 → 合并策略不清或崩。
- **检测**：`test_save_roundtrip.gd` 增加"加载旧 5 字段 settings 的 v1 档 → 合并出合法扩展 settings"用例；CI 覆盖。
- **缓解**：明确 load 合并策略（见 OQ4）——要么并入 schemaVersion 迁移链（v1→v2 把 settings 升到扩展），要么在 `SaveManager` 加载层做"全局键胜出 + DEFAULTS 前向填充缺失字段"。**当前无用例覆盖此路径**。

### R2 — RNG 种子化影响战斗复现
- **面**：`RNGService` 是战斗唯一随机源；seed = `RunState.seed` + battle nonce。任意额外 RNG 抽（如 initiative tie-break 位置变化）会平移后续所有抽 → 同 seed 产出不同战斗。
- **触发**：代码改动在 `resolve_action` 前/中新增一次 `rng.next()`；或 battle nonce 组合不稳定。
- **检测**：`test_combat_fsm_determinism.gd`（C3）固定 seed=42 钉死；RNG lint 守 `src/combat`+`src/battle`；建议补充"seed 组成契约"文档断言。
- **缓解**：确定性测试即回归门；RNG lint 防全局 RNG 泄漏；**要求 battle nonce 组合在实现中稳定且注释**。

### R3 — Autoload 初始化顺序
- **面**：`main-architecture.md` §2.1 规定严格 13 步顺序（SettingsManager 最先，依赖者后）。顺序错 → 依赖单例读到未初始化数据（null 崩溃）。
- **触发**：新增 `AudioBus`/`Analytics`；或 `AssetRegistry` 早于 `SettingsManager`；或 `controlRemap` 在 boot 应用 InputMap 时引用尚未注册的动作。
- **检测**：`test_autoload_init_order.gd` 断言注册顺序==§2.1；smoke 断言 boot 后各 autoload 非 null。
- **缓解**：顺序变更需 review；新增 autoload 必须排入依赖正确位置。

### R4 — Checksum 对序列化顺序敏感（false corruption）
- **面**：CRC32 对已序列化字节计算；若 GDScript `JSON.stringify` 键序不稳定，两次相同 RunState 的 checksum 不同 → 旧存档 reload 时被误判为损坏。
- **触发**：引擎版本升级改变 dict 序列化键序；或写入/读取使用不同序列化路径。
- **检测**：`test_save_roundtrip.gd` 增加"两次独立序列化同 state → checksum 相等"用例。
- **缓解**：定义**规范（sorted-key）序列化**契约（见 OQ5），checksum 仅对规范字节计算。

### R5 — 安全节点写盘被绕过（save-scum）
- **面**：`save_at_safe_node()` 是唯一公开写盘；若某场景直接调 `save()` 中战斗 → 可存档刷。
- **触发**：后续 Town/Dungeon 场景误用 `SaveManager.save()`。
- **检测**：`test_safe_node_write.gd` + smoke 断言战斗中 `emberveil.save.v1` 键不变。
- **缓解**：`save()` 设为内部/private；公开写盘仅 `save_at_safe_node()`；CI 评审。

### R6 — 亲和值被"平衡"误改（破坏 GDD 契约）
- **面**：亲和力 1.5/0.67/1.0 是 GDD 逐字固定（非数据），但有人可能误当可调参数。
- **触发**：把 affinity 移入 `content/` 调参。
- **检测**：`test_affinity.gd` 钉死精确乘子 + 对称 7-cycle。
- **缓解**：亲和矩阵代码常量化，注释"来自 GDD，禁止数据化"。

### R7 — 全 Defend 死锁（确定性下的卡死回归）
- **面**：E3-B 验收 #3 要求"全 Defend 不卡死，enemy escalation 解开死锁"。当前 `test_combat_fsm_determinism.gd` 用脚本化动作列表，**未覆盖全 Defend 场景**。
- **触发**：enemy escalation 阈值（E8-D）实现缺失/错误 → 无限选人。
- **检测**：**待建** `test_combat_deadlock.gd`（脚本化双方全 Defend → N 回合内收敛）。
- **缓解**：作为集成回归门（见 OQ7）。

---

## 4. Bug 分级标准与 Triage 流程

### 4.1 分级（对齐团队惯例：S=阻塞发布 / A=功能缺陷 / B=体验 / C=建议）

| 级 | 名称 | 定义 | 典型示例（Sprint 1 语境） |
|----|----|----|----|
| **S** | Blocker（阻塞发布） | 任意 ⛔ 项失败；任意 CI 道闸变红；IP 违规；存档损坏可被加载；纯离线保证被破（出现网络/云/账号调用）；数据丢失 | gl_compatibility 缺失、GUT 全红、CRC32 误放行损坏档、出现 `OS.request`/登录 UI、FF1 资产残留 |
| **A** | 功能缺陷 | 破坏某 Epic 验收或核心契约，无可行绕过 | 亲和乘子错、RNG 不可复现、FSM 某相不可达、settings 未应用、单槽被静默覆盖、安全节点写盘漏触发 |
| **B** | 体验 | 功能可用但不达标 | reduced-motion 仍有轻微闪烁、命令 chip 在极端视口 <44px、text-scale 在 1.25 裁剪标签 |
| **C** | 建议 | 打磨/命名/文档 | 命名不一致、注释缺失、文档 typo |

### 4.2 Triage 流程
1. **提交**： reporter 在 `production/qa/bugs/` 建单，含 severity + 复现步骤（环境/前置/步骤/预期/实际）+ 上下文。
2. **确认**：QA lead（严守真）确认 severity，指派 priority（**P0**=S 立即修 / **P1**=A 本冲刺修或被 lead 正式豁免 / **P2**=B 入 Sprint 2 backlog / **P3**=C backlog）。
3. **每日 Triage**：S→阻断合并、立即修；A→本冲刺内修或经主理人书面豁免；B/C→backlog。
4. **放行规则**：任何 **S 降级**或 **⛔ 项豁免**须主理人（游承峰）签字；质量门为**建议性门控**——判定给主理人，最终放行由用户定。
5. **追踪**：bug 状态进 `production/qa/bugs/`，回归用例补入 `tests/`（见 R1–R7 对应用例）。

---

## 5. CI 五道闸对应关系

> 对齐 `.github/workflows/ci.yml` 实际步骤。任务所述"5 道闸"= {godot headless, asset_audit, palette_validator, content_lint, RNG lint}；GUT（单测/集成/烟雾金字塔）是该 5 道闸之外、由 godot headless 驱动的**第 6 类门**（CI 第 2 步），其下用例覆盖 B/C/D/E3/G 的绝大多数 ⛔。下表给出完整映射。

| 道闸 | CI 步骤 | 覆盖的 ⛔ 项 | 验证脚本/工具 |
|------|----|----|----|
| **G1 godot --headless boot** | 第 1 步 `./godot --headless --path . --quit` | A1（gl_compatibility 启动）、A3*（Boot→Title）、C 启动健康 | `project.godot` ConfigFile；`TITLE_REACHED` 日志 |
| **G2 GUT（unit+integration+smoke）** | 第 2 步 `gut_cmdln.gd -gdir=res://tests -gexit` | B1/B2/B3/B4/B5/B6、C1/C2/C3、D1/D2/D3/D4/D5、E3（viewport 经 GUT）、G | `tests/unit/*` `tests/integration/*` `tests/smoke/*`（见 §2 矩阵） |
| **G3 asset_audit.py** | 第 3 步 `python3 tools/asset_audit.py` | E（atlas/纹理/预算：≤4×1024²、≤16MB、1×128² grain、WebP/PNG） | `tools/asset_audit.py` |
| **G4 palette_validator.gd** | 第 4 步 `godot --headless --script tools/palette_validator.gd` | E（全局调色板 ≤48 色） | `tools/palette_validator.gd` + `content/palette.json` |
| **G5 content_lint.py** | 第 5 步 `python3 tools/content_lint.py || gut content_lint.gd` | F（MVP defs 完整性：id 唯一、元素引用合法） | `tools/content_lint.py`（**注意：当前仅扫 JSON 且不校验必填/数值范围，见 OQ1/OQ2**） |
| **G6 RNG lint** | 第 6 步 `grep randi/randf/OS.rand src/combat src/battle` | C4（combat/battle 无全局 RNG） | shell grep（CI 内联） |

**IP gate（退出标准硬项）的 CI 支撑**：自动令牌 grep（SE/FF1/水晶图标等）建议并入 G5 或独立 step；**Underdog Stage 构图 + Ward-Sigil 形状 ID 唯一性为人工评审门**（见 §6、OQ6），不进自动 CI。

---

## 6. IP 护栏验证

> 原始 IP 铁律：无 Square Enix / FF1 资产、布局、字体、商标；仅 Ward-Sigil 语 + Underdog Stage。

| 护栏 | 验证手段 | 自动/人工 | 通过判据 |
|------|----|----|----|
| 无 SE/FF1 资产/引用 | CI grep `src/`、`content/`、`assets/` 对令牌 `se_`/`ff1`/`ffix`/`square_enix`/`final_fantasy`/`crystal`（FF1 水晶图标语义） | **自动**（建议新增 G-step） | grep 零命中 |
| Underdog Stage 构图（非 FF1 敌人右/我方左） | 布局断言 + 人工评审 | **人工评审门**（art-director/design-strategist 签字） | 敌弧在上、我方带居中下、命令 dock 左下；非 FF1 全宽底栏（art-bible §6.1） |
| Ward-Sigil 形状 ID 唯一 | `SigilDrawer` 单测：7 字形互异；人工比对 FF1 元素图标 | **自动+人工评审** | 7 字形轮廓两两不同；无任一匹配 FF1 元素图标 |
| 战斗数值占位（非 E8 锁定） | 不在此冲刺验证"好玩"；仅验证结构/确定性 | — | E8 spike 在 Sprint 2+ 锁定（CONCERN 1） |

---

## 7. 需主理人裁决的开放问题（不自行假设）

> 以下为 Sprint 1 范围/退出标准中的**歧义或缺失**，已尽可能用现有文档佐证；请主理人（游承峰）择一裁决，交 engineering-lead 落实。

- **OQ1（Critical）— content_lint 格式覆盖缺口。** `content_lint.py` 仅 `os.walk` 扫 `.json`（`fn.endswith(".json")`）。但 E6-A DoD 与 `main-architecture.md` §2.5 均说 MVP def 是 **`.tres`/JSON（Godot Resource）**，且 `AssetRegistry` 加载 `.tres`。若 E6 实际落地为 `.tres`，则 **F 道闸将扫描 0 个 def、空过通过** → checklist F ⛔ 实际未被验证。需裁决：① E6 的权威内容格式（.tres vs .json）；② 确保 content-lint 覆盖该格式（落地 `content_lint.gd` 读 Resource，或统一 JSON + tres→json 导出供 lint）。

- **OQ2（High）— content_lint 校验深度不足。** E6-B DoD 要求校验"必填字段存在、数值范围合理（stats≥1、MP 费用 4–10、resonance≤5、level cap 20）"。现有 `content_lint.py` 仅查 id 唯一 + 元素引用合法，**不查必填字段与数值范围**。即使内容全 JSON，F 道闸仍不完整。需裁决：扩展 `content_lint.py` 覆盖必填/范围，或正式接受较弱门控。

- **OQ3（High）— Checklist A ⛔ 标记分歧。** `epic-01` 将 E1-A..D **全部**标 ⛔，Sprint 1 退出标准按"全部 E1 ⛔"处理；但 `phase4-readiness-checklist.md` 的 A 段**仅 A1/A2 标 ⛔**，A3（导出预设/Boot→Title）与 A4（仓库布局）未标。需裁决：E1-C/E1-D 是否为 Sprint 1 退出的硬阻塞（影响 A3/A4 失败时的 severity 定级与门控强度）。

- **OQ4（High）— Settings 扩展 schema 与旧档合并策略。** phase4-gate 决策 3.1 扩展 settings 且全局键权威。但无用例加载"旧 5 字段 settings 的 v1 档"并合并为扩展状态（见 R1）。需裁决：合并走 schemaVersion 迁移链（v1→v2 升 settings）还是 `SaveManager` 加载层前向填充 DEFAULTS；据此 QA 才能写回归用例。

- **OQ5（Med-High）— Checksum 序列化规范。** ADR-004/main-arch 未规定序列化键序；GDScript `JSON.stringify` 键序可能随版本变 → 同 RunState 两次 checksum 不同 → 旧档被误判损坏（见 R4）。需裁决：采用 **sorted-key 规范序列化** 作为 checksum 计算契约，并在 `test_save_roundtrip.gd` 增"两次序列化 checksum 相等"用例。

- **OQ6（Med）— IP gate 人工评审归属与记录。** 自动令牌 grep 可行；但 Underdog Stage 构图 + Ward-Sigil 形状唯一性为人工评审门（§6）。需裁决：评审执行人（建议 art-director + design-strategist）与签字产物文件（如 `design/reviews/ip-clearance-sprint1.md`），以便退出标准"IP gate 过"可审计。

- **OQ7（Med）— 缺失的死锁/视口测试文件。** E3-B 验收 #3（全 Defend 死锁由 escalation 解开）与 E5-C（360×640/44px 视口）在 `tests/` 脚手架中**尚无对应文件**（`test_combat_fsm_determinism.gd` 用脚本化动作未覆盖全 Defend；无 `test_viewport_layout.gd`）。E5-C 在 checklist E 标 ⛔、E3-B 标 ⛔。需裁决：确认这两例属 Sprint 1 范围（建议新增 `test_combat_deadlock.gd` 集成 + `test_viewport_layout.gd` 单测），并由 engineering-lead 建文件、QA 钉用例。

---

*End of Sprint 1 QA Plan. 下游：engineering-lead 据本计划实现/补建用例与 CI 辅助；主理人据 §7 裁决开放问题后放行 Sprint 1。*
