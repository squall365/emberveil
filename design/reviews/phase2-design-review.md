# EMBERVEIL — Phase 2 设计评审门控 (Design Review Gate)

> 评审强度: FULL · 评审人: 主理人（游承峰）· 日期: 2026-07-26
> 评审对象: `design/gdd/`（index + 6 系统 GDD：party-jobs / combat / elements / progression / world-nodes / save-load）

## 判定: ✅ PASS（附条件）

六份 GDD + 索引齐全、统一八节模板、跨系统引用已抽查核验自洽、原创 IP 合规。放行进 Phase 3，条件：(a) 数值平衡 spike 在落地前完成；(b) 下列主理人决策已采纳。

## 一致性核验（抽查）
| 检查项 | 结果 |
|---|---|
| 元素枚举 `Ember/Frost/Storm/Stone/Gale/Lumen/Umbra` 单一真相源（elements §2），全系统引用一致 | ✅ |
| 亲和矩阵 强 1.5 / 弱 0.67 / 中 1.0（elements §2 定义，combat §2 引用完全一致） | ✅ |
| 共享 Ward Codex（Set + resonance Map）定义与消费一致（combat/elements/world/progression/save-load） | ✅ |
| 元素 hex 与美术圣经 §2.3 一致 | ✅ |
| 对称 7 循环亲和 → 无主导策略（设计红线） | ✅ |

## 设计理论回看
- 5 支柱 / MDA / SDT（自主·胜任·关联）/ 心流 均被各系统服务；无主导策略。✅

## 主理人决策（Open Decisions 落定）
1. **共享 Ward Codex（队伍级）+ 每英雄 aptitude 门控 + 每英雄 MP** — 采纳（具体系数留调平 spike）。
2. **组队规则** — 采纳"每职业最多 1 个"，防 4×Channeler 主导组合。⚠️ 这轻微牺牲 Compose/Autonomy 自由度；若你想允许像经典 FF1 那样同职业多份，说一声我改。
3. **存档** — MVP 单本地槽（+ New Run 二次确认）。
4. **地牢长度** — 4 层。
5. **数值平衡** — 指定 design + engineering 在落地前做调平 spike 锁定初值。
6. **L2–L5**（转职/大地图/Driftwing/剧情/后日谈）— 维持 MVP 外，标注"后续"不展开。

## CONCERNS（非阻塞）
1. 数值为初稿，需调平 spike（见决策 5）— Phase 3 可先搭架构/脚手架，但实现锁数值前必须调平。
2. 状态效果集 MVP 极简（Slow/Guard/Mark）；扩容留 L2。
3. 音频方向未启动（阮和鸣待 Phase 4 / Phase 6 介入）。

## 已知风险与缓解
| 风险 | 缓解 |
|---|---|
| 数值失衡导致不好玩 | 调平 spike（design+engineering）在 Phase 3 实现锁前完成；Phase 5 烟雾测试 + Phase 6 Playtest 验证 |
| 组队限制伤自由度 | 已采纳 max-1-per-job；若反馈需更自由可回退 |
| 单存档误覆盖 | New Run 二次确认；仅安全节点写盘 |
| 跨 Phase 3 架构漂移 | Phase 3 架构评审门控校验 ADR 与 GDD 契约一致 |

## 决议
Phase 2 PASS。进入 **Phase 3 · 技术搭建**：engineering-lead（程基岩）出主架构 + ≥3 ADR + 架构评审；art-director（林绘澄）出可访问性分级（Basic/Standard/Comprehensive）。
