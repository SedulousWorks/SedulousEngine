using System;
using System.Collections;
using System.Reflection;
using Sedulous.Json;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Gameplay;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Play;

/// What the PIE probes read of a game's native code while it runs: a field of its Game, or of
/// a scene's active Level, found by name through reflection, public or private, and written as
/// entity_inspect writes a field (FieldJson: an enum by name, an entity reference or an asset as
/// its guid). [Game] and [Level] reflect a class's instance fields, the private ones included,
/// which is what lets a probe reach runtime state the inspector never shows.
static class NativeGameFields
{
	/// The running game's class name, appended to `outName`; false for no game.
	public static bool GameTypeName(IGameHooks game, String outName)
	{
		if (game == null)
			return false;
		((Object)game).GetType().GetName(outName);
		return true;
	}

	/// `path` on the running game: a field of its class, then keys and indices inside it
	/// ("mSpawn.y"). OWNED; null with the reason in `outError`.
	public static JsonValue GameField(IGameHooks game, StringView path, String outError)
	{
		if (game == null)
		{
			outError.Append("no native game runs");
			return null;
		}
		let segments = Segments(path, .. scope .());
		let owner = scope String("the game '");
		GameTypeName(game, owner);
		owner.Append('\'');
		return ObjectField((Object)game, path, segments, 0, owner, outError);
	}

	/// `path` on the scene's active level: "<field>" while one level is active, or
	/// "<Level>.<field>", the level named by its class name or its level id (which may hold
	/// dots), then keys and indices inside. OWNED; null with the reason in `outError`, and null
	/// with `outError` left EMPTY when the scene has no native level active (no scene, or none
	/// turned on), which is the caller's cue to read the scene's level script instead.
	public static JsonValue LevelField(Sedulous.Scene.Scene scene, StringView path, String outError)
	{
		if (scene == null)
			return null;
		let levels = scope List<Level>();
		Level active = null;
		int activeCount = 0;
		for (let system in scene.Systems)
		{
			if (let level = system as Level)
			{
				levels.Add(level);
				if (level.Active)
				{
					active = level;
					activeCount++;
				}
			}
		}
		if (activeCount == 0)
			return null;

		let segments = Segments(path, .. scope .());
		// Named: the longest leading run of segments that names one of the scene's levels.
		let qualifier = scope String();
		for (int k = segments.Count - 1; k >= 1; k--)
		{
			qualifier.Clear();
			for (int s < k)
			{
				if (s > 0)
					qualifier.Append('.');
				qualifier.Append(segments[s]);
			}
			for (let level in levels)
			{
				if (!NamesLevel(level, qualifier))
					continue;
				let owner = LevelOwner(level, .. scope .());
				if (!level.Active)
				{
					outError.AppendF("{} is not active in scene '{}'", owner, scene.Name);
					return null;
				}
				return ObjectField(level, path, segments, k, owner, outError);
			}
		}
		if (activeCount > 1)
		{
			let names = scope String();
			StringView first = default;
			for (let level in levels)
			{
				if (!level.Active)
					continue;
				let name = level.GetType().GetName(.. scope:: .());
				if (first.IsEmpty)
					first = name;
				if (!names.IsEmpty)
					names.Append(", ");
				names.Append(name);
			}
			outError.AppendF("{} levels are active in scene '{}' ({}): name one, as {}.{}", activeCount, scene.Name, names, first, path);
			return null;
		}
		return ObjectField(active, path, segments, 0, LevelOwner(active, .. scope .()), outError);
	}

	/// The instance field `segments[first]` of `obj`, public or private, then the keys and
	/// indices after it. OWNED; null with the reason, naming `owner` and listing its fields.
	public static JsonValue ObjectField(Object obj, StringView path, List<StringView> segments, int first, StringView owner, String outError)
	{
		let type = obj.GetType();
		FieldInfo field = default;
		if (!(type.GetField(scope String(segments[first])) case .Ok(out field)) || field.IsStatic)
		{
			let known = scope String();
			for (let candidate in type.GetFields(.Instance | .Public | .NonPublic))
			{
				if (!known.IsEmpty)
					known.Append(", ");
				known.Append(candidate.Name);
			}
			outError.AppendF("{} has no field '{}' (its fields: {})", owner, segments[first], known);
			return null;
		}
		let root = FieldJson.ValueJson(field.FieldType, (uint8*)Internal.UnsafeCastToPtr(obj) + field.MemberOffset);
		return PieRunTool.Inside(root, segments, first + 1, path, owner, outError);
	}

	/// Whether `name` is the level's class name, full name or level id.
	private static bool NamesLevel(Level level, StringView name)
	{
		let type = level.GetType();
		return (type.GetName(.. scope .()) == name) || (type.GetFullName(.. scope .()) == name) || (level.SettingsId == name);
	}

	private static void LevelOwner(Level level, String outText)
	{
		outText.Append("level '");
		level.GetType().GetName(outText);
		outText.Append('\'');
	}

	private static void Segments(StringView path, List<StringView> outSegments)
	{
		for (let part in path.Split('.'))
			outSegments.Add(part);
	}
}
