using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Motion: CSS transitions and @keyframes animations over any property a sheet sets. A widget
// whose style moves gets one StyleAnimation, an action on its SceneRoot's clock (so a GUI's time
// is its own), holding the style the sheet wants (the target) and a track per moving property: a
// transition from the value showing when the property changed toward its new one, or a keyframe
// animation's track through its stops, each eased (cubic-bezier, steps, the named curves) and
// interpolated through the typed values. Each tick it applies the target with the tracks' values
// over it. It holds its widget weakly (the element table), so a destroyed widget ends it. A
// transition that ends tells its widget `transitionend`, an animation that runs its last iteration
// `animationend`, and a widget leaving goes once nothing it waits for moves it.
//
// What C++ keeps by value here (a key, a track) owns a value or a list, so each is a class.

static
{
	/// Whether a property's values move smoothly in a transition (`all` covers these): those the
	/// property table parses into numbers, lengths, colours, shadows, transforms, origins, layers
	/// or filters.
	public static bool IsTransitionable(StringView property)
	{
		let spec = FindStyleProperty(property);
		if (spec == null)
			return false;
		switch (spec.Grammar)
		{
		case .Number,
			.Length,
			.Size, // lengths move; auto and the content sizes switch
			.Color,
			.Shadows,
			.Transforms,
			.Origin,
			.Layers,
			.Filters,
			.TextOutline,
			.TextGlow:
			return true;
		case .Keyword, .Text:
			return false;
		}
	}

	/// The node's animated layer over `style`: each value a tween moves, from its start or the
	/// value underneath (the cascade's and its transitions', else the property's initial value)
	/// toward its end, as CSS's animation origin outranks the rest. Each value shown is kept, for a
	/// tween that replaces it to start there.
	public static void OverlayMotion(UINode node, ResolvedStyle style, StyleInterpolationContext? ctx)
	{
		let initial = scope StyleValue();
		let value = scope StyleValue();
		for (let motion in node.MotionValues)
		{
			StringView property = motion.Property;
			var under = style.Value(property);
			if (under == null)
			{
				let spec = FindStyleProperty(property);
				if ((spec != null) && (spec.Initial != null))
				{
					ResolvedStyle.ParseLonghand(property, spec.Initial, initial);
					if (initial.Kind != .None)
						under = initial;
				}
			}
			let from = motion.HasFrom ? motion.From : under;
			// Nothing to move from (no start, nothing underneath): it shows its end.
			if (from != null)
				InterpolateStyleValue(from, motion.To, motion.Progress, value, ctx);
			else
				value.Set(motion.To);
			// Kept before the override, which writes over the value `from` may point at.
			motion.HasUnder = from != null;
			if (from != null)
				motion.Under.Set(from);
			style.Override(property, value);
			motion.Shown.Set(value);
			motion.HasShown = true;
		}
	}
}

// === Tracks ===

class AnimationKey
{
	public float Offset = 0.0f;
	public StyleValue Value = new .() ~ delete _;
	/// The segment from this key to the next.
	public Easing Timing = .();

	public this() { }

	/// A key at `offset` holding a copy of `value`.
	public this(float offset, StyleValue value, Easing timing)
	{
		Offset = offset;
		Value.Set(value);
		Timing = timing;
	}
}

/// One moving property: a transition (two keys) or a keyframe animation's track.
class AnimationTrack
{
	public String Property = new .() ~ delete _;
	/// The @keyframes name; empty for a transition.
	public String Animation = new .() ~ delete _;
	public List<AnimationKey> Keys = new .() ~ DeleteContainerAndItems!(_);
	public float Duration = 0.0f;
	public float Delay = 0.0f;
	/// Negative: infinite.
	public float Iterations = 1.0f;
	public AnimationDirection Direction = .Normal;
	public AnimationFill Fill = .None;
	/// animation-play-state: its clock stands still.
	public bool Paused = false;
	public float Elapsed = 0.0f;

	public bool Ended => (Iterations >= 0.0f) && (Elapsed >= Delay + Duration * Iterations);

	/// The value now, into `outValue`, or false when the track shows nothing (before its delay
	/// without a backwards fill, after its end without a forwards one).
	public bool ValueNow(StyleValue outValue, StyleInterpolationContext? ctx = null)
	{
		if (Keys.IsEmpty)
			return false;
		let active = Elapsed - Delay;
		float iterationProgress = 0.0f;
		float iteration = 0.0f;
		if (active < 0.0f)
		{
			if ((Fill != .Backwards) && (Fill != .Both))
				return false;
		}
		else if (Ended || (Duration <= 0.0f))
		{
			if ((Fill != .Forwards) && (Fill != .Both))
				return false;
			// The end of the last iteration (a whole count ends at its full progress).
			let total = (Iterations < 0.0f) ? 1.0f : Iterations;
			iteration = Math.Max(0.0f, Math.Ceiling(total) - 1.0f);
			iterationProgress = total - iteration;
			if (total == 0.0f)
			{
				iteration = 0.0f;
				iterationProgress = 0.0f;
			}
		}
		else
		{
			let cycles = active / Duration;
			iteration = Math.Floor(cycles);
			iterationProgress = cycles - iteration;
		}
		// Direction: odd iterations of an alternating animation run backwards.
		let odd = ((int64)iteration % 2) != 0;
		let reversed = (Direction == .Reverse) || ((Direction == .Alternate) && odd) || ((Direction == .AlternateReverse) && !odd);
		let p = reversed ? 1.0f - iterationProgress : iterationProgress;
		// The segment the progress falls in, eased by its first key's timing.
		if (p <= Keys[0].Offset)
		{
			outValue.Set(Keys[0].Value);
			return true;
		}
		for (int i = 0; i + 1 < Keys.Count; i++)
		{
			let a = Keys[i];
			let b = Keys[i + 1];
			if (p <= b.Offset)
			{
				let span = b.Offset - a.Offset;
				let local = (span > 0.0f) ? (p - a.Offset) / span : 1.0f;
				InterpolateStyleValue(a.Value, b.Value, a.Timing.Evaluate(local), outValue, ctx);
				return true;
			}
		}
		outValue.Set(Keys[Keys.Count - 1].Value);
		return true;
	}
}

/// What applying a style needs besides the style.
struct StyleApplyContext
{
	/// Not owned.
	public IResourceProvider Resources = null;
	/// Not owned.
	public IFontService FontService = null;
	public LengthContext Lengths = .();

	public this() { }
}

// === The action ===

class StyleAnimation : Sedulous.GUI.Action
{
	private class MotionEnd
	{
		public EventType Type = .TransitionEnd;
		public String Name = new .() ~ delete _;
		public float Elapsed = 0.0f;
	}

	private Element<UINode> mNode ~ delete _;
	private ResolvedStyle mTargetStyle = new .() ~ delete _;
	private StyleApplyContext mContext = .();
	private List<AnimationTrack> mTracks = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mAnimations = new .() ~ DeleteContainerAndItems!(_);
	private List<String> mResets = new .() ~ DeleteContainerAndItems!(_); // properties whose tracks just went, to return on the next apply
	private List<String> mEnded = new .() ~ DeleteContainerAndItems!(_); // the animations that told their end (not again until restarted)
	private bool mDone = false;

	public this(UINode node)
	{
		mNode = new .(node);
	}

	/// The style the sheet wants now (copied), and what applying it needs.
	public void SetTargetStyle(ResolvedStyle target, StyleApplyContext context)
	{
		mTargetStyle.Set(target);
		mContext = context;
	}

	public ResolvedStyle TargetStyle => mTargetStyle;

	/// It moves its node only through a property that is not paint alone (a colour or an opacity
	/// changes how the node looks where it is; a transform, a size or a shadow may change where its
	/// drawing reaches).
	public override bool CanMoveTarget
	{
		get
		{
			for (let track in mTracks)
			{
				if (!IsPaintOnlyStyleProperty(track.Property))
					return true;
			}
			return false;
		}
	}

	/// The value a track shows for `property` now, into `outValue`, or false when none moves it (a
	/// transition retargets from here; the target style is already the new one).
	public bool TrackValue(StringView property, StyleValue outValue)
	{
		let ctx = InterpolationContext();
		for (int i = mTracks.Count - 1; i >= 0; i--)
		{
			if ((mTracks[i].Property == property) && mTracks[i].ValueNow(outValue, ctx))
				return true;
		}
		return false;
	}

	/// A transition of `property` from `from` to `to` (replacing one already running on it).
	public void StartTransition(StringView property, StyleValue from, StyleValue to, TransitionSpec spec)
	{
		RemoveTracks(property, default);
		let track = new AnimationTrack();
		track.Property.Set(property);
		track.Duration = spec.Duration;
		track.Delay = spec.Delay;
		track.Fill = .Backwards; // the old value shows through the delay
		track.Keys.Add(new AnimationKey(0.0f, from, spec.Timing));
		track.Keys.Add(new AnimationKey(1.0f, to, Easing.Linear()));
		mTracks.Add(track);
	}

	/// A keyframe animation: one track per property its stops set, each stop's declarations
	/// expanded and parsed; a property missing from the first or last stop takes the target's value
	/// there (CSS's implicit keyframes). A stop's animation-timing-function eases the segment it
	/// starts, the animation's timing the others.
	public void StartKeyframes(AnimationSpec spec, Keyframes keyframes)
	{
		StopKeyframes(spec.Name);
		ForgetEnded(spec.Name);
		let tracks = scope List<AnimationTrack>();
		AnimationTrack TrackFor(StringView property)
		{
			for (let t in tracks)
			{
				if (t.Property == property)
					return t;
			}
			let t = new AnimationTrack();
			t.Property.Set(property);
			t.Animation.Set(spec.Name);
			t.Duration = spec.Duration;
			t.Delay = spec.Delay;
			t.Iterations = spec.Iterations;
			t.Direction = spec.Direction;
			t.Fill = spec.Fill;
			t.Paused = spec.Paused;
			tracks.Add(t);
			return t;
		}
		let longhands = scope List<StyleLonghand>();
		let value = scope StyleValue();
		for (let stop in keyframes.Stops)
		{
			var timing = spec.Timing;
			for (let declared in stop.Properties)
			{
				if (declared.Name == "animation-timing-function")
				{
					let e = ParseEasing(declared.Value);
					if (e.HasValue)
						timing = e.Value;
				}
			}
			for (let declared in stop.Properties)
			{
				if (declared.Name == "animation-timing-function")
					continue;
				ClearAndDeleteItems!(longhands);
				if (!ExpandStyleShorthand(declared.Name, declared.Value, longhands))
					continue;
				for (let longhand in longhands)
				{
					ResolvedStyle.ParseLonghand(longhand.Name, longhand.Text, value);
					if (value.Kind == .None)
						continue;
					let track = TrackFor(longhand.Name);
					track.Keys.Add(new AnimationKey(stop.Offset, value, timing));
				}
			}
		}
		ClearAndDeleteItems!(longhands);
		for (let track in tracks)
		{
			SortKeys(track.Keys);
			let underlying = mTargetStyle.Value(track.Property);
			if ((track.Keys[0].Offset > 0.0f) && (underlying != null))
				track.Keys.Insert(0, new AnimationKey(0.0f, underlying, spec.Timing));
			if ((track.Keys[track.Keys.Count - 1].Offset < 1.0f) && (underlying != null))
				track.Keys.Add(new AnimationKey(1.0f, underlying, spec.Timing));
			mTracks.Add(track);
		}
		tracks.Clear(); // the tracks are this animation's now
		mAnimations.Add(new String(spec.Name));
	}

	public void StopKeyframes(StringView name)
	{
		RemoveTracks(default, name);
		for (int i = 0; i < mAnimations.Count; i++)
		{
			if (mAnimations[i] == name)
			{
				delete mAnimations[i];
				mAnimations.RemoveAt(i);
				break;
			}
		}
	}

	/// Pauses or resumes a keyframe animation (animation-play-state).
	public void SetPaused(StringView name, bool paused)
	{
		for (let t in mTracks)
		{
			if (t.Animation == name)
				t.Paused = paused;
		}
	}

	public bool RunsKeyframes(StringView name)
	{
		for (let n in mAnimations)
		{
			if (n == name)
				return true;
		}
		return false;
	}

	public Span<String> KeyframeAnimations => mAnimations;
	public int TrackCount => mTracks.Count;

	/// Whether something it runs will end and has not (a leaving node waits for it): an infinite
	/// animation or a paused one is not waited for.
	public bool WaitsForEnd
	{
		get
		{
			for (let t in mTracks)
			{
				if (!t.Paused && (t.Iterations >= 0.0f) && !t.Ended)
					return true;
			}
			return false;
		}
	}

	/// Applies the target with every track's value now over it.
	public void ApplyNow()
	{
		let node = mNode.Get();
		if (node == null)
		{
			mDone = true;
			return;
		}
		let effective = scope ResolvedStyle();
		effective.Set(mTargetStyle);
		let ctx = InterpolationContext();
		// A track in its delay or past its end shows the target: the sheet's value, or the node's
		// own when the sheet sets none (the applier returns it there).
		let value = scope StyleValue();
		for (let track in mTracks)
		{
			if (track.ValueNow(value, ctx))
				effective.Override(track.Property, value);
		}
		OverlayMotion(node, effective, ctx); // tweens over the sheet's motion
		ClearAndDeleteItems!(mResets);
		ApplyStyle(node, effective, mContext.Resources, mContext.FontService, mContext.Lengths);
	}

	// === Action ===

	public override void Start()
	{
		ApplyNow();
	}

	public override void Stop()
	{
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		if (mDone)
			return;
		let seconds = (float)elapsed.TotalSeconds;
		for (let track in mTracks)
		{
			if (!track.Paused)
				track.Elapsed += seconds;
		}
		ApplyNow();
		// The animations whose every track has now ended (told once; a forwards fill keeps its
		// tracks, so this is asked before the others go).
		let ends = scope List<MotionEnd>();
		defer { ClearAndDeleteItems!(ends); }
		for (let name in mAnimations)
		{
			bool any = false;
			bool ended = true;
			float ran = 0.0f;
			for (let t in mTracks)
			{
				if (t.Animation == name)
				{
					any = true;
					ended = ended && t.Ended;
					ran = t.Duration * t.Iterations;
				}
			}
			if (any && ended && !HasEnded(name))
			{
				mEnded.Add(new String(name));
				let end = new MotionEnd();
				end.Type = .AnimationEnd;
				end.Name.Set(name);
				end.Elapsed = ran;
				ends.Add(end);
			}
		}
		// Ended tracks that hold nothing go (a forwards fill keeps its track, showing its end).
		for (int i = 0; i < mTracks.Count;)
		{
			let t = mTracks[i];
			let holds = (t.Fill == .Forwards) || (t.Fill == .Both);
			if (t.Ended && (!holds || t.Animation.IsEmpty))
			{
				if (t.Animation.IsEmpty)
				{
					let end = new MotionEnd();
					end.Type = .TransitionEnd;
					end.Name.Set(t.Property);
					end.Elapsed = t.Duration;
					ends.Add(end);
				}
				mResets.Add(new String(t.Property));
				mTracks.RemoveAt(i);
				delete t;
			}
			else
				i++;
		}
		if (!mResets.IsEmpty)
			ApplyNow(); // what the ended tracks moved returns to the target, or its initial value
		let node = mNode.Get();
		if (node == null)
			return;
		// Told after the tick is done: a listener may restyle, retarget or remove the node.
		node.AddRef();
		defer node.ReleaseRef();
		for (let end in ends)
			node.SendEvent(scope MotionEndEvent(end.Type, node, end.Name, end.Elapsed));
		if (node.WatchesMotion && !WaitsForEnd)
			node.MotionSettled();
	}

	public override bool IsDone => mDone || mTracks.IsEmpty;
	public override float CurrentProgress => 0.0f;
	public override TimeSpan TotalTime => default;

	private bool HasEnded(StringView animation)
	{
		for (let name in mEnded)
		{
			if (name == animation)
				return true;
		}
		return false;
	}

	private void ForgetEnded(StringView animation)
	{
		for (int i = 0; i < mEnded.Count; i++)
		{
			if (mEnded[i] == animation)
			{
				delete mEnded[i];
				mEnded.RemoveAt(i);
				return;
			}
		}
	}

	private StyleInterpolationContext InterpolationContext()
	{
		var ctx = StyleInterpolationContext();
		ctx.Lengths = mContext.Lengths;
		let node = mNode.Get();
		if (node != null)
			ctx.BoxSize = node.Size;
		return ctx;
	}

	private static void SortKeys(List<AnimationKey> keys)
	{
		for (int a = 1; a < keys.Count; a++)
		{
			let key = keys[a];
			int b = a;
			while ((b > 0) && (keys[b - 1].Offset > key.Offset))
			{
				keys[b] = keys[b - 1];
				b--;
			}
			keys[b] = key;
		}
	}

	// Removes the tracks of `property` (any, when empty) belonging to `animation` (transitions when
	// empty, unless `property` is empty too).
	private void RemoveTracks(StringView property, StringView animation)
	{
		for (int i = 0; i < mTracks.Count;)
		{
			let t = mTracks[i];
			let match = property.IsEmpty ? (t.Animation == animation) : ((t.Property == property) && t.Animation.IsEmpty);
			if (match)
			{
				mResets.Add(new String(t.Property));
				mTracks.RemoveAt(i);
				delete t;
			}
			else
				i++;
		}
	}
}
