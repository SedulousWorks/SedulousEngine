using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// The sheet's `animation`s on a view: started, kept and ended to match the cascade, advanced
/// on the transitions' tick, and read over the cascade's values while they run.
extension View
{
	/// One of the sheet's `animation`s on the view. A finished one stays listed, so it does not
	/// start again while the cascade still names it.
	private class RunningAnimation
	{
		/// The spec, its Name borrowing NameText, which the view owns: the list it came from
		/// can go with a sheet before the view syncs again.
		public AnimationSpec Spec;
		public String NameText = new .() ~ delete _;
		/// A reference this holds.
		public KeyframesRule Keyframes ~ _?.ReleaseRef();
		public float Elapsed = 0.0f;
		public bool Finished = false;
	}

	/// In the list's order: a later one wins a property both animate.
	private List<RunningAnimation> mAnimations = null ~ DeleteContainerAndItems!(_);
	/// Where an animated value's list goes (a shadow list's in-between), as ResolveStyle
	/// answers it: rewritten by each resolve, and borrowed by the value it answers.
	private StyleLerpScratch mAnimationScratch = null ~ delete _;

	/// Animations running (not finished) on the view.
	public int RunningAnimationCount
	{
		get
		{
			var running = 0;
			if (mAnimations != null)
			{
				for (let animation in mAnimations)
					running += animation.Finished ? 0 : 1;
			}
			return running;
		}
	}

	private bool HasAnimations => (mAnimations != null) && !mAnimations.IsEmpty;

	/// The @keyframes of this name the view's sheets hold: the nearest local sheet's, else the
	/// context's. BORROWED.
	private KeyframesRule FindKeyframes(StringView name)
	{
		for (var view = this; view != null; view = view.Parent)
		{
			if (view.mLocalStyleSheet != null)
			{
				if (let found = view.mLocalStyleSheet.FindKeyframes(name))
					return found;
			}
		}
		if ((Context != null) && (Context.GetStyleSheet() != null))
			return Context.GetStyleSheet().FindKeyframes(name);
		return null;
	}

	/// Starts, keeps or ends the running animations to match the cascade's `animation`, after
	/// a style recompute.
	private void SyncAnimations()
	{
		// Read from the cache just built, never through ComputeStyle: a view outside a context
		// keeps no valid cache, and would rebuild it here, and sync again.
		AnimationList list = null;
		if (let winner = mStyleCache.Winners[(int)StyleProperty.Animation])
		{
			if (let raw = winner.GetValue(.Animation))
				list = raw.AsAnimations;
		}
		if (((list == null) || list.Specs.IsEmpty) && !HasAnimations)
			return;

		let next = new List<RunningAnimation>();
		if (list != null)
		{
			for (let spec in list.Specs)
			{
				let keyframes = FindKeyframes(spec.Name);
				if (keyframes == null)
					continue; // no such @keyframes: nothing plays
				let running = new RunningAnimation();
				running.NameText.Set(spec.Name);
				running.Spec = spec;
				running.Spec.Name = running.NameText;
				keyframes.AddRef();
				running.Keyframes = keyframes;
				// The same name over the same keyframes carries on where it was.
				if (mAnimations != null)
				{
					for (let old in mAnimations)
					{
						if ((old.NameText == spec.Name) && (old.Keyframes == keyframes))
						{
							running.Elapsed = old.Elapsed;
							running.Finished = old.Finished;
						}
					}
				}
				next.Add(running);
			}
		}

		let oldCount = (mAnimations != null) ? mAnimations.Count : 0;
		var changed = next.Count != oldCount;
		for (int i = 0; !changed && (i < next.Count); i++)
			changed = (next[i].Keyframes != mAnimations[i].Keyframes) || (next[i].NameText != mAnimations[i].NameText);
		if (mAnimations != null)
			DeleteContainerAndItems!(mAnimations);
		mAnimations = next;
		if (RunningAnimationCount > 0)
			RegisterTransitioning();
		if (changed)
			InvalidateVisual();
	}

	/// The value an animation gives `property` now, over `baseValue` (the cascade's), if one
	/// does.
	private StyleValue? AnimatedValue(StyleProperty property, StyleValue baseValue)
	{
		for (int a = mAnimations.Count - 1; a >= 0; a--)
		{
			let running = mAnimations[a];
			let spec = running.Spec;
			let keyframes = running.Keyframes;
			if (!keyframes.Animates(property))
				continue;

			// Where in its run the animation is: an iteration and the way through it.
			let local = running.Elapsed - spec.Delay;
			let infinite = spec.Iterations < 0.0f;
			let duration = Math.Max(spec.Duration, 0.0f);
			let total = infinite ? float.MaxValue : duration * spec.Iterations;
			var iteration = 0.0f;
			var progress = 0.0f;
			if (local < 0.0f)
			{
				if ((spec.Fill != .Backwards) && (spec.Fill != .Both))
					continue;
			}
			else if (!infinite && (local >= total))
			{
				if ((spec.Fill != .Forwards) && (spec.Fill != .Both))
					continue;
				// The end of the last iteration: a count of 2.5 ends half way through the third.
				let whole = Math.Floor(spec.Iterations);
				iteration = (spec.Iterations > whole) ? whole : Math.Max(0.0f, whole - 1.0f);
				progress = (spec.Iterations > whole) ? (spec.Iterations - whole) : 1.0f;
			}
			else if (duration > 0.0f)
			{
				iteration = Math.Floor(local / duration);
				progress = local / duration - iteration;
			}
			else
			{
				progress = 1.0f;
			}
			let odd = ((int64)iteration % 2) == 1;
			let reversed = (spec.Direction == .Reverse) || ((spec.Direction == .Alternate) && odd)
				|| ((spec.Direction == .AlternateReverse) && !odd);
			let p = reversed ? (1.0f - progress) : progress;

			// The frames either side of p that declare the property; a missing first or last
			// frame is the cascade's value, as CSS fills it in.
			var fromOffset = 0.0f;
			var from = baseValue;
			var toOffset = 1.0f;
			var to = baseValue;
			for (let frame in keyframes.Frames)
			{
				let raw = frame.Declarations.GetValue(property);
				if (raw == null)
					continue;
				if (frame.Offset <= p)
				{
					fromOffset = frame.Offset;
					from = ResolveKeywords(property, raw.Value, 0);
				}
				else
				{
					toOffset = frame.Offset;
					to = ResolveKeywords(property, raw.Value, 0);
					break;
				}
			}
			if (toOffset <= fromOffset)
				return from;
			let t = spec.Easing.Evaluate((p - fromOffset) / (toOffset - fromOffset));
			if (from.IsNone || to.IsNone || !StyleValueOps.Interpolable(from, to))
				return (t < 0.5f) ? from : to;
			if (mAnimationScratch == null)
				mAnimationScratch = new .();
			return StyleValueOps.Lerp(from, to, t, mAnimationScratch);
		}
		return null;
	}

	/// Advances the running animations by `deltaTime`, marking the damage they do: a redraw,
	/// or a layout when one animates a property that moves geometry. True while one runs.
	private bool AdvanceAnimations(float deltaTime)
	{
		if (mAnimations == null)
			return false;
		var animating = false;
		var animated = false;
		var layoutDamage = false;
		for (let running in mAnimations)
		{
			if (running.Finished)
				continue;
			animated = true;
			running.Elapsed += deltaTime;
			let spec = running.Spec;
			if ((spec.Iterations >= 0.0f) && (running.Elapsed >= spec.Delay + Math.Max(spec.Duration, 0.0f) * spec.Iterations))
				running.Finished = true;
			animating = animating || !running.Finished;
			for (let frame in running.Keyframes.Frames)
			{
				for (int e < frame.Declarations.PropertyCount)
					layoutDamage = layoutDamage || !StylePropertyKinds.IsVisualOnly(frame.Declarations.GetProperty(e).Prop);
			}
		}
		if (animated)
		{
			if (layoutDamage)
				Invalidate();
			else
				InvalidateVisual();
		}
		return animating;
	}
}
