extends Node
# class_name ElementRegistry
# 7-element affinity ring (GDD §2). Symmetric cycle, strong=1.5 / weak=0.67 / neutral=1.0.
# Exposed as an autoload singleton; tests call ElementRegistry.affinity(...) on the instance.
# Cycle (strong direction): Ember▸Frost▸Storm▸Stone▸Gale▸Lumen▸Umbra▸Ember.
# Design red line: each element is strong vs EXACTLY one other (no dominant element).

const CYCLE := ["Ember", "Frost", "Storm", "Stone", "Gale", "Lumen", "Umbra"]
const ALL := CYCLE
const STRONG_MULT := 1.5
const WEAK_MULT := 0.67
const NEUTRAL_MULT := 1.0

func strong_vs(e: String) -> String:
	var i := CYCLE.find(e)
	if i < 0:
		return e
	return CYCLE[(i + 1) % CYCLE.size()]

func weak_vs(e: String) -> String:
	var i := CYCLE.find(e)
	if i < 0:
		return e
	return CYCLE[(i - 1 + CYCLE.size()) % CYCLE.size()]

func affinity(a: String, b: String) -> float:
	if a == b:
		return NEUTRAL_MULT
	if b == strong_vs(a):
		return STRONG_MULT
	if b == weak_vs(a):
		return WEAK_MULT
	return NEUTRAL_MULT
