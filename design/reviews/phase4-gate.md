# EMBERVEIL — Phase 4 预制作 收口门控（主理人视角）

> 评审强度: FULL · 评审人: 主理人 游承峰 · 日期: 2026-07-26
> 评审对象: `design/ux/ux-spec.md` (P4-UX-001) + `design/art/asset-spec.md` (P4-ARTSPEC-002) + `production/epics/` + `production/sprint-1-plan.md` + `tests/` scaffold + `tools/` (P4-EPIC-003)
> 上游: Phase 1–3 全部产物；主理人 Phase 3 门控 CONCERN #5/#6

---

## 判定：✅ PASS（附条件）

Phase 4 三份预制作产物全部交付、互相咬合：UX 规格闭合了主理人 Phase 3 门控的两个缺口（#5/#6），资产规格在硬预算内自洽，工程 Epic/Story + 测试脚手架覆盖 Phase 4 checklist 全部 ⛔ 阻塞项且 enforce 纯离线。可进入 **Sprint 1 实现**。

---

## 1. 三份产物一致性核查

| 产物 | 关键交付 | 与上下游一致性 |
|------|----------|----------------|
| UX 规格 (`design/ux/ux-spec.md`) | 屏幕流 / InputMap 重绑定 (#6) / SettingsManager 全9开关+扩展schema (#5) / Underdog Stage HUD / 反馈系统 / 纯离线 | 闭合 Phase 3 门控 #5/#6 ✅；对齐架构 §2.3/§4、可访问性 §4 |
| 资产规格 (`design/art/asset-spec.md`) | ≈90 资产、预算 15.75MB<16MB、≤48色、atlas→def 映射 | 对齐架构 §5 硬预算 + 美术圣经九节 + 可访问性（44px/形状通道）✅ |
| Epic/Story (`production/epics/`) | 8 Epic、S1–S6 覆盖矩阵、纯离线 guardrail | 映射 checklist A–H ⛔ ✅；Sprint 1 = A/B/C/D⛔+G ✅ |
| 测试脚手架 (`tests/`) | GUT unit×3 + integration×1 + smoke×1 | 覆盖 affinity/存档/战斗确定性 ✅ |
| 工具 (`tools/`) | asset_audit.py / palette_validator.gd / content_lint.py | 对应架构 §5 CI 审计 ✅ |

---

## 2. Phase 3 门控缺口闭合确认

- **CONCERN #5（SettingsManager 全开关）**：UX §4 枚举了可访问性 §4 全部 9 开关，并把 `main-architecture.md` §4 的 settings schema 扩展为 `controlRemap / dyslexiaFont / subtitle{enabled,size,background,position} / audioVisualParity / highContrast`（保留原字段，additive）。✅ 闭合。
- **CONCERN #6（缺 InputManager）**：UX §3 定义逻辑动作集 + `SettingsManager` 持有 `controlRemap` 表、经 Godot `InputMap` 在 boot/runtime 应用，含冲突拒绝/交换/重置默认。架构 §1.1 缺的模块已补。✅ 闭合。

---

## 3. 主理人决策（拍板 open question）

### 3.1 设置存储归属（文策渊 open question）
**采纳推荐**：全局 `localStorage` key **`emberveil.settings.v1` 为权威**，`RunState.settings` 保留为镜像（load 时全局 key 胜出）。理由：纯离线、设置在 Title 首屏即达、跨 New Run 持久、additive 不破坏锁定存档序列化。程基岩在 E2 实现时据此更新 save serializer。

### 3.2 资产规格三处 load-bearing 风险 → 落实为工程硬约束
林绘澄在资产规格 §3.4 / §7 提了三个需确认的硬设置，主理人拍板如下，由程基岩写入 E5（资产管线）与导出预设：
1. **角色 Atlas A 的 mipmap 必须 OFF**（开启 → 17MB 超限）。→ 写入导出预设 + `asset_audit.py` 校验。
2. **环境 Atlas B 建筑立面 ≤200×240 平涂**；若需更精致城镇，预批降到 512² mip。→ 资产管线约定。
3. **VFX ≤12 种**塞 Atlas C，ignite/shield 走 shader glow。→ 资产管线约定。

### 3.3 其他采纳项
- `musicVolume` 字段现已 additive 入 schema（默认 1.0），Comprehensive "separate channels" 解锁，MVP 保持 1.0。✅
- `audioVisualParity` 默认 true、作为安全地板不暴露给用户开关。✅

---

## 4. CONCERNS（非阻塞）

承接三人各自留的开放项，收口时归并：
1. **调平 spike (E8)** 必须在战斗数值锁定前完成——Sprint 1 仅落结构，数值全在 `content/` 占位（ADR-003）。⚠️ 已通过 Epic 依赖图约束。
2. **资产审计工具须在美术导入前就位**——Sprint 1 已含 E5 stub（`asset_audit.py`/`palette_validator.gd`），但需在首次资产提交前完成实装。⚠️
3. **音频未启动**——`AudioBus` 占位，AudioBus 事件名已在 UX §6.1 定义，待 Phase 6 阮和鸣填充。
4. **标题 clearance**——EMBERVEIL 为工作名，发布前过 IP clearance（Phase 1 已登记）。⚠️
5. **触屏重映射粒度**——UX §3.3 以"屏幕按钮分配/顺序"为触屏重映射面（chips 本身恒可点）。若后续要完整拖拽重定位需 HUD anchor 工作，标 Comprehensive。✅ 当前 MVP 足够。

---

## 5. 已知风险与缓解

| 风险 | 缓解 |
|------|------|
| Web/HTML5 预算静默突破 | `asset_audit.py` + `palette_validator.gd` 入 CI，超限 fail build（E5） |
| 确定性纪律松懈 | `combat/`+`battle/` lint 禁全局 RNG（E3） |
| 调平未定 → 不好玩 | E8 spike 在锁数值前完成；Phase 5 烟雾 + Phase 6 playtest |
| 设置/存档 schema 漂移 | 3.1 决策锁定存储模型；save serializer 单点 |
| 单存档误覆盖 | New Run 二次确认 + 仅安全节点写盘（S6） |

---

## 6. Sprint 1 放行建议

**范围**（程基岩草案，主理人确认）：checklist A/B/C/D ⛔ + G smoke。
- E1 脚手架 → E2 autoloads（含 3.1 设置存储模型）→ E4 存档读写 → E3 战斗 FSM（结构+确定性+5命令）→ E7 测试 harness + CI → E5/E6 审计/数据 stub。
- **退出标准**：A/B/C/D ⛔ 全绿、G smoke 过、CI 门（godot headless + 资产审计 + 调色板校验 + content-lint + RNG lint）绿、IP gate 过。
- **推迟**：S1/S3/S4/S5 功能 UI（Town/Dungeon/Codex 施法/Barracks）、L2–L5、E8 数值锁定（Sprint 2+）。

**可选垂直切片验证**：Sprint 1 退出后，建议做一次"Boot→Title→Town→Dungeon→Combat→win→safe-node Save"可玩性走查，确认核心循环"好玩"再扩功能 UI。

---

## 7. 决议

Phase 4 预制作 **PASS（附条件）**。放行进入 **Sprint 1 实现**（制作 Phase 起点）。主理人决策 3.1/3.2/3.3 由程基岩在 E2/E5 落实；CONCERNS 1–5 有负责人与阶段归属。下一步：Sprint 1 执行（程基岩带队实现，quality-lead 在每冲刺做 QA 计划 + 烟雾测试，主理人收尾回顾）。
