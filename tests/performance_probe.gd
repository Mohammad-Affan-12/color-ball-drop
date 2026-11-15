extends SceneTree

## Desktop synthetic workload: CPU timings and memory, not Android FPS claims.
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.test-user"))
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	game.save_path = "res://.test-user/performance.cfg"
	root.add_child(game)
	game.sfx.muted = true
	game.sfx.music_muted = true
	var rows: Array[Dictionary] = []
	for level in [1, 41, 61, 100]:
		game.load_level(level)
		var process_ms: Array[float] = []
		var physics_ms: Array[float] = []
		var controller: LevelController = game.current_level
		var step_index := 0
		var next_cut := 30
		for frame in range(360):
			await physics_frame
			if step_index < controller.solution_steps.size() and frame >= next_cut:
				var step: Dictionary = controller.solution_steps[step_index]
				game.slice_controller.simulate_swipe(step["from"], step["to"])
				step_index += 1
				if step_index < controller.solution_steps.size():
					next_cut += int(float(controller.solution_steps[step_index].get("delay", 0.2)) * 60)
			if frame > 30:
				process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
				physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
		process_ms.sort()
		physics_ms.sort()
		rows.append({"level": level, "process_p95_ms": process_ms[int(process_ms.size() * 0.95)], "physics_p95_ms": physics_ms[int(physics_ms.size() * 0.95)], "static_memory_mib": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, "objects": Performance.get_monitor(Performance.OBJECT_COUNT)})
	var output := FileAccess.open("res://docs/performance-desktop.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "mode": "synthetic headless fixed-fps workload; no mobile GPU/battery conclusion", "measurements": rows}, "\t"))
	print("PERFORMANCE PROBE: ", JSON.stringify(rows))
	game.queue_free()
	await process_frame
	quit()
