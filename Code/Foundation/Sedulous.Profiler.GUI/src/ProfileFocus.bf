using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Profiler.GUI;

// What a profiler page looks at, held once and read by every view on it: the source, the frames
// chosen (one or a range, from the frame strip), the name chosen (a
// scope or a GPU pass, from the timeline or the table) and a span marked on the timeline. A view sets
// them through the focus and draws what it says; none keeps a copy, so the strip, the counters, the
// timeline, the table and the detail stay in step, as TimeAxis keeps a ruler and its views. Nothing
// here draws: the questions the views ask of the frames (a name's time in a frame, the longest and
// the median frame) are answered here, where tests ask them too.

/// A name chosen: a CPU scope's or a GPU pass's (the same id may name both).
struct ChosenName : IEquatable<ChosenName>
{
	public uint32 Name = 0;
	public bool Gpu = false;
	public bool Any = false;

	public this() { }

	public this(uint32 name, bool gpu)
	{
		Name = name;
		Gpu = gpu;
		Any = true;
	}

	public bool Is(uint32 other, bool otherGpu) => Any && (Name == other) && (Gpu == otherGpu);
	public bool Equals(ChosenName other) => (Name == other.Name) && (Gpu == other.Gpu) && (Any == other.Any);
}

/// A span marked on the timeline, in the source's ticks.
struct MarkedSpan : IEquatable<MarkedSpan>
{
	public int64 BeginTick = 0;
	public int64 EndTick = 0;
	public bool Any = false;

	public this() { }

	public bool Equals(MarkedSpan other) => (BeginTick == other.BeginTick) && (EndTick == other.EndTick) && (Any == other.Any);
}

/// What a focus tells the views on it.
interface IProfileFocusClient
{
	/// The source or its frames changed (new frames recorded, another capture shown).
	void OnProfileSourceChanged();
	/// The frames chosen changed.
	void OnProfileFramesChanged();
	/// The name chosen or the span marked changed.
	void OnProfileChoiceChanged();
}

class ProfileFocus : RefCounted
{
	/// Not owned: it outlives the focus or is set to null first.
	private IProfileSource mSource = null;
	private FrameRange mFrames = .();
	private ChosenName mChosen = .();
	private MarkedSpan mSpan = .();
	/// Not owned: each view leaves as it goes.
	private List<IProfileFocusClient> mClients = new .() ~ delete _;

	// === The source ===

	/// What the views read. The choices are let go: the frames and names they name belong to the old
	/// source.
	public void SetSource(IProfileSource source)
	{
		mSource = source;
		mFrames = .();
		mChosen = .();
		mSpan = .();
		for (let client in mClients)
			client.OnProfileSourceChanged();
		for (let client in mClients)
			client.OnProfileFramesChanged();
		for (let client in mClients)
			client.OnProfileChoiceChanged();
	}

	public IProfileSource Source => mSource;

	/// The source has new frames (or dropped old ones): the views read it again.
	public void SourceGrew()
	{
		for (let client in mClients)
			client.OnProfileSourceChanged();
	}

	// === The frames ===

	public FrameRange Frames => mFrames;

	/// Chooses frames (empty: none). The marked span goes: it was a part of the frames before.
	public void SetFrames(FrameRange frames)
	{
		var frames;
		if (frames.Empty)
			frames = .();
		if ((frames.Empty == mFrames.Empty) && (frames.First == mFrames.First) && (frames.Last == mFrames.Last))
			return;
		mFrames = frames;
		let hadSpan = mSpan.Any;
		mSpan = .();
		for (let client in mClients)
			client.OnProfileFramesChanged();
		if (hadSpan)
			Chosen();
	}

	/// One frame chosen.
	public void SetFrame(uint64 frame)
	{
		var range = FrameRange();
		range.First = frame;
		range.Last = frame;
		range.Empty = false;
		SetFrames(range);
	}

	// === The name and the span ===

	public ChosenName Name => mChosen;

	public void SetName(ChosenName name)
	{
		var name;
		if (!name.Any)
			name = .();
		if (name.Equals(mChosen))
			return;
		mChosen = name;
		Chosen();
	}

	public void ChooseName(uint32 name, bool gpu) => SetName(.(name, gpu));
	public void ClearName() => SetName(.());

	public MarkedSpan Span => mSpan;

	/// Marks [begin, end] (in either order; an empty one clears it).
	public void SetSpan(int64 beginTick, int64 endTick)
	{
		var span = MarkedSpan();
		span.BeginTick = Math.Min(beginTick, endTick);
		span.EndTick = Math.Max(beginTick, endTick);
		span.Any = span.EndTick > span.BeginTick;
		if (!span.Any)
			span = .();
		if (span.Equals(mSpan))
			return;
		mSpan = span;
		Chosen();
	}

	public void ClearSpan() => SetSpan(0, 0);

	// === Views ===

	public void Join(IProfileFocusClient client)
	{
		mClients.Add(client);
	}

	public void Leave(IProfileFocusClient client)
	{
		for (int i < mClients.Count)
		{
			if (mClients[i] === client)
			{
				mClients.RemoveAt(i);
				return;
			}
		}
	}

	public int ClientCount => mClients.Count;

	private void Chosen()
	{
		for (let client in mClients)
			client.OnProfileChoiceChanged();
	}
}

/// The questions the views ask of the frames.
static class ProfileFrames
{
	/// The ticks `name` took in `frame`: its CPU scopes on every thread (a scope inside another of the
	/// same name counted once, by the outer) or its GPU passes.
	public static int64 NameTicksInFrame(FrameRecord frame, ChosenName name)
	{
		if (!name.Any)
			return 0;
		int64 ticks = 0;
		if (name.Gpu)
		{
			for (let pass in frame.Gpu)
			{
				if (pass.Name == name.Name)
					ticks += pass.EndTick - pass.BeginTick;
			}
			return ticks;
		}
		for (let thread in frame.Threads)
		{
			// Scopes are in the order they ended, so an outer one of the name comes after the inner
			// ones it holds (a recursive scope): each is counted unless one of the name ended later at
			// a lesser depth around it.
			let scopes = thread.Scopes;
			for (int i < scopes.Count)
			{
				let scopeEvent = scopes[i];
				if (scopeEvent.Name != name.Name)
					continue;
				var inside = false;
				for (int j = i + 1; (j < scopes.Count) && !inside; j++)
				{
					inside = (scopes[j].Name == name.Name) && (scopes[j].Depth < scopeEvent.Depth)
						&& (scopes[j].BeginTick <= scopeEvent.BeginTick) && (scopeEvent.EndTick <= scopes[j].EndTick);
				}
				if (!inside)
					ticks += scopeEvent.EndTick - scopeEvent.BeginTick;
			}
		}
		return ticks;
	}

	/// The frame in `range` that took longest (its CPU time), or none.
	public static FrameRange LongestFrame(IProfileSource source, FrameRange range)
	{
		var longest = FrameRange();
		int64 most = 0;
		for (uint64 n = range.First; !range.Empty && (n <= range.Last); n++)
		{
			let frame = source.Frame(n);
			if (frame == null)
				continue;
			let ticks = frame.EndTick - frame.BeginTick;
			if (longest.Empty || (ticks > most))
			{
				most = ticks;
				longest.First = n;
				longest.Last = n;
				longest.Empty = false;
			}
		}
		return longest;
	}

	/// The frame in `range` whose CPU time is the median (of an even count, the shorter of the middle
	/// two), or none.
	public static FrameRange MedianFrame(IProfileSource source, FrameRange range)
	{
		let frames = scope List<(uint64 frame, int64 ticks)>();
		for (uint64 n = range.First; !range.Empty && (n <= range.Last); n++)
		{
			let frame = source.Frame(n);
			if (frame != null)
				frames.Add((n, frame.EndTick - frame.BeginTick));
		}
		var median = FrameRange();
		if (frames.IsEmpty)
			return median;
		frames.Sort(scope (a, b) => (a.ticks != b.ticks) ? (a.ticks <=> b.ticks) : (a.frame <=> b.frame));
		median.First = frames[(frames.Count - 1) / 2].frame;
		median.Last = median.First;
		median.Empty = false;
		return median;
	}

	/// Every frame the source holds, or none.
	public static FrameRange AllFrames(IProfileSource source)
	{
		var all = FrameRange();
		if ((source == null) || !source.HasFrames)
			return all;
		all.First = source.OldestFrame;
		all.Last = source.NewestFrame;
		all.Empty = false;
		return all;
	}
}
