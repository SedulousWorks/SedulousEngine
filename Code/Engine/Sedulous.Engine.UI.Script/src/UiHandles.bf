using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.UI;

namespace Sedulous.Engine.UI.Script;

/// The identity behind every UI handle a script holds.
///
/// A handle is a view's id and nothing else, so a script may copy it freely and a VM may
/// carry it by value; this table resolves it to the live view. An entry holds one
/// reference on its view, and is SWEPT once that is the only reference left, the tree
/// having let the view go: from then on the handle reads null but valid, the loud null a
/// script sees rather than a dangling pointer. What a view's script bindings own, its click
/// callbacks, dies with the entry.
static class UiHandles
{
	private class Entry
	{
		public View View;
		public List<ScriptDelegate> Owned = null ~ { if (_ != null) DeleteContainerAndItems!(_); };
	}

	private static Dictionary<uint32, Entry> sEntries = new .() ~ DeleteDictionaryAndValues!(_);

	/// The handle id for a live view, registering it if new. Nought for null.
	public static uint32 IdOf(View view)
	{
		if (view == null)
			return 0;
		let id = view.Id.RawValue;
		if (!sEntries.ContainsKey(id))
		{
			let entry = new Entry();
			entry.View = view;
			view.AddRef();
			sEntries[id] = entry;
		}
		return id;
	}

	/// The live view behind a handle, null once the tree has dropped it.
	public static View Resolve(uint32 id)
	{
		if (id == 0)
			return null;
		if (!sEntries.TryGetValue(id, let entry))
			return null;
		if (entry.View.RefCount <= 1)
		{
			// Ours is the last reference: the view is out of every tree. Let it go.
			Drop(id, entry);
			return null;
		}
		return entry.View;
	}

	public static T Resolve<T>(uint32 id) where T : View => Resolve(id) as T;

	/// A view's opacity at once, clamped to 0..1; a running fade on it stops. Nothing for null.
	public static void SetOpacity(View view, float value)
	{
		if (view == null)
			return;
		StopTween(view, .Opacity);
		view.Opacity = Math.Clamp(value, 0.0f, 1.0f);
	}

	/// The view's post layout offset, in pixels.
	public static Float2 Translation(View view) => (view != null) ? view.Transform.Translation : .Zero;

	public static void SetTranslation(View view, float x, float y)
	{
		if (view != null)
			view.Transform.Translation = .(x, y);
	}

	/// The view's rotation in degrees (the transform holds radians).
	public static float Rotation(View view) => (view != null) ? RadiansToDegrees(view.Transform.Rotation) : 0.0f;

	public static void SetRotation(View view, float degrees)
	{
		if (view != null)
			view.Transform.Rotation = DegreesToRadians(degrees);
	}

	// ---- tweens ----
	// On the UI frame clock, which goes on while the game is paused (time scale 0). Each
	// property runs its own: a new tween of one property replaces the running one of that
	// property and leaves the others, so a label can rise and fade at once. Zero seconds, or a
	// view in no tree yet, is a set.

	/// Fades a view from its opacity now to `opacity` over `seconds`.
	public static void FadeTo(View view, float opacity, float seconds, Ease ease)
	{
		if (view == null)
			return;
		let to = Math.Clamp(opacity, 0.0f, 1.0f);
		if ((seconds <= 0.0f) || !StartTween(view, ViewAnimator.FadeTo(view, view.Opacity, to, seconds, EasingOf(ease))))
			SetOpacity(view, to);
	}

	/// Moves a view's offset from where it is now to (x, y).
	public static void MoveTo(View view, float x, float y, float seconds, Ease ease)
	{
		if (view == null)
			return;
		let target = Float2(x, y);
		if ((seconds <= 0.0f) || !StartTween(view, ViewAnimator.TranslateTo(view, view.Transform.Translation, target, seconds, EasingOf(ease))))
		{
			StopTween(view, .Translation);
			view.Transform.Translation = target;
		}
	}

	/// A uniform scale about the view's centre, as drawn (layout is unchanged).
	public static float Scale(View view) => (view != null) ? view.Transform.Scale.X : 1.0f;

	public static void SetScale(View view, float value)
	{
		if (view == null)
			return;
		StopTween(view, .Scale);
		view.Transform.Scale = .(value, value);
	}

	public static void ScaleTo(View view, float target, float seconds, Ease ease)
	{
		if (view == null)
			return;
		if ((seconds <= 0.0f) || !StartTween(view, ViewAnimator.ScaleTo(view, view.Transform.Scale.X, target, seconds, EasingOf(ease))))
			SetScale(view, target);
	}

	/// To `degrees`, clockwise on screen.
	public static void RotateTo(View view, float degrees, float seconds, Ease ease)
	{
		if (view == null)
			return;
		let to = DegreesToRadians(degrees);
		if ((seconds <= 0.0f) || !StartTween(view, ViewAnimator.RotateTo(view, view.Transform.Rotation, to, seconds, EasingOf(ease))))
		{
			StopTween(view, .Rotation);
			view.Transform.Rotation = to;
		}
	}

	/// From its normal size out to `peak` and back, half the time each way: the return is the
	/// same tween played backward, so it always settles at the normal size, even when a pulse
	/// starts over one still running.
	public static void Pulse(View view, float peak, float seconds)
	{
		if ((view == null) || (view.Context == null) || (seconds <= 0.0f))
			return;
		let swell = ViewAnimator.ScaleTo(view, 1.0f, peak, seconds * 0.5f, Easing.EaseOut);
		swell.AutoReverse = true;
		swell.RepeatCount = 1;
		StartTween(view, swell);
	}

	private static EasingFunction EasingOf(Ease ease)
	{
		switch (ease)
		{
		case .Linear: return Easing.Linear;
		case .In: return Easing.EaseIn;
		case .Out: return Easing.EaseOut;
		case .OutBack: return Easing.BackOut;
		case .OutBounce: return Easing.BounceOut;
		case .OutElastic: return Easing.ElasticOut;
		case .InOut: return Easing.EaseInOut;
		}
	}

	/// Runs `animation` in place of the view's running one on the same property. A view in no
	/// tree yet has no clock to run it on: the animation is dropped and the caller sets the end
	/// value instead.
	private static bool StartTween(View view, Animation animation)
	{
		let context = view.Context;
		if (context == null)
		{
			delete animation;
			return false;
		}
		context.Animations.CancelForView(view, animation.Channel);
		context.Animations.Add(animation);
		return true;
	}

	private static void StopTween(View view, AnimationChannel channel)
	{
		view.Context?.Animations.CancelForView(view, channel);
	}

	/// Parks a delegate with the view it is bound to, to die with the view.
	public static void Own(View view, ScriptDelegate d)
	{
		let id = IdOf(view);
		if ((id == 0) || (d == null))
			return;
		let entry = sEntries[id];
		if (entry.Owned == null)
			entry.Owned = new .();
		entry.Owned.Add(d);
	}

	/// Releases every view the trees have dropped. Cheap; a host may call it per frame, and
	/// a resolve does its own.
	public static void Sweep()
	{
		// Dropping a parent releases its children, which may then be ours alone: again
		// until nothing moves.
		let dropped = scope List<uint32>();
		repeat
		{
			dropped.Clear();
			for (let kv in sEntries)
			{
				if (kv.value.View.RefCount <= 1)
					dropped.Add(kv.key);
			}
			for (let id in dropped)
				Drop(id, sEntries[id]);
		}
		while (!dropped.IsEmpty);
	}

	/// Everything, whatever its references: process teardown.
	public static void Clear()
	{
		for (let kv in sEntries)
		{
			kv.value.View.ReleaseRef();
			delete kv.value;
		}
		sEntries.Clear();
	}

	public static int Count => sEntries.Count;

	private static void Drop(uint32 id, Entry entry)
	{
		sEntries.Remove(id);
		let view = entry.View;
		delete entry; // the owned delegates first: a callback must not outlive its button
		view.ReleaseRef();
	}
}
