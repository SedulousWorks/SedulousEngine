using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// A node's tweens: Node.Animate and StopAnimation, here because Node.bf does not see the tweens (a
// tween targets a node), and the tweens' one count; and a GUI's data value's
// (GUIContext.AnimateData).
//
// Each call that makes a tween hands back a reference of the caller's, which it releases; a
// running tween is held by its GUI's action manager as well.

static
{
	/// A mark no other tween has had (in the library, so every binary draws from one count).
	public static uint64 NextTweenOwner() => ++TweenImplDetail.sNextOwner;
}

/// What TweenImpl.bf keeps out of the public surface.
internal static class TweenImplDetail
{
	public static uint64 sNextOwner = 0;

	// Calls `f(tween)` for each running tween, inside groups too.
	public static void VisitRunning(Sedulous.GUI.Action action, delegate void(Tween tween) f)
	{
		if (action.IsDone)
			return;
		let tween = action as Tween;
		if (tween != null)
		{
			f(tween);
			return;
		}
		let group = action as TweenGroup;
		if (group != null)
			group.ForEachRunning(scope (step) => VisitRunning(step, f));
	}

	public static void ForEachRunningTween(Node node, delegate void(Tween tween) f)
	{
		let manager = node.ActionManager;
		if (manager != null)
			manager.ForEachAction(scope (action) => VisitRunning(action, f));
	}

	/// Another tween of `tween`'s property on its node, running on its own or in a group, gives way
	/// to it.
	public static void ReplaceOthersOf(Tween tween)
	{
		let target = tween.ResolveTarget();
		if (target == null)
			return;
		ForEachRunningTween(target, scope (other) =>
			{
				if ((other != tween) && (other.ResolveTarget() == target) && (other.Property == tween.Property))
					other.Replace(); // the new one starts from the value it shows
			});
	}
}

extension Node
{
	/// A tween of this node as Animate makes one, not yet running: a step for a group. The caller
	/// releases the reference it is handed.
	public Tween CreateTween(StringView property, StringView to, float seconds) => CreateTween(property, to, seconds, "ease");

	public Tween CreateTween(StringView property, StringView to, float seconds, StringView easing)
	{
		let tween = new Tween(property, to, seconds, ParseEasing(easing).GetValueOrDefault(Easing.Ease()));
		TargetAction(tween);
		return tween;
	}

	/// Moves `property` to `to` over `seconds` on the GUI's clock, eased as `easing` names (a CSS
	/// easing or a named curve; `ease` when none is given). The property is named as a sheet names
	/// it, and composes over the cascade, holding its end until stopped; a name no sheet knows is a
	/// reflected property (`value`, `x`, `opacity` on a plain node). A tween of the same property
	/// replaces the running one, from the value showing. The tween, to shape further (a start
	/// value, a delay, repeats), whose reference the caller releases; inert on a node in no GUI.
	public Tween Animate(StringView property, StringView to, float seconds) => Animate(property, to, seconds, "ease");

	public Tween Animate(StringView property, StringView to, float seconds, StringView easing)
	{
		let tween = CreateTween(property, to, seconds, easing);
		RunAction(tween); // its start replaces the one running
		return tween;
	}

	/// Moves `property` toward `to` as a damped spring (Tween.Spring): a spring already moving it
	/// turns toward the new end from where it is, at the speed it has, rather than starting again.
	/// The spring, running; the caller releases the reference it is handed.
	public Tween SpringTo(StringView property, StringView to, float stiffness = 170.0f, float damping = 26.0f, float mass = 1.0f)
	{
		Tween running = null;
		TweenImplDetail.ForEachRunningTween(this, scope [&] (tween) =>
			{
				if (tween.IsSpring && (tween.ResolveTarget() == this) && (tween.Property == property))
					running = tween;
			});
		if (running != null)
		{
			running.AddRef(); // the caller's
			running.Spring(stiffness, damping, mass);
			running.Retarget(to);
			return running;
		}
		let created = CreateTween(property, to, 0.0f);
		created.Spring(stiffness, damping, mass);
		RunAction(created);
		return created;
	}

	/// Runs `group` on this node's GUI clock (the caller keeps its reference).
	public void Play(TweenGroup group)
	{
		if (group != null)
			RunAction(group);
	}

	/// Stops what moves `property` and gives it back to the sheet (a tween that ended holds its end
	/// until this); false when nothing moved it.
	public bool StopAnimation(StringView property)
	{
		bool stopped = false;
		TweenImplDetail.ForEachRunningTween(this, scope [&] (tween) =>
			{
				if ((tween.ResolveTarget() == this) && (tween.Property == property))
				{
					tween.Cancel();
					stopped = true;
				}
			});
		let node = this as UINode;
		if (node != null)
			stopped = node.RemoveMotion(property) || stopped;
		return stopped;
	}
}

extension GUIContext
{
	/// A data value's tween as AnimateData makes one, not yet running: a step for a group. The
	/// caller releases the reference it is handed.
	public Tween CreateDataTween(StringView name, double to, float seconds) => CreateDataTween(name, to, seconds, "ease");

	public Tween CreateDataTween(StringView name, double to, float seconds, StringView easing)
	{
		let text = scope String();
		var value = System.Variant.Create(to);
		FormatVariant(value, text);
		value.Dispose();
		let tween = new Tween(name, text, seconds, ParseEasing(easing).GetValueOrDefault(Easing.Ease()));
		tween.TargetData(Data);
		return tween;
	}

	/// Moves data value `name` to `to` over `seconds` on the GUI's clock, eased as `easing` names:
	/// whatever is bound to it follows each frame (a score counting up with no widget to drive it),
	/// in the value's own type (a whole number counts in whole numbers). A tween of the same name
	/// replaces the running one, from the value showing; a GUI root's pause does not hold it. The
	/// tween, to shape further, whose reference the caller releases.
	public Tween AnimateData(StringView name, double to, float seconds) => AnimateData(name, to, seconds, "ease");

	public Tween AnimateData(StringView name, double to, float seconds, StringView easing)
	{
		let tween = CreateDataTween(name, to, seconds, easing);
		this.ActionManager.AddAction(tween); // its start replaces the one moving the value
		return tween;
	}
}
