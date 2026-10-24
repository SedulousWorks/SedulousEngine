using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// What `transition` and `animation` declare: their lists, the shorthands expanded into their
// longhands (transition-property, -duration, -timing-function, -delay; animation-name, -duration,
// -timing-function, -delay, -iteration-count, -direction, -fill-mode, -play-state) so each
// cascades on its own, and the specs composed back from the longhands, a shorter list repeating
// to the length of the property or name list, as CSS does.
//
// The specs own their text, so they are classes; a list of them owns its items, which the parsers
// add and the caller deletes.

// === Declarations ===

/// One entry of `transition`: a property (or `all`), a duration, an easing, a delay.
class TransitionSpec
{
	public String Property = new .() ~ delete _;
	public float Duration = 0.0f;
	public float Delay = 0.0f;
	public Easing Timing = Easing.Ease();

	public void Set(TransitionSpec other)
	{
		if (other === this)
			return;
		Property.Set(other.Property);
		Duration = other.Duration;
		Delay = other.Delay;
		Timing = other.Timing;
	}
}

enum AnimationDirection : uint8
{
	Normal,
	Reverse,
	Alternate,
	AlternateReverse,
}

enum AnimationFill : uint8
{
	None,
	Forwards,
	Backwards,
	Both,
}

/// One entry of `animation`.
class AnimationSpec
{
	public String Name = new .() ~ delete _;
	public float Duration = 0.0f;
	public float Delay = 0.0f;
	public Easing Timing = Easing.Ease();
	/// Negative: infinite.
	public float Iterations = 1.0f;
	public AnimationDirection Direction = .Normal;
	public AnimationFill Fill = .None;
	/// animation-play-state: paused.
	public bool Paused = false;

	public void Set(AnimationSpec other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Duration = other.Duration;
		Delay = other.Delay;
		Timing = other.Timing;
		Iterations = other.Iterations;
		Direction = other.Direction;
		Fill = other.Fill;
		Paused = other.Paused;
	}
}

/// What Motion.bf keeps out of the public surface: the longhands' text.
internal static class MotionDetail
{
	public static void AppendListItem(String list, StringView item)
	{
		if (!list.IsEmpty)
			list.Append(", ");
		list.Append(item);
	}

	/// A number in its shortest form that reads back as the same float ("0.3", "1").
	public static void AppendNumber(String outText, float value)
	{
		value.ToString(outText);
	}

	public static void AppendTime(String outText, float seconds)
	{
		AppendNumber(outText, seconds);
		outText.Append('s');
	}

	public static void AppendEasing(String outText, Easing e)
	{
		switch (e.Kind)
		{
		case .Linear:
			outText.Append("linear");
		case .CubicBezier:
			outText.Append("cubic-bezier(");
			AppendNumber(outText, e.X1);
			outText.Append(", ");
			AppendNumber(outText, e.Y1);
			outText.Append(", ");
			AppendNumber(outText, e.X2);
			outText.Append(", ");
			AppendNumber(outText, e.Y2);
			outText.Append(')');
		case .Steps:
			outText.AppendF("steps({}, ", e.Steps);
			outText.Append((e.Position == .JumpStart) ? "jump-start" : ((e.Position == .JumpEnd) ? "jump-end" :
				((e.Position == .JumpNone) ? "jump-none" : "jump-both")));
			outText.Append(')');
		case .Named:
			NamedEasingText(e, outText);
		}
	}

	/// The `index`-th item of a comma list, the list repeating when shorter (CSS's rule for the
	/// longhands); empty when the list is.
	public static StringView Cycled(List<StringView> list, int index) => list.IsEmpty ? StringView() : list[index % list.Count];
}

static
{
	/// `transition`: a comma list of `<property> <duration> [<easing>] [<delay>]` in any order
	/// past the property (the first time is the duration, the second the delay); `none` is
	/// empty. The specs are added to `outSpecs`, which owns them.
	public static void ParseTransitionList(StringView value, List<TransitionSpec> outSpecs)
	{
		if (ParseUtil.Trim(value) == "none")
			return;
		let entries = scope List<StringView>();
		SplitTopLevel(value, ',', entries);
		for (let entry in entries)
		{
			let spec = new TransitionSpec();
			spec.Property.Set("all");
			bool haveDuration = false;
			bool haveProperty = false;
			let tokens = scope List<StringView>();
			SplitTopLevel(entry, ' ', tokens);
			for (let token in tokens)
			{
				let time = ParseTime(token);
				if (time.HasValue)
				{
					if (!haveDuration)
					{
						spec.Duration = time.Value;
						haveDuration = true;
					}
					else
					{
						spec.Delay = time.Value;
					}
					continue;
				}
				let easing = ParseEasing(token);
				if (easing.HasValue)
				{
					spec.Timing = easing.Value;
				}
				else if (!haveProperty)
				{
					spec.Property.Set(token);
					haveProperty = true;
				}
			}
			outSpecs.Add(spec);
		}
	}

	/// `animation`: a comma list of `<name> <duration> [<easing>] [<delay>] [<iteration-count> |
	/// infinite] [<direction>] [<fill-mode>]`, keywords in any order; `none` is empty. The specs
	/// are added to `outSpecs`, which owns them.
	public static void ParseAnimationList(StringView value, List<AnimationSpec> outSpecs)
	{
		if (ParseUtil.Trim(value) == "none")
			return;
		let entries = scope List<StringView>();
		SplitTopLevel(value, ',', entries);
		for (let entry in entries)
		{
			let spec = new AnimationSpec();
			bool haveDuration = false;
			let tokens = scope List<StringView>();
			SplitTopLevel(entry, ' ', tokens);
			for (let token in tokens)
			{
				let time = ParseTime(token);
				if (time.HasValue)
				{
					if (haveDuration)
						spec.Delay = time.Value;
					else
						spec.Duration = time.Value;
					haveDuration = true;
					continue;
				}
				if (token == "infinite")
				{
					spec.Iterations = -1.0f;
					continue;
				}
				let count = ParseLength(token);
				if (count.HasValue && (token.Length > 0) && (ParseUtil.IsDigit(token[0]) || (token[0] == '.')))
				{
					spec.Iterations = Math.Max(0.0f, count.Value);
					continue;
				}
				if (token == "normal")
					spec.Direction = .Normal;
				else if (token == "reverse")
					spec.Direction = .Reverse;
				else if (token == "alternate")
					spec.Direction = .Alternate;
				else if (token == "alternate-reverse")
					spec.Direction = .AlternateReverse;
				else if (token == "forwards")
					spec.Fill = .Forwards;
				else if (token == "backwards")
					spec.Fill = .Backwards;
				else if (token == "both")
					spec.Fill = .Both;
				else if (token == "paused")
					spec.Paused = true;
				else if (token == "running")
					spec.Paused = false;
				else
				{
					let easing = ParseEasing(token);
					if (easing.HasValue)
						spec.Timing = easing.Value;
					else if (spec.Name.IsEmpty)
						spec.Name.Set(token);
				}
			}
			if (!spec.Name.IsEmpty)
				outSpecs.Add(spec);
			else
				delete spec;
		}
	}

	// === The longhands ===

	/// `transition` as its four longhands (each a comma list, one item per entry): their names
	/// and their values added to `names` and `values`, which own them.
	public static void ExpandTransition(StringView value, List<String> names, List<String> values)
	{
		let properties = scope String();
		let durations = scope String();
		let timings = scope String();
		let delays = scope String();
		let specs = scope List<TransitionSpec>();
		defer { ClearAndDeleteItems(specs); }
		ParseTransitionList(value, specs);
		if (specs.IsEmpty)
			properties.Set("none");
		let item = scope String();
		for (let spec in specs)
		{
			MotionDetail.AppendListItem(properties, spec.Property);
			item.Clear();
			MotionDetail.AppendTime(item, spec.Duration);
			MotionDetail.AppendListItem(durations, item);
			item.Clear();
			MotionDetail.AppendEasing(item, spec.Timing);
			MotionDetail.AppendListItem(timings, item);
			item.Clear();
			MotionDetail.AppendTime(item, spec.Delay);
			MotionDetail.AppendListItem(delays, item);
		}
		String[4] longhands = .("transition-property", "transition-duration", "transition-timing-function", "transition-delay");
		String[4] texts = .(properties, durations, timings, delays);
		for (int i = 0; i < 4; i++)
		{
			names.Add(new String(longhands[i]));
			values.Add(new String(texts[i].IsEmpty ? "0s" : texts[i]));
		}
	}

	/// `animation` as its eight longhands, added to `names` and `values`, which own them.
	public static void ExpandAnimation(StringView value, List<String> names, List<String> values)
	{
		let n = scope String();
		let durations = scope String();
		let timings = scope String();
		let delays = scope String();
		let counts = scope String();
		let directions = scope String();
		let fills = scope String();
		let states = scope String();
		let specs = scope List<AnimationSpec>();
		defer { ClearAndDeleteItems(specs); }
		ParseAnimationList(value, specs);
		if (specs.IsEmpty)
			n.Set("none");
		let item = scope String();
		for (let spec in specs)
		{
			MotionDetail.AppendListItem(n, spec.Name);
			item.Clear();
			MotionDetail.AppendTime(item, spec.Duration);
			MotionDetail.AppendListItem(durations, item);
			item.Clear();
			MotionDetail.AppendEasing(item, spec.Timing);
			MotionDetail.AppendListItem(timings, item);
			item.Clear();
			MotionDetail.AppendTime(item, spec.Delay);
			MotionDetail.AppendListItem(delays, item);
			item.Clear();
			if (spec.Iterations < 0.0f)
				item.Append("infinite");
			else
				MotionDetail.AppendNumber(item, spec.Iterations);
			MotionDetail.AppendListItem(counts, item);
			MotionDetail.AppendListItem(directions, (spec.Direction == .Reverse) ? "reverse" : ((spec.Direction == .Alternate) ? "alternate" :
				((spec.Direction == .AlternateReverse) ? "alternate-reverse" : "normal")));
			MotionDetail.AppendListItem(fills, (spec.Fill == .Forwards) ? "forwards" : ((spec.Fill == .Backwards) ? "backwards" :
				((spec.Fill == .Both) ? "both" : "none")));
			MotionDetail.AppendListItem(states, spec.Paused ? "paused" : "running");
		}
		String[8] longhands = .("animation-name", "animation-duration", "animation-timing-function", "animation-delay",
			"animation-iteration-count", "animation-direction", "animation-fill-mode", "animation-play-state");
		String[8] texts = .(n, durations, timings, delays, counts, directions, fills, states);
		String[8] defaults = .("none", "0s", "ease", "0s", "1", "normal", "none", "running");
		for (int i = 0; i < 8; i++)
		{
			names.Add(new String(longhands[i]));
			values.Add(new String(texts[i].IsEmpty ? defaults[i] : texts[i]));
		}
	}

	/// The transitions the longhands declare: one per item of transition-property (none: no
	/// transitions), the other lists repeating to its length; an item that does not parse takes
	/// the longhand's initial value. The specs are added to `outSpecs`, which owns them.
	public static void ComposeTransitions(StringView properties, StringView durations, StringView timings, StringView delays,
		List<TransitionSpec> outSpecs)
	{
		if (properties.IsEmpty || (ParseUtil.Trim(properties) == "none"))
			return;
		let p = scope List<StringView>();
		let d = scope List<StringView>();
		let t = scope List<StringView>();
		let l = scope List<StringView>();
		SplitTopLevel(properties, ',', p);
		SplitTopLevel(durations, ',', d);
		SplitTopLevel(timings, ',', t);
		SplitTopLevel(delays, ',', l);
		for (int i = 0; i < p.Count; i++)
		{
			let spec = new TransitionSpec();
			spec.Property.Set(p[i]);
			spec.Duration = ParseTime(MotionDetail.Cycled(d, i)).GetValueOrDefault(0.0f);
			spec.Timing = ParseEasing(MotionDetail.Cycled(t, i)).GetValueOrDefault(Easing.Ease());
			spec.Delay = ParseTime(MotionDetail.Cycled(l, i)).GetValueOrDefault(0.0f);
			outSpecs.Add(spec);
		}
	}

	/// The animations the longhands declare: one per item of animation-name (none: none). The
	/// specs are added to `outSpecs`, which owns them.
	public static void ComposeAnimations(StringView names, StringView durations, StringView timings, StringView delays,
		StringView counts, StringView directions, StringView fills, StringView states, List<AnimationSpec> outSpecs)
	{
		if (names.IsEmpty || (ParseUtil.Trim(names) == "none"))
			return;
		let n = scope List<StringView>();
		let d = scope List<StringView>();
		let t = scope List<StringView>();
		let l = scope List<StringView>();
		let c = scope List<StringView>();
		let r = scope List<StringView>();
		let f = scope List<StringView>();
		let s = scope List<StringView>();
		SplitTopLevel(names, ',', n);
		SplitTopLevel(durations, ',', d);
		SplitTopLevel(timings, ',', t);
		SplitTopLevel(delays, ',', l);
		SplitTopLevel(counts, ',', c);
		SplitTopLevel(directions, ',', r);
		SplitTopLevel(fills, ',', f);
		SplitTopLevel(states, ',', s);
		for (int i = 0; i < n.Count; i++)
		{
			if (n[i] == "none")
				continue;
			let spec = new AnimationSpec();
			spec.Name.Set(n[i]);
			spec.Duration = ParseTime(MotionDetail.Cycled(d, i)).GetValueOrDefault(0.0f);
			spec.Timing = ParseEasing(MotionDetail.Cycled(t, i)).GetValueOrDefault(Easing.Ease());
			spec.Delay = ParseTime(MotionDetail.Cycled(l, i)).GetValueOrDefault(0.0f);
			let count = MotionDetail.Cycled(c, i);
			spec.Iterations = (count == "infinite") ? -1.0f : Math.Max(0.0f, ParseLength(count).GetValueOrDefault(1.0f));
			let dir = MotionDetail.Cycled(r, i);
			spec.Direction = (dir == "reverse") ? AnimationDirection.Reverse : ((dir == "alternate") ? AnimationDirection.Alternate :
				((dir == "alternate-reverse") ? AnimationDirection.AlternateReverse : AnimationDirection.Normal));
			let fill = MotionDetail.Cycled(f, i);
			spec.Fill = (fill == "forwards") ? AnimationFill.Forwards : ((fill == "backwards") ? AnimationFill.Backwards :
				((fill == "both") ? AnimationFill.Both : AnimationFill.None));
			spec.Paused = MotionDetail.Cycled(s, i) == "paused";
			outSpecs.Add(spec);
		}
	}
}
