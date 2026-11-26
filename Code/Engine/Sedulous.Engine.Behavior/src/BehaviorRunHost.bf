using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Behavior;

/// A run's behaviors: the services its objects find (the host's own, its run's, the
/// application's), its random numbers, and the classes it makes objects of. A class in a script
/// language is made in the run's script runtime, which its script half holds (Scripts); a native
/// class (language `native`) is made from its built-in type, with no runtime (Natives). Plain
/// class, no runtime dependencies, so a headless test drives it directly.
class BehaviorRunHost
{
	/// OWNED: the run's script runtime and the classes loaded into it.
	private ScriptBehaviorClasses mScripts ~ delete _;
	/// OWNED: the run's native classes.
	private NativeBehaviorClasses mNatives ~ delete _;
	/// OWNED: this run's random numbers, `Random` to a script; seedable by the owner.
	private RandomFacade mRandom = new .() ~ delete _;
	/// BORROWED: the services the owner installed on this host, by exact type, which its scripts
	/// find first (FindService).
	private List<(Type type, Object service)> mServices = new .() ~ delete _;
	/// BORROWED: the run this host belongs to (a ApplicationRun, a scene page's run), whose
	/// services its scripts find after the host's own; null outside every run (the subsystem's
	/// default host).
	public IRun OwningRun = null;
	/// BORROWED: the application's subsystems, whose services its scripts find last; set by the
	/// BehaviorSubsystem that wires the host, and cleared as it shuts down. Null: none.
	public SubsystemManager Subsystems = null;

	public this()
	{
		mScripts = new .(this);
		mNatives = new .(this);
	}

	/// The run's script half: its runtime, made for the first class in a script language.
	public ScriptBehaviorClasses Scripts => mScripts;
	/// The run's native half: classes written in native code.
	public NativeBehaviorClasses Natives => mNatives;

	/// Appends why the last class failed to be made, or the last native object faulted, then
	/// forgets it: a native reason first, else a script one.
	public void TakeLastError(String outText)
	{
		let native = mNatives.TakeLastError(.. scope .());
		if (!native.IsEmpty)
			outText.Append(native);
		else
			mScripts.TakeLastError(outText);
	}
	public RandomFacade Random => mRandom;

	/// A game script running on this host pins it: no teardown while it lives. Set by the
	/// application run that launched it.
	public bool HasGameScriptHold = false;
	/// Asks the host's owner whether the host can go now (nothing pins it), and tears it down
	/// when so. Installed by the BehaviorSubsystem; null for a host nobody watches. Owned.
	public delegate void(BehaviorRunHost host) TeardownCheck = null ~ delete _;

	/// Runs the owner's teardown check: what an application run calls when its game script ends.
	public void CheckTeardown()
	{
		if (TeardownCheck != null)
			TeardownCheck(this);
	}

	/// Installs a service on this host, reached by a script as the handle of its type before its
	/// run's and the application's, by the runtime now and any later one. BORROWED.
	public void SetService<T>(T service) where T : class
	{
		for (int i = 0; i < mServices.Count; i++)
		{
			if (mServices[i].type == typeof(T))
			{
				mServices[i] = (typeof(T), service);
				return;
			}
		}
		mServices.Add((typeof(T), service));
	}

	/// The service of exactly `type` this host's scripts reach: the host's own (SetService), then
	/// its run's (OwningRun), then the application's (Subsystems); null when none has one. Asked as
	/// each call is made, so a run's service that goes with the run is not found after it.
	public Object FindService(Type type)
	{
		for (let entry in mServices)
		{
			if (entry.type == type)
				return entry.service;
		}
		if (OwningRun != null)
		{
			let found = OwningRun.FindService(type);
			if (found != null)
				return found;
		}
		return (Subsystems != null) ? Subsystems.FindService(type) : null;
	}

	/// A call the debugger suspended is being held, which the host's ticks and handlers
	/// hold still for: starting a new update each frame would hit the breakpoint again
	/// every frame and orphan the held call.
	public bool IsDebugPaused => mScripts.IsDebugPaused;

	/// Advances the run's coroutines by gameplay time: its scripts' clock. Once per frame, by
	/// whoever owns the host (a game's run, a scene page's, the subsystem for its default host),
	/// never per scene: a run with three scenes has one clock, and a run with no scene yet, a game
	/// script loading its first level, still has to move.
	public void Advance(float deltaTime) => mScripts.Advance(deltaTime);

	/// An instance of the class, for the place that takes a class of kind `kind` (a scene's Level
	/// slot a SceneBehavior, an entity's an EntityBehavior, the run's a RunBehavior). Null on
	/// failure, logged, and for a class of another kind.
	public BehaviorObject Instantiate(BehaviorClass scriptClass, BehaviorKind kind)
	{
		if (scriptClass.Kind != kind)
		{
			let what = scope String();
			if (scriptClass.Kind == .None)
				what.Append("declares no behavior class");
			else
				what.AppendF("derives from {}", BehaviorKinds.TypeName(scriptClass.Kind));
			GlobalLog(.Error, scope $"Script: '{scriptClass.SourceName}' {what}: it is set where a class deriving from {BehaviorKinds.TypeName(kind)} goes");
			return null;
		}
		if (scriptClass.Language == NativeBehaviorClasses.cLanguage)
			return mNatives.Create(scriptClass, kind);
		return mScripts.Create(scriptClass);
	}

	/// The run's end: the runtime and every class reference go. Instances held elsewhere
	/// must have been released first.
	public void Teardown()
	{
		mScripts.Teardown();
		// The next run starts from the default seed, as a fresh run does: a second play in
		// the same tab must not continue the first one's sequence.
		delete mRandom;
		mRandom = new .();
	}
}
