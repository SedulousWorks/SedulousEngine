using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Motion as an API: a tween moves one property of a node toward a value on its GUI's clock, eased
// by a CSS easing or a named curve. A property a sheet names composes over the cascade, as CSS's
// animation origin does: the tween writes its progress into the node's animated layer and the
// style pass interpolates there, through the typed values the sheets' transitions use, from the
// start given or the value underneath. Any other name is a reflected property, read and written
// through its accessors (numbers, colours and points move; what cannot switches halfway). A tween
// may wait, repeat and run back and forth; at its end it holds its value until stopped or
// replaced. It holds its node weakly (the action's weak target). A tween of a GUI's data value
// (GUIContext.AnimateData) has no node: it moves a number in the data model, which whatever is
// bound to it follows (a score counting up), keeping the value's type (a whole number counts in
// whole numbers).
//
// Tweens and groups are reference counted, as every action is: whoever makes one (or is handed
// one by Animate, CreateTween and the rest) releases its reference; a manager or a group running
// it holds one of its own.
//
// To a script they are counted handles (Raptor's names, in PascalCase): a handle is a reference
// of the script's own, so a tween a script keeps outlives the manager's (a kept tween's IsDone
// reads after it ended), and one kept past its GUI finds no target. The shaping verbs give back
// the tween or group itself, lent, so a script chains them as native code does.

[Scriptable]
class Tween : Sedulous.GUI.Action
{
	private enum Route : uint8
	{
		Unbound,
		Style,
		Reflected,
		/// A data model's value.
		Data,
	}

	private String mProperty = new .() ~ delete _;
	private String mToText = new .() ~ delete _;
	private String mFromText = new .() ~ delete _;
	private bool mHasFrom = false;
	private float mSeconds = 0.0f;
	private float mDelay = 0.0f;
	private int32 mIterations = 1;
	private bool mPingPong = false;
	private Easing mEasing;
	private delegate void() mOnFinished ~ delete _;

	private bool mSpring = false;
	private float mStiffness = 170.0f;
	private float mDamping = 26.0f;
	private float mMass = 1.0f;
	private float mSpringX = 0.0f; // progress, past 1 when it overshoots
	private float mSpringV = 0.0f; // its speed, in progress per second

	private Route mRoute = .Unbound;
	private GuiPropertyInfo mReflected = null;
	private DataModel mData = null ~ _?.ReleaseRef(); // the model whose value it moves, or none
	private Type mDataType = null; // the value's type, kept as it moves
	private bool mWhole = false; // a data value's: whole numbers only
	private System.Variant mFrom ~ _.Dispose();
	private System.Variant mTo ~ _.Dispose();
	private uint64 mOwner = 0; // its mark in the layer
	private float mElapsed = 0.0f;
	private float mOverrun = 0.0f;
	private float mProgress = 0.0f;
	private bool mDone = false;

	public this(StringView property, StringView to, float seconds, Easing easing)
	{
		mProperty.Set(property);
		mToText.Set(to);
		mSeconds = Math.Max(0.0f, seconds);
		mEasing = easing;
		mOwner = NextTweenOwner();
	}

	/// Moves the data value its property names in `model`, rather than a node's property (the
	/// tween takes a reference to the model).
	public void TargetData(DataModel model)
	{
		if (model != null)
			model.AddRef();
		mData?.ReleaseRef();
		mData = model;
	}

	public bool MovesData => mData != null;

	// === Shaping (before its first frame) ===

	/// Where it starts, as a value of its property (else the value showing).
	[Scriptable]
	public Tween From(StringView text)
	{
		mFromText.Set(text);
		mHasFrom = true;
		return this;
	}

	/// How long it waits first, in seconds.
	[Scriptable]
	public Tween Delay(float seconds)
	{
		mDelay = Math.Max(0.0f, seconds);
		return this;
	}

	/// How many times it runs (1 by default; a negative count runs until stopped). `Repeats` to a
	/// script, as Raptor names it (`repeat` is a word of Luau's).
	[Scriptable, ScriptName("Repeats")]
	public Tween Repeat(int32 count)
	{
		mIterations = count;
		return this;
	}

	/// Every other run goes back from the end to the start.
	[Scriptable]
	public Tween PingPong(bool on = true)
	{
		mPingPong = on;
		return this;
	}

	public Tween Ease(Easing easing)
	{
		mEasing = easing;
		return this;
	}

	/// Ease for a script: the easing as a sheet names it (a CSS easing or a named curve), `ease`
	/// when the text is none. `Ease` to a script.
	[Scriptable, ScriptName("Ease")]
	public Tween EaseScript(StringView easing) => Ease(ParseEasing(easing).GetValueOrDefault(Easing.Ease()));

	/// A data value's tween counts in whole numbers: each value it writes rounded to the nearest (a
	/// score; a script's numbers all arrive as fractions, so its type cannot say).
	[Scriptable]
	public Tween Whole(bool on = true)
	{
		mWhole = on;
		return this;
	}

	/// Moves as a damped spring toward its end rather than over a time (GPUI's and react-spring's
	/// springs): `stiffness` pulls, `damping` slows, `mass` resists; little damping overshoots and
	/// rings. Its duration, easing, repeats and ping-pong no longer apply; it ends once settled.
	[Scriptable]
	public Tween Spring(float stiffness = 170.0f, float damping = 26.0f, float mass = 1.0f)
	{
		mSpring = true;
		mStiffness = Math.Max(0.0f, stiffness);
		mDamping = Math.Max(0.0f, damping);
		mMass = Math.Max(1e-4f, mass);
		return this;
	}

	public bool IsSpring => mSpring;

	/// Called once it reaches its end (not when stopped or replaced). OWNERSHIP of `callback`
	/// transfers (one set before is deleted).
	public Tween OnFinished(delegate void() callback)
	{
		delete mOnFinished;
		mOnFinished = callback;
		return this;
	}

	/// OnFinished with a script function. OWNERSHIP of `handler` transfers: the callback holds it,
	/// and it goes with the tween (or the next one set); none set leaves the one before. A dead
	/// function is not called. `OnFinished` to a script.
	[Scriptable, ScriptName("OnFinished")]
	public Tween OnFinishedScript(ScriptDelegate handler)
	{
		if (handler == null)
			return this;
		return OnFinished(new [=handler] () =>
			{
				var result = ScriptValue.Nil;
				GuiScriptDetail.Call(handler, default, ref result);
			} ~ { delete handler; });
	}

	public StringView Property => mProperty;

	/// Whether it composes over the cascade (a property a sheet names) rather than through a
	/// reflected property. Known once it has run a frame.
	public bool MovesStyle => mRoute == .Style;

	/// Sends it toward another end from where it is now, its speed carried over: a drag that
	/// settles, a menu that follows the pointer, without a jolt.
	[Scriptable]
	public void Retarget(StringView to)
	{
		mToText.Set(to);
		let target = ResolveTarget();
		if (((target == null) && (mData == null)) || (mRoute == .Unbound))
			return; // it reads its end at its first frame
		if (!mSpring)
			mElapsed = mDelay; // a timed tween runs its time again, from where it is
		if (mRoute == .Style)
		{
			let node = target as UINode;
			let motion = (node != null) ? node.FindMotion(mProperty) : null;
			let nextValue = scope StyleValue();
			ResolvedStyle.ParseLonghand(mProperty, to, nextValue);
			if ((motion == null) || (motion.Owner != mOwner) || (nextValue.Kind == .None))
				return;
			let nowValue = scope StyleValue();
			if (motion.HasUnder)
				InterpolateStyleValue(motion.Under, motion.To, motion.Progress, nowValue);
			else
				nowValue.Set(motion.Shown);
			let before = motion.HasUnder ? Distance(motion.Under, motion.To) : 0.0f;
			CarrySpeed(before, Distance(nowValue, nextValue));
			motion.From.Set(nowValue);
			motion.HasFrom = true;
			motion.To.Set(nextValue);
			motion.Progress = 0.0f;
			node.MarkStyleMotionDirty();
			return;
		}
		if (mRoute == .Data)
		{
			let end = TextRunsDetail.ParseFloat(ParseUtil.Trim(to));
			if (!end.HasValue)
				return;
			// From the value showing (a whole number's rounding aside, where it is).
			var shown = Mix(mFrom, mTo, mSpring ? mSpringX : mEasing.Evaluate(mProgress));
			var ending = System.Variant.Create(end.Value);
			CarrySpeed(Distance(mFrom, mTo), Distance(shown, ending));
			mFrom.Dispose();
			mFrom = shown;
			mTo.Dispose();
			mTo = ending;
			return;
		}
		var next = StyleApplierDetail.ParseForProperty(mReflected, to, LengthContext());
		if (!next.HasValue)
			return;
		var now = Mix(mFrom, mTo, mSpringX);
		CarrySpeed(Distance(mFrom, mTo), Distance(now, next));
		mFrom.Dispose();
		mFrom = now;
		mTo.Dispose();
		mTo = next;
	}

	/// Stops it and gives its property back to the sheet (a reflected property keeps the value it
	/// has).
	[Scriptable]
	public void Cancel()
	{
		if ((mData != null) && (mData.TweenOwnerOf(mProperty) == mOwner))
			mData.ClaimTween(mProperty, 0); // the value stays as it is
		if (mRoute == .Style)
		{
			let node = ResolveTarget() as UINode;
			if (node != null)
			{
				let motion = node.FindMotion(mProperty);
				if ((motion != null) && (motion.Owner == mOwner))
					node.RemoveMotion(mProperty);
			}
		}
		mDone = true;
	}

	/// Another tween took its property: it stops where it is, leaving the value to the new one.
	public void Replace()
	{
		mDone = true;
	}

	// === Action ===

	/// Starting (run, or reached in its group, or again for a group's next run) it takes its
	/// property from any other tween moving it, and reads its values afresh at its first frame.
	public override void Start()
	{
		mElapsed = 0.0f;
		mOverrun = 0.0f;
		mDone = false;
		mRoute = .Unbound;
		mSpringX = 0.0f;
		mSpringV = 0.0f;
		if (mData != null)
			mData.ClaimTween(mProperty, mOwner); // the one moving it gives way
		else
			TweenImplDetail.ReplaceOthersOf(this);
	}

	public override void Stop()
	{
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		if (mDone)
			return;
		let target = ResolveTarget();
		if ((target == null) && (mData == null))
		{
			mDone = true;
			return;
		}
		let step = (float)elapsed.TotalSeconds;
		mElapsed += step;
		let active = mElapsed - mDelay;
		if (active < 0.0f)
			return; // waiting: the property shows what it did
		if ((mRoute == .Unbound) && !((mData != null) ? BindData() : Bind(target)))
		{
			mDone = true;
			return;
		}
		// Another tween took the data value: stop where it is.
		if ((mRoute == .Data) && (mData.TweenOwnerOf(mProperty) != mOwner))
		{
			mDone = true;
			return;
		}
		// Superseded through the layer (another writer took the property): stop.
		if (mRoute == .Style)
		{
			let node = target as UINode;
			let motion = (node != null) ? node.FindMotion(mProperty) : null;
			if ((motion == null) || (motion.Owner != mOwner))
			{
				mDone = true;
				return;
			}
		}
		if (mSpring)
		{
			StepSpring(Math.Min(active, step));
			let settled = (Math.Abs(1.0f - mSpringX) < 1e-3f) && (Math.Abs(mSpringV) < 1e-3f);
			if (settled)
				mSpringX = 1.0f;
			mProgress = Math.Clamp(mSpringX, 0.0f, 1.0f);
			Write(target, mSpringX);
			if (settled)
			{
				mDone = true;
				if (mOnFinished != null)
					mOnFinished();
				FireDone();
			}
			return;
		}
		bool finished = false;
		float local = 1.0f;
		uint32 run = 0;
		if (mSeconds <= 0.0f)
		{
			finished = true;
			run = (mIterations > 0) ? (uint32)(mIterations - 1) : 0;
			mOverrun = active;
		}
		else
		{
			let runs = active / mSeconds;
			let count = Math.Max(mIterations, 1);
			if ((mIterations >= 0) && (runs >= (float)count))
			{
				finished = true;
				run = (uint32)(count - 1);
				mOverrun = active - mSeconds * (float)count;
			}
			else
			{
				run = (uint32)Math.Floor(runs);
				local = runs - (float)run;
			}
		}
		if (mPingPong && ((run % 2) == 1))
			local = 1.0f - local;
		mProgress = local;
		Write(target, mEasing.Evaluate(local));
		if (finished)
		{
			mDone = true;
			if (mOnFinished != null)
				mOnFinished();
			FireDone();
		}
	}

	/// Marked here, as an override carries none of the base's attributes.
	[Scriptable]
	public override bool IsDone => mDone;
	public override float CurrentProgress => mProgress;
	public override TimeSpan TotalTime => TweenDetail.SecondsSpan((double)(mDelay + mSeconds * (float)Math.Max(mIterations, 1)));
	public override bool CanMoveTarget => !IsPaintOnlyStyleProperty(mProperty);
	public override TimeSpan Overrun => TweenDetail.SecondsSpan((double)mOverrun);

	// The spring's progress toward 1 over `seconds`, in small steps (semi-implicit Euler holds a
	// stiff spring steady where one big step would fly off).
	private void StepSpring(float seconds)
	{
		const float cStep = 1.0f / 240.0f;
		var left = seconds;
		while (left > 0.0f)
		{
			let h = Math.Min(left, cStep);
			let force = -mStiffness * (mSpringX - 1.0f) - mDamping * mSpringV;
			mSpringV += force / mMass * h;
			mSpringX += mSpringV * h;
			left -= h;
		}
	}

	// How far apart two values are, where that has a measure (a number, a length of one unit, a
	// colour, a point); 0 where it has none.
	private static float Distance(StyleValue a, StyleValue b)
	{
		if (a.Kind != b.Kind)
			return 0.0f;
		switch (a.Kind)
		{
		case .Number:
			return Math.Abs(b.Number - a.Number);
		case .Length:
			return (a.Length.Unit == b.Length.Unit) ? Math.Abs(b.Length.Value - a.Length.Value) : 0.0f;
		case .ColorValue:
			let r = b.ColorValue.R - a.ColorValue.R;
			let g = b.ColorValue.G - a.ColorValue.G;
			let bl = b.ColorValue.B - a.ColorValue.B;
			let al = b.ColorValue.A - a.ColorValue.A;
			return Math.Sqrt(r * r + g * g + bl * bl + al * al);
		default:
			return 0.0f;
		}
	}

	private static float Distance(System.Variant a, System.Variant b)
	{
		let ta = a.VariantType;
		let tb = b.VariantType;
		if ((ta == null) || (ta != tb))
			return 0.0f;
		if (ta == typeof(float))
			return Math.Abs(b.Get<float>() - a.Get<float>());
		if (ta == typeof(double))
		{
			let x = a.Get<double>();
			let y = b.Get<double>();
			return (float)((y > x) ? y - x : x - y);
		}
		if (ta == typeof(int32))
			return Math.Abs((float)(b.Get<int32>() - a.Get<int32>()));
		if (ta == typeof(Float2))
		{
			let x = a.Get<Float2>();
			let y = b.Get<Float2>();
			return Length(Float2(y.X - x.X, y.Y - x.Y));
		}
		return 0.0f;
	}

	// The speed carried to a new span: the same speed in the value's own units where both spans
	// have a measure, the same speed in progress where not.
	private void CarrySpeed(float before, float after)
	{
		if ((before > 0.0f) && (after > 0.0f))
			mSpringV *= before / after;
		mSpringX = 0.0f;
	}

	// Whether code set `name` on the node (its slot pinned, as an inline style): the sheet leaves it
	// alone then, and so would the style's motion layer.
	private static bool PinnedByCode(Node node, StringView name)
	{
		for (uint32 slot = 0; slot < (uint32)StyleSlot.SlotCount; slot++)
		{
			if (StyleSlotProperty((StyleSlot)slot) == name)
				return node.IsStylePinned((StyleSlot)slot);
		}
		return false;
	}

	// Its first frame: which way it writes, and its values parsed.
	private bool Bind(Node target)
	{
		// A sheet's property on a node a sheet styles; on any other node, its reflected one (a plain
		// node's opacity, x, y), and so where code set the property itself: code's value is the
		// node's own, which the style pass leaves alone, so the tween moves it as code would, from
		// where it is.
		let node = target as UINode;
		if ((node != null) && (FindStyleProperty(mProperty) != null) && !PinnedByCode(node, mProperty))
		{
			let motion = scope MotionValue();
			motion.Property.Set(mProperty);
			ResolvedStyle.ParseLonghand(mProperty, mToText, motion.To);
			if (motion.To.Kind == .None)
				return false;
			if (mHasFrom)
			{
				ResolvedStyle.ParseLonghand(mProperty, mFromText, motion.From);
				motion.HasFrom = motion.From.Kind != .None;
			}
			else
			{
				let before = node.FindMotion(mProperty);
				if ((before != null) && before.HasShown)
				{
					// From where the tween before it is now: its progress may have moved since the
					// style pass last showed it (it ended this frame, before the pass).
					if (before.HasUnder)
						InterpolateStyleValue(before.Under, before.To, before.Progress, motion.From);
					else
						motion.From.Set(before.Shown);
					motion.HasFrom = true;
				}
			}
			motion.Owner = mOwner;
			node.SetMotion(motion);
			mRoute = .Style;
			return true;
		}
		// The property a sheet does not name, by its CSS name or its reflected one.
		mReflected = target.GuiType.Find(mProperty);
		if ((mReflected == null) || !mReflected.CanWrite)
			return false;
		mTo.Dispose();
		mTo = StyleApplierDetail.ParseForProperty(mReflected, mToText, LengthContext());
		if (!mTo.HasValue)
			return false;
		mFrom.Dispose();
		mFrom = mHasFrom ? StyleApplierDetail.ParseForProperty(mReflected, mFromText, LengthContext()) : mReflected.Get(target);
		if (!mFrom.HasValue)
			mFrom = mReflected.Get(target);
		mRoute = .Reflected;
		return true;
	}

	// Its first frame, for a data value: from the value now (or the start given), toward its end,
	// both numbers; the value's own type kept (a number when it has none yet).
	private bool BindData()
	{
		let to = TextRunsDetail.ParseFloat(ParseUtil.Trim(mToText));
		if (!to.HasValue)
			return false;
		let now = mData.Peek(mProperty); // a view: not disposed
		double from = 0.0;
		NumberOf(now, out from);
		if (mHasFrom)
			from = TextRunsDetail.ParseFloat(ParseUtil.Trim(mFromText)).GetValueOrDefault(from);
		mDataType = (now.HasValue && NumberOf(now, let probe) && (now.VariantType != typeof(bool))) ? now.VariantType : typeof(double);
		mFrom.Dispose();
		mFrom = System.Variant.Create(from);
		mTo.Dispose();
		mTo = System.Variant.Create(to.Value);
		mRoute = .Data;
		return true;
	}

	// The value at eased progress `t`.
	private void Write(Node target, float t)
	{
		if (mRoute == .Data)
		{
			var mixed = Mix(mFrom, mTo, t);
			defer mixed.Dispose();
			if (mWhole && (mixed.VariantType == typeof(double)))
			{
				let n = mixed.Get<double>();
				mixed.Dispose();
				mixed = System.Variant.Create((n < 0.0) ? -Math.Floor(-n + 0.5) : Math.Floor(n + 0.5));
			}
			var typed = (mDataType != null) ? ConvertVariant(mixed, mDataType) : default(System.Variant);
			defer typed.Dispose();
			mData.Set(mProperty, typed.HasValue ? typed : mixed);
			return;
		}
		if (target == null)
			return;
		if (mRoute == .Style)
		{
			let node = target as UINode;
			let motion = node.FindMotion(mProperty);
			if (motion != null)
			{
				motion.Progress = t;
				node.MarkStyleMotionDirty();
			}
			return;
		}
		var value = Mix(mFrom, mTo, t);
		defer value.Dispose();
		mReflected.Set(target, value);
	}

	// Numbers, colours and points move; anything else switches halfway, as CSS's discrete values.
	// The caller disposes what comes back.
	private static System.Variant Mix(System.Variant a, System.Variant b, float t)
	{
		float Lerp(float x, float y) => x + (y - x) * t;
		let ta = a.VariantType;
		let tb = b.VariantType;
		if ((ta != null) && (ta == tb))
		{
			if (ta == typeof(float))
				return System.Variant.Create(Lerp(a.Get<float>(), b.Get<float>()));
			if (ta == typeof(double))
			{
				let x = a.Get<double>();
				let y = b.Get<double>();
				return System.Variant.Create(x + (y - x) * (double)t);
			}
			if (ta == typeof(int32))
				return System.Variant.Create((int32)Math.Round(Lerp((float)a.Get<int32>(), (float)b.Get<int32>())));
			if (ta == typeof(Color))
			{
				let x = a.Get<Color>();
				let y = b.Get<Color>();
				return System.Variant.Create(Color(Lerp(x.R, y.R), Lerp(x.G, y.G), Lerp(x.B, y.B), Lerp(x.A, y.A)));
			}
			if (ta == typeof(Float2))
			{
				let x = a.Get<Float2>();
				let y = b.Get<Float2>();
				return System.Variant.Create(Float2(Lerp(x.X, y.X), Lerp(x.Y, y.Y)));
			}
		}
		return CopyVariant((t < 0.5f) ? a : b);
	}
}

/// What Tween.bf keeps out of the public surface.
internal static class TweenDetail
{
	/// `seconds` as a time span, by ticks (TimeSpan.FromSeconds rounds to whole milliseconds).
	public static TimeSpan SecondsSpan(double seconds) => TimeSpan((int64)(seconds * (double)TimeSpan.TicksPerSecond));
}

// === Groups ===

/// A step of a group that waits.
class TweenWait : Sedulous.GUI.Action
{
	private float mSeconds;
	private float mElapsed = 0.0f;
	private bool mDone = false;

	public this(float seconds)
	{
		mSeconds = Math.Max(0.0f, seconds);
	}

	public override void Start()
	{
		mElapsed = 0.0f;
		mDone = false;
	}

	public override void Stop()
	{
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		if (mDone)
			return;
		mElapsed += (float)elapsed.TotalSeconds;
		mDone = mElapsed >= mSeconds;
	}

	public override bool IsDone => mDone;
	public override float CurrentProgress => (mSeconds > 0.0f) ? Math.Min(1.0f, mElapsed / mSeconds) : 1.0f;
	public override TimeSpan TotalTime => TweenDetail.SecondsSpan((double)mSeconds);
	public override bool CanMoveTarget => false;
	public override TimeSpan Overrun => TweenDetail.SecondsSpan((double)Math.Max(0.0f, mElapsed - mSeconds));
}

/// A step of a group that calls back, taking no time.
class TweenCall : Sedulous.GUI.Action
{
	private delegate void() mCallback ~ delete _;
	private float mOverrun = 0.0f;
	private bool mDone = false;

	/// OWNERSHIP of `callback` transfers.
	public this(delegate void() callback)
	{
		mCallback = callback;
	}

	public override void Start()
	{
		mDone = false;
		mOverrun = 0.0f;
	}

	public override void Stop()
	{
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		if (mDone)
			return;
		mDone = true;
		mOverrun = (float)elapsed.TotalSeconds;
		if (mCallback != null)
			mCallback();
	}

	public override bool IsDone => mDone;
	public override float CurrentProgress => mDone ? 1.0f : 0.0f;
	public override TimeSpan TotalTime => default;
	public override bool CanMoveTarget => false;
	public override TimeSpan Overrun => TweenDetail.SecondsSpan((double)mOverrun);
}

/// Steps run as one (Zero's action groups, Godot's chained and parallel tweens, foundation.ui's
/// storyboards): tweens of any nodes, waits, calls and other groups, one after another
/// (TweenSequence) or together (TweenParallel), repeated as a whole, calling back at the end. Run
/// it on a node (RunAction): the node's GUI keeps its time; each step keeps its own target. A
/// script makes a TweenSequence or TweenParallel, and plays it with Node.Play.
[Scriptable]
abstract class TweenGroup : Sedulous.GUI.Action
{
	/// Each holds a reference of the group's.
	protected List<Sedulous.GUI.Action> mSteps = new .() ~ { for (let s in _) s.ReleaseRef(); delete _; };

	private int32 mIterations = 1;
	private uint32 mRun = 0;
	private float mOverrun = 0.0f;
	private bool mDone = false;
	private delegate void() mOnFinished ~ delete _;

	/// Adds a step: the group takes a reference of its own (the caller keeps, and releases, the one
	/// it holds).
	public TweenGroup Add(Sedulous.GUI.Action step)
	{
		if (step != null)
		{
			step.AddRef();
			mSteps.Add(step);
		}
		return this;
	}

	/// Adds a tween as a step: Add for a script, whose handle keeps its own reference. `Add` to a
	/// script.
	[Scriptable, ScriptName("Add")]
	public TweenGroup AddScript(Tween tween) => Add(tween);

	/// Adds a group as a step (a sequence in a parallel group, or the other way). `AddGroup` to a
	/// script.
	[Scriptable, ScriptName("AddGroup")]
	public TweenGroup AddGroupScript(TweenGroup group) => Add(group);

	[Scriptable]
	public TweenGroup Wait(float seconds)
	{
		let wait = new TweenWait(seconds);
		Add(wait);
		wait.ReleaseRef();
		return this;
	}

	/// OWNERSHIP of `callback` transfers.
	public TweenGroup Call(delegate void() callback)
	{
		let call = new TweenCall(callback);
		Add(call);
		call.ReleaseRef();
		return this;
	}

	/// A step that calls a script function. OWNERSHIP of `handler` transfers: the step holds it,
	/// and it goes with the group; a dead function, or none, is a step that calls nothing. `Call`
	/// to a script.
	[Scriptable, ScriptName("Call")]
	public TweenGroup CallScript(ScriptDelegate handler)
	{
		return Call(new [=handler] () =>
			{
				if (handler == null)
					return;
				var result = ScriptValue.Nil;
				GuiScriptDetail.Call(handler, default, ref result);
			} ~ { delete handler; });
	}

	/// How many times it runs (1 by default; a negative count runs until stopped). `Repeats` to a
	/// script, as Raptor names it.
	[Scriptable, ScriptName("Repeats")]
	public TweenGroup Repeat(int32 count)
	{
		mIterations = count;
		return this;
	}

	/// OWNERSHIP of `callback` transfers (one set before is deleted).
	public TweenGroup OnFinished(delegate void() callback)
	{
		delete mOnFinished;
		mOnFinished = callback;
		return this;
	}

	/// OnFinished with a script function, as Tween.OnFinishedScript takes one. `OnFinished` to a
	/// script.
	[Scriptable, ScriptName("OnFinished")]
	public TweenGroup OnFinishedScript(ScriptDelegate handler)
	{
		if (handler == null)
			return this;
		return OnFinished(new [=handler] () =>
			{
				var result = ScriptValue.Nil;
				GuiScriptDetail.Call(handler, default, ref result);
			} ~ { delete handler; });
	}

	public int StepCount => mSteps.Count;

	/// Calls `f(step)` for each step running now (a replacement finds a tween inside a group).
	public void ForEachRunning(delegate void(Sedulous.GUI.Action step) f)
	{
		for (let step in mSteps)
		{
			if (IsRunning(step))
				f(step);
		}
	}

	public override void Start()
	{
		mRun = 0;
		mDone = false;
		mOverrun = 0.0f;
		StartRun();
	}

	public override void Stop()
	{
		for (let step in mSteps)
			step.Stop();
		mDone = true;
	}

	public override void Update(TimeSpan elapsed)
	{
		var seconds = (float)elapsed.TotalSeconds;
		for (uint32 guard = 0; !mDone && (guard < 64); guard++)
		{
			float over = 0.0f;
			if (!Advance(seconds, ref over))
				return;
			mRun++;
			if ((mIterations >= 0) && (mRun >= (uint32)Math.Max(mIterations, 1)))
			{
				mDone = true;
				mOverrun = over;
				if (mOnFinished != null)
					mOnFinished();
				FireDone();
				return;
			}
			StartRun();
			if (over <= 0.0f)
				return;
			seconds = over; // the next run takes what this one left
		}
	}

	/// Marked here, as an override carries none of the base's attributes.
	[Scriptable]
	public override bool IsDone => mDone;
	public override float CurrentProgress => 0.0f;
	public override TimeSpan TotalTime => default;

	public override bool CanMoveTarget
	{
		get
		{
			for (let step in mSteps)
			{
				if (step.CanMoveTarget)
					return true;
			}
			return false;
		}
	}

	public override TimeSpan Overrun => TweenDetail.SecondsSpan((double)mOverrun);

	protected abstract void StartRun();
	/// Runs the steps `seconds` on; true when this run has ended, with what it left over.
	protected abstract bool Advance(float seconds, ref float overrun);
	protected abstract bool IsRunning(Sedulous.GUI.Action step);
}

/// Steps one after another: each starts as the last ends, with the time it left.
[Scriptable]
class TweenSequence : TweenGroup
{
	private int mIndex = 0;

	/// A script makes one (`TweenSequence()`): counted, so the reference it is made with is handed
	/// over to the script's handle.
	[Scriptable]
	public this()
	{
	}

	protected override void StartRun()
	{
		mIndex = 0;
		if (!mSteps.IsEmpty)
			mSteps[0].Start();
	}

	protected override bool Advance(float seconds, ref float overrun)
	{
		var left = seconds;
		while (mIndex < mSteps.Count)
		{
			let step = mSteps[mIndex];
			step.Update(TweenDetail.SecondsSpan((double)left));
			if (!step.IsDone)
				return false;
			left = (float)step.Overrun.TotalSeconds;
			if (++mIndex < mSteps.Count)
				mSteps[mIndex].Start();
		}
		overrun = left;
		return true;
	}

	protected override bool IsRunning(Sedulous.GUI.Action step) => (mIndex < mSteps.Count) && (mSteps[mIndex] == step);
}

/// Steps together: the run ends with the last of them.
[Scriptable]
class TweenParallel : TweenGroup
{
	/// A script makes one (`TweenParallel()`), as it makes a sequence.
	[Scriptable]
	public this()
	{
	}

	protected override void StartRun()
	{
		for (let step in mSteps)
			step.Start();
	}

	protected override bool Advance(float seconds, ref float overrun)
	{
		bool all = true;
		float least = seconds;
		for (let step in mSteps)
		{
			if (step.IsDone)
				continue;
			step.Update(TweenDetail.SecondsSpan((double)seconds));
			if (step.IsDone)
				least = Math.Min(least, (float)step.Overrun.TotalSeconds);
			else
				all = false;
		}
		overrun = least; // the time past the end of the step that ended last
		return all;
	}

	protected override bool IsRunning(Sedulous.GUI.Action step) => !step.IsDone;
}
