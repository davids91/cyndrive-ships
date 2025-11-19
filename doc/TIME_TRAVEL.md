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

## Input data records -- transforms
Input data is stored of the monitored entitys `Transform2D`, in every `_physics_process` of the recorded, in millsecond resolution.

## Input data records -- recording
One recording contains both the actions and the transforms in a Dictionary. 
e.g. an empty record: `{ "actions" : {}, "transforms" :  {} }`

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
