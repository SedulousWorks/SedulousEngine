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
	/// The surface's hash, worked out on first use: the surface is fixed for the cook's life.
	private uint64 mSurfaceHash = 0;
	private bool mHashed = false;
	/// The surface's revision the hash was taken at: a plugin's types joining or leaving moves it.
	private uint64 mHashedRevision = 0;

	public this(ScriptSurface surface)
	{
		mSurface = surface;
	}

	public int32 CookVersion => 1;

	public uint64 SurfaceHash
	{
		get
		{
			let revision = (mSurface != null) ? mSurface.Revision : 0;
			if (!mHashed || (revision != mHashedRevision))
			{
				mSurfaceHash = (mSurface != null) ? mSurface.RuntimeHash() : 0;
				mHashed = true;
				mHashedRevision = revision;
			}
			return mSurfaceHash;
		}
	}

	public void NewAssetTemplate(ScriptTier tier, StringView className, String outSource)
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
				// A behaviour: attach it to an entity through a Script component. An annotated
				// field, `[default, "description"]` in front of it, is a property the editor
				// shows and sets; `self` and `scene` are filled in by the engine; `on` handlers
				// run by their names.
				class {CLASSNAME}
				{
					Entity self;
					Scene@ scene;
					[1.0, "Units per second"] float speed;

					void onStart() {}
					void onUpdate(float dt) {}
				}

				""");
			outSource.Replace("{CLASSNAME}", className.IsEmpty ? "NewBehavior" : className);
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

		let name = scope String();
		if (!ChooseClass(source, sourceName, className, name, problems))
			return false;
		if (name.IsEmpty)
		{
			// A utility module: no class.
			outRecord.ClassName.Clear();
			ClearAndDeleteItems!(outRecord.Properties);
			ClearAndDeleteItems!(outRecord.Handlers);
			outRecord.UsesCoroutines = source.Contains("startCoroutine");
			return true;
		}
		outRecord.ClassName.Set(name);
		let harvestProblems = scope List<String>();
		defer { ClearAndDeleteItems(harvestProblems); }
		let harvested = ScriptHarvest.Harvest(runtime, cModule, name, outRecord, harvestProblems);
		for (let p in harvestProblems)
			problems.Add(new $"{sourceName}: {p}");
		return harvested;
	}

	/// Through the runtime's Check, so unlike Cook no global initializer runs.
	public bool Check(StringView source, StringView sourceName, StringView className, String outClassName, List<String> problems, Span<StringView> hidden)
	{
		let runtime = scope AngelScriptRuntime();
		runtime.Bind(mSurface, default, hidden);
		ClearAndDeleteItems!(runtime.Problems);

		let ok = runtime.Check(sourceName, source);
		for (let p in runtime.Problems)
			problems.Add(new String(p));
		outClassName.Clear();
		if (!ok)
			return false;
		return ChooseClass(source, sourceName, className, outClassName, problems);
	}

	/// The class `source` plays, by `className` (empty: the one named like `sourceName`'s
	/// file), into `outClass`; false with the problem when it declares several and none so named.
	private static bool ChooseClass(StringView source, StringView sourceName, StringView className, String outClass, List<String> problems)
	{
		let declared = scope List<String>();
		defer { ClearAndDeleteItems!(declared); }
		ScriptClasses.ListClasses(source, declared);
		let preferred = ScriptClasses.PreferredFor(className, sourceName, .. scope .());
		let problem = scope String();
		if (ScriptClasses.Choose(declared, preferred, outClass, problem))
			return true;
		problems.Add(new $"{sourceName}: {problem}");
		return false;
	}

	/// Registers this cook for `.as`, with the surface the host cooks against.
	public static void Register(ScriptSurface surface)
	{
		ScriptLanguageCooks.Register(AngelScriptBackend.cLanguage, cExtension, new AngelScriptCook(surface));
	}
}
