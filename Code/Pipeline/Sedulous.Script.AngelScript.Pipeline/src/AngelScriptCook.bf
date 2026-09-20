using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Pipeline;
using Sedulous.Script.Resource;

namespace Sedulous.Script.AngelScript.Pipeline;

/// The AngelScript cook: compiles the source in a cook owned runtime bound to the surface
/// the host supplies, finds the class, harvests it.
///
/// The surface is the HOST's: a cook checking game scripts binds the runtime surface, so a
/// script reaching a pipeline or editor type fails here rather than in a player. Anything
/// AngelScript sees lives in the backend; this only drives it.
class AngelScriptCook : IScriptLanguageCook
{
	public const String cExtension = "as";

	/// BORROWED: the host owns the surface for the cook's life.
	private ScriptSurface mSurface;

	public this(ScriptSurface surface)
	{
		mSurface = surface;
	}

	public int32 CookVersion => 1;

	public void NewAssetTemplate(ScriptTier tier, String outSource)
	{
		switch (tier)
		{
		case .Level:
			outSource.Append("""
				// The scene's own script: set it on the scene's Script settings. One instance
				// per scene, `scene` filled in by the engine; the handlers run by their names
				// while the scene simulates. Print, Random, Math and the facades on `scene`
				// (scene.Physics, scene.Audio, scene.Scripts, ...) are visible globally.
				class Level
				{
					Scene@ scene;

					void onStart() { Print("Level started"); }
					void onUpdate(float dt) {}
					void onFixedUpdate(float dt) {}
					void onStop() {}
				}

				""");
		case .Game:
			outSource.Append("""
				// The run's orchestrator: the reserved class `Game`, one per run. `Run` is the
				// game instance: load the opening scene from launch(), Run.LoadScene(sceneId),
				// and use Run.Emit for run wide events; on<Event> handlers receive them.
				class Game
				{
					void launch() { Print("Game launched"); }
					void update(float dt) {}
					void exit() {}
				}

				""");
		case .Behavior:
			outSource.Append("""
				// A behaviour: attach it to an entity through a Script component. Public fields of
				// the authored kinds are its properties; `self` and `scene` are filled in by the
				// engine; `on` handlers run by their names.
				class NewBehavior
				{
					Entity self;
					Scene@ scene;
					float speed = 1.0f;

					void onStart() {}
					void onUpdate(float dt) {}
				}

				""");
		}
	}

	public bool Cook(StringView source, StringView sourceName, StringView className, ScriptClassSource outRecord, List<String> problems)
	{
		let runtime = scope AngelScriptRuntime();
		runtime.Bind(mSurface);
		ClearAndDeleteItems!(runtime.Problems);

		const String cModule = "cook";
		let ok = runtime.Compile(cModule, sourceName, source);
		for (let p in runtime.Problems)
			problems.Add(new String(p));
		if (!ok)
			return false;

		let name = scope String(className);
		if (name.IsEmpty)
		{
			// The first class the module declares, or a utility module with none.
			if (!FirstClass(source, name))
			{
				outRecord.ClassName.Clear();
				ClearAndDeleteItems!(outRecord.Properties);
				ClearAndDeleteItems!(outRecord.Handlers);
				outRecord.UsesCoroutines = source.Contains("startCoroutine");
				return true;
			}
		}
		outRecord.ClassName.Set(name);
		if (!ScriptHarvest.Harvest(runtime, cModule, name, outRecord))
		{
			problems.Add(new String(scope $"{sourceName}: no class '{name}' in the source"));
			return false;
		}
		return true;
	}

	/// The first top level `class Name` in the source, comments aside.
	private static bool FirstClass(StringView source, String outName)
	{
		let stripped = StripComments(source, .. scope .());
		int depth = 0;
		int i = 0;
		while (i < stripped.Length)
		{
			let c = stripped[i];
			if (c == '{') depth++;
			else if (c == '}') depth--;
			else if ((depth == 0) && stripped.Substring(i).StartsWith("class") && ((i == 0) || !stripped[i - 1].IsLetterOrDigit))
			{
				int j = i + 5;
				while ((j < stripped.Length) && stripped[j].IsWhiteSpace) j++;
				int start = j;
				while ((j < stripped.Length) && (stripped[j].IsLetterOrDigit || (stripped[j] == '_'))) j++;
				if (j > start)
				{
					outName.Set(stripped.Substring(start, j - start));
					return true;
				}
			}
			i++;
		}
		return false;
	}

	private static void StripComments(StringView source, String outStripped)
	{
		int i = 0;
		while (i < source.Length)
		{
			if ((i + 1 < source.Length) && (source[i] == '/') && (source[i + 1] == '/'))
			{
				while ((i < source.Length) && (source[i] != '\n')) i++;
				continue;
			}
			if ((i + 1 < source.Length) && (source[i] == '/') && (source[i + 1] == '*'))
			{
				i += 2;
				while ((i + 1 < source.Length) && !((source[i] == '*') && (source[i + 1] == '/'))) i++;
				i += 2;
				continue;
			}
			if (source[i] == '"')
			{
				outStripped.Append(' ');
				i++;
				while ((i < source.Length) && (source[i] != '"')) { if (source[i] == '\\') i++; i++; }
				i++;
				continue;
			}
			outStripped.Append(source[i]);
			i++;
		}
	}

	/// Registers this cook for `.as`, with the surface the host cooks against.
	public static void Register(ScriptSurface surface)
	{
		ScriptLanguageCooks.Register(AngelScriptBackend.cLanguage, cExtension, new AngelScriptCook(surface));
	}
}
