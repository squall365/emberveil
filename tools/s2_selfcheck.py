#!/usr/bin/env python3
# S2-IMPL-02 static self-check (no Godot required).
# Verifies: required files exist, key symbols/contracts are present, the deterministic
# battle-seed formula string is present, content cross-references resolve, and each .gd has
# balanced brackets (heuristic GDScript syntax sanity).

import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# (path, [required substrings]) -- all must be present.
CHECKS = [
    ("src/world/town_controller.gd", [
        "class_name TownController", "func setup(", "func _map_move(", "func _map_accept(",
        "func _map_cancel(", "Rest (Inn)", "decision 2.8", "func _save_at_shrine(", "WorldDirector.enter_dungeon(",
    ]),
    ("src/world/dungeon_controller.gd", [
        "class_name DungeonController", "func setup(", "func _start_battle(",
        "func _on_battle_resolved(", "func _battle_seed(", "rng.seed(", "get_tree().get_root().add_child(battle)",
        "func _move_cursor(", "GAP-2", "func _on_stone_tapped(", "decision 2.4",
        "func _reload_last_safe_save(", "WorldDirector.return_to_town(", "BattleQueue.initiative_order(",
        "func _load_json(", "record_ally_outcome(", "apply_battle_xp(", "sync_to_run_state(",
    ]),
    ("src/battle/combat_controller.gd", [
        "class_name CombatController", "func setup(", "BattleResolver.resolve_action(",
        "EnemyAI.choose_action(", "EventBus.battle_event.emit(", "queue_free()", "func _finish(",
    ]),
    ("src/battle/battle_queue.gd", [
        "class_name BattleQueue", "static func initiative_order(", "func next_actor(", "func mark_acted(",
        "sort_custom", "SPD",
    ]),
    ("src/world/map_input.gd", [
        "class_name MapInput", "func _unhandled_input(", "ui_accept", "ui_cancel", "_owner()._map_move(",
    ]),
    ("scenes/town/Town.tscn", ["Town", "town_controller.gd", "map_input.gd", "Button", "Rest (Inn)"]),
    ("scenes/dungeon/Dungeon.tscn", ["Dungeon", "dungeon_controller.gd", "map_input.gd", "VBoxContainer", "Info"]),
    ("scenes/world/World.tscn", ["World", "WorldMount"]),
    ("scenes/battle/Battle.tscn", ["Battle", "combat_controller.gd"]),
    ("content/encounters.json", ["sw_f0_combat", "sw_f1_combat", "sw_f2_combat", "sw_f3_combat", "sw_f3_boss"]),
    ("tests/integration/test_return_to_town_safe_save.gd", [
        "extends GutTest", "func test_town_entry_is_safe_node", "func test_floor_clear_persists_progress",
        "WorldDirector.return_to_town(",
    ]),
    # GAP-fix regression guards on existing autoloads (already present in repo state).
    ("src/autoloads/scene_manager.gd", ["func get_run_state(", "func get_world_state("]),
    ("src/autoloads/world_director.gd", ["func _swap_world_child(", "func enter_dungeon(", "func return_to_town("]),
    ("src/autoloads/party_manager.gd", ["func build_party_combatants(", "func sync_to_run_state("]),
    ("src/autoloads/progression_manager.gd", ["func apply_battle_xp(", "xp_for_level"]),
    ("src/combat/battle_resolver.gd", [
        'match atype', '"Attack"', '"Skill"', '"Elemental"', '"Defend"', '"Item"', '"Run"',
    ]),
]

# Hard contract #6: deterministic seed formula must appear literally in the dungeon controller.
SEED_FORMULA = [
    ("src/world/dungeon_controller.gd", "floor_idx * 100"),
    ("src/world/dungeon_controller.gd", "room_idx * 10"),
    ("src/world/dungeon_controller.gd", "(1 if is_boss else 0)"),
]


def read(p):
    with open(os.path.join(ROOT, p), "r", encoding="utf-8") as f:
        return f.read()


def bracket_balance(src, opens, closes):
    # Skip string literals so message text containing brackets is not miscounted.
    stack = []
    pairs = dict(zip(opens, closes))
    in_str = None  # None | '"' | "'"
    i = 0
    while i < len(src):
        ch = src[i]
        if in_str is not None:
            if ch == "\\":  # skip escaped char
                i += 2
                continue
            if ch == in_str:
                in_str = None
            i += 1
            continue
        if ch == '#':  # GDScript line comment: ignore to EOL
            while i < len(src) and src[i] != '\n':
                i += 1
            continue
        if ch == '"' or ch == "'":
            in_str = ch
            i += 1
            continue
        if ch in opens:
            stack.append(ch)
        elif ch in closes:
            if not stack or pairs[stack.pop()] != ch:
                return False
        i += 1
    return len(stack) == 0


def check_content_xref():
    """encounters.json ids must cover dungeons.json encounterIds; enemies.json must supply them."""
    problems = []
    dungeons = json.loads(read("content/dungeons.json"))
    encounters = json.loads(read("content/encounters.json"))
    enemies = json.loads(read("content/enemies.json"))

    enc_ids = {e["id"] for e in encounters}
    enemy_ids = {e["id"] for e in enemies}
    all_enc_ids = set()
    boss_present = False
    for d in dungeons:
        for f in d.get("floors", []):
            for r in f.get("rooms", []):
                eid = r.get("encounterId", "")
                if eid:
                    all_enc_ids.add(eid)
                if r.get("type") == "boss":
                    boss_present = True
                    if not r.get("reward", {}).get("sigilId"):
                        problems.append("boss room missing sigilId reward (Stone Sigil)")
    missing_enc = all_enc_ids - enc_ids
    if missing_enc:
        problems.append("dungeons.json references undefined encounters: %s" % sorted(missing_enc))
    # every encounter's enemies must exist, and boss flagged isBoss
    for e in encounters:
        for eid in e.get("enemyIds", []):
            if eid not in enemy_ids:
                problems.append("encounter %s references missing enemy %s" % (e["id"], eid))
        if e.get("isBoss") and e["id"] != "sw_f3_boss":
            problems.append("non-final encounter flagged isBoss: %s" % e["id"])
    # xpValue present on all enemies
    for e in enemies:
        if "xpValue" not in e:
            problems.append("enemy %s missing xpValue" % e["id"])
    if not boss_present:
        problems.append("no boss room in dungeons.json")
    if "sigil_twisted_warden" not in enemy_ids:
        problems.append("boss enemy sigil_twisted_warden missing")
    return problems


def main():
    results = []
    for path, subs in CHECKS:
        try:
            src = read(path)
        except FileNotFoundError:
            results.append((path, "MISSING FILE", False))
            continue
        missing = [s for s in subs if s not in src]
        ok = not missing
        results.append((path, "" if ok else "missing: " + ", ".join(missing), ok))

    for path, sub in SEED_FORMULA:
        try:
            src = read(path)
        except FileNotFoundError:
            results.append((path + "::seed", "MISSING FILE", False))
            continue
        ok = sub in src
        results.append((path + " :: " + sub, "" if ok else "seed formula token absent", ok))

    # bracket sanity for all .gd under src/ and tests/
    bracket_issues = []
    for base in ("src", "tests"):
        for root, _, files in os.walk(os.path.join(ROOT, base)):
            for fn in files:
                if fn.endswith(".gd"):
                    p = os.path.join(root, fn)
                    rel = os.path.relpath(p, ROOT)
                    src = open(p, encoding="utf-8").read()
                    if not bracket_balance(src, "([{", ")]}"):
                        bracket_issues.append(rel)

    xref = check_content_xref()

    passed = sum(1 for _, _, ok in results if ok)
    total = len(results)
    print("=" * 70)
    print("S2-IMPL-02 STATIC SELF-CHECK")
    print("=" * 70)
    for path, msg, ok in results:
        print(("[PASS] " if ok else "[FAIL] ") + path + ("" if ok else "  -> " + msg))
    print("-" * 70)
    print("Bracket balance (.gd): " + ("OK" if not bracket_issues else "ISSUES: " + ", ".join(bracket_issues)))
    print("Content cross-ref: " + ("OK" if not xref else "ISSUES:"))
    for x in xref:
        print("   - " + x)
    print("-" * 70)
    print("Symbol checks: %d/%d passed" % (passed, total))
    ok_all = passed == total and not bracket_issues and not xref
    print("OVERALL: " + ("PASS" if ok_all else "ATTENTION NEEDED"))
    print("=" * 70)
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main())
