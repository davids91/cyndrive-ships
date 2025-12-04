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

### Input data records -- motion
Motion related data is stored on given intervals, and can ship travel course can be corrected based on it.
The structure of a motion entry is as follows:
`{ "transform": Tranform2D, "velocity": Vector2, "intent_force": Vector2, "internal_force": Vector2 }`

## Input data records -- transforms
Input data is stored of the monitored entitys `Transform2D`, in every `_physics_process` of the recorded, in millsecond resolution.

## Input data records -- recording
One recording contains both the actions, motion and important characteristics in a Dictionary. 
e.g. an empty record: `{ "actions" : {}, "motion" :  {} }`
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

# Temporal checklist - Battle Presence
In order to introduce a new entity into the temporal records the following steps are to be followed:
- Add either a `CharacterBody2D` or `RigidBody2D` to the scene with the `battle_character.gd` or `battle_debris.gd` script attached respectively
- Insert a Node(2D) as a child with the name `temporal_recorder`, with the `temporal_recroder.gd` script attached
- (Optional) For `BattleDebris` objects, place the nodes under the `debris` node within the battle.
	- This will take care of points (A), (B) and (C) automatically
- (Optional) For `BattleCharacter` objects, place the nodes under the `combatants` node within the battle.
	- This will take care of points (A), (B) and (C) automatically
- (A)Ensure that the `start_recording` function is called at the start of the battle for the object
- (B)Ensure that the `reset` function of the `temporal_recorder` is being called at the end of the objects timeline
- (C)Ensure that the `respawn` function of the node is being called at the start of the objects timeline

# Temporal checklist - Persistent Presence
To introduce a character which replays a given set of recorded presence, the following steps need to be followed.
(The function `create_new_puppet` does the below steps)
- Add either a `CharacterBody2D` or `RigidBody2D` to the scene with the `battle_character.gd` or `battle_debris.gd` script attached respectively
- Insert a Node(2D) as a child with the name `replayer`, with the `temporal_recroder.gd` script attached
- Initialize the `replayer` with the stored moves
- Ensure the node functions `respawn`, `pause_control`, `resume_control` are called appropriately to battle `reset` and `rewind_started`, `rewind_stopped` signals
- Ensure the `replayer` functions `reset` and `start_replay` are called appropriately to battle timeline
