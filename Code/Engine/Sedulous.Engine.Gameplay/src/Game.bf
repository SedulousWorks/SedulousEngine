using System;
using System.Collections;
using System.Reflection;
using Sedulous.Run;
using Sedulous.Scene;
using Sedulous.Engine.GameInstance;

namespace Sedulous.Engine.Gameplay;

/// The game's code for a whole run, above its scenes: boot, the flow from level to level, what
/// lasts across them. One per build, registered with GameplayServices.SetGame; each session of
/// a run makes a fresh one (GameInstance.LaunchGame), which the run holds until the session
/// stops and then deletes, so nothing of one play reaches the next.
///
/// OnLaunch runs once, as the host launches the game, before the first scene: a game may load
/// its first level itself (Instance.LoadScene). OnUpdate runs every frame the run ticks, with
/// a delta the run's own time scale does not touch, so a game that pauses its scenes
/// (Instance.InstanceTimeScale = 0) keeps its own timers going. OnSceneActivated runs as each
/// scene becomes the run's current one, started and with the scene it replaced gone. OnExit
/// runs once, as the session stops, before the run writes its save, so what it saves there is
/// kept; its event subscriptions end after it returns.
///
/// A subclass carries [Game], which reflects its fields (public and private) for the editor's
/// play tools; SetGame refuses one without it.
///
/// The constructor and the field initialisers must not touch the run: Instance is set after
/// them.
abstract class Game : IGameHooks
{
	/// BORROWED: the run that holds this game, and outlives it.
	private GameInstance mInstance = null;
	private bool mLaunched = false;
	private bool mExited = false;
	/// The run event subscriptions Listen made, ended at its exit. Null until the first.
	private List<EventSubscription> mSubscriptions = null ~ delete _;

	/// The run this game drives: its scene loads (LoadScene, LoadSceneAsync), RequestExit,
	/// InstanceTimeScale, RealDeltaTime, Saves, and every service it holds (Instance.Get<T>(),
	/// such as InputFacade or SaveFacade). Null before the launch.
	public GameInstance Instance => mInstance;

	/// The run, as the typed events take it.
	public IRun Run => mInstance;

	/// The run's random numbers, the ones all of the run's game code draws, back to the default
	/// seed as each session stops; null before the launch. BORROWED.
	public Sedulous.Core.RunRandom Random => RunServices.Get<Sedulous.Core.RunRandom>(Run);

	/// The run's current scene; null until one is.
	public Scene CurrentScene => (mInstance != null) ? mInstance.CurrentScene : null;

	/// It launched and has not exited: it runs.
	public bool Running => mLaunched && !mExited;

	/// Whatever it still listens to ends with it, its exit skipped (a run disposed without a
	/// session): nothing it subscribed outlives it.
	public ~this()
	{
		EndSubscriptions();
	}

	// ---- events ----

	/// Calls `handler` with every `T` emitted or posted in its run (GameEvents), while it runs.
	/// The subscription ends at its exit. TAKES OWNERSHIP of `handler`; false, the handler
	/// deleted, before the launch or after the exit.
	public bool Listen<T>(delegate void(T) handler) where T : struct
	{
		if ((mInstance == null) || mExited)
		{
			delete handler;
			return false;
		}
		delegate void(T) gated = new [=this, =handler] (evt) =>
			{
				if (Running)
					handler(evt);
			} ~ delete handler;
		let subscription = GameEvents.Listen<T>(mInstance, gated);
		if (!subscription.IsSubscribed)
			return false;
		if (mSubscriptions == null)
			mSubscriptions = new .();
		mSubscriptions.Add(subscription);
		return true;
	}

	/// GameEvents.Emit in its run: delivered now.
	public void Emit<T>(T evt) where T : struct => GameEvents.Emit<T>(Run, evt);

	/// GameEvents.Post in its run: delivered at the run's next drain.
	public void Post<T>(T evt) where T : struct => GameEvents.Post<T>(Run, evt);

	// ---- the game's hooks ----

	/// Once, as the host launches it.
	protected virtual void OnLaunch() {}
	/// Every frame the run ticks, `dt` unscaled by the run's time scale.
	protected virtual void OnUpdate(float dt) {}
	/// `scene` became the run's current scene.
	protected virtual void OnSceneActivated(Scene scene) {}
	/// Once, as the session stops, before the run writes its save.
	protected virtual void OnExit() {}

	// ---- what the run calls ----

	/// The run it is made for, set by the runner before the run takes it.
	internal void Bind(GameInstance instance)
	{
		mInstance = instance;
	}

	void IGameHooks.Launch()
	{
		if (mLaunched || mExited)
			return;
		mLaunched = true;
		OnLaunch();
	}

	void IGameHooks.Update(float dt)
	{
		if (Running)
			OnUpdate(dt);
	}

	void IGameHooks.SceneActivated(Scene scene)
	{
		if (Running)
			OnSceneActivated(scene);
	}

	void IGameHooks.Exit()
	{
		if (!Running)
			return;
		mExited = true;
		OnExit();
		EndSubscriptions();
	}

	private void EndSubscriptions()
	{
		if (mSubscriptions == null)
			return;
		for (var subscription in ref mSubscriptions)
			subscription.Dispose();
		mSubscriptions.Clear();
	}

	/// What GameplayServices.SetGame checks of `type` at compile time: it carries [Game], so
	/// its fields are reflected for the tools. The refusal is a compile error naming the class.
	/// The unspecialized generic (a generic parameter, not a class) is passed over: it is never
	/// built.
	[Comptime]
	internal static void EmitChecks(Type type)
	{
		if (!(type is TypeInstance) || type.IsGenericParam)
			return;
		if (!(type.GetCustomAttribute<GameAttribute>() case .Ok))
		{
			let message = scope String();
			type.GetFullName(message);
			message.Append(" is registered as the Game but carries no [Game] attribute");
			Runtime.FatalError(message);
		}
	}
}
