# Contributing

We use trunk-based development — push directly to main, no branches or PRs.

## Feature Flags

Production flags live in `feature_flags.json` (tracked in git). To override flags locally during development, create `feature_flags.dev.json` (gitignored) — it merges on top of the production config. Dev overrides are only applied when running in the Godot editor; exported builds always use production flags.

### Quick Start

1. Check `feature_flags.json` for available flags and their production defaults
2. To override locally, create `feature_flags.dev.json` with only the flags you want to change
3. Use `FeatureFlags.is_enabled("flag_name")` in code

### Dev Override Example

You only need to include flags you want to change:

```json
{
    "disable_ai": {
        "enabled": true,
        "description": "Disable all enemy AI - useful for testing weapons"
    }
}
```

### Usage in Code

```gdscript
if FeatureFlags.is_enabled("new_combat"):
    _new_combat_logic()
else:
    _old_combat_logic()
```

### Usage in Scenes

Add a `FeatureFlaggedNode` as a child of any node you want to conditionally include:

```
EnemyNode
  └── FeatureFlaggedNode (flag_name = "new_enemy_ai")
```

If the flag is disabled, the parent node is removed at runtime.

### Adding a New Flag

1. Add the flag to `feature_flags.json` with the desired production default
2. Commit the change so teammates have the flag

### Removing a Flag

Search for usages:

```bash
grep -r "is_enabled(\"flag_name\")" --include="*.gd" .
```
