extends SceneTree

## HeatStatus lives, rescue immunity and elimination.
##
## TIME. _initialize() runs start to finish inside a single call, so no frame
## ever ticks while these assertions run and nothing that decays on a timer
## decays on its own. That matters because a rescue now grants
## RESCUE_IMMUNITY_TIME seconds during which a tag simply does not land (see
## HeatStatus.RESCUE_IMMUNITY_TIME) - an earlier version of this file rescued and
## re-tagged on the next line, and every tag after the first rescue quietly did
## nothing. _advance() drives HeatStatus's own clock by hand instead, standing in
## for the seconds a real player would have spent running away.

var _f := 0
func _c(l, a, e) -> void:
	if a == e: print("  PASS  %s" % l)
	else:
		_f += 1
		print("  FAIL  %s  (got %s, expected %s)" % [l, a, e])


## Offline, _process() runs its whole body, so this decays rescue immunity and
## the burn timer exactly the way a real frame would.
func _advance(heat, seconds: float) -> void:
	heat._process(seconds)


## Two teammates channeling the same downed player. Each rescuer's own timer
## was always independent - what broke was the ONE progress bar on the downed
## body, which every rescuer writes to. It used to show whichever report came
## last, so with two rescuers it swung between two timers, and a rescuer
## letting go reported 0.0 and blanked it for the teammate still holding E.
## That looked exactly like the rescue restarting, and made players restart it.
func _run_shared_rescue_bar(tubig) -> void:
	# Peers 2 and 3 are both on top of this body. The bar reads the furthest.
	tubig._report_rescue_progress(2, 0.5, 3.0)
	_c("one rescuer's progress is shown",
		tubig._best_rescue_progress()[0], 0.5)

	tubig._report_rescue_progress(3, 0.2, 4.8)
	_c("a second, slower rescuer does not drag the bar back",
		tubig._best_rescue_progress()[0], 0.5)
	_c("the bar keeps the leading rescuer's countdown",
		tubig._best_rescue_progress()[1], 3.0)

	tubig._report_rescue_progress(3, 0.7, 1.8)
	_c("whoever pulls ahead takes the bar",
		tubig._best_rescue_progress()[0], 0.7)

	# The regression itself: one rescuer stepping away must not blank the bar
	# for the one still channeling.
	tubig._report_rescue_progress(3, 0.0, 0.0)
	_c("a rescuer letting go does not reset the other's bar",
		tubig._best_rescue_progress()[0], 0.5)

	tubig._report_rescue_progress(2, 0.0, 0.0)
	_c("the bar clears once nobody is channeling",
		tubig._best_rescue_progress()[0], 0.0)

	# A rescuer who vanishes without a final report - tagged, or dropped off
	# the network - has to age out rather than freezing the bar forever.
	tubig._report_rescue_progress(2, 0.4, 3.6)
	tubig._rescuers[2][2] = Time.get_ticks_msec() - tubig.RESCUER_STALE_MSEC - 1
	_c("a rescuer who went quiet is dropped",
		tubig._best_rescue_progress()[0], 0.0)
	_c("...and forgotten", tubig._rescuers.has(2), false)


func _initialize() -> void:
	print("HeatStatus lives/elimination tests")
	var tubig = load("res://game/arena/actors/tubig/tubig.tscn").instantiate()
	root.add_child(tubig)
	var heat = tubig.get_node("HeatStatus")

	_c("starts with 3 lives", heat.lives_left, 3)
	_c("starts NORMAL", heat.state, 0)

	# The return value is what the feed reads: HeatStatus announces a tag only
	# when one actually landed, so a claim the rules refuse has to report false
	# rather than silently doing nothing.
	_c("a tag that lands reports true", heat.ignite(), true)
	_c("tag 1 spends a life", heat.lives_left, 2)
	_c("tag 1 -> BURNING", heat.state, 1)

	_c("re-tag while burning reports false", heat.ignite(), false)
	_c("re-tag while burning is a no-op", heat.lives_left, 2)

	_c("a rescue that frees somebody reports true", heat.cool_fully(), true)
	_c("rescue does NOT refund a life", heat.lives_left, 2)
	_c("rescue -> NORMAL", heat.state, 0)
	_c("rescue grants immunity", heat.is_immune, true)
	_c("rescuing an already-free player reports false", heat.cool_fully(), false)

	# The Sili is usually still standing on the spot the burn had them rooted to,
	# so without this window a rescue and an instant re-tag are the same frame.
	_c("a tag inside the immunity window reports false", heat.ignite(), false)
	_c("a tag inside the immunity window costs no life", heat.lives_left, 2)
	_c("...and leaves them NORMAL", heat.state, 0)

	_advance(heat, heat.RESCUE_IMMUNITY_TIME + 0.1)
	_c("immunity expires", heat.is_immune, false)

	heat.ignite()
	_c("tag 2 spends a life", heat.lives_left, 1)
	heat.cool_fully()
	_advance(heat, heat.RESCUE_IMMUNITY_TIME + 0.1)

	heat.ignite()
	_c("tag 3 spends the last life", heat.lives_left, 0)
	_c("last life goes straight to DEAD", heat.state, 2)
	_c("is_dead", heat.is_dead(), true)

	_c("a dead player cannot be rescued", heat.cool_fully(), false)
	_c("...and stays DEAD", heat.state, 2)
	_c("a dead player cannot be re-tagged", heat.ignite(), false)
	_c("...and loses nothing further", heat.lives_left, 0)

	_run_shared_rescue_bar(tubig)

	print("")
	print("ALL TESTS PASSED" if _f == 0 else "%d FAILED" % _f)
	quit(1 if _f > 0 else 0)
