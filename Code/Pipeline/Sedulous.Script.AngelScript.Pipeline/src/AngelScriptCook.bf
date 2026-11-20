using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Profiler; // a check's stages
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
	/// The runtime the checks with nothing hidden share.
	private CachedCheckRuntime mChecks ~ delete _;

	public this(ScriptSurface surface)
	{
		mSurface = surface;
		mChecks = new .(surface, new () => new AngelScriptRuntime());
	}

	public uint32 CheckRuntimeBuildCount => mChecks.BuildCount;

	public void PrepareCheck()
	{
		mChecks.Prepare();
		// A worker's thread local data, freed while its runtime's engine lives on for the checks.
		AngelScriptRuntime.ThreadCleanup();
	}

	public bool DescribeApi(ScriptSurface surface, List<ScriptApiType> outTypes)
	{
		if (surface != mSurface)
			return false;
		mChecks.DescribeApi(outTypes);
		return true;
	}

	public bool Declarations(String outFileName, String outText)
	{
		let written = mChecks.Declarations(outFileName, outText);
		// Called on a worker (the editor's Code folder tooling), which may have made the runtime:
		// its thread local data, freed while the runtime's engine lives on for the checks.
		AngelScriptRuntime.ThreadCleanup();
		return written;
	}

	public StringView DeclarationsFile => AngelScriptRuntime.DeclarationsFile;

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
				// A scene behavior, one per scene: set it on the scene's Script settings.
				// `scene` is filled in by the engine; the handlers run by their names while the
				// scene simulates. Print, Random, Math and the facades on `scene`
				// (scene.Physics, scene.Audio, scene.Scripts, ...) are visible globally.
				class {CLASSNAME} : SceneBehavior
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
				// A run behavior, the game's orchestrator, one per run: set it as the project's.
				// `Run` is the application run: load the opening scene from onStart(),
				// Run.LoadScene(sceneId), and use Run.Emit for run wide events; on<Event>
				// handlers receive them.
				class {CLASSNAME} : RunBehavior
				{
					void onStart() { Print("Game launched"); }
					void onUpdate(float dt) {}
					void onStop() {}
				}

				""");
		case .Behavior:
			outSource.Append("""
				// A behaviour: attach it to an entity through a Script component. An annotated
				// field, `[default, "description"]` in front of it, is a property the editor
				// shows and sets; `self` and `scene` are filled in by the engine; `on` handlers
				// run by their names.
				class {CLASSNAME} : EntityBehavior
				{
					Entity self;
					Scene@ scene;
					[1.0, "Units per second"] float speed;

					void onStart() {}
					void onUpdate(float dt) {}
				}

				""");
		}
		outSource.Replace("{CLASSNAME}", className.IsEmpty ? "NewBehavior" : className);
	}

	public void ListIncludes(StringView source, List<String> outPaths) => AngelScriptRuntime.IncludesOf(source, outPaths);

	public bool Cook(StringView source, StringView sourceName, ScriptClassSource outRecord, List<String> problems,
		IScriptIncludeReader includes = null)
	{
		// The files it includes, compiled beside it and recorded for a run that compiles it again.
		ClearAndDeleteItems!(outRecord.Includes);
		if (!ScriptIncludes.Gather(this, sourceName, source, includes, outRecord.Includes, problems))
			return false;
		let sections = scope List<ScriptSection>();
		sections.Add(.(sourceName, source));
		for (let included in outRecord.Includes)
			sections.Add(.(included.Path, included.Source));

		AngelScriptRuntime runtime;
		using (ProfileScope("Script.Cook.MakeEngine"))
			runtime = scope:: AngelScriptRuntime();
		using (ProfileScope("Script.Cook.RegisterApi"))
			runtime.Bind(mSurface);
		ClearAndDeleteItems!(runtime.Problems);

		const String cModule = "cook";
		// Compiled without running: the script's global initializers are the game's to run when
		// it loads the script, under the call budget.
		bool ok;
		using (ProfileScope("Script.Cook.Compile"))
			ok = runtime.CompileModule(cModule, sections, false);
		for (let p in runtime.Problems)
			problems.Add(new String(p));
		if (!ok)
			return false;

		// The class it plays is the one deriving from a kind, read from the classes this file
		// declares as compiled (an included file's classes are its own file's).
		let declared = scope List<String>();
		defer { ClearAndDeleteItems!(declared); }
		ScriptClasses.ListClasses(source, declared);
		let kinds = scope List<BehaviorKind>();
		for (let declaredClass in declared)
			kinds.Add(runtime.KindOf(cModule, declaredClass));
		let name = scope String();
		BehaviorKind kind;
		if (!ChooseClass(sourceName, declared, kinds, name, out kind, problems))
			return false;
		if (name.IsEmpty)
		{
			// A utility module: no class.
			outRecord.ClassName.Clear();
			ClearAndDeleteItems!(outRecord.Properties);
			ClearAndDeleteItems!(outRecord.Handlers);
			outRecord.UsesCoroutines = source.Contains("startCoroutine");
			outRecord.Kind = .None;
			return true;
		}
		outRecord.ClassName.Set(name);
		outRecord.Kind = kind;
		let harvestProblems = scope List<String>();
		defer { ClearAndDeleteItems(harvestProblems); }
		let harvested = ScriptHarvest.Harvest(runtime, cModule, name, outRecord, harvestProblems);
		for (let p in harvestProblems)
			problems.Add(new $"{sourceName}: {p}");
		return harvested;
	}

	/// Through the runtime's Check, which compiles as Cook does and keeps no module.
	public bool Check(StringView source, StringView sourceName, String outClassName, List<String> problems, Span<StringView> hidden,
		IScriptIncludeReader includes = null)
	{
		outClassName.Clear();
		let found = scope List<ScriptIncludedSource>();
		defer { ClearAndDeleteItems!(found); }
		if (!ScriptIncludes.Gather(this, sourceName, source, includes, found, problems))
			return false;
		let sections = scope List<ScriptSection>();
		for (let included in found)
			sections.Add(.(included.Path, included.Source));
		let declared = scope List<String>();
		defer { ClearAndDeleteItems!(declared); }
		ScriptClasses.ListClasses(source, declared);
		let kinds = scope List<BehaviorKind>();
		BehaviorKind kind;
		if (hidden.IsEmpty)
		{
			// The whole surface: the shared runtime, the script in a module of its own, discarded
			// after.
			bool ok = false;
			let ran = mChecks.Run(scope [&] (runtime) =>
				{
					using (ProfileScope("Script.Cook.Compile"))
						ok = runtime.Check(sourceName, source, sections, declared, kinds);
					for (let p in runtime.Problems)
						problems.Add(new String(p));
					ClearAndDeleteItems!(runtime.Problems);
					return true;
				});
			if (!ran)
				problems.Add(new $"{sourceName}: no AngelScript runtime to check it in");
			if (!ok)
				return false;
			return ChooseClass(sourceName, declared, kinds, outClassName, out kind, problems);
		}

		AngelScriptRuntime runtime;
		using (ProfileScope("Script.Cook.MakeEngine"))
			runtime = scope:: AngelScriptRuntime();
		using (ProfileScope("Script.Cook.RegisterApi"))
			runtime.Bind(mSurface, default, hidden);
		ClearAndDeleteItems!(runtime.Problems);

		bool ok;
		using (ProfileScope("Script.Cook.Compile"))
			ok = runtime.Check(sourceName, source, sections, declared, kinds);
		for (let p in runtime.Problems)
			problems.Add(new String(p));
		outClassName.Clear();
		if (!ok)
			return false;
		return ChooseClass(sourceName, declared, kinds, outClassName, out kind, problems);
	}

	/// The behavior class among the `declared` classes (`kinds` theirs), into `outClass` with its
	/// kind; false with the problem when several derive from a kind.
	private static bool ChooseClass(StringView sourceName, List<String> declared, List<BehaviorKind> kinds, String outClass,
		out BehaviorKind outKind, List<String> problems)
	{
		let problem = scope String();
		if (ScriptClasses.ChooseBehavior(declared, kinds, outClass, out outKind, problem))
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
