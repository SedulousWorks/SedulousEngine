using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// A flexbox: children distributed along a main axis, aligned across it, and optionally
/// wrapped onto several lines.
///
/// Both passes work the same way: collect the in flow children into ITEMS, break the items
/// into LINES, and then work a line at a time. Not wrapping is simply the case of one line,
/// so there is no separate code path for it to drift out of agreement with.
class FlexLayout : ViewGroup
{
	public Orientation Direction = .Horizontal;
	public Justify JustifyContent = .Start;
	public Align AlignItems = .Stretch;
	/// The main axis gap between items: CSS column gap in a row, row gap in a column.
	public float Spacing = 0.0f;
	/// The cross axis gap between wrapped lines.
	public float LineSpacing = 0.0f;
	/// The CSS named gaps, by AXIS rather than by role, which is what markup's `gap`,
	/// `row-gap` and `column-gap` write. Set, they win over Spacing and LineSpacing.
	public float? RowGap = null;
	public float? ColumnGap = null;
	/// Breaks items onto new lines when the main axis is definite and they do not fit.
	public bool Wrap = false;
	public AlignContent AlignContent = .Stretch;

	public this() {}

	/// The gap between items on the main axis, after the named overrides.
	public float MainGap
	{
		get
		{
			let named = (Direction == .Horizontal) ? ColumnGap : RowGap;
			return (named != null) ? named.Value : Spacing;
		}
	}

	/// The gap between LINES on the cross axis, after the named overrides.
	public float CrossGap
	{
		get
		{
			let named = (Direction == .Horizontal) ? RowGap : ColumnGap;
			return (named != null) ? named.Value : LineSpacing;
		}
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasureLines(constraints.Deflate(Padding), constraints, Direction == .Horizontal);
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		LayoutLines(width, height, Direction == .Horizontal);
	}

	// ---- The item and line model -----------------------------------------------------------

	private struct FlexItem
	{
		/// BORROWED: the group owns the child.
		public View Child = null;
		public float Grow = 0.0f;
		/// The main axis size at line breaking time: a growing child's basis BEFORE its share,
		/// or the measured margin box for everything else.
		public float Main = 0.0f;
		public float Cross = 0.0f;
		/// Whether the child asked to Match on the CROSS axis, which needs a second measure at
		/// the settled line size.
		public bool MatchCross = false;

		public this() {}
	}

	private struct FlexLine
	{
		public int Start = 0;
		public int Count = 0;
		public float Main = 0.0f;
		public float Cross = 0.0f;

		public this() {}
	}

	/// Per pass scratch, kept as fields so a warm layout allocates nothing.
	private List<FlexItem> mItems = new .() ~ delete _;
	private List<FlexLine> mLines = new .() ~ delete _;

	private static float MainOf(Float2 size, bool horizontal) => horizontal ? size.X : size.Y;
	private static float CrossOf(Float2 size, bool horizontal) => horizontal ? size.Y : size.X;

	private static BoxConstraints MainCross(float minMain, float maxMain, float minCross,
		float maxCross, bool horizontal) =>
		horizontal ? BoxConstraints(minMain, maxMain, minCross, maxCross)
			: BoxConstraints(minCross, maxCross, minMain, maxMain);

	/// The SEMANTIC half of the first measure, kept on the parent by design: Match fills its
	/// axis, but Match on the CROSS axis is demoted to loose so the child wraps naturally
	/// first. Handling it in the base Measure would defeat that, because the base cannot know
	/// which axis is the cross one.
	private static BoxConstraints LooseCrossConstraints(BoxConstraints parent, View child,
		bool horizontal)
	{
		let widthKind = child.Layout.Width.Value.kind;
		let heightKind = child.Layout.Height.Value.kind;
		let fillWidth = (widthKind == .Match) && horizontal;
		let fillHeight = (heightKind == .Match) && !horizontal;
		let availableWidth = Max(0.0f, parent.MaxWidth);
		let availableHeight = Max(0.0f, parent.MaxHeight);
		return .(fillWidth ? availableWidth : 0.0f, availableWidth,
			fillHeight ? availableHeight : 0.0f, availableHeight);
	}

	/// A child's declared flex basis in logical units, or negative for auto.
	///
	/// A percentage resolves against the available MAIN size, nought when that is unbounded,
	/// and em against the child's own computed font size.
	private static float DeclaredBasis(View child, float availableMain)
	{
		let basis = child.Layout.FlexBasis.Value;
		if (basis == Unit())
			return -1.0f;

		let reference = BoxConstraints.IsBounded(availableMain) ? availableMain : 0.0f;
		// Resolved only when the basis actually has an em component: computing a font size is
		// not free.
		let fontSize = (basis.em != 0.0f)
			? child.ResolveStyleLength(.FontSize, 0.0f, 16.0f) : 0.0f;
		let root = child.Root();
		let dpiScale = (root != null) ? Max(root.DpiScale, 0.01f) : 1.0f;
		return Max(0.0f, basis.Resolve(dpiScale, reference, fontSize));
	}

	/// Breaks the items into lines against a limit, an unbounded limit meaning one line.
	///
	/// The FIRST item of a line always fits, however big it is: an oversized item overflows
	/// rather than being pushed onto an empty line and still not fitting. The half unit
	/// tolerance keeps a line that grow filled exactly from spilling when it is re-broken
	/// during arrange.
	private void BreakLines(float limit, float gap)
	{
		mLines.Clear();
		var line = FlexLine();
		for (int i < mItems.Count)
		{
			let itemMain = mItems[i].Main;
			let needed = (line.Count == 0) ? itemMain : (line.Main + gap + itemMain);
			if ((line.Count > 0) && BoxConstraints.IsBounded(limit) && (needed > limit + 0.5f))
			{
				mLines.Add(line);
				line = .();
				line.Start = i;
			}
			line.Main = (line.Count == 0) ? itemMain : needed;
			line.Count++;
		}
		if (line.Count > 0)
			mLines.Add(line);
	}

	// ---- Measure ---------------------------------------------------------------------------

	private void MeasureLines(BoxConstraints inner, BoxConstraints outer, bool horizontal)
	{
		let availableMain = horizontal ? inner.MaxWidth : inner.MaxHeight;
		let availableCross = horizontal ? inner.MaxHeight : inner.MaxWidth;
		let mainDefinite = BoxConstraints.IsBounded(availableMain);
		let gap = MainGap;
		let looseInner = horizontal
			? BoxConstraints(inner.MinWidth, inner.MaxWidth, 0, inner.MaxHeight)
			: BoxConstraints(0, inner.MaxWidth, inner.MinHeight, inner.MaxHeight);

		// 1. Every item at its HYPOTHETICAL main size: the declared basis, nought for a growing
		//    child, which is what the `flex: <grow>` shorthand means, or its content size.
		mItems.Clear();
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			var item = FlexItem();
			item.Child = child;
			item.Grow = child.Layout.FlexGrow.Value;
			item.MatchCross =
				(horizontal ? child.Layout.Height.Value.kind : child.Layout.Width.Value.kind)
				== .Match;

			let basis = DeclaredBasis(child, availableMain);
			if ((basis >= 0.0f) && (item.Grow <= 0.0f))
			{
				// A declared basis with no grow IS the main size: tight on main, loose across.
				child.Measure(MainCross(basis, basis, 0.0f, Max(0.0f, availableCross), horizontal));
				item.Main = MainOf(child.MarginBoxSize, horizontal);
				item.Cross = CrossOf(child.MarginBoxSize, horizontal);
			}
			else if (item.Grow > 0.0f)
			{
				// Measured below, once the line is known and its share can be worked out.
				item.Main = Max(0.0f, basis);
			}
			else
			{
				child.Measure(LooseCrossConstraints(looseInner, child, horizontal));
				item.Main = MainOf(child.MarginBoxSize, horizontal);
				item.Cross = CrossOf(child.MarginBoxSize, horizontal);
			}

			mItems.Add(item);
		}

		// 2. The lines.
		BreakLines((Wrap && mainDefinite) ? availableMain : FloatMax, gap);

		// 3. Per line: a growing child takes its share of the free space and is measured, and
		//    the line's cross size is its tallest item.
		for (int lineIndex < mLines.Count)
		{
			var line = mLines[lineIndex];
			var totalGrow = 0.0f;
			var used = gap * (float)((line.Count > 0) ? (line.Count - 1) : 0);
			for (int i = line.Start; i < line.Start + line.Count; i++)
			{
				totalGrow += Max(0.0f, mItems[i].Grow);
				used += mItems[i].Main;
			}

			let remaining = mainDefinite ? Max(0.0f, availableMain - used) : 0.0f;
			line.Main = gap * (float)((line.Count > 0) ? (line.Count - 1) : 0);
			line.Cross = 0.0f;

			for (int i = line.Start; i < line.Start + line.Count; i++)
			{
				var item = mItems[i];
				if (item.Grow > 0.0f)
				{
					if (mainDefinite)
					{
						// The grow share is the child's MARGIN BOX main length; the base
						// Measure deflates the margin out of it.
						let childMain = item.Main + remaining * item.Grow / totalGrow;
						item.Child.Measure(MainCross(childMain, Max(0.0f, childMain), 0.0f,
							Max(0.0f, availableCross), horizontal));
					}
					else
					{
						// Nothing to share out of an indefinite axis, so the child measures to
						// its content and grow simply does not apply.
						item.Child.Measure(
							LooseCrossConstraints(looseInner, item.Child, horizontal));
					}
					item.Main = MainOf(item.Child.MarginBoxSize, horizontal);
					item.Cross = CrossOf(item.Child.MarginBoxSize, horizontal);
				}

				line.Main += item.Main;
				line.Cross = Max(line.Cross, item.Cross);
				mItems[i] = item;
			}

			// A cross axis Match is re-measured at the SETTLED line cross size, which is only
			// known now. The targets are tight MARGIN boxes, the base insetting to the border
			// box itself.
			if (line.Cross > 0.0f)
			{
				for (int i = line.Start; i < line.Start + line.Count; i++)
				{
					var item = mItems[i];
					if (!item.MatchCross)
						continue;

					item.Child.Measure(
						MainCross(item.Main, item.Main, line.Cross, line.Cross, horizontal));
					item.Cross = CrossOf(item.Child.MarginBoxSize, horizontal);
					mItems[i] = item;
				}
			}

			mLines[lineIndex] = line;
		}

		// 4. The container: the WIDEST line on the main axis, and the lines stacked with their
		//    gaps on the cross one.
		var totalMain = 0.0f;
		var totalCross = 0.0f;
		for (let line in mLines)
		{
			totalMain = Max(totalMain, line.Main);
			totalCross += line.Cross;
		}
		if (mLines.Count > 1)
			totalCross += CrossGap * (float)(mLines.Count - 1);

		let width = horizontal ? totalMain : totalCross;
		let height = horizontal ? totalCross : totalMain;
		MeasuredSize = .(outer.ConstrainWidth(width + Padding.TotalHorizontal),
			outer.ConstrainHeight(height + Padding.TotalVertical));
	}

	// ---- Arrange ---------------------------------------------------------------------------

	private void LayoutLines(float width, float height, bool horizontal)
	{
		let contentWidth = width - Padding.TotalHorizontal;
		let contentHeight = height - Padding.TotalVertical;
		let contentMain = horizontal ? contentWidth : contentHeight;
		let contentCross = horizontal ? contentHeight : contentWidth;
		let gap = MainGap;
		let crossGap = CrossGap;

		// The items at their MEASURED sizes, re-broken against the arranged main size, which
		// may differ from what measure was offered.
		mItems.Clear();
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			var item = FlexItem();
			item.Child = child;
			item.Main = MainOf(child.MarginBoxSize, horizontal);
			item.Cross = CrossOf(child.MarginBoxSize, horizontal);
			mItems.Add(item);
		}

		BreakLines(Wrap ? contentMain : FloatMax, gap);
		for (int lineIndex < mLines.Count)
		{
			var line = mLines[lineIndex];
			line.Cross = 0.0f;
			for (int i = line.Start; i < line.Start + line.Count; i++)
				line.Cross = Max(line.Cross, mItems[i].Cross);
			mLines[lineIndex] = line;
		}

		// The lines packed on the cross axis. A SINGLE non wrapping line IS the container, so
		// align content has no effect on it, which is what CSS says.
		var crossStart = 0.0f;
		var crossBetween = crossGap;
		if (!Wrap && (mLines.Count == 1))
		{
			var only = mLines[0];
			only.Cross = contentCross;
			mLines[0] = only;
		}
		else if (!mLines.IsEmpty)
		{
			var stacked = crossGap * (float)(mLines.Count - 1);
			for (let line in mLines)
				stacked += line.Cross;

			let free = Max(0.0f, contentCross - stacked);
			let lineCount = (float)mLines.Count;
			switch (AlignContent)
			{
			case .Start:
			case .End: crossStart = free;
			case .Center: crossStart = free * 0.5f;
			case .SpaceBetween:
				if (mLines.Count > 1)
					crossBetween += free / (lineCount - 1.0f);
			case .SpaceAround:
				crossStart = free / lineCount * 0.5f;
				crossBetween += free / lineCount;
			case .Stretch:
				for (int lineIndex < mLines.Count)
				{
					var line = mLines[lineIndex];
					line.Cross += free / lineCount;
					mLines[lineIndex] = line;
				}
			}
		}

		let padMain = horizontal ? Padding.Left : Padding.Top;
		let padCross = horizontal ? Padding.Top : Padding.Left;
		var crossPos = padCross + crossStart;

		for (let line in mLines)
		{
			var lineMain = gap * (float)((line.Count > 0) ? (line.Count - 1) : 0);
			for (int i = line.Start; i < line.Start + line.Count; i++)
				lineMain += mItems[i].Main;

			ComputeJustify(JustifyContent, contentMain, lineMain, (int32)line.Count,
				var startOffset, var between);
			between += gap;

			var mainPos = padMain + startOffset;
			for (int i = line.Start; i < line.Start + line.Count; i++)
			{
				let item = mItems[i];
				if (i > line.Start)
					mainPos += between;

				let alignSelf = item.Child.Layout.AlignSelf;
				let align = (alignSelf != null) ? alignSelf.Value : AlignItems;

				// MARGIN box placement: the base Layout insets by the margin once.
				var itemCrossPos = crossPos;
				var finalCross = item.Cross;
				switch (align)
				{
				case .Start, .Baseline:
					// Baseline falls back to start: real baseline alignment needs the items'
					// baselines, which the line model does not carry yet.
				case .End: itemCrossPos = crossPos + line.Cross - item.Cross;
				case .Center: itemCrossPos = crossPos + (line.Cross - item.Cross) * 0.5f;
				case .Stretch:
					// CSS: stretch fills the cross axis only where the cross size is AUTO. An
					// explicitly sized child keeps the length it measured to.
					let crossSpec = horizontal ? item.Child.Layout.Height.Value
						: item.Child.Layout.Width.Value;
					finalCross = crossSpec.IsFixed ? item.Cross : line.Cross;
				}

				finalCross = Max(0.0f, finalCross);
				if (horizontal)
					item.Child.Layout(mainPos, itemCrossPos, item.Main, finalCross);
				else
					item.Child.Layout(itemCrossPos, mainPos, finalCross, item.Main);

				mainPos += item.Main;
			}

			crossPos += line.Cross + crossBetween;
		}
	}

	/// The leading offset and the extra gap a justification asks for.
	///
	/// The gap is returned as an ADDITION to the container's own spacing rather than as the
	/// whole gap, so a `space-between` and a declared `gap` compose the way CSS composes them.
	private static void ComputeJustify(Justify justify, float containerSize,
		float totalChildSize, int32 childCount, out float startOffset, out float extraGap)
	{
		startOffset = 0.0f;
		extraGap = 0.0f;
		let freeSpace = Max(0.0f, containerSize - totalChildSize);

		switch (justify)
		{
		case .Start:
		case .End: startOffset = freeSpace;
		case .Center: startOffset = freeSpace * 0.5f;
		case .SpaceBetween:
			if (childCount > 1)
				extraGap = freeSpace / (float)(childCount - 1);
		case .SpaceAround:
			if (childCount > 0)
			{
				let around = freeSpace / (float)childCount;
				startOffset = around * 0.5f;
				extraGap = around;
			}
		case .SpaceEvenly:
			if (childCount > 0)
			{
				let even = freeSpace / (float)(childCount + 1);
				startOffset = even;
				extraGap = even;
			}
		}
	}
}
