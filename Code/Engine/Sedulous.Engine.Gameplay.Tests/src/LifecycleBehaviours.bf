using System;
using Sedulous.Scene;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// The calls the lifecycle tests' behaviours receive, in order, each as
/// "<tag>:<entity>.<call> ". Cleared by each test before it ticks.
static class LifecycleLog
{
	public static String Text = new .() ~ delete _;

	public static void Add(Behaviour behaviour, StringView tag, StringView call)
	{
		let scene = behaviour.Scene;
		StringView name = (scene != null) ? scene.GetEntityName(behaviour.Entity) : "?";
		Text.AppendF("{}:{}.{} ", tag, name, call);
	}
}

/// A behaviour that overrides every lifecycle call, logging each, with a hook a test sets to
/// act from inside a callback (adding, removing, destroying).
[Behaviour("test.walker")]
class Walker : Behaviour
{
	/// Run after the call is logged, when set. BORROWED: a test's scoped delegate, which the
	/// test clears before it goes.
	public static delegate void(Walker walker) StartHook = null;
	public static delegate void(Walker walker) UpdateHook = null;
	public static delegate void(Walker walker) FixedHook = null;

	private float mUpdateTime = 0.0f;
	private float mFixedTime = 0.0f;
	private int mFixedCount = 0;
	private int mLateCount = 0;

	/// The time the updates were handed, summed; the same for the fixed steps.
	public float UpdateTime => mUpdateTime;
	public float FixedTime => mFixedTime;
	public int FixedCount => mFixedCount;
	public int LateCount => mLateCount;

	protected override void OnEnable() => LifecycleLog.Add(this, "W", "Enable");

	protected override void OnStart()
	{
		LifecycleLog.Add(this, "W", "Start");
		if (StartHook != null)
			StartHook(this);
	}

	protected override void OnUpdate(float dt)
	{
		LifecycleLog.Add(this, "W", "Update");
		mUpdateTime += dt;
		if (UpdateHook != null)
			UpdateHook(this);
	}

	protected override void OnFixedUpdate(float dt)
	{
		LifecycleLog.Add(this, "W", "Fixed");
		mFixedTime += dt;
		mFixedCount++;
		if (FixedHook != null)
			FixedHook(this);
	}

	protected override void OnLateUpdate(float dt)
	{
		LifecycleLog.Add(this, "W", "Late");
		mLateCount++;
	}

	protected override void OnDisable() => LifecycleLog.Add(this, "W", "Disable");
	protected override void OnDestroy() => LifecycleLog.Add(this, "W", "Destroy");
}

/// A second class with an OnUpdate and no fixed or late tick: registration order between two
/// types, and a type on only one tick list.
[Behaviour("test.runner")]
class Runner : Behaviour
{
	protected override void OnEnable() => LifecycleLog.Add(this, "R", "Enable");
	protected override void OnStart() => LifecycleLog.Add(this, "R", "Start");
	protected override void OnUpdate(float dt) => LifecycleLog.Add(this, "R", "Update");
}
