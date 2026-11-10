using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using Sedulous.GUI;

namespace Sedulous.Profiler.GUI;

// The name chosen, apart: its calls, total, mean and longest over
// the frames chosen (the span's, when one is marked) and the lanes it ran in; what it was called
// from; its children by name with their share of it, its own time last; and how long its calls take
// over every frame the source holds, as a histogram whose bars holding the frames chosen's calls are
// lit. Its longest call in the frames chosen is the one a page zooms the timeline to.

[GuiReflect(true)]
class ScopeDetail : ProfilerWidget
{
	public const int cBins = 24;
	public const float cLineHeight = 18.0f;
	public const float cHistogramHeight = 56.0f;

	/// One of the name's children by name, or its own time.
	public class Child
	{
		public String Name = new .() ~ delete _;
		public uint32 Id = 0;
		public int64 Ticks = 0;
		/// Its own time, not a child's.
		public bool IsSelf = false;
	}

	/// What it says about the name chosen.
	public class Summary
	{
		public bool Any = false;
		public uint64 Calls = 0;
		public int64 TotalTicks = 0;
		public int64 MaxTicks = 0;
		/// The lanes it ran in, by name.
		public String Lanes = new .() ~ delete _;
		/// What it was called from: "Physics.Step (Main)".
		public List<String> Callers = new .() ~ DeleteContainerAndItems!(_);
		/// By their time, the longest first; its own time last.
		public List<Child> Children = new .() ~ DeleteContainerAndItems!(_);
		/// cBins: its calls' durations over every frame held.
		public List<uint32> Bins = new .() ~ delete _;
		/// cBins: where a call of the frames chosen falls.
		public List<bool> Lit = new .() ~ delete _;
		public int64 BinLeast = 0;
		public int64 BinMost = 0;
		public uint64 HeldCalls = 0;
		public uint32 HeldFrames = 0;
		/// Its longest call in the frames chosen.
		public int64 LongestBegin = 0;
		public int64 LongestEnd = 0;

		public void Clear()
		{
			Any = false;
			Calls = 0;
			TotalTicks = 0;
			MaxTicks = 0;
			Lanes.Clear();
			ClearAndDeleteItems!(Callers);
			ClearAndDeleteItems!(Children);
			Bins.Clear();
			Lit.Clear();
			BinLeast = 0;
			BinMost = 0;
			HeldCalls = 0;
			HeldFrames = 0;
			LongestBegin = 0;
			LongestEnd = 0;
		}
	}

	private Summary mSummary = new .() ~ delete _;
	private bool mDirty = true;

	/// The parts it draws, which the sheet styles as `tag::part`.
	public override void CollectStyleParts(List<StringView> outParts)
	{
		base.CollectStyleParts(outParts);
		outParts.Add("title");
		outParts.Add("heading");
		outParts.Add("note");
		outParts.Add("track");
		outParts.Add("self");
		outParts.Add("plot");
		outParts.Add("bar");
		outParts.Add("lit");
	}
	public this()
	{
		Tag = "scopedetail";
		TabFocusable = false;
	}

	public Summary Describe
	{
		get
		{
			Refresh();
			return mSummary;
		}
	}

	/// Its longest call in the frames chosen (false: none chosen, or it did not run there).
	public bool LongestCall(out int64 begin, out int64 end)
	{
		let summary = Describe;
		begin = summary.LongestBegin;
		end = summary.LongestEnd;
		return summary.Any && (summary.LongestEnd > summary.LongestBegin);
	}

	public override void OnProfileSourceChanged() => Dirty();
	public override void OnProfileFramesChanged() => Dirty();
	public override void OnProfileChoiceChanged() => Dirty();

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let summary = Describe;
		let @box = ContentBounds;
		let source = Source;
		let text = TextColor;
		let dim = PartTextColor("note");
		let heading = PartTextColor("heading");
		let line = scope String();
		ctx.PushClip(@box);
		defer ctx.PopClip();
		var y = @box.Y;
		if (!summary.Any || (source == null))
		{
			DrawLabel(ctx, "Choose a scope on the timeline or in the table", .(@box.X, y, @box.Width, cLineHeight), dim);
			return;
		}
		let chosen = mFocus.Name;
		let name = source.NameOf(chosen.Name);
		let frequency = source.TickFrequency;
		// The swatch centred on the title's own line, which is taller than the others.
		let titleHeight = cLineHeight + 4.0f;
		ctx.VG.FillRoundedRect(.(@box.X, y + titleHeight * 0.5f - 5.0f, 10.0f, 10.0f), 2.0f, NameColor(name));
		DrawLabel(ctx, name, .(@box.X + 16.0f, y, @box.Width - 16.0f, titleHeight), PartTextColor("title"));
		y += cLineHeight + 6.0f;
		line.AppendF("{} {} on {}   total {:F2}   mean {:F2}   max {:F2} ms", summary.Calls, (summary.Calls == 1) ? "call" : "calls", summary.Lanes,
			ProfileWindow.TicksToMs(summary.TotalTicks, frequency),
			(summary.Calls > 0) ? (ProfileWindow.TicksToMs(summary.TotalTicks, frequency) / (float)summary.Calls) : 0.0f,
			ProfileWindow.TicksToMs(summary.MaxTicks, frequency));
		DrawLabel(ctx, line, .(@box.X, y, @box.Width, cLineHeight), dim);
		y += cLineHeight + 8.0f;

		DrawLabel(ctx, "Called from", .(@box.X, y, @box.Width, cLineHeight), heading);
		y += cLineHeight;
		for (let caller in summary.Callers)
		{
			DrawLabel(ctx, caller, .(@box.X, y, @box.Width, cLineHeight), dim);
			y += cLineHeight;
		}
		y += 8.0f;

		if (!summary.Children.IsEmpty)
		{
			DrawLabel(ctx, "Children", .(@box.X, y, @box.Width, cLineHeight), heading);
			y += cLineHeight;
			let track = PartColor("track", .(0.0f, 0.0f, 0.0f, 0.18f));
			for (let child in summary.Children)
			{
				let share = (summary.TotalTicks > 0) ? ((float)child.Ticks / (float)summary.TotalTicks) : 0.0f;
				let swatch = child.IsSelf ? PartColor("self", .(0.6f, 0.6f, 0.6f, 1.0f)) : NameColor(child.Name);
				ctx.VG.FillRoundedRect(.(@box.X, y + cLineHeight * 0.5f - 5.0f, 10.0f, 10.0f), 2.0f, swatch);
				DrawLabel(ctx, child.Name, .(@box.X + 16.0f, y, @box.Width * 0.55f, cLineHeight), text);
				line.Clear();
				line.AppendF("{:F2} ms  {:F0}%", ProfileWindow.TicksToMs(child.Ticks, frequency), share * 100.0f);
				DrawLabel(ctx, line, .(@box.X, y, @box.Width, cLineHeight), dim, .End);
				y += cLineHeight;
				ctx.VG.FillRoundedRect(.(@box.X, y, @box.Width, 5.0f), 2.5f, track);
				ctx.VG.FillRoundedRect(.(@box.X, y, Math.Max(@box.Width * share, 2.0f), 5.0f), 2.5f, swatch);
				y += 8.0f;
			}
			y += 6.0f;
		}

		line.Clear();
		line.AppendF("Durations over {} frames ({} calls)", summary.HeldFrames, summary.HeldCalls);
		DrawLabel(ctx, line, .(@box.X, y, @box.Width, cLineHeight), heading);
		y += cLineHeight + 2.0f;
		let plot = Rect(@box.X, y, @box.Width, cHistogramHeight);
		ctx.VG.FillRect(plot.ToRectangle(), PartColor("plot", .(0.0f, 0.0f, 0.0f, 0.18f)));
		uint32 most = 1;
		for (let count in summary.Bins)
			most = Math.Max(most, count);
		let bar = PartColor("bar", .(0.44f, 0.53f, 0.72f, 1.0f));
		let lit = PartColor("lit", .(0.18f, 0.43f, 0.87f, 1.0f));
		let binWidth = plot.Width / (float)cBins;
		for (int b < summary.Bins.Count)
		{
			if (summary.Bins[b] == 0)
				continue;
			let h = 2.0f + (float)summary.Bins[b] / (float)most * (plot.Height - 4.0f);
			ctx.VG.FillRect(.(plot.X + (float)b * binWidth + binWidth * 0.1f, plot.Bottom - h, binWidth * 0.8f, h), summary.Lit[b] ? lit : bar);
		}
		y += cHistogramHeight + 2.0f;
		line.Clear();
		line.AppendF("{:F2} ms", ProfileWindow.TicksToMs(summary.BinLeast, frequency));
		DrawLabel(ctx, line, .(@box.X, y, @box.Width, cLineHeight), dim);
		line.Clear();
		line.AppendF("{:F2} ms", ProfileWindow.TicksToMs(summary.BinMost, frequency));
		DrawLabel(ctx, line, .(@box.X, y, @box.Width, cLineHeight), dim, .End);
	}

	private void Dirty()
	{
		mDirty = true;
		Invalidate();
	}

	private void Refresh()
	{
		if (!mDirty)
			return;
		mDirty = false;
		let @out = mSummary;
		@out.Clear();
		let source = Source;
		if ((source == null) || !mFocus.Name.Any)
			return;
		let chosen = mFocus.Name;
		let tree = scope ScopeTree();
		tree.Build(source, mFocus.Frames, mFocus.Span);
		let lanes = scope List<uint32>();
		let caller = scope String();
		for (let node in tree.Nodes)
		{
			if (node.Group || (node.Name != chosen.Name) || (node.Gpu != chosen.Gpu) || (node.Calls == 0))
				continue;
			@out.Any = true;
			@out.Calls += node.Calls;
			@out.TotalTicks += node.TotalTicks;
			@out.MaxTicks = Math.Max(@out.MaxTicks, node.MaxTicks);
			// The lanes it ran in, each once.
			let group = Root(tree, node);
			if (!lanes.Contains(group))
			{
				lanes.Add(group);
				if (!@out.Lanes.IsEmpty)
					@out.Lanes.Append(", ");
				@out.Lanes.Append(tree.Nodes[(int)group].GroupName);
			}
			// What called it, each once.
			let parent = tree.Nodes[node.Parent];
			caller.Clear();
			if (parent.Group)
				caller.AppendF("The top of {}", parent.GroupName);
			else
				caller.AppendF("{} ({})", source.NameOf(parent.Name), tree.Nodes[(int)group].GroupName);
			var known = false;
			for (let at in @out.Callers)
				known = known || (at == caller);
			if (!known)
				@out.Callers.Add(new String(caller));
			// Its children by name, and its own time.
			for (let child in node.Children)
				AddChildTime(@out, source.NameOf(tree.Nodes[(int)child].Name), tree.Nodes[(int)child].Name, tree.Nodes[(int)child].TotalTicks, false);
			AddChildTime(@out, "Self", 0, node.SelfTicks, true);
		}
		if (!@out.Any)
			return;
		@out.Children.Sort(scope (a, b) =>
			{
				if (a.IsSelf != b.IsSelf)
					return a.IsSelf ? 1 : -1;
				return b.Ticks <=> a.Ticks;
			});
		Spread(source, chosen, @out);
	}

	// The group (the lane) a node hangs from.
	private static uint32 Root(ScopeTree tree, ScopeNode node)
	{
		var at = node;
		var index = (uint32)tree.Nodes.IndexOf(node);
		while (at.Parent >= 0)
		{
			index = (uint32)at.Parent;
			at = tree.Nodes[(int)index];
		}
		return index;
	}

	private static void AddChildTime(Summary @out, StringView name, uint32 id, int64 ticks, bool self)
	{
		for (let at in @out.Children)
		{
			if ((at.IsSelf == self) && (self || (at.Id == id)))
			{
				at.Ticks += ticks;
				return;
			}
		}
		let child = new Child();
		child.Name.Set(name);
		child.Id = id;
		child.Ticks = ticks;
		child.IsSelf = self;
		@out.Children.Add(child);
	}

	private struct Call
	{
		public int64 Ticks;
		public bool InChosen;

		public this(int64 ticks, bool inChosen)
		{
			Ticks = ticks;
			InChosen = inChosen;
		}
	}

	// Its calls' durations over every frame held; the frames chosen's calls lit; its longest call in
	// the frames chosen.
	private void Spread(IProfileSource source, ChosenName chosen, Summary @out)
	{
		let calls = scope List<Call>();
		let frames = mFocus.Frames;
		let all = ProfileFrames.AllFrames(source);
		int64 longest = 0;
		if (!all.Empty)
		{
			for (var n = all.First; n <= all.Last; n++)
			{
				let frame = source.Frame(n);
				if (frame == null)
					continue;
				@out.HeldFrames++;
				let inChosen = !frames.Empty && (n >= frames.First) && (n <= frames.Last);
				void Take(int64 begin, int64 end)
				{
					calls.Add(.(end - begin, inChosen));
					if (inChosen && (end - begin > longest))
					{
						longest = end - begin;
						@out.LongestBegin = begin;
						@out.LongestEnd = end;
					}
				}
				if (chosen.Gpu)
				{
					for (let pass in frame.Gpu)
					{
						if (pass.Name == chosen.Name)
							Take(pass.BeginTick, pass.EndTick);
					}
				}
				else
				{
					for (let thread in frame.Threads)
					{
						for (let scopeEvent in thread.Scopes)
						{
							if (scopeEvent.Name == chosen.Name)
								Take(scopeEvent.BeginTick, scopeEvent.EndTick);
						}
					}
				}
			}
		}
		for (int b < cBins)
		{
			@out.Bins.Add(0);
			@out.Lit.Add(false);
		}
		@out.HeldCalls = (uint64)calls.Count;
		if (calls.IsEmpty)
			return;
		@out.BinLeast = calls[0].Ticks;
		@out.BinMost = calls[0].Ticks;
		for (let call in calls)
		{
			@out.BinLeast = Math.Min(@out.BinLeast, call.Ticks);
			@out.BinMost = Math.Max(@out.BinMost, call.Ticks);
		}
		let width = (double)Math.Max(@out.BinMost - @out.BinLeast, 1);
		for (let call in calls)
		{
			let bin = Math.Min((int)((double)(call.Ticks - @out.BinLeast) / width * (double)cBins), cBins - 1);
			@out.Bins[bin]++;
			if (call.InChosen)
				@out.Lit[bin] = true;
		}
	}
}
