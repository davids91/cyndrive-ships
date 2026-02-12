# Time travel
Time travel is achieved through recording the actions and positions of "past selves".

# Recording moves
The game stores moves about any controllable entity, may it be a turret, enemy ship or the player.
There are two kinds of data stored about a controllable entity, input data and motion data.
For an entity to be monitored, it needs to have a child called `move_recorder`,
with the `scripts/recordable.gd` script attached to it.
A recording session starts when `start_recording` is called within the `move recorder`,
where the recorder is initialized, previous records are discarded and start times are set.
Start times need to be set because the recorder stores entries based on a time interval relative to
its stored starting point.

## Input data records -- actions
Input data is stored whenever an action is processed, in microseconds resolution. 
Actions are created from InputEvents from `_unhandled_input` through the global class `BattleInputMap`.
Action structure is documented in the class, it contains user movement and action intention.

### Input data records -- temporal_snapshot
The sotred information includes position, velocity, health or any information(acquired state) describing the object.
The above is stored on given intervals. Any objects state can be fully recreated based on a single temporal record.

## Input data records -- recording
One recording contains both the actions, motion and important characteristics in a Dictionary. 
e.g. an empty record: `{ "actions" : {}, "temporal_snapshots" :  {} }`
Actions are stored in microsecrond resolution, but sparsely, while other characteristics are stored in milliseconds resolution.
The latter containts forces, velocities, health etc...
While these are not neccesarily relevant to motion, they are kept in under the same key to hint on the frequency of storage.

# Replaying records
To initialize an entity to be replayed, it is to have a child node named `replayer`
with the `scripts/replayable.gd` attached, and its relevant member variables initialized.
The members to initialize can be found in the `init_before_ready` section. 
Once the replayer is initialized the functions `start_replay` and `stop_replay` handle the replay flow.
The replays are handled from the `_process` function.
Replay prioritizes input actions. If an input action is within the current estimated frame time interval,
the replayer will pause the `_process` function, and then apply the input.
Should there be no input corrections within the current frame, replay checks if the next stored position
is "close enough" to the next `_physics_process`, and if that's the case, a position correction is also applied.

# Temporal record checklist
To integrate an object into the time traveling mechanic:
- Provide function: `func get_snapshot() -> Dictionary: ...`
- Provide function: `func correct_temporal_state(snapshot: Dictionary, over_time_msec: float) -> void: ...`
- Provide function: ``
- To at least have the object take part in time rewind:
	- Insert a Node(2D) as a child with the name `temporal_recorder`, with the `temporal_recroder.gd` script attached
- To introduce a character which replays a given set of recorded presence, the following steps need to be followed:
	- The function `create_new_puppet` within `dev_room_battle.tscn` does the exact below steps
	- Add a clone of the battle character which already has the recorder set up (described in previous steps)
	- Insert a Node(2D) as a child with the name `replayer`, with the `temporal_recroder.gd` script attached
	- Initialize the `replayer` with the stored moves(set member variables where it's indicated)
	- Ensure the node functions `respawn`, `pause_control`, `resume_control` are called appropriately to battle `reset` and `rewind_started`, `rewind_stopped` signals
	- Ensure the `replayer` functions `reset` and `start_replay` are called appropriately to battle timeline
