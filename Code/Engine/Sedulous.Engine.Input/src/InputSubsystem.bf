using System;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Input;

namespace Sedulous.Engine.Input;

/// The runtime hookup: it owns the action runtime and the device source, and evaluates once
/// per frame before scenes tick.
///
/// The provider seam is the play in editor story. The player hands over the shell's devices;
/// an editor's game tab hands over its viewport's gated facades, so an unfocused viewport
/// forwards nothing and the same map evaluates either way.
class InputSubsystem : Subsystem
{
	private ShellInputSource mShellSource ~ delete _;
	/// BORROWED: whoever installed it owns it, and clears it before it goes.
	private IInputSourceProvider mOverride = null;
	/// The override's scene binding. Compared, never dereferenced.
	private void* mBoundSceneKey = null;
	private UnboundInputScenePolicy mUnboundScenePolicy = .AllScenes;
	private ActionRuntime mRuntime = new .() ~ delete _;

	/// A null device hub is tolerated: a headless run reads every device as released.
	public this(IInputManager input)
	{
		mShellSource = new ShellInputSource(input);
	}

	public ActionRuntime Runtime => mRuntime;

	/// The raw shell devices as a source, for a host with no gated viewport to point at.
	public IInputSourceProvider ShellSource => mShellSource;

	/// Installs a COPY of a map, from a cooked resource, a test, or written by hand.
	public void SetMap(InputMap map) => mRuntime.SetMap(map);

	/// Overrides the device source. Null restores the shell devices.
	///
	/// `boundSceneKey` is the PER SURFACE SCENE BINDING: the opaque identity of the scene
	/// this source represents, compared and never dereferenced, which is what keeps this
	/// module free of Scene. Bound, the UI pump routes pointer, keyboard and gamepad
	/// navigation to that scene's root alone, so two interactive scenes on overlapping
	/// coordinates can no longer cross route. Null leaves it to the policy.
	///
	/// The binding RIDES the override, so clearing the provider clears it.
	public void SetSourceProvider(IInputSourceProvider provider, void* boundSceneKey = null)
	{
		mOverride = provider;
		mBoundSceneKey = (provider != null) ? boundSceneKey : null;
	}

	/// Clears the override only if it currently points at `source`.
	///
	/// A source about to be destroyed, a closing tab's viewport, calls this so the next pump
	/// cannot read freed memory. Guarded, so it never clears a DIFFERENT still open tab's
	/// active source.
	public void ClearSourceProviderIf(IInputSourceProvider source)
	{
		if (mOverride === source)
		{
			mOverride = null;
			mBoundSceneKey = null;
		}
	}

	/// The active source's scene binding, or null when it is un-bound.
	public void* BoundSceneKey => mBoundSceneKey;

	/// How an un-bound source routes. An editor sets this once at startup; the player keeps
	/// the default.
	public UnboundInputScenePolicy UnboundScenePolicy
	{
		get => mUnboundScenePolicy;
		set => mUnboundScenePolicy = value;
	}

	/// What actions evaluate against. The UI subsystem reads the SAME facades, so game UI
	/// sees viewport coordinates in an editor and window coordinates in the player without
	/// knowing which it is.
	public IInputSourceProvider ActiveSource => (mOverride != null) ? mOverride : mShellSource;

	public override void Update(float deltaTime)
	{
		if (Context != null)
			mRuntime.SetTimeScale(Context.TimeScale);

		mRuntime.Update(ActiveSource, deltaTime);
	}
}
