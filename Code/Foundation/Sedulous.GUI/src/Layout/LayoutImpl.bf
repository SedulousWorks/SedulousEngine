using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Layout: Node's measure and arrange, and the display kinds they run: flex (CSS's algorithm: base
// sizes, lines, grow and shrink with minimums freezing, stretch, justify and align), grid
// (explicit and implicit tracks of lengths, percentages, auto and fr, items placed by line or
// flowed, spans), stack (children over each other, each aligned on its own), dock (children to the
// sides in order), then the out-of-flow children by their insets. One algorithm per kind serves
// both measuring (the content's size within the space available) and arranging (placing the
// children in the content box), so the two can never disagree. Scrolling (the range, the bars,
// smooth scrolls and flings, a scroller's own input) and the layout overlay are here too.

/// What LayoutImpl.bf keeps out of the public surface: the display kinds' algorithms.
internal static class LayoutImplDetail
{
	public const float cMinThumb = 20.0f;
	/// Seconds an overlay's bars stay once let be, and then take to fade.
	public const float cOverlayLinger = 0.8f;
	public const float cOverlayFade = 0.3f;
	/// A finger's speed has a ceiling (a stray sample must not throw the page a mile).
	public const float cMaxFlingSpeed = 8000.0f;
	/// Seconds for a fling's speed to fall to a third; and the speed (offset units a second) that is
	/// stopped.
	public const float cFlingTau = 0.35f;
	public const float cFlingStopSpeed = 12.0f;
	/// A smooth scroll's time constant: the rest of the way shrinks by e^(-t/tau).
	public const float cSmoothTau = 0.06f;

	public static bool Scrolls(Overflow o) => (o == .Scroll) || (o == .Auto);

	public static bool InFlow(Node node) => node.Displayed && !node.InTopLayer && (node.LayoutStyle.Placement != .Absolute);

	// Both axes sized by the style, not by what is inside: the node's size does not follow its
	// content, so a change inside it stops at it.
	public static bool HasDefiniteSize(Node node)
	{
		let s = node.LayoutStyle;
		return Definite(s.Width) && Definite(s.Height);
	}

	private static bool Definite(LayoutLength l) => (l.Kind == .Px) || (l.Kind == .Percent) || (l.Kind == .Calc);

	public static float Less(float available, float by) => IsUnbounded(available) ? cUnbounded : Max(0.0f, available - by);
	public static float BaseOf(float available) => IsUnbounded(available) ? -1.0f : available;

	// One layout run over a container's children: its content box (Width and Height, cUnbounded on
	// an axis with no limit), where that box starts, and whether to place the children or only
	// measure them.
	public struct Flow
	{
		public Node Container;
		public Sedulous.GUI.LayoutStyle Style;
		public float Width;
		public float Height;
		public Float2 Origin;
		public bool Arrange;
		/// Right to left: laid out as left to right with each child's left and right margins
		/// swapped, then mirrored within the box (LayoutChildren), so its margins stay where its
		/// style puts them.
		public bool Rtl = false;

		public this(Node container, Sedulous.GUI.LayoutStyle style, float width, float height, Float2 origin, bool arrange)
		{
			Container = container;
			Style = style;
			Width = width;
			Height = height;
			Origin = origin;
			Arrange = arrange;
		}
	}

	// A child's margin-box size within the space given (the size its own style and content want,
	// kept within the space less its margins).
	public static Float2 MeasureItem(Node child, float availW, float availH, Float2 percentBase)
	{
		let m = child.GetMarginWithin(percentBase.X);
		var c = LayoutConstraints();
		c.Max = .(Less(availW, m.TotalHorizontal), Less(availH, m.TotalVertical));
		c.PercentBase = percentBase;
		let border = child.Measure(c);
		return .(border.X + m.TotalHorizontal, border.Y + m.TotalVertical);
	}

	// The border-box size of a child given its size on some axes (tight) and a limit on the others.
	public static Float2 MeasureBorder(Node child, float? w, float? h, float maxW, float maxH, Float2 percentBase)
	{
		var c = LayoutConstraints();
		c.Min = .(w.HasValue ? w.Value : 0.0f, h.HasValue ? h.Value : 0.0f);
		c.Max = .(w.HasValue ? w.Value : maxW, h.HasValue ? h.Value : maxH);
		c.PercentBase = percentBase;
		c.ExactWidth = w.HasValue;
		c.ExactHeight = h.HasValue;
		return child.Measure(c);
	}

	// The child's margin as the flow lays it out: in right to left, left and right swapped (the
	// mirror puts them back).
	public static Thickness FlowMargin(Flow f, Node child)
	{
		var m = child.GetMarginWithin(BaseOf(f.Width));
		if (f.Rtl)
		{
			let left = m.Left;
			m.Left = m.Right;
			m.Right = left;
		}
		return m;
	}

	// The gaps between a container's columns and its rows: their lengths and their percentages of
	// its content width and height (none where those are unbounded).
	public static float ColumnGapOf(Flow f) => f.Style.ColumnGap + (IsUnbounded(f.Width) ? 0.0f : f.Style.ColumnGapPercent * 0.01f * f.Width);
	public static float RowGapOf(Flow f) => f.Style.RowGap + (IsUnbounded(f.Height) ? 0.0f : f.Style.RowGapPercent * 0.01f * f.Height);

	public static void Place(Flow f, Node child, float x, float y, float w, float h)
	{
		if (f.Arrange)
			child.Arrange(.(f.Origin.X + x, f.Origin.Y + y, Max(0.0f, w), Max(0.0f, h)));
	}

	public static Align SelfAlign(Align self, Align container) => (self == .Auto) ? container : self;

	// The in-flow children in their `order` (stable).
	public static void FlowChildren(Node container, List<Node> outItems)
	{
		for (int i = 0; i < container.ChildCount; i++)
		{
			let child = container.GetChildAt(i);
			if ((child != null) && InFlow(child))
				outItems.Add(child);
		}
		for (int i = 1; i < outItems.Count; i++) // insertion sort: stable, and lists are short
		{
			for (int j = i; (j > 0) && (outItems[j].LayoutStyle.Order < outItems[j - 1].LayoutStyle.Order); j--)
			{
				let swap = outItems[j];
				outItems[j] = outItems[j - 1];
				outItems[j - 1] = swap;
			}
		}
	}

	// Where `count` items along `free` space start and how far apart they are.
	public static void Distribute(Justify justify, float free, int count, out float start, out float between)
	{
		start = 0.0f;
		between = 0.0f;
		if ((free <= 0.0f) || (count == 0))
		{
			if (justify == .End)
				start = free;
			else if (justify == .Center)
				start = free * 0.5f;
			return;
		}
		switch (justify)
		{
		case .End: start = free;
		case .Center: start = free * 0.5f;
		case .SpaceBetween: between = (count > 1) ? free / (float)(count - 1) : 0.0f;
		case .SpaceAround:
			between = free / (float)count;
			start = between * 0.5f;
		case .SpaceEvenly:
			between = free / (float)(count + 1);
			start = between;
		default:
		}
	}

	// === Flex ===

	public struct FlexItem
	{
		public Node Node = null;
		public Thickness Margin = .();
		public float MarginMain = 0.0f;
		public float MarginCross = 0.0f;
		/// The flex base size (border box).
		public float Base = 0.0f;
		/// Resolved.
		public float Main = 0.0f;
		/// Border box.
		public float Cross = 0.0f;
		/// Down from its margin box's top, when it aligns by baseline.
		public float Baseline = 0.0f;
		public float MinMain = 0.0f;
		public float MaxMain = cUnbounded;
		public bool MinMainKnown = false;
		public bool Frozen = false;
		public bool Stretch = false;
		public Align Align = .Start;

		public this() { }
	}

	public struct FlexLine
	{
		public int Start = 0;
		public int Count = 0;
		public float Cross = 0.0f;
		/// Where its baseline-aligned items' baselines meet, down from its top.
		public float Baseline = 0.0f;

		public this() { }

		public this(int start, int count, float cross)
		{
			Start = start;
			Count = count;
			Cross = cross;
		}
	}

	public static Float2 Flex(Flow f)
	{
		let s = f.Style;
		let row = (s.Direction == .Row) || (s.Direction == .RowReverse);
		let reverse = (s.Direction == .RowReverse) || (s.Direction == .ColumnReverse);
		let mainAvail = row ? f.Width : f.Height;
		let crossAvail = row ? f.Height : f.Width;
		let mainDefinite = !IsUnbounded(mainAvail);
		let crossDefinite = !IsUnbounded(crossAvail);
		let mainGap = row ? ColumnGapOf(f) : RowGapOf(f);
		let crossGap = row ? RowGapOf(f) : ColumnGapOf(f);
		let percentBase = Float2(BaseOf(f.Width), BaseOf(f.Height));

		let children = scope List<Node>();
		FlowChildren(f.Container, children);
		let items = scope List<FlexItem>();
		for (let child in children)
		{
			let cs = child.LayoutStyle;
			var item = FlexItem();
			item.Node = child;
			item.Margin = FlowMargin(f, child);
			item.MarginMain = row ? item.Margin.TotalHorizontal : item.Margin.TotalVertical;
			item.MarginCross = row ? item.Margin.TotalVertical : item.Margin.TotalHorizontal;
			item.Align = SelfAlign(cs.AlignSelf, s.AlignItems);
			let crossSize = row ? cs.Height : cs.Width;
			item.Stretch = (item.Align == .Stretch) && crossSize.IsAuto;
			// The base size: flex-basis, else the main size its style gives, else its content's
			// (max-content along the main axis, at the cross size it will have when stretched).
			let basis = cs.Basis.Resolve(BaseOf(mainAvail));
			if (basis.HasValue)
				item.Base = basis.Value;
			else
			{
				let crossLimit = Less(crossAvail, item.MarginCross);
				let crossTight = (item.Stretch && crossDefinite) ? (float?)crossLimit : (float?)null;
				let b = row ? MeasureBorder(child, null, crossTight, cUnbounded, crossLimit, percentBase)
					: MeasureBorder(child, crossTight, null, crossLimit, cUnbounded, percentBase);
				item.Base = row ? b.X : b.Y;
			}
			let minL = row ? cs.MinWidth : cs.MinHeight;
			let maxL = row ? cs.MaxWidth : cs.MaxHeight;
			let mn = minL.Resolve(BaseOf(mainAvail));
			if (mn.HasValue)
			{
				item.MinMain = mn.Value;
				item.MinMainKnown = true;
			}
			let mx = maxL.Resolve(BaseOf(mainAvail));
			if (mx.HasValue)
				item.MaxMain = mx.Value;
			items.Add(item);
		}

		// Lines: break where the next item does not fit, when wrapping into a known length.
		let lines = scope List<FlexLine>();
		{
			var line = FlexLine();
			float used = 0.0f;
			for (int i = 0; i < items.Count; i++)
			{
				let size = items[i].Base + items[i].MarginMain;
				let needed = (line.Count == 0) ? size : used + mainGap + size;
				if ((s.Wrap != .NoWrap) && mainDefinite && (line.Count > 0) && (needed > mainAvail + 0.5f))
				{
					lines.Add(line);
					line = FlexLine(i, 0, 0.0f);
					used = 0.0f;
				}
				used = (line.Count == 0) ? size : used + mainGap + size;
				line.Count++;
			}
			if ((line.Count > 0) || lines.IsEmpty)
				lines.Add(line);
		}

		float contentMain = 0.0f;
		for (int li = 0; li < lines.Count; li++)
		{
			var line = lines[li];
			let gaps = mainGap * (float)((line.Count > 0) ? line.Count - 1 : 0);
			// Grow into free space, or shrink out of the overflow (each in proportion to its shrink
			// times its base size, frozen at its minimum: its content's when auto).
			float used = gaps;
			for (int i = line.Start; i < line.Start + line.Count; i++)
			{
				items[i].Main = items[i].Base;
				items[i].Frozen = false;
				used += items[i].Base + items[i].MarginMain;
			}
			float grown = 0.0f; // the free space the line's items grew into
			if (mainDefinite)
			{
				let free = mainAvail - used;
				if (free > 0.0f)
				{
					float grow = 0.0f;
					for (int i = line.Start; i < line.Start + line.Count; i++)
						grow += items[i].Node.LayoutStyle.Grow;
					if (grow > 0.0f)
					{
						for (int i = line.Start; i < line.Start + line.Count; i++)
							items[i].Main += free * items[i].Node.LayoutStyle.Grow / grow;
						grown = free;
					}
				}
				else if (free < 0.0f)
				{
					for (int round = 0; round <= line.Count; round++)
					{
						float fixedSum = gaps;
						float scaled = 0.0f;
						for (int i = line.Start; i < line.Start + line.Count; i++)
						{
							let shrink = items[i].Node.LayoutStyle.Shrink;
							if (items[i].Frozen || (shrink <= 0.0f))
								fixedSum += items[i].Main + items[i].MarginMain;
							else
							{
								fixedSum += items[i].Base + items[i].MarginMain;
								scaled += shrink * items[i].Base;
							}
						}
						let overflow = fixedSum - mainAvail;
						if ((overflow <= 0.0f) || (scaled <= 0.0f))
							break;
						bool froze = false;
						for (int i = line.Start; i < line.Start + line.Count; i++)
						{
							let shrink = items[i].Node.LayoutStyle.Shrink;
							if (items[i].Frozen || (shrink <= 0.0f))
								continue;
							if (!items[i].MinMainKnown) // min auto: the content's minimum, no more than its specified size
							{
								let n = items[i].Node;
								let chrome = n.Chrome;
								let content = n.MeasureContentOnGrid(row ? Float2(0.0f, Less(crossAvail, items[i].MarginCross + chrome.TotalVertical))
									: Float2(Less(crossAvail, items[i].MarginCross + chrome.TotalHorizontal), 0.0f));
								var minContent = row ? content.X + chrome.TotalHorizontal : content.Y + chrome.TotalVertical;
								let ns = n.LayoutStyle;
								// A scroll container's on an axis it scrolls is none (as CSS's): its
								// content scrolls inside it rather than sizing it, or a virtualised
								// list grows with the rows it realises.
								if (Scrolls(row ? ns.OverflowX : ns.OverflowY))
									minContent = row ? chrome.TotalHorizontal : chrome.TotalVertical;
								let specified = (row ? ns.Width : ns.Height).Resolve(BaseOf(mainAvail));
								if (specified.HasValue)
									minContent = Min(minContent, specified.Value);
								items[i].MinMain = minContent;
								items[i].MinMainKnown = true;
							}
							items[i].Main = items[i].Base - overflow * shrink * items[i].Base / scaled;
							if (items[i].Main <= items[i].MinMain)
							{
								items[i].Main = items[i].MinMain;
								items[i].Frozen = true;
								froze = true;
							}
						}
						if (!froze)
							break;
					}
				}
			}
			float lineMain = gaps;
			line.Cross = 0.0f;
			float aboveBaseline = 0.0f; // the baseline-aligned items' reach above and below it
			float belowBaseline = 0.0f;
			for (int i = line.Start; i < line.Start + line.Count; i++)
			{
				var item = items[i];
				item.Main = Clamp(item.Main, item.MinMainKnown ? Min(item.MinMain, item.Main) : 0.0f, item.MaxMain);
				let ns = item.Node.LayoutStyle;
				if ((ns.MinWidth.Kind == .Px) && row)
					item.Main = Max(item.Main, ns.MinWidth.Value);
				if ((ns.MinHeight.Kind == .Px) && !row)
					item.Main = Max(item.Main, ns.MinHeight.Value);
				// Its cross size at that main size (text wraps to the width it was given). A row's
				// item that does not stretch is as tall as its content, as a box's height follows
				// its content whatever the space (it overflows a short row); a column's is kept
				// within the width, where text wraps.
				let crossLimit = (row && !item.Stretch) ? cUnbounded : Less(crossAvail, item.MarginCross);
				let b = row ? MeasureBorder(item.Node, item.Main, null, item.Main, crossLimit, percentBase)
					: MeasureBorder(item.Node, null, item.Main, crossLimit, item.Main, percentBase);
				item.Cross = row ? b.Y : b.X;
				line.Cross = Max(line.Cross, item.Cross + item.MarginCross);
				lineMain += item.Main + item.MarginMain;
				// Baselines line up across a row; in a column, baseline is start (as in CSS).
				if (row && (item.Align == .Baseline))
				{
					item.Baseline = item.Margin.Top + item.Node.BaselineAt(.(item.Main, item.Cross));
					aboveBaseline = Max(aboveBaseline, item.Baseline);
					belowBaseline = Max(belowBaseline, item.Cross + item.MarginCross - item.Baseline);
				}
				items[i] = item;
			}
			line.Baseline = aboveBaseline;
			line.Cross = Max(line.Cross, aboveBaseline + belowBaseline);
			// Measuring, the space along is a limit, not a size: the content is as long as its items
			// before they grow (a button's text grows to fill the button, yet a button asked its size
			// in a wide column is as wide as its text, not the column). Placing, it is the size the
			// items were given. The items' depth is at their grown size either way, the size they
			// get when the container fills the space.
			contentMain = Max(contentMain, (f.Arrange || (grown <= 0.0f)) ? lineMain : Max(lineMain - grown, Min(used, lineMain)));
			lines[li] = line;
		}
		// One line is as deep as the container, once it is laid out at its size. Measuring, the
		// space across is a limit, not a size: the content is as deep as its line (a size the
		// container is told exactly, Measure gives it).
		if ((lines.Count == 1) && crossDefinite && f.Arrange)
			lines[0].Cross = crossAvail;
		float contentCross = crossGap * (float)((lines.Count > 0) ? lines.Count - 1 : 0);
		for (let line in lines)
			contentCross += line.Cross;

		if (f.Arrange)
		{
			// Lines across: align-content shares the free cross space (stretch: each line grows by
			// the same).
			float crossStart = 0.0f;
			float crossBetween = 0.0f;
			if (crossDefinite && (lines.Count > 1))
			{
				let free = crossAvail - contentCross;
				if ((s.AlignContent == .Stretch) && (free > 0.0f))
				{
					for (int li = 0; li < lines.Count; li++)
						lines[li].Cross += free / (float)lines.Count;
				}
				else
					Distribute(s.AlignContent, free, lines.Count, out crossStart, out crossBetween);
			}
			float crossPos = crossStart;
			let mainExtent = mainDefinite ? mainAvail : contentMain;
			for (int li = 0; li < lines.Count; li++)
			{
				let line = lines[(s.Wrap == .WrapReverse) ? lines.Count - 1 - li : li];
				float used = mainGap * (float)((line.Count > 0) ? line.Count - 1 : 0);
				for (int i = line.Start; i < line.Start + line.Count; i++)
					used += items[i].Main + items[i].MarginMain;
				Distribute(s.JustifyContent, mainDefinite ? mainAvail - used : 0.0f, line.Count, let start, let between);
				float mainPos = start;
				for (int k = 0; k < line.Count; k++)
				{
					let item = items[line.Start + k];
					var cross = item.Cross;
					float crossOffset = 0.0f;
					let room = line.Cross - item.MarginCross;
					switch (item.Align)
					{
					case .End: crossOffset = room - cross;
					case .Center: crossOffset = (room - cross) * 0.5f;
					case .Stretch:
						if (item.Stretch)
						{
							let cs = item.Node.LayoutStyle;
							let mx = (row ? cs.MaxHeight : cs.MaxWidth).Resolve(BaseOf(crossAvail));
							cross = mx.HasValue ? Min(room, mx.Value) : room;
						}
					case .Baseline:
						if (row)
							crossOffset = line.Baseline - item.Baseline;
					default:
					}
					let mainEdge = reverse ? mainExtent - mainPos - item.Main - item.MarginMain : mainPos;
					let mainAt = mainEdge + (row ? item.Margin.Left : item.Margin.Top);
					let crossAt = crossPos + crossOffset + (row ? item.Margin.Top : item.Margin.Left);
					if (row)
						Place(f, item.Node, mainAt, crossAt, item.Main, cross);
					else
						Place(f, item.Node, crossAt, mainAt, cross, item.Main);
					mainPos += item.Main + item.MarginMain + mainGap + between;
				}
				crossPos += line.Cross + crossGap + crossBetween;
			}
		}
		return row ? Float2(contentMain, contentCross) : Float2(contentCross, contentMain);
	}

	// === Grid ===

	public struct GridItem
	{
		public Node Node = null;
		public int32 Column = 0;
		public int32 Row = 0;
		public int32 ColumnSpan = 1;
		public int32 RowSpan = 1;

		public this() { }

		public this(Node node, int32 column, int32 row, int32 columnSpan, int32 rowSpan)
		{
			Node = node;
			Column = column;
			Row = row;
			ColumnSpan = columnSpan;
			RowSpan = rowSpan;
		}
	}

	// Places items on the grid: those with both lines where they say, the rest flowed into the
	// first cells free (row by row, or column by column). Gives the track counts.
	public static void PlaceGridItems(Sedulous.GUI.LayoutStyle s, List<GridItem> items, out int32 columns, out int32 rows)
	{
		let byRow = s.AutoFlow == .Row;
		int32 columnCount = Math.Max((int32)1, (int32)s.Columns.Count);
		int32 rowCount = Math.Max((int32)0, (int32)s.Rows.Count);
		for (let item in items)
		{
			if (item.Column > 0)
				columnCount = Math.Max(columnCount, item.Column + item.ColumnSpan - 1);
			if (byRow)
				columnCount = Math.Max(columnCount, item.ColumnSpan);
		}
		let taken = scope List<bool>(); // rows x columns (byRow) or columns x rows
		let across = byRow ? columnCount : Math.Max((int32)1, rowCount);
		int32 along = 0;
		void Grow(int32 to)
		{
			while (along < to)
			{
				for (int32 b = 0; b < across; b++)
					taken.Add(false);
				along++;
			}
		}
		bool Fits(int32 a, int32 b, int32 spanA, int32 spanB)
		{
			if (b + spanB > across)
				return false;
			Grow(a + spanA);
			for (int32 i = a; i < a + spanA; i++)
			{
				for (int32 j = b; j < b + spanB; j++)
				{
					if (taken[(int)(i * across + j)])
						return false;
				}
			}
			return true;
		}
		void Take(int32 a, int32 b, int32 spanA, int32 spanB)
		{
			Grow(a + spanA);
			for (int32 i = a; i < a + spanA; i++)
			{
				for (int32 j = b; j < b + spanB; j++)
					taken[(int)(i * across + j)] = true;
			}
		}
		int32 cursorA = 0;
		int32 cursorB = 0;
		for (int k = 0; k < items.Count; k++)
		{
			var item = items[k];
			var a = byRow ? item.Row : item.Column; // along the flow
			var b = byRow ? item.Column : item.Row; // across it
			let spanA = byRow ? item.RowSpan : item.ColumnSpan;
			let spanB = Math.Min(byRow ? item.ColumnSpan : item.RowSpan, across);
			if ((a > 0) && (b > 0))
			{
				a--;
				b--;
				Take(a, b, spanA, spanB);
			}
			else if (b > 0) // its cross line given: the first free place along it
			{
				b--;
				int32 at = 0;
				while (!Fits(at, b, spanA, spanB))
					at++;
				a = at;
				Take(a, b, spanA, spanB);
			}
			else if (a > 0) // its line along the flow given: the first free cell in it
			{
				a--;
				int32 at = 0;
				while ((at < across) && !Fits(a, at, spanA, spanB))
					at++;
				b = Math.Min(at, across - spanB);
				Take(a, b, spanA, spanB);
			}
			else
			{
				while (!Fits(cursorA, cursorB, spanA, spanB))
				{
					if (++cursorB + spanB > across)
					{
						cursorB = 0;
						cursorA++;
					}
				}
				a = cursorA;
				b = cursorB;
				Take(a, b, spanA, spanB);
				cursorB += spanB;
			}
			if (byRow)
			{
				item.Row = a;
				item.Column = b;
			}
			else
			{
				item.Column = a;
				item.Row = b;
			}
			items[k] = item;
		}
		if (byRow)
			rowCount = Math.Max(rowCount, along);
		else
			columnCount = Math.Max(columnCount, along);
		columns = columnCount;
		rows = rowCount;
	}

	// Whether a track is sized by what is in it: an fr track on an axis with no limit, else one
	// whose minimum and maximum are not one length.
	private static bool ContentSized(GridTrack t, float available, float baseLength)
	{
		if (t.Fr > 0.0f)
			return IsUnbounded(available);
		let lo = t.Min.Resolve(baseLength);
		let hi = t.Max.Resolve(baseLength);
		return !(lo.HasValue && hi.HasValue && (lo.Value == hi.Value));
	}

	// Sizes one axis's tracks into `outSizes`: fixed and percentage tracks at their length, auto
	// tracks at their single-span items' largest size, fr tracks sharing what is left (or at their
	// content when the axis has no limit); items spanning auto tracks widen them to fit.
	public static void SizeTracks(List<GridTrack> explicitTracks, GridTrack implicitTrack, int32 count, float available, float gap,
		List<GridItem> items, bool columns, delegate float(GridItem item) contentOf, List<float> outSizes)
	{
		let tracks = scope List<GridTrack>();
		for (int32 i = 0; i < count; i++)
			tracks.Add((i < (int32)explicitTracks.Count) ? explicitTracks[i] : implicitTrack);
		let baseLength = BaseOf(available);
		float fixedTotal = gap * (float)((count > 0) ? count - 1 : 0);
		float frTotal = 0.0f;
		for (let t in tracks)
		{
			float size = 0.0f;
			if (t.Fr <= 0.0f)
			{
				let lo = t.Min.Resolve(baseLength);
				let hi = t.Max.Resolve(baseLength);
				if (lo.HasValue && hi.HasValue && (lo.Value == hi.Value))
					size = lo.Value;
				else
					size = lo.HasValue ? lo.Value : 0.0f;
			}
			outSizes.Add(size);
		}
		// Content-sized tracks from their single-span items.
		for (let item in items)
		{
			if ((columns ? item.ColumnSpan : item.RowSpan) != 1)
				continue;
			let i = (int)(columns ? item.Column : item.Row);
			if ((i < outSizes.Count) && ContentSized(tracks[i], available, baseLength))
				outSizes[i] = Max(outSizes[i], contentOf(item));
		}
		for (int i = 0; i < tracks.Count; i++)
		{
			if ((tracks[i].Fr > 0.0f) && !IsUnbounded(available))
				frTotal += tracks[i].Fr;
			else
				fixedTotal += outSizes[i];
		}
		if (frTotal > 0.0f)
		{
			let free = Max(0.0f, available - fixedTotal);
			for (int i = 0; i < tracks.Count; i++)
			{
				if (tracks[i].Fr > 0.0f)
				{
					let lo = tracks[i].Min.Resolve(baseLength);
					outSizes[i] = Max(lo.HasValue ? lo.Value : 0.0f, free * tracks[i].Fr / frTotal);
				}
			}
		}
		// Items spanning several tracks widen the content-sized ones among them to fit.
		for (let item in items)
		{
			let span = columns ? item.ColumnSpan : item.RowSpan;
			if (span <= 1)
				continue;
			let first = (int)(columns ? item.Column : item.Row);
			let last = Math.Min(outSizes.Count, first + (int)span);
			float have = gap * (float)(last - first - 1);
			int flexible = 0;
			for (int i = first; i < last; i++)
			{
				have += outSizes[i];
				flexible += ContentSized(tracks[i], available, baseLength) ? 1 : 0;
			}
			let need = contentOf(item) - have;
			if ((need > 0.0f) && (flexible > 0))
			{
				for (int i = first; i < last; i++)
				{
					if (ContentSized(tracks[i], available, baseLength))
						outSizes[i] += need / (float)flexible;
				}
			}
		}
	}

	// The length an item's area spans across tracks: its tracks' sizes and the gaps between them.
	private static float AreaSpan(List<float> sizes, float gap, int32 start, int32 span, int32 count)
	{
		float length = gap * (float)(span - 1);
		for (int32 i = start; (i < start + span) && (i < count); i++)
			length += sizes[i];
		return length;
	}

	private static float AlignOffset(Align a, float room, float size) =>
		(a == .End) ? room - size : ((a == .Center) ? (room - size) * 0.5f : 0.0f);

	public static Float2 Grid(Flow f)
	{
		let s = f.Style;
		let columnGap = ColumnGapOf(f);
		let rowGap = RowGapOf(f);
		let percentBase = Float2(BaseOf(f.Width), BaseOf(f.Height));
		let children = scope List<Node>();
		FlowChildren(f.Container, children);
		let items = scope List<GridItem>();
		for (let child in children)
		{
			let cs = child.LayoutStyle;
			items.Add(.(child, cs.Column.Start, cs.Row.Start, Math.Max((int32)1, cs.Column.Span), Math.Max((int32)1, cs.Row.Span)));
		}
		PlaceGridItems(s, items, let columns, let rows);
		let widths = scope List<float>();
		SizeTracks(s.Columns, s.AutoColumns, columns, f.Width, columnGap, items, true,
			scope (item) => MeasureItem(item.Node, cUnbounded, cUnbounded, percentBase).X, widths);
		let heights = scope List<float>();
		SizeTracks(s.Rows, s.AutoRows, rows, f.Height, rowGap, items, false,
			scope [&](item) => MeasureItem(item.Node, AreaSpan(widths, columnGap, item.Column, item.ColumnSpan, columns), cUnbounded, percentBase).Y,
			heights);
		float contentW = columnGap * (float)((columns > 0) ? columns - 1 : 0);
		float contentH = rowGap * (float)((rows > 0) ? rows - 1 : 0);
		for (let w in widths)
			contentW += w;
		for (let h in heights)
			contentH += h;
		if (f.Arrange)
		{
			let xs = scope List<float>();
			let ys = scope List<float>();
			float at = 0.0f;
			for (let w in widths)
			{
				xs.Add(at);
				at += w + columnGap;
			}
			at = 0.0f;
			for (let h in heights)
			{
				ys.Add(at);
				at += h + rowGap;
			}
			for (let item in items)
			{
				let cs = item.Node.LayoutStyle;
				let m = FlowMargin(f, item.Node);
				let areaW = AreaSpan(widths, columnGap, item.Column, item.ColumnSpan, columns);
				let areaH = AreaSpan(heights, rowGap, item.Row, item.RowSpan, rows);
				let jx = SelfAlign(cs.JustifySelf, s.JustifyItems);
				let ay = SelfAlign(cs.AlignSelf, s.AlignItems);
				let roomW = Max(0.0f, areaW - m.TotalHorizontal);
				let roomH = Max(0.0f, areaH - m.TotalVertical);
				let fillW = (jx == .Stretch) && cs.Width.IsAuto;
				let fillH = (ay == .Stretch) && cs.Height.IsAuto;
				let b = MeasureBorder(item.Node, fillW ? (float?)roomW : (float?)null, fillH ? (float?)roomH : (float?)null, roomW, roomH, percentBase);
				let ci = (int)((item.Column < columns) ? item.Column : 0);
				let ri = (int)((item.Row < rows) ? item.Row : 0);
				Place(f, item.Node, xs[ci] + m.Left + AlignOffset(jx, roomW, b.X), ys[ri] + m.Top + AlignOffset(ay, roomH, b.Y), b.X, b.Y);
			}
		}
		return .(contentW, contentH);
	}

	// === Stack ===

	public static Float2 Stack(Flow f)
	{
		let s = f.Style;
		let percentBase = Float2(BaseOf(f.Width), BaseOf(f.Height));
		var content = Float2(0.0f, 0.0f);
		let children = scope List<Node>();
		FlowChildren(f.Container, children);
		for (let child in children)
		{
			let size = MeasureItem(child, f.Width, f.Height, percentBase);
			content.X = Max(content.X, size.X);
			content.Y = Max(content.Y, size.Y);
		}
		if (f.Arrange)
		{
			let w = IsUnbounded(f.Width) ? content.X : f.Width;
			let h = IsUnbounded(f.Height) ? content.Y : f.Height;
			for (let child in children)
			{
				let cs = child.LayoutStyle;
				let m = FlowMargin(f, child);
				let jx = SelfAlign(cs.JustifySelf, s.JustifyItems);
				let ay = SelfAlign(cs.AlignSelf, s.AlignItems);
				let roomW = Max(0.0f, w - m.TotalHorizontal);
				let roomH = Max(0.0f, h - m.TotalVertical);
				let fillW = (jx == .Stretch) && cs.Width.IsAuto;
				let fillH = (ay == .Stretch) && cs.Height.IsAuto;
				let b = MeasureBorder(child, fillW ? (float?)roomW : (float?)null, fillH ? (float?)roomH : (float?)null, roomW, roomH, percentBase);
				Place(f, child, m.Left + AlignOffset(jx, roomW, b.X), m.Top + AlignOffset(ay, roomH, b.Y), b.X, b.Y);
			}
		}
		return content;
	}

	// === Dock ===

	public static Float2 DockChildren(Flow f)
	{
		let percentBase = Float2(BaseOf(f.Width), BaseOf(f.Height));
		float left = 0.0f; // what the docked children took
		float top = 0.0f;
		float right = 0.0f;
		float bottom = 0.0f;
		float needW = 0.0f;
		float needH = 0.0f;
		let rtl = f.Container.IsRightToLeft; // start and end are the sides it runs from and to
		// The docked children first, in order, then those that fill: a fill takes what every side
		// left, wherever it stands among them (several fills share that box, over each other, as a
		// stack's children do).
		let children = scope List<Node>();
		FlowChildren(f.Container, children);
		let ordered = scope List<Node>();
		bool[2] passes = .(false, true);
		for (let fills in passes)
		{
			for (let child in children)
			{
				if ((child.LayoutStyle.DockSide == .Fill) == fills)
					ordered.Add(child);
			}
		}
		for (let child in ordered)
		{
			var side = child.LayoutStyle.DockSide;
			if ((side == .Start) || (side == .End))
				side = ((side == .Start) != rtl) ? .Left : .Right;
			let availW = Less(f.Width, left + right);
			let availH = Less(f.Height, top + bottom);
			let m = child.GetMarginWithin(percentBase.X);
			let horizontal = (side == .Left) || (side == .Right);
			let vertical = (side == .Top) || (side == .Bottom);
			// Docked to a side, it fills that side's length; filling, it takes what is left.
			let tightW = ((vertical || (side == .Fill)) && !IsUnbounded(availW)) ? (float?)Less(availW, m.TotalHorizontal) : (float?)null;
			let tightH = ((horizontal || (side == .Fill)) && !IsUnbounded(availH)) ? (float?)Less(availH, m.TotalVertical) : (float?)null;
			let b = MeasureBorder(child, child.LayoutStyle.Width.IsAuto ? tightW : (float?)null,
				child.LayoutStyle.Height.IsAuto ? tightH : (float?)null,
				Less(availW, m.TotalHorizontal), Less(availH, m.TotalVertical), percentBase);
			let w = b.X + m.TotalHorizontal;
			let h = b.Y + m.TotalVertical;
			switch (side)
			{
			case .Start, .End, .Left: // start and end resolved above
				Place(f, child, left + m.Left, top + m.Top, b.X, b.Y);
				needH = Max(needH, top + bottom + h);
				left += w;
			case .Right:
				Place(f, child, (IsUnbounded(f.Width) ? left : f.Width - right - w) + m.Left, top + m.Top, b.X, b.Y);
				needH = Max(needH, top + bottom + h);
				right += w;
			case .Top:
				Place(f, child, left + m.Left, top + m.Top, b.X, b.Y);
				needW = Max(needW, left + right + w);
				top += h;
			case .Bottom:
				Place(f, child, left + m.Left, (IsUnbounded(f.Height) ? top : f.Height - bottom - h) + m.Top, b.X, b.Y);
				needW = Max(needW, left + right + w);
				bottom += h;
			case .Fill:
				Place(f, child, left + m.Left, top + m.Top, b.X, b.Y);
				needW = Max(needW, left + right + w);
				needH = Max(needH, top + bottom + h);
			}
		}
		return .(Max(needW, left + right), Max(needH, top + bottom));
	}

	public static Float2 RunFlow(Flow f)
	{
		switch (f.Style.Kind)
		{
		case .Grid: return Grid(f);
		case .Stack: return Stack(f);
		case .Dock: return DockChildren(f);
		case .None: return .(0.0f, 0.0f);
		default: return Flex(f);
		}
	}

	public static bool ShowsBar(Overflow o, float range) => (o == .Scroll) || ((o == .Auto) && (range > 0.0f));

	// A bar's thickness in logical units (scrollbar-width); none shows no bars.
	public static float BarThickness(ScrollbarWidth width) => (width == .None) ? 0.0f : ((width == .Thin) ? 5.0f : 8.0f);
}

extension Node
{
	/// The border-box size this node wants within `constraints`: its width and height where its
	/// style gives them (a length, or a percentage of the constraints' base), its content's
	/// (MeasureContent) plus its chrome where they are auto, then kept within its min and max and
	/// the constraints. Cached until its style, content or children change.
	public Float2 Measure(LayoutConstraints constraints)
	{
		for (uint8 i = 0; i < mMeasureCount; i++)
		{
			if (mMeasures[i].Key == constraints)
				return mMeasures[i].Size;
		}
		let s = mLayoutStyle;
		// Its padding's percentages are of the box that holds it, the width it is measured in.
		if (constraints.PercentBase.X >= 0.0f)
			mPercentWidth = constraints.PercentBase.X;
		var size = Float2(0.0f, 0.0f);
		if (s.Kind != .None)
		{
			let chrome = Chrome;
			let ch = chrome.TotalHorizontal;
			let cv = chrome.TotalVertical;
			let contentBox = s.Sizing == .ContentBox;
			float? BorderBoxOf(LayoutLength l, float baseLength, float chromeAxis)
			{
				let v = l.Resolve(baseLength);
				if (v.HasValue && contentBox)
					return v.Value + chromeAxis;
				return v;
			}
			let w = BorderBoxOf(s.Width, constraints.PercentBase.X, ch);
			let h = BorderBoxOf(s.Height, constraints.PercentBase.Y, cv);
			let minW = BorderBoxOf(s.MinWidth, constraints.PercentBase.X, ch) ?? 0.0f;
			let minH = BorderBoxOf(s.MinHeight, constraints.PercentBase.Y, cv) ?? 0.0f;
			let maxW = Max(minW, BorderBoxOf(s.MaxWidth, constraints.PercentBase.X, ch) ?? cUnbounded);
			let maxH = Max(minH, BorderBoxOf(s.MaxHeight, constraints.PercentBase.Y, cv) ?? cUnbounded);
			if (w.HasValue && h.HasValue)
				size = .(w.Value, h.Value);
			else
			{
				var availW = w.HasValue ? w.Value : Min(constraints.Max.X, maxW);
				var availH = h.HasValue ? h.Value : Min(constraints.Max.Y, maxH);
				if (s.Width.Kind == .MaxContent)
					availW = cUnbounded;
				else if (s.Width.Kind == .MinContent)
					availW = ch;
				if (s.Height.Kind == .MaxContent)
					availH = cUnbounded;
				else if (s.Height.Kind == .MinContent)
					availH = cv;
				let content = MeasureContentOnGrid(.(LayoutImplDetail.Less(availW, ch), LayoutImplDetail.Less(availH, cv)));
				size.X = w.HasValue ? w.Value : content.X + ch;
				size.Y = h.HasValue ? h.Value : content.Y + cv;
			}
			size.X = Clamp(size.X, minW, maxW);
			size.Y = Clamp(size.Y, minH, maxH);
			// The container's limit holds an auto size; a size the style gives overflows it, as in
			// CSS, unless the container fixes the size exactly (flex's resolved size, a stretch).
			// Exact is said, not read from a limit as low as the minimum: measured with no room (its
			// min-content), a node with a width of its own keeps it.
			float Fit(float v, bool given, bool exact, float lo, float hi)
			{
				if (exact)
					return lo;
				return Max(lo, given ? v : Min(v, hi));
			}
			size.X = Fit(size.X, w.HasValue, constraints.ExactWidth, constraints.Min.X, constraints.Max.X);
			size.Y = Fit(size.Y, h.HasValue, constraints.ExactHeight, constraints.Min.Y, constraints.Max.Y);
		}
		var slot = mMeasureCount;
		if (slot < cMeasureSlots)
			mMeasureCount++;
		else
		{
			slot = mMeasureNext;
			mMeasureNext = (uint8)((mMeasureNext + 1) % cMeasureSlots);
		}
		mMeasures[slot] = .(constraints, size);
		return size;
	}

	/// MeasureContent rounded up to the device grid its tree lays out on. A box's edges round to the
	/// grid on their own (Arrange), so a content size off it can lose up to a device pixel there:
	/// text measured 29.06 wide, laid out in 29, would end in an ellipsis. Up on the grid, a box
	/// placed on it keeps all of its content.
	public Float2 MeasureContentOnGrid(Float2 available)
	{
		let content = MeasureContent(available);
		var top = this;
		while (top.mParent != null)
			top = top.mParent;
		let s = top.TopPixelScale;
		// A hair over the grid is float noise, not a pixel more.
		float Up(float v) => (v < cUnbounded) ? Ceil(v * s - 1.0e-3f) / s : v;
		return .(Up(content.X), Up(content.Y));
	}

	/// The size of what is inside the chrome, given the space `available` there (cUnbounded on an
	/// axis with no limit). A widget with content of its own (text, an image) answers it; the
	/// default measures the children by the display kind.
	public virtual Float2 MeasureContent(Float2 available)
	{
		if (mChildren.IsEmpty)
			return .(0.0f, 0.0f);
		let flow = LayoutImplDetail.Flow(this, mLayoutStyle, available.X, available.Y, .(0.0f, 0.0f), false);
		return LayoutImplDetail.RunFlow(flow);
	}

	/// Places this node at `rect` (its border box, in its parent's space) and lays out its children
	/// when its size changed or they need it.
	public void Arrange(Rect rect)
	{
		// Each edge rounds to the device grid on its own, so neighbours that share an edge still
		// share it and a box's size is what its edges make (a third of 400 is 133 or 134 wide).
		// The container's own origin is on the grid already, so its space's grid is the device's.
		mPixelScale = (mParent != null) ? mParent.mPixelScale : TopPixelScale;
		let s = mPixelScale;
		float Snap(float v) => Round(v * s) / s;
		let left = Snap(rect.X);
		let top = Snap(rect.Y);
		mPlacing = true;
		Position = .(left, top);
		let size = Float2(Max(0.0f, Snap(rect.X + rect.Width) - left), Max(0.0f, Snap(rect.Y + rect.Height) - top));
		let resized = size != mSize;
		if (resized)
		{
			mSize = size;
			HandleSizeChange();
		}
		mPlacing = false;
		if (mMirrorOnRtl)
			RefreshMirror(); // laid out again when the direction changes
		if (resized || mLayoutDirty)
		{
			mLayoutDirty = false;
			mChildLayoutDirty = false;
			mLayingOut = true;
			OnLayout();
			mLayingOut = false;
			if (!mChildren.IsEmpty) // a container laid out (a leaf has nothing to place)
				sLayoutRunCounter++;
		}
		else if (mChildLayoutDirty)
		{
			mChildLayoutDirty = false;
			for (int i = 0; i < mChildren.Count; i++)
				mChildren[i].ArrangeAgain();
		}
	}

	/// Lays out the children by this node's display kind, the out-of-flow ones by their insets,
	/// and records the content's extent (what a scroll container scrolls over).
	public void LayoutChildren()
	{
		let contentBox = ContentBounds;
		// A scroll container's content is laid out with no limit on the axes it scrolls.
		var flow = LayoutImplDetail.Flow(this, mLayoutStyle, LayoutImplDetail.Scrolls(mLayoutStyle.OverflowX) ? cUnbounded : contentBox.Width,
			LayoutImplDetail.Scrolls(mLayoutStyle.OverflowY) ? cUnbounded : contentBox.Height, .(contentBox.X, contentBox.Y), true);
		// Right to left: rows, grid columns and a stack's start run from the right. Dock stays
		// physical (its sides say where; start and end are its logical sides).
		flow.Rtl = (mLayoutStyle.Kind != .Dock) && (mLayoutStyle.Kind != .None) && IsRightToLeft;
		LayoutImplDetail.RunFlow(flow);
		if (flow.Rtl)
		{
			// Mirrored within the box: content wider than it overflows toward the inline end, the
			// left, as CSS's does; a scroller's then scrolls to negative offsets.
			for (int i = 0; i < mChildren.Count; i++)
			{
				let child = mChildren[i];
				if (LayoutImplDetail.InFlow(child))
					child.Position = .(contentBox.X + contentBox.Width - (child.Position.X - contentBox.X) - child.mSize.X, child.Position.Y);
			}
		}

		// Out of flow: placed by the insets against this node's box, sized by their style, by both
		// insets of an axis, or by their content.
		for (int i = 0; i < mChildren.Count; i++)
		{
			let child = mChildren[i];
			let cs = child.mLayoutStyle;
			if (child.Displayed && child.mTopLayer)
			{
				// An open popup: the top layer places it; laid out where it is, so what it holds is.
				child.Arrange(.(child.Position.X, child.Position.Y, child.mSize.X, child.mSize.Y));
				continue;
			}
			if (!child.Displayed || (cs.Placement != .Absolute))
				continue;
			// A sheet's insets are from the padding box, inside the border, as CSS's are; a position
			// code gave is in the box itself, as it was given.
			let border = BorderThickness;
			let codeX = child.IsPlacedByCode;
			let codeY = child.IsPlacedByCode;
			let x0 = codeX ? 0.0f : border.Left;
			let x1 = codeX ? 0.0f : border.Right;
			let y0 = codeY ? 0.0f : border.Top;
			let y1 = codeY ? 0.0f : border.Bottom;
			let spanX = Max(0.0f, mSize.X - x0 - x1);
			let spanY = Max(0.0f, mSize.Y - y0 - y1);
			let m = child.GetMarginWithin(spanX);
			let left = cs.Left.Resolve(spanX);
			let right = cs.Right.Resolve(spanX);
			let top = cs.Top.Resolve(spanY);
			let bottom = cs.Bottom.Resolve(spanY);
			float? w = null;
			float? h = null;
			if (cs.Width.IsAuto && left.HasValue && right.HasValue)
				w = Max(0.0f, spanX - left.Value - right.Value - m.TotalHorizontal);
			if (cs.Height.IsAuto && top.HasValue && bottom.HasValue)
				h = Max(0.0f, spanY - top.Value - bottom.Value - m.TotalVertical);
			let b = LayoutImplDetail.MeasureBorder(child, w, h, cUnbounded, cUnbounded, .(spanX, spanY));
			let x = left.HasValue ? x0 + left.Value + m.Left
				: (right.HasValue ? mSize.X - x1 - right.Value - b.X - m.Right : contentBox.X + m.Left);
			let y = top.HasValue ? y0 + top.Value + m.Top
				: (bottom.HasValue ? mSize.Y - y1 - bottom.Value - b.Y - m.Bottom : contentBox.Y + m.Top);
			child.Arrange(.(x, y, b.X, b.Y));
		}

		// Relative: moved after the flow, its siblings where they were. From the right, the extent
		// reaches from the content's left edge, past the box's left, to the box's right.
		var extent = Float2(0.0f, 0.0f);
		let fromRight = ScrollsFromRight;
		float leftmost = 0.0f;
		for (int i = 0; i < mChildren.Count; i++)
		{
			let child = mChildren[i];
			if (!child.Displayed || child.mTopLayer)
				continue;
			let cs = child.mLayoutStyle;
			if (cs.Placement == .Relative)
			{
				let dx = cs.Left.Resolve(contentBox.Width) ?? -(cs.Right.Resolve(contentBox.Width) ?? 0.0f);
				let dy = cs.Top.Resolve(contentBox.Height) ?? -(cs.Bottom.Resolve(contentBox.Height) ?? 0.0f);
				let s = mPixelScale; // moved by whole device pixels, keeping it on the grid
				child.Position = .(child.Position.X + Round(dx * s) / s, child.Position.Y + Round(dy * s) / s);
			}
			let m = child.GetMarginWithin(contentBox.Width);
			extent.X = Max(extent.X, child.Position.X + child.mSize.X + m.Right - contentBox.X);
			extent.Y = Max(extent.Y, child.Position.Y + child.mSize.Y + m.Bottom - contentBox.Y);
			leftmost = Min(leftmost, child.Position.X - m.Left - contentBox.X);
		}
		if (fromRight)
			extent.X = Max(extent.X, contentBox.Width) - leftmost;
		SetScrollExtent(extent);
	}

	/// Sets what a scroll container scrolls over, as laying out its children does (the offset kept
	/// within it, held at the end while latched): a container that places its children itself (an
	/// item view, which realises only some of them) says how far its content reaches.
	public void SetScrollExtent(Float2 extent)
	{
		let latched = IsLatchedToEnd; // as it was before the content changed
		let before = mContentExtent;
		mContentExtent = extent;
		ApplyScrollOffset(mScrollOffset); // kept within the new range, a smooth scroll going on
		if (latched && !mSmoothScrolling && !mFlinging)
		{
			// Held at the end: it follows the content's new end.
			ApplyScrollOffset(ScrollEnd(mScrollOffset));
			mLatchedToEnd = true;
		}
		if (mSmoothScrolling)
			mScrollTarget = ClampScroll(mScrollTarget);
		// The focused widget inside keeps its focus area in view (a caret on a line just typed,
		// which the old range could not reach).
		if (extent == before)
			return;
		let dispatcher = EventDispatcher;
		let focused = (dispatcher != null) ? dispatcher.FocusNode : null;
		Rect area = .();
		if ((focused == null) || (focused == this) || !focused.GetFocusArea(out area))
			return;
		for (var up = focused.Parent; up != null; up = up.Parent)
		{
			if (up == this)
			{
				ScrollIntoView(focused, area, .Nearest, .Instant);
				return;
			}
		}
	}

	/// This node's content or children changed: it measures and lays out again, and so do the
	/// containers above it whose size follows it, at the next layout pass (a GUI runs one each
	/// frame, so a burst of changes costs one layout).
	public void RequestLayout()
	{
		mMeasureCount = 0;
		mLayoutDirty = true;
		// Up through the containers whose size follows what is inside them: each measures and lays
		// out again. One of definite size stops it (its size does not change); one out of flow
		// makes its container place it again, nothing more.
		var n = this;
		while ((n.mParent != null) && !LayoutImplDetail.HasDefiniteSize(n))
		{
			let outOfFlow = n.mLayoutStyle.Placement == .Absolute;
			n = n.mParent;
			n.mLayoutDirty = true;
			if (outOfFlow)
				break;
			n.mMeasureCount = 0;
		}
		for (var p = n.mParent; (p != null) && !p.mChildLayoutDirty; p = p.mParent)
			p.mChildLayoutDirty = true;
		Invalidate();
	}

	/// This node and everything under it measure and lay out again: for a change every node's
	/// layout reads (the display scale its edges round to).
	public void RequestLayoutTree()
	{
		MarkLayoutTree();
		RequestLayout();
	}

	private void MarkLayoutTree()
	{
		mMeasureCount = 0;
		mLayoutDirty = true;
		for (let child in mChildren)
			child.MarkLayoutTree();
	}

	/// The layout pass for the tree this node tops: lays out what asked, a few rounds while layouts
	/// resize what they hold. A GUI runs it each frame; a tree in no GUI when its owner wants its
	/// geometry. How many containers laid out.
	public uint32 UpdateLayout()
	{
		let before = sLayoutRunCounter;
		for (int32 round = 0; (round < 8) && (mLayoutDirty || mChildLayoutDirty); round++)
		{
			// The top node's size is its style's, or what it holds where that is auto.
			let size = Measure(LayoutConstraints());
			Arrange(.(mPosition.X, mPosition.Y, size.X, size.Y));
		}
		return sLayoutRunCounter - before;
	}

	// === Scrolling ===

	/// Where a scroll container's bar is on an axis (0 horizontal, 1 vertical), in local space; an
	/// empty rect when it shows none.
	public Rect ScrollBarTrack(uint32 axis)
	{
		let barWidth = LayoutImplDetail.BarThickness(mLayoutStyle.BarWidth);
		if (!IsScrollContainer || (barWidth <= 0.0f))
			return .();
		let range = ScrollRange;
		let showX = LayoutImplDetail.ShowsBar(mLayoutStyle.OverflowX, range.X);
		let showY = LayoutImplDetail.ShowsBar(mLayoutStyle.OverflowY, range.Y);
		let b = BorderThickness;
		let w = Max(0.0f, mSize.X - b.TotalHorizontal);
		let h = Max(0.0f, mSize.Y - b.TotalVertical);
		// The vertical bar on the inline end (the left in right to left); the offsets stay physical.
		let rtl = IsRightToLeft;
		if ((axis == 1) && showY)
			return .(rtl ? b.Left : mSize.X - b.Right - barWidth, b.Top, barWidth, showX ? Max(0.0f, h - barWidth) : h);
		if ((axis == 0) && showX)
			return .((rtl && showY) ? b.Left + barWidth : b.Left, mSize.Y - b.Bottom - barWidth, showY ? Max(0.0f, w - barWidth) : w, barWidth);
		return .();
	}

	/// Where a scroll container's thumb is on an axis, in local space; empty when it shows none.
	public Rect ScrollBarThumb(uint32 axis)
	{
		let track = ScrollBarTrack(axis);
		if ((track.Width <= 0.0f) || (track.Height <= 0.0f))
			return .();
		let contentBox = ContentBounds;
		let view = (axis == 1) ? contentBox.Height : contentBox.Width;
		let extent = Max(view, (axis == 1) ? mContentExtent.Y : mContentExtent.X);
		let range = (axis == 1) ? ScrollRange.Y : ScrollRange.X;
		// Along the track from where the offset may start (the left, from the right too).
		let offset = (axis == 1) ? mScrollOffset.Y : mScrollOffset.X - ScrollMin.X;
		let length = (axis == 1) ? track.Height : track.Width;
		let thumb = Min(length, Max(LayoutImplDetail.cMinThumb, length * view / Max(1.0f, extent)));
		let at = (range > 0.0f) ? (length - thumb) * offset / range : 0.0f;
		return (axis == 1) ? Rect(track.X, track.Y + at, track.Width, thumb) : Rect(track.X + at, track.Y, thumb, track.Height);
	}

	public void DrawScrollBars(DrawContext ctx)
	{
		let alpha = ScrollbarOpacity;
		if (alpha <= 0.0f)
			return;
		// Each bar is two parts: ::scrollbar (the track, clear by default) and ::scrollbar-thumb,
		// each its own look with the sheet's over it, the thumb's lighter while hovered or held.
		let trackStyle = FindPartStyle("scrollbar");
		let thumbStyle = FindPartStyle("scrollbar-thumb");
		let none = scope PartStyle();
		let empty = scope NodeBox();
		let own = scope NodeBox();
		if (alpha < 1.0f)
			ctx.PushOpacity(alpha);
		for (uint32 axis = 0; axis < 2; axis++)
		{
			let track = ScrollBarTrack(axis);
			if ((track.Width <= 0.0f) || (track.Height <= 0.0f))
				continue;
			if (trackStyle != null)
				trackStyle.Draw(ctx, track, empty);
			let thumb = ScrollBarThumb(axis);
			let held = mScrollDragAxis == axis;
			let a = held ? 0.85f : ((mScrollHover == 2) ? 0.72f : 0.55f);
			let inset = Rect(thumb.X + 1.5f, thumb.Y + 1.5f, Max(0.0f, thumb.Width - 3.0f), Max(0.0f, thumb.Height - 3.0f));
			FilledBox(Color(0.62f, 0.66f, 0.72f, a), CornerRadii(Min(inset.Width, inset.Height) * 0.5f), own);
			((thumbStyle != null) ? thumbStyle : none).Draw(ctx, inset, own);
		}
		if (alpha < 1.0f)
			ctx.PopOpacity();
	}

	/// Flings it at `velocity` (offset units a second, as a finger left it): it glides on, slowing
	/// by e^(-t/tau) whatever the frame rate, until it nearly stops or meets an end.
	public void Fling(Float2 velocity)
	{
		let max = LayoutImplDetail.cMaxFlingSpeed;
		mSmoothScrolling = false;
		mFlingVelocity = .(Clamp(velocity.X, -max, max), Clamp(velocity.Y, -max, max));
		mFlingStart = mScrollOffset;
		mFlingTime = 0.0f;
		mFlinging = true;
		if (mFlingTicking || (ActionManager == null))
			return;
		mFlingTicking = true;
		let tick = new TickAction(new (elapsed) =>
			{
				if (!mFlinging)
				{
					mFlingTicking = false;
					return false;
				}
				// Closed form: where it is after t, and how fast, the same at any frame rate.
				let tau = LayoutImplDetail.cFlingTau;
				mFlingTime += (float)elapsed.TotalSeconds;
				let decay = Exp(-mFlingTime / tau);
				let v = mFlingVelocity;
				let before = mScrollOffset;
				ApplyScrollOffset(.(mFlingStart.X + v.X * tau * (1.0f - decay), mFlingStart.Y + v.Y * tau * (1.0f - decay)));
				let stopSpeed = LayoutImplDetail.cFlingStopSpeed;
				let slow = (Abs(v.X) * decay < stopSpeed) && (Abs(v.Y) * decay < stopSpeed);
				if (slow || (mScrollOffset == before)) // nearly stopped, or held at an end
				{
					mFlinging = false;
					mFlingTicking = false;
					return false;
				}
				return true;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	/// Which bar part is under the pointer: 0 none, 1 a track, 2 a thumb; the part states follow.
	protected void SetScrollHover(uint8 part)
	{
		if (part == mScrollHover)
			return;
		mScrollHover = part;
		MarkStyleStateDirty(StateHover | StateActive); // its parts' states changed
		Invalidate();
	}

	/// An overlay scroller's bars are wanted (it scrolled, or the pointer is over it): shown, then
	/// fading once let be.
	protected void ShowOverlayScrollbars()
	{
		mScrollbarAlpha = 1.0f;
		mScrollbarIdle = 0.0f;
		Invalidate();
		if (mScrollbarFading || (ActionManager == null))
			return;
		mScrollbarFading = true;
		let tick = new TickAction(new (elapsed) =>
			{
				let dt = (float)elapsed.TotalSeconds;
				// Held by the pointer over it or a drag; once let be, it lingers, then fades.
				if (Hovered || (mScrollDragAxis <= 1))
					mScrollbarIdle = 0.0f;
				else
					mScrollbarIdle += dt;
				if (mScrollbarIdle <= LayoutImplDetail.cOverlayLinger)
					return true;
				mScrollbarAlpha = Max(0.0f, mScrollbarAlpha - dt / LayoutImplDetail.cOverlayFade);
				Invalidate();
				if (mScrollbarAlpha > 0.0f)
					return true;
				mScrollbarFading = false;
				return false;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	/// Scrolls to `offset`, at once or easing there (Auto: as the node's `scroll-behavior` says).
	public void ScrollTo(Float2 offset, ScrollBehavior behavior = .Auto)
	{
		var behavior;
		if (behavior == .Auto)
			behavior = (mLayoutStyle.Scrolling == .Smooth) ? .Smooth : .Instant;
		if (behavior != .Smooth)
		{
			ScrollOffset = offset;
			return;
		}
		// A smooth scroll eases toward its target; another scroll while it runs moves the target
		// on, so wheel notches accumulate rather than restart.
		mScrollTarget = ClampScroll(offset);
		if (mScrollTarget == mScrollOffset)
		{
			mSmoothScrolling = false;
			return;
		}
		mSmoothScrolling = true;
		StartSmoothScroll();
	}

	/// Scrolls to the end of its content (the bottom; a horizontal-only scroller's inline end).
	public void ScrollToEnd(ScrollBehavior behavior = .Auto)
	{
		ScrollTo(ScrollEnd(ScrollTarget), behavior);
	}

	/// Where the end of its content is (ScrollToEnd's offset), from `from` on the other axis.
	public Float2 ScrollEnd(Float2 from)
	{
		// The bottom; a scroller that only scrolls across, its inline end (the left from the right).
		let range = ScrollRange;
		if ((range.Y > 0.0f) || (range.X <= 0.0f))
			return .(from.X, range.Y);
		return .(ScrollsFromRight ? ScrollMin.X : range.X, from.Y);
	}

	/// Eases toward the scroll target on the GUI's clock (at once with no clock).
	protected void StartSmoothScroll()
	{
		if (mSmoothTicking)
			return;
		if (ActionManager == null)
		{
			ScrollOffset = mScrollTarget; // no clock to ease on: there at once
			return;
		}
		mSmoothTicking = true;
		let tick = new TickAction(new (elapsed) =>
			{
				if (!mSmoothScrolling)
				{
					mSmoothTicking = false;
					return false;
				}
				// The rest of the way shrinks by e^(-t/tau) whatever the frame rate; within half a
				// pixel it arrives.
				let keep = Exp(-(float)elapsed.TotalSeconds / LayoutImplDetail.cSmoothTau);
				let at = mScrollOffset;
				let to = mScrollTarget;
				var next = Float2(to.X - (to.X - at.X) * keep, to.Y - (to.Y - at.Y) * keep);
				if ((Abs(to.X - next.X) < 0.5f) && (Abs(to.Y - next.Y) < 0.5f))
					next = to;
				ApplyScrollOffset(next);
				if ((mScrollOffset == to) || (mScrollOffset == at)) // arrived, or held at the range's end
				{
					mSmoothScrolling = false;
					mSmoothTicking = false;
					return false;
				}
				return true;
			});
		RunAction(tick);
		tick.ReleaseRef();
	}

	/// Scrolls to show `area` of `descendant` (in its own space): a text field's caret.
	public void ScrollIntoView(Node descendant, Rect area, ScrollAlign align = .Nearest, ScrollBehavior behavior = .Auto)
	{
		if (!IsScrollContainer || (descendant == this))
			return;
		let world = descendant.WorldTransform.TransformRect(area);
		let lo = ConvertToNodeSpace(.(world.X, world.Y));
		let hi = ConvertToNodeSpace(.(world.X + world.Width, world.Y + world.Height));
		let contentBox = ContentBounds;
		// Positions here are as scrolled now; a smooth scroll in progress starts from its target.
		let from = ScrollTarget;
		let shift = Float2(from.X - mScrollOffset.X, from.Y - mScrollOffset.Y);
		float Axis(float offset, float start, float end, float boxStart, float boxLength)
		{
			switch (align)
			{
			case .Start: return offset + (start - boxStart);
			case .End: return offset + (end - (boxStart + boxLength));
			case .Center: return offset + ((start + end) * 0.5f - (boxStart + boxLength * 0.5f));
			default: // nearest
				if (start < boxStart)
					return offset - (boxStart - start);
				if (end > boxStart + boxLength)
					return offset + Min(end - (boxStart + boxLength), start - boxStart); // never past its start
				return offset;
			}
		}
		let offset = Float2(Axis(from.X, lo.X - shift.X, hi.X - shift.X, contentBox.X, contentBox.Width),
			Axis(from.Y, lo.Y - shift.Y, hi.Y - shift.Y, contentBox.Y, contentBox.Height));
		ScrollTo(offset, behavior);
	}

	// A scroll container's own handling, after its widget's: the wheel (taken when it moved), the
	// keys while it is focused, and its bars (a press on one drags its thumb or pages).
	protected void ScrollDefaultAction(Event e)
	{
		switch (e.Type)
		{
		case .MouseWheel:
			{
				// Wheel up (positive y) shows what is above. Shift turns it to the other axis, and a
				// scroller that only scrolls across takes a vertical wheel across. A scroller at its
				// end leaves the wheel to the one around it, unless it contains its overscroll.
				let wheel = (WheelEvent)e;
				var delta = wheel.Delta;
				if (((wheel.Modifiers & KeyModShift) != 0) && (delta.X == 0.0f))
					delta = .(delta.Y, 0.0f);
				let range = ScrollRange;
				if ((delta.X == 0.0f) && (range.Y <= 0.0f) && (range.X > 0.0f))
					delta = .(ScrollsFromRight ? -delta.Y : delta.Y, 0.0f); // down goes toward the inline end
				let target = ScrollTarget;
				ScrollBy(.(-delta.X * mScrollStep, -delta.Y * mScrollStep), .Auto);
				e.Handled = (ScrollTarget != target) || (mLayoutStyle.Overscroll == .Contain);
				return;
			}
		case .KeyDown:
			{
				if ((e.Target != this) || !mScrollsByKeys)
					return; // keys a focused widget inside left go on to navigation, not to scrolling
				let contentBox = ContentBounds;
				let key = (KeyEvent)e;
				let target = ScrollTarget;
				let own = ScrollBehavior.Auto; // smooth where the node asks
				bool arrow = false;
				switch ((KeyCode)key.KeyCode)
				{
				case .Down:
					ScrollBy(.(0.0f, mScrollStep), own);
					arrow = true;
				case .Up:
					ScrollBy(.(0.0f, -mScrollStep), own);
					arrow = true;
				case .Right:
					ScrollBy(.(mScrollStep, 0.0f), own);
					arrow = true;
				case .Left:
					ScrollBy(.(-mScrollStep, 0.0f), own);
					arrow = true;
				case .PageDown: ScrollBy(.(0.0f, contentBox.Height), own);
				case .PageUp: ScrollBy(.(0.0f, -contentBox.Height), own);
				case .Home: ScrollTo(.(target.X, 0.0f), own);
				case .End: ScrollTo(.(target.X, ScrollRange.Y), own);
				default: return;
				}
				// An arrow that could not scroll further is given back (focus moves on).
				e.Handled = !arrow || (ScrollTarget != target);
				return;
			}
		case .MouseDown:
			{
				let mouse = (MouseEvent)e;
				if (mouse.Button != .Left)
					return;
				let p = ConvertToNodeSpace(mouse.Position);
				for (uint32 axis = 0; axis < 2; axis++)
				{
					let track = ScrollBarTrack(axis);
					if (!track.Contains(p))
						continue;
					let thumb = ScrollBarThumb(axis);
					if (thumb.Contains(p)) // grab the thumb where it was taken
					{
						mScrollDragAxis = axis;
						MarkStyleStateDirty(StateHover | StateActive); // ::scrollbar-thumb:active
						mScrollDragGrab = (axis == 1) ? p.Y - thumb.Y : p.X - thumb.X;
						let dispatcher = EventDispatcher;
						if (dispatcher != null)
							dispatcher.CapturePointer(this);
					}
					else // a press on the track pages toward it
					{
						let contentBox = ContentBounds;
						let back = (axis == 1) ? (p.Y < thumb.Y) : (p.X < thumb.X);
						let page = (axis == 1) ? contentBox.Height : contentBox.Width;
						ScrollBy((axis == 1) ? Float2(0.0f, back ? -page : page) : Float2(back ? -page : page, 0.0f));
					}
					e.Handled = true;
					Invalidate();
					return;
				}
				return;
			}
		case .MouseEnter, .MouseLeave, .MouseMove:
			{
				let mouse = (MouseEvent)e;
				let p = ConvertToNodeSpace(mouse.Position);
				if ((mLayoutStyle.BarVisibility == .Overlay) && (e.Type != .MouseLeave))
					ShowOverlayScrollbars(); // the pointer over it shows its bars
				if (mScrollDragAxis > 1)
				{
					// Which bar part the pointer is over (`::scrollbar-thumb:hover`).
					uint8 part = 0;
					if (e.Type != .MouseLeave)
					{
						for (uint32 a = 0; (a < 2) && (part == 0); a++)
						{
							if (ScrollBarTrack(a).Contains(p))
								part = ScrollBarThumb(a).Contains(p) ? 2 : 1;
						}
					}
					SetScrollHover(part);
					return;
				}
				if (e.Type != .MouseMove)
					return;
				let axis = mScrollDragAxis;
				let track = ScrollBarTrack(axis);
				let thumb = ScrollBarThumb(axis);
				let travel = (axis == 1) ? track.Height - thumb.Height : track.Width - thumb.Width;
				let at = ((axis == 1) ? p.Y - track.Y : p.X - track.X) - mScrollDragGrab;
				let range = (axis == 1) ? ScrollRange.Y : ScrollRange.X;
				let low = (axis == 1) ? 0.0f : ScrollMin.X;
				let offset = low + ((travel > 0.0f) ? Clamp(at / travel, 0.0f, 1.0f) * range : 0.0f);
				ScrollOffset = (axis == 1) ? Float2(mScrollOffset.X, offset) : Float2(offset, mScrollOffset.Y);
				e.Handled = true;
				return;
			}
		case .MouseUp, .PointerCancel, .PointerCaptureLost:
			if (mScrollDragAxis <= 1)
			{
				mScrollDragAxis = 2;
				MarkStyleStateDirty(StateHover | StateActive);
				Invalidate();
			}
			return;
		default:
			return;
		}
	}

	// === The layout overlay ===

	/// Draws `what` of the layout overlay for this node and its displayed subtree, in this node's
	/// space (clipped where its children are).
	public void DrawLayoutOverlay(DrawContext ctx, DebugOverlay what)
	{
		if (!mVisible || !Displayed)
			return;
		let vg = ctx.VG;
		let hair = 1.0f / Max(ctx.DeviceScale, 0.01f); // one device pixel
		void Ring(Rect outer, Rect inner, Color color)
		{
			// The band between two boxes, as four strips (top and bottom full width).
			let top = inner.Y - outer.Y;
			let bottom = outer.Y + outer.Height - (inner.Y + inner.Height);
			let left = inner.X - outer.X;
			let right = outer.X + outer.Width - (inner.X + inner.Width);
			if (top > 0.0f)
				vg.FillRect(.(outer.X, outer.Y, outer.Width, top), color);
			if (bottom > 0.0f)
				vg.FillRect(.(outer.X, inner.Y + inner.Height, outer.Width, bottom), color);
			if (left > 0.0f)
				vg.FillRect(.(outer.X, inner.Y, left, inner.Height), color);
			if (right > 0.0f)
				vg.FillRect(.(inner.X + inner.Width, inner.Y, right, inner.Height), color);
		}
		let border = Rect(0.0f, 0.0f, mSize.X, mSize.Y);
		if (what.Margin)
		{
			let m = GetMarginWithin(mPercentWidth);
			Ring(.(-m.Left, -m.Top, mSize.X + m.TotalHorizontal, mSize.Y + m.TotalVertical), border, .(1.0f, 0.6f, 0.2f, 0.35f));
		}
		if (what.Padding)
		{
			let content = ContentBounds;
			let p = Padding;
			Ring(.(content.X - p.Left, content.Y - p.Top, content.Width + p.TotalHorizontal, content.Height + p.TotalVertical), content,
				.(0.3f, 0.85f, 0.4f, 0.35f));
		}
		if (what.Bounds)
			vg.StrokeRect(border.ToRectangle(), .(1.0f, 0.25f, 0.25f, 0.8f), hair);
		if (what.Baselines)
		{
			// Only a baseline of its own (text): every other node's is its content's bottom.
			let baseline = Baseline;
			if (Abs(baseline - (mSize.Y - Chrome.Bottom)) > 0.01f)
				vg.DrawLine(.(0.0f, baseline), .(mSize.X, baseline), .(1.0f, 0.2f, 0.9f, 0.9f), hair);
		}

		if (mChildren.IsEmpty)
			return;
		let clips = ClipsChildren;
		if (clips)
			ctx.PushClip(border);
		let shift = ScrollShift;
		for (let child in mChildren)
		{
			ctx.Save();
			var t = Transform2D();
			t.Translate(-shift.X, -shift.Y);
			ctx.ConcatTransform(t);
			ctx.ConcatTransform(child.Transform);
			child.DrawLayoutOverlay(ctx, what);
			ctx.Restore();
		}
		if (clips)
			ctx.PopClip();
	}
}
