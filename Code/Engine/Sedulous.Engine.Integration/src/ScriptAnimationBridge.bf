using System;
using Sedulous.Script;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Integration;

/// The composition root adapter from the animation's events to the script layer's neutral
/// DeliverEvent ingress: a one-shot that ended (scene.Animation.PlayOneShot) reaches the
/// entity's behaviours as onAnimationFinished(clip).
///
/// The animation subsystem publishes to IAnimationListeners and knows nothing about scripts;
/// the script subsystem takes a handler name and its arguments and knows nothing about
/// animation. This is the one place that names both. A host installs it once both subsystems
/// exist and uninstalls it before the animation subsystem goes.
class ScriptAnimationBridge : IAnimationListener
{
	/// BORROWED, both.
	private AnimationSubsystem mAnimation = null;
	private ScriptSubsystem mScripts = null;

	public ~this()
	{
		Uninstall();
	}

	public bool Installed => mAnimation != null;

	/// Points `animation`'s events at `scripts`. Calling again re-points cleanly, the prior
	/// registration dropped first, so re-wiring is safe.
	public void Install(AnimationSubsystem animation, ScriptSubsystem scripts)
	{
		Uninstall();
		if ((animation == null) || (scripts == null))
			return;
		mScripts = scripts;
		mAnimation = animation;
		mAnimation.RegisterListener(this);
	}

	/// Unregisters from the animation subsystem. Idempotent; a no-op when not installed.
	public void Uninstall()
	{
		if (mAnimation != null)
		{
			mAnimation.UnregisterListener(this);
			mAnimation = null;
		}
		mScripts = null;
	}

	/// Only enqueues: the script subsystem defers to its scene's queue.
	public void OnOneShotEnded(AnimationOneShotEnded ended)
	{
		if (mScripts == null)
			return;
		var args = ScriptValue[1](.FromGuid(ended.Clip));
		mScripts.DeliverEvent(ended.Scene, ended.Entity, "onAnimationFinished", .(&args[0], 1));
	}
}
