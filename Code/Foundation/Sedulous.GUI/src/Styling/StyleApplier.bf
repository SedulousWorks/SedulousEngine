using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// ApplyStyle: writes a resolved style's typed values onto a node. Node and text properties go to
// their setters; the box properties (background colour and layers, a border per side, radii, box
// shadows, filters, the backdrop filter, the blend mode) become the node's NodeBox and `transform`
// its style transform, both owned by the sheet; a property the table (StyleProperties) does not
// name goes to the widget's reflected property declaring it as its CSS name, so a library's widget
// is styled with no applier code of its own.

static
{
	/// Strip a CSS url(...) wrapper (and any quotes) to the inner resource name; returns the value
	/// unchanged if it is not a url() form.
	public static StringView ParseUrl(StringView value)
	{
		var v = ParseUtil.Trim(value);
		if ((v.Length >= 5) && (v.Substring(0, 4) == "url(") && (v[v.Length - 1] == ')'))
			v = ParseUtil.Trim(v.Substring(4, v.Length - 5));
		if ((v.Length >= 2) && ((v[0] == '"') || (v[0] == '\'')) && (v[v.Length - 1] == v[0]))
			v = v.Substring(1, v.Length - 2);
		return v;
	}

	/// Apply the supported declarations of `style` to `node`. The box properties (background,
	/// border, radius, box-shadow) become the node's box, owned by the sheet: a restyle without any
	/// replaces it with none.
	public static void ApplyStyle(UINode node, ResolvedStyle input)
	{
		ApplyStyle(node, input, null, null, LengthContext());
	}

	/// `resources` (may be null) loads background-image; `fontService` (may be null) resolves
	/// font-family and font-size. Missing either just skips that property.
	public static void ApplyStyle(UINode node, ResolvedStyle input, IResourceProvider resources, IFontService fontService)
	{
		ApplyStyle(node, input, resources, fontService, LengthContext());
	}

	public static void ApplyStyle(UINode node, ResolvedStyle input, IResourceProvider resources, IFontService fontService,
		LengthContext lengths)
	{
		var style = input;
		if (!input.IsFinalized)
		{
			let settledCopy = scope:: ResolvedStyle();
			settledCopy.Set(input);
			settledCopy.Finalize();
			style = settledCopy;
		}

		float? LengthOf(StringView name, float percentBase)
		{
			let v = style.Value(name);
			if ((v == null) || (v.Kind != .Length))
				return null;
			return ResolveLengthValue(v.Length, lengths, percentBase);
		}
		// A length given as a percentage, which layout resolves (a margin's, a padding's, a gap's).
		float? PercentOf(StringView name)
		{
			let v = style.Value(name);
			if ((v == null) || (v.Kind != .Length) || (v.Length.PercentPart == 0.0f))
				return null;
			return v.Length.PercentPart; // a calc()'s too: layout adds it to the pixels
		}
		StringView KeywordOf(StringView name)
		{
			let v = style.Value(name);
			return (v != null) ? (StringView)v.Keyword : default;
		}
		bool Free(StyleSlot slot) => !node.IsStylePinned(slot);

		// What the sheet sets through setters: a property code pinned stays code's; one the sheet
		// sets takes its value; one it does not returns to the node's own value.
		using (Node.StyleWriteScope(node))
		{
			let own = node.CaptureUnstyledValues();

			if (Free(.SlotOpacity))
			{
				let o = style.Value("opacity");
				let alpha = (o != null) ? o.Number : own.Alpha;
				if (alpha != node.Alpha)
					node.Alpha = alpha;
			}

			// The direction first, as the logical sides (inline start and end) and the text's start
			// and end follow it. Not inherited through the style: a node with none runs as the first
			// ancestor that says does.
			if (Free(.SlotDirection))
			{
				let v = KeywordOf("direction");
				node.SetLayoutDirection((v == "rtl") ? .RightToLeft : ((v == "ltr") ? .LeftToRight : ((v == "auto") ? .Auto : .Inherit)));
			}

			// The logical sides name the physical ones the node's direction puts them on; given
			// beside a physical one for the same side, the logical one wins.
			let rtl = node.IsRightToLeft;
			StringView startSide = rtl ? "right" : "left";
			StringView Logical(StringView prefix, StringView side)
			{
				// margin- / padding- / inset- with inline-start or inline-end, by which side `side` is.
				let start = side == startSide;
				if (prefix == "margin-")
					return start ? "margin-inline-start" : "margin-inline-end";
				if (prefix == "padding-")
					return start ? "padding-inline-start" : "padding-inline-end";
				return start ? "inset-inline-start" : "inset-inline-end";
			}

			{
				var padding = node.PaddingLengths;
				var paddingPercent = node.PaddingPercent;
				void Side(StyleSlot slot, StringView name, ref float field, float ownValue, ref float percentField)
				{
					if (!Free(slot))
						return;
					// A percentage is of the containing box's width, which layout knows. A calc()
					// has both: its percent part here, its pixels (base 0 drops the percent) there.
					let percent = PercentOf(name);
					percentField = percent.GetValueOrDefault(0.0f);
					field = LengthOf(name, 0.0f).GetValueOrDefault(percent.HasValue ? 0.0f : ownValue);
				}
				Side(.SlotPaddingTop, "padding-top", ref padding.Top, own.Padding.Top, ref paddingPercent.Top);
				Side(.SlotPaddingRight, "padding-right", ref padding.Right, own.Padding.Right, ref paddingPercent.Right);
				Side(.SlotPaddingBottom, "padding-bottom", ref padding.Bottom, own.Padding.Bottom, ref paddingPercent.Bottom);
				Side(.SlotPaddingLeft, "padding-left", ref padding.Left, own.Padding.Left, ref paddingPercent.Left);
				void LogicalSide(StyleSlot slot, StringView name, ref float field, ref float percentField)
				{
					if (!Free(slot))
						return;
					let percent = PercentOf(name);
					if (percent.HasValue)
					{
						percentField = percent.Value;
						field = LengthOf(name, 0.0f).GetValueOrDefault(0.0f); // a calc()'s pixels beside its percent
						return;
					}
					let v = LengthOf(name, 0.0f);
					if (v.HasValue)
					{
						field = v.Value;
						percentField = 0.0f;
					}
				}
				LogicalSide(.SlotPaddingLeft, Logical("padding-", "left"), ref padding.Left, ref paddingPercent.Left);
				LogicalSide(.SlotPaddingRight, Logical("padding-", "right"), ref padding.Right, ref paddingPercent.Right);
				if (!(padding == node.PaddingLengths))
					node.Padding = padding;
				node.PaddingPercent = paddingPercent;
			}

			// Layout: the sheet's values over the node's own, then each field code pinned as code
			// left it. Percentages and auto wait for layout.
			{
				let ls = scope LayoutStyle();
				ls.Set(own.Layout);
				void SizeOf(StringView name, ref LayoutLength field)
				{
					let v = style.Value(name);
					if (v == null)
						return;
					if (v.Kind == .Length)
						field = StyleApplierDetail.ToLayoutLength(v.Length, lengths);
					else if (v.Kind == .Keyword)
						field = StyleApplierDetail.LayoutKeyword(v.Keyword);
				}
				SizeOf("width", ref ls.Width);
				SizeOf("height", ref ls.Height);
				SizeOf("min-width", ref ls.MinWidth);
				SizeOf("min-height", ref ls.MinHeight);
				SizeOf("max-width", ref ls.MaxWidth);
				SizeOf("max-height", ref ls.MaxHeight);
				SizeOf("top", ref ls.Top);
				SizeOf("right", ref ls.Right);
				SizeOf("bottom", ref ls.Bottom);
				SizeOf("left", ref ls.Left);
				SizeOf(Logical("inset-", "left"), ref ls.Left);
				SizeOf(Logical("inset-", "right"), ref ls.Right);
				SizeOf("flex-basis", ref ls.Basis);
				{
					// A side as a length, or as a percentage of the containing box's width (layout's).
					var margin = ls.Margin;
					var percent = ls.MarginPercent;
					void MarginSide(StringView name, ref float field, ref float percentField)
					{
						let p = PercentOf(name);
						if (p.HasValue)
						{
							percentField = p.Value;
							field = LengthOf(name, 0.0f).GetValueOrDefault(0.0f); // a calc()'s pixels beside its percent
							return;
						}
						let v = LengthOf(name, 0.0f);
						if (v.HasValue)
						{
							field = v.Value;
							percentField = 0.0f;
						}
					}
					MarginSide("margin-top", ref margin.Top, ref percent.Top);
					MarginSide("margin-right", ref margin.Right, ref percent.Right);
					MarginSide("margin-bottom", ref margin.Bottom, ref percent.Bottom);
					MarginSide("margin-left", ref margin.Left, ref percent.Left);
					MarginSide(Logical("margin-", "left"), ref margin.Left, ref percent.Left);
					MarginSide(Logical("margin-", "right"), ref margin.Right, ref percent.Right);
					ls.Margin = margin;
					ls.MarginPercent = percent;
				}
				float? NumberOf(StringView name)
				{
					let v = style.Value(name);
					if ((v != null) && (v.Kind == .Number))
						return v.Number;
					return null;
				}
				let grow = NumberOf("flex-grow");
				if (grow.HasValue)
					ls.Grow = grow.Value;
				let shrink = NumberOf("flex-shrink");
				if (shrink.HasValue)
					ls.Shrink = shrink.Value;
				let order = NumberOf("order");
				if (order.HasValue)
					ls.Order = (int32)order.Value;
				let zIndex = NumberOf("z-index");
				if (zIndex.HasValue)
					ls.ZIndex = (int32)zIndex.Value;
				// A gap as a length, or a percentage of the container's content size (layout's).
				let rowGapPercent = PercentOf("row-gap");
				if (rowGapPercent.HasValue)
				{
					ls.RowGapPercent = rowGapPercent.Value;
					ls.RowGap = LengthOf("row-gap", 0.0f).GetValueOrDefault(0.0f);
				}
				else
				{
					let v = LengthOf("row-gap", 0.0f);
					if (v.HasValue)
						ls.RowGap = v.Value;
				}
				let columnGapPercent = PercentOf("column-gap");
				if (columnGapPercent.HasValue)
				{
					ls.ColumnGapPercent = columnGapPercent.Value;
					ls.ColumnGap = LengthOf("column-gap", 0.0f).GetValueOrDefault(0.0f);
				}
				else
				{
					let v = LengthOf("column-gap", 0.0f);
					if (v.HasValue)
						ls.ColumnGap = v.Value;
				}
				{
					let display = StyleApplierDetail.DisplayNamed(KeywordOf("display"));
					if (display.HasValue) ls.Kind = display.Value;
					let position = StyleApplierDetail.PositionNamed(KeywordOf("position"));
					if (position.HasValue) ls.Placement = position.Value;
					let sizing = StyleApplierDetail.BoxSizingNamed(KeywordOf("box-sizing"));
					if (sizing.HasValue) ls.Sizing = sizing.Value;
					let overflowX = StyleApplierDetail.OverflowNamed(KeywordOf("overflow-x"));
					if (overflowX.HasValue) ls.OverflowX = overflowX.Value;
					let overflowY = StyleApplierDetail.OverflowNamed(KeywordOf("overflow-y"));
					if (overflowY.HasValue) ls.OverflowY = overflowY.Value;
					let scrolling = StyleApplierDetail.ScrollBehaviorNamed(KeywordOf("scroll-behavior"));
					if (scrolling.HasValue) ls.Scrolling = scrolling.Value;
					let overscroll = StyleApplierDetail.OverscrollBehaviorNamed(KeywordOf("overscroll-behavior"));
					if (overscroll.HasValue) ls.Overscroll = overscroll.Value;
					let barWidth = StyleApplierDetail.ScrollbarWidthNamed(KeywordOf("scrollbar-width"));
					if (barWidth.HasValue) ls.BarWidth = barWidth.Value;
					let barVisibility = StyleApplierDetail.ScrollbarVisibilityNamed(KeywordOf("scrollbar-visibility"));
					if (barVisibility.HasValue) ls.BarVisibility = barVisibility.Value;
					let direction = StyleApplierDetail.DirectionNamed(KeywordOf("flex-direction"));
					if (direction.HasValue) ls.Direction = direction.Value;
					let wrap = StyleApplierDetail.WrapNamed(KeywordOf("flex-wrap"));
					if (wrap.HasValue) ls.Wrap = wrap.Value;
					let justifyContent = StyleApplierDetail.JustifyNamed(KeywordOf("justify-content"));
					if (justifyContent.HasValue) ls.JustifyContent = justifyContent.Value;
					let alignContent = StyleApplierDetail.JustifyNamed(KeywordOf("align-content"));
					if (alignContent.HasValue) ls.AlignContent = alignContent.Value;
					let alignItems = StyleApplierDetail.AlignNamed(KeywordOf("align-items"));
					if (alignItems.HasValue) ls.AlignItems = alignItems.Value;
					let justifyItems = StyleApplierDetail.AlignNamed(KeywordOf("justify-items"));
					if (justifyItems.HasValue) ls.JustifyItems = justifyItems.Value;
					let alignSelf = StyleApplierDetail.AlignNamed(KeywordOf("align-self"));
					if (alignSelf.HasValue) ls.AlignSelf = alignSelf.Value;
					let justifySelf = StyleApplierDetail.AlignNamed(KeywordOf("justify-self"));
					if (justifySelf.HasValue) ls.JustifySelf = justifySelf.Value;
					let autoFlow = StyleApplierDetail.AutoFlowNamed(KeywordOf("grid-auto-flow"));
					if (autoFlow.HasValue) ls.AutoFlow = autoFlow.Value;
					let dock = StyleApplierDetail.DockNamed(KeywordOf("dock"));
					if (dock.HasValue) ls.DockSide = dock.Value;
				}
				let tracks = scope List<GridTrack>();
				let columns = KeywordOf("grid-template-columns");
				if (columns.Length != 0)
				{
					tracks.Clear();
					if (StyleApplierDetail.ParseGridTracks(columns, lengths, tracks) && !LayoutStyleDetail.SameTracks(ls.Columns, tracks))
					{
						ls.Columns.Clear();
						ls.Columns.AddRange(tracks);
					}
				}
				let rows = KeywordOf("grid-template-rows");
				if (rows.Length != 0)
				{
					tracks.Clear();
					if (StyleApplierDetail.ParseGridTracks(rows, lengths, tracks) && !LayoutStyleDetail.SameTracks(ls.Rows, tracks))
					{
						ls.Rows.Clear();
						ls.Rows.AddRange(tracks);
					}
				}
				let autoRows = KeywordOf("grid-auto-rows");
				if (autoRows.Length != 0)
				{
					tracks.Clear();
					if (StyleApplierDetail.ParseGridTracks(autoRows, lengths, tracks) && (tracks.Count == 1))
						ls.AutoRows = tracks[0];
				}
				let autoColumns = KeywordOf("grid-auto-columns");
				if (autoColumns.Length != 0)
				{
					tracks.Clear();
					if (StyleApplierDetail.ParseGridTracks(autoColumns, lengths, tracks) && (tracks.Count == 1))
						ls.AutoColumns = tracks[0];
				}
				let gridColumn = KeywordOf("grid-column");
				if (gridColumn.Length != 0)
				{
					let g = StyleApplierDetail.ParseGridPlacement(gridColumn);
					if (g.HasValue)
						ls.Column = g.Value;
				}
				let gridRow = KeywordOf("grid-row");
				if (gridRow.Length != 0)
				{
					let g = StyleApplierDetail.ParseGridPlacement(gridRow);
					if (g.HasValue)
						ls.Row = g.Value;
				}
				let result = scope LayoutStyle();
				result.Set(node.LayoutStyle);
				StyleApplierDetail.TakeFreeLayoutFields(node, ls, result);
				if (Free(.SlotMarginTop)) { result.Margin.Top = ls.Margin.Top; result.MarginPercent.Top = ls.MarginPercent.Top; }
				if (Free(.SlotMarginRight)) { result.Margin.Right = ls.Margin.Right; result.MarginPercent.Right = ls.MarginPercent.Right; }
				if (Free(.SlotMarginBottom)) { result.Margin.Bottom = ls.Margin.Bottom; result.MarginPercent.Bottom = ls.MarginPercent.Bottom; }
				if (Free(.SlotMarginLeft)) { result.Margin.Left = ls.Margin.Left; result.MarginPercent.Left = ls.MarginPercent.Left; }
				if (Free(.SlotRowGap)) result.RowGapPercent = ls.RowGapPercent;
				if (Free(.SlotColumnGap)) result.ColumnGapPercent = ls.ColumnGapPercent;
				if (ChangedLayoutSlots(result, node.LayoutStyle).Any)
					node.LayoutStyle = result;
				// Anything but visible clips the children to the box (and scroll and auto scroll
				// them); a widget that clips its own parts (an item view's rows) keeps doing so unless
				// the sheet says.
				if (Free(.SlotOverflowX) && Free(.SlotOverflowY))
				{
					if ((KeywordOf("overflow-x").Length != 0) || (KeywordOf("overflow-y").Length != 0))
						node.ClipChildren = (result.OverflowX != .Visible) || (result.OverflowY != .Visible);
					else
						node.ClipChildren = own.ClipChildren;
				}
			}

			if (Free(.SlotEnabled))
			{
				var enabled = own.Enabled;
				let e = KeywordOf("enabled");
				if (e.Length != 0)
				{
					let b = ParseBool(e);
					if (b.HasValue)
						enabled = b.Value;
				}
				if (enabled != node.Enabled)
					node.Enabled = enabled;
			}
			if (Free(.SlotVisibility))
			{
				let v = KeywordOf("visibility");
				let visible = (v == "hidden") ? false : ((v == "visible") ? true : own.Visible);
				if (visible != node.Visible)
					node.Visible = visible;
			}

			// Text: colour, the font, text-align, white-space, line-height and letter-spacing inherit
			// (the sheet's value, else the parent's, else the node's own; `initial` is the node's own,
			// or CSS's where the table names one); vertical-align does not.
			{
				let ownText = node.CaptureUnstyledText();
				let parent = node.Parent as UINode;
				bool Initial(StringView name) => style.Get(name) == "initial";
				bool Inherits(StringView name) => (parent != null) && !Initial(name);
				let text = scope UINode.TextStyle();
				text.Set(node.GetTextStyle());
				if (Free(.SlotColor))
				{
					let c = style.Value("color");
					if (c != null)
						text.TextColor = c.ColorValue;
					else
						text.TextColor = Inherits("color") ? parent.TextColor : ownText.TextColor;
				}
				if (Free(.SlotTextAlign))
				{
					// start and end are the line's: its paragraph's direction places them.
					let v = KeywordOf("text-align");
					if ((v == "left") || (v == "justify"))
						text.HAlign = .Left;
					else if ((v == "center") || (v == "centre"))
						text.HAlign = .Center;
					else if (v == "right")
						text.HAlign = .Right;
					else if (v == "start")
						text.HAlign = .Start;
					else if (v == "end")
						text.HAlign = .End;
					else
						text.HAlign = Inherits("text-align") ? parent.TextAlignH : ownText.HAlign;
				}
				if (Free(.SlotVerticalAlign))
				{
					let v = KeywordOf("vertical-align");
					if (v == "top")
						text.VAlign = .Top;
					else if ((v == "middle") || (v == "center"))
						text.VAlign = .Middle;
					else if (v == "bottom")
						text.VAlign = .Bottom;
					else
						text.VAlign = ownText.VAlign;
				}
				if (Free(.SlotFontFamily) || Free(.SlotFontSize))
				{
					// The family and the size each from the sheet, the parent or the node itself; the
					// font is the parent's or the node's own when both come from there, else the font
					// service's for the pair.
					// A list: the first family the service has is the font, the rest after it the faces
					// a character it lacks falls back to. When it has none of them, the first is asked
					// for all the same (a service may resolve a family it does not list, to its
					// default).
					let declaredList = Initial("font-family") ? StringView() : KeywordOf("font-family");
					StringView declaredFamily = default;
					StringView firstFamily = default;
					let declaredFallbacks = scope String();
					ForEachFamily(declaredList, scope [&] (family) =>
						{
							if (firstFamily.Length == 0)
								firstFamily = family;
							if (declaredFamily.Length == 0)
							{
								if ((fontService == null) || fontService.HasFamily(family))
									declaredFamily = family;
								return;
							}
							if (declaredFallbacks.Length != 0)
								declaredFallbacks.Append(", ");
							declaredFallbacks.Append(family);
						});
					if (declaredFamily.Length == 0)
						declaredFamily = firstFamily;
					// font-size's em and percentages are of the parent's size, not its own.
					var parentLengths = lengths;
					parentLengths.ElementFontSize = ((parent != null) && (parent.GetTextStyle().FontSize > 0.0f)) ? parent.GetTextStyle().FontSize
						: lengths.RootFontSize;
					let sizeValue = style.Value("font-size");
					float? declaredSize = ((sizeValue != null) && (sizeValue.Kind == .Length))
						? (float?)ResolveLengthValue(sizeValue.Length, parentLengths, parentLengths.ElementFontSize)
						: null;
					let from = (Inherits("font-family") || Inherits("font-size")) ? parent.GetTextStyle() : ownText;
					let familyDeclared = Free(.SlotFontFamily) && (declaredFamily.Length != 0);
					let sizeDeclared = Free(.SlotFontSize) && declaredSize.HasValue && (declaredSize.Value > 0.0f);
					if (!familyDeclared && !sizeDeclared)
					{
						text.Font = from.Font;
						text.FontFamily.Set(from.FontFamily);
						text.Selection.FallbackFamilies.Set(from.Selection.FallbackFamilies);
						text.FontSize = from.FontSize;
					}
					else
					{
						StringView family = familyDeclared ? declaredFamily : (StringView)from.FontFamily;
						StringView fallbacks = familyDeclared ? (StringView)declaredFallbacks : (StringView)from.Selection.FallbackFamilies;
						let size = sizeDeclared ? declaredSize.Value : ((from.FontSize > 0.0f) ? from.FontSize : 16.0f);
						if ((fontService != null) && (family.Length != 0))
						{
							let font = fontService.GetFont(family, size);
							if (font != null)
							{
								text.Font = font;
								text.FontFamily.Set(family);
								text.Selection.FallbackFamilies.Set(fallbacks);
								text.FontSize = size;
							}
						}
					}
				}
				// white-space, line-height and letter-spacing inherit as the rest do.
				if (Free(.SlotWhiteSpace))
				{
					let v = KeywordOf("white-space");
					if (v == "normal")
						text.WhiteSpace = .Normal;
					else if (v == "nowrap")
						text.WhiteSpace = .NoWrap;
					else if (v == "pre")
						text.WhiteSpace = .Pre;
					else if ((v == "pre-wrap") || (v == "pre-line") || (v == "break-spaces"))
						text.WhiteSpace = .PreWrap;
					else
						text.WhiteSpace = Inherits("white-space") ? parent.GetTextStyle().WhiteSpace : ownText.WhiteSpace;
				}
				if (Free(.SlotLineHeight))
				{
					// normal; a bare number, a multiple of each node's own font size (inherited as the
					// number); a length; a percentage of the font size (inherited as the pixels).
					let v = ParseUtil.Trim(KeywordOf("line-height"));
					let number = (v.Length != 0) ? TextRunsDetail.ParseFloat(v) : null;
					let from = Inherits("line-height") ? parent.GetTextStyle() : ownText;
					let percent = ((v.Length > 1) && (v[v.Length - 1] == '%')) ? TextRunsDetail.ParseFloat(v.Substring(0, v.Length - 1)) : null;
					let px = (v.Length != 0) ? ResolveLength(v, lengths) : null;
					if (v == "normal")
					{
						text.LineHeight = 0.0f;
						text.LineHeightFactor = false;
					}
					else if (number.HasValue)
					{
						text.LineHeight = Math.Max(0.0f, (float)number.Value);
						text.LineHeightFactor = true;
					}
					else if (percent.HasValue)
					{
						text.LineHeight = Math.Max(0.0f, (float)percent.Value * 0.01f * text.FontSize);
						text.LineHeightFactor = false;
					}
					else if (px.HasValue)
					{
						text.LineHeight = Math.Max(0.0f, px.Value);
						text.LineHeightFactor = false;
					}
					else
					{
						text.LineHeight = from.LineHeight;
						text.LineHeightFactor = from.LineHeightFactor;
					}
				}
				// font-weight and font-style inherit; a run's face is chosen from them as it lays out.
				// bolder and lighter are of the parent's weight.
				if (Free(.SlotFontWeight))
				{
					let v = ParseUtil.Trim(KeywordOf("font-weight"));
					let inherited = (parent != null) ? parent.GetTextStyle().Selection.Weight : (uint16)400;
					let number = (v.Length != 0) ? TextRunsDetail.ParseFloat(v) : null;
					if (v == "normal")
						text.Selection.Weight = 400;
					else if (v == "bold")
						text.Selection.Weight = 700;
					else if (v == "bolder")
						text.Selection.Weight = TextLayoutDetail.Bolder(inherited);
					else if (v == "lighter")
						text.Selection.Weight = TextLayoutDetail.Lighter(inherited);
					else if (number.HasValue && (number.Value >= 1.0) && (number.Value <= 1000.0))
						text.Selection.Weight = (uint16)number.Value;
					else
						text.Selection.Weight = Inherits("font-weight") ? inherited : ownText.Selection.Weight;
				}
				if (Free(.SlotFontStyle))
				{
					let v = ParseUtil.Trim(KeywordOf("font-style"));
					if (v == "normal")
						text.Selection.Italic = false;
					else if ((v == "italic") || v.StartsWith("oblique"))
						text.Selection.Italic = true;
					else
						text.Selection.Italic = Inherits("font-style") ? parent.GetTextStyle().Selection.Italic : ownText.Selection.Italic;
				}
				if (Free(.SlotOverflowWrap))
				{
					let v = KeywordOf("overflow-wrap");
					if (v == "normal")
						text.BreakWords = false;
					else if ((v == "break-word") || (v == "anywhere"))
						text.BreakWords = true;
					else
						text.BreakWords = Inherits("overflow-wrap") ? parent.GetTextStyle().BreakWords : ownText.BreakWords;
				}
				if (Free(.SlotLetterSpacing))
				{
					let v = ParseUtil.Trim(KeywordOf("letter-spacing"));
					let px = (v.Length != 0) ? ResolveLength(v, lengths) : null;
					if (v == "normal")
						text.LetterSpacing = 0.0f;
					else if (px.HasValue)
						text.LetterSpacing = px.Value;
					else
						text.LetterSpacing = Inherits("letter-spacing") ? parent.GetTextStyle().LetterSpacing : ownText.LetterSpacing;
				}
				node.ApplyTextStyle(text);
			}

			// The box: the sheet's, or none when a restyle drops every box property it had set.
			if (StyleApplierDetail.AnyBoxProperty(style))
			{
				let nodeBox = scope NodeBox();
				StyleApplierDetail.BuildBox(node, style, resources, lengths, nodeBox);
				node.SetBox(nodeBox, true);
			}
			else if (node.IsBoxFromStyle)
				node.SetBox(scope NodeBox(), true);

			// The transform about its origin; likewise owned by the sheet once it sets one.
			let transform = style.Value("transform");
			let origin = style.Value("transform-origin");
			if ((transform != null) || (origin != null))
			{
				let none = scope List<TransformFunction>();
				node.SetStyleTransform((transform != null) ? transform.Transforms : none,
					(origin != null) ? origin.OriginX : LengthValue(50.0f, .Percent),
					(origin != null) ? origin.OriginY : LengthValue(50.0f, .Percent));
			}
			else if (node.IsTransformFromStyle)
			{
				node.SetStyleTransform(scope List<TransformFunction>(), LengthValue(50.0f, .Percent), LengthValue(50.0f, .Percent));
			}

			// What the table does not name: a reflected property that takes it by its CSS name.
			StyleApplierDetail.ApplyReflected(node, style, lengths);
		}
	}

	/// Apply a resolved pseudo-element style to a widget part (slider::thumb, checkbox::box,
	/// window::title, ...): its box properties, opacity and colour (a part that is text), each
	/// aspect marked where the sheet gives it, so the widget's own look shows through the rest.
	public static void ApplyPartStyle(UINode node, StringView part, ResolvedStyle input)
	{
		ApplyPartStyle(node, part, input, null, LengthContext());
	}

	public static void ApplyPartStyle(UINode node, StringView part, ResolvedStyle input, IResourceProvider resources)
	{
		ApplyPartStyle(node, part, input, resources, LengthContext());
	}

	public static void ApplyPartStyle(UINode node, StringView part, ResolvedStyle input, IResourceProvider resources, LengthContext lengths)
	{
		var style = input;
		if (!input.IsFinalized)
		{
			let settledCopy = scope:: ResolvedStyle();
			settledCopy.Set(input);
			settledCopy.Finalize();
			style = settledCopy;
		}
		let partStyle = scope PartStyle();
		StyleApplierDetail.BuildBox(node, style, resources, lengths, partStyle.Box);
		bool Any(String[4] names)
		{
			for (let n in names)
			{
				if (style.Has(n))
					return true;
			}
			return false;
		}
		partStyle.HasBackground = style.Has("background-color") || style.Has("background-image");
		partStyle.HasBorderWidth = Any(StyleApplierDetail.sBorderWidths) || Any(StyleApplierDetail.sBorderStyles);
		partStyle.HasBorderColor = Any(StyleApplierDetail.sBorderColors);
		partStyle.HasRadii = Any(StyleApplierDetail.sBorderRadii);
		partStyle.HasShadows = style.Has("box-shadow");
		let o = style.Value("opacity");
		if (o != null)
			partStyle.Opacity = o.Number;
		let c = style.Value("color");
		if ((c != null) && (c.Kind == .ColorValue))
		{
			partStyle.TextColor = c.ColorValue;
			partStyle.HasColor = true;
		}
		let w = style.Value("width");
		if ((w != null) && (w.Kind == .Length)) // not auto
		{
			partStyle.Width = Math.Max(0.0f, StyleApplierDetail.PixelsOf(w, lengths, 0.0f, 0.0f));
			partStyle.HasWidth = true;
		}
		let h = style.Value("height");
		if ((h != null) && (h.Kind == .Length)) // not auto
		{
			partStyle.Height = Math.Max(0.0f, StyleApplierDetail.PixelsOf(h, lengths, 0.0f, 0.0f));
			partStyle.HasHeight = true;
		}
		node.SetPartStyle(part, partStyle);
	}
}

/// What StyleApplier.bf keeps out of the public surface: the layout keywords and grid values, the
/// box's pieces, and the reflected properties a sheet sets.
internal static class StyleApplierDetail
{
	public static String[4] sBorderWidths = .("border-top-width", "border-right-width", "border-bottom-width", "border-left-width");
	public static String[4] sBorderStyles = .("border-top-style", "border-right-style", "border-bottom-style", "border-left-style");
	public static String[4] sBorderColors = .("border-top-color", "border-right-color", "border-bottom-color", "border-left-color");
	public static String[4] sBorderRadii = .("border-top-left-radius", "border-top-right-radius", "border-bottom-right-radius",
		"border-bottom-left-radius");

	// === Layout keywords and grid values ===

	public static LayoutLength LayoutKeyword(StringView k)
	{
		if (k == "fit-content")
			return .(.FitContent, 0.0f);
		if (k == "min-content")
			return .(.MinContent, 0.0f);
		if (k == "max-content")
			return .(.MaxContent, 0.0f);
		if (k == "none")
			return LayoutLength.None();
		return .();
	}

	public static Display? DisplayNamed(StringView k)
	{
		if (k == "flex") return .Flex;
		if (k == "grid") return .Grid;
		if (k == "stack") return .Stack;
		if (k == "dock") return .Dock;
		if (k == "none") return .None;
		if (k == "block") return .Flex;
		return null;
	}

	public static Position? PositionNamed(StringView k)
	{
		if (k == "static") return .Static;
		if (k == "relative") return .Relative;
		if (k == "absolute") return .Absolute;
		return null;
	}

	public static BoxSizing? BoxSizingNamed(StringView k)
	{
		if (k == "border-box") return .BorderBox;
		if (k == "content-box") return .ContentBox;
		return null;
	}

	public static Overflow? OverflowNamed(StringView k)
	{
		if (k == "visible") return .Visible;
		if (k == "hidden") return .Hidden;
		if (k == "clip") return .Hidden;
		if (k == "scroll") return .Scroll;
		if (k == "auto") return .Auto;
		return null;
	}

	public static ScrollBehavior? ScrollBehaviorNamed(StringView k)
	{
		if (k == "auto") return .Auto;
		if (k == "smooth") return .Smooth;
		return null;
	}

	public static OverscrollBehavior? OverscrollBehaviorNamed(StringView k)
	{
		if (k == "auto") return .Auto;
		if (k == "contain") return .Contain;
		if (k == "none") return .Contain;
		return null;
	}

	public static ScrollbarWidth? ScrollbarWidthNamed(StringView k)
	{
		if (k == "auto") return .Auto;
		if (k == "thin") return .Thin;
		if (k == "none") return .None;
		return null;
	}

	public static ScrollbarVisibility? ScrollbarVisibilityNamed(StringView k)
	{
		if (k == "auto") return .Auto;
		if (k == "overlay") return .Overlay;
		return null;
	}

	public static FlexDirection? DirectionNamed(StringView k)
	{
		if (k == "row") return .Row;
		if (k == "column") return .Column;
		if (k == "row-reverse") return .RowReverse;
		if (k == "column-reverse") return .ColumnReverse;
		return null;
	}

	public static FlexWrap? WrapNamed(StringView k)
	{
		if (k == "nowrap") return .NoWrap;
		if (k == "wrap") return .Wrap;
		if (k == "wrap-reverse") return .WrapReverse;
		return null;
	}

	public static Justify? JustifyNamed(StringView k)
	{
		if ((k == "start") || (k == "flex-start")) return .Start;
		if ((k == "end") || (k == "flex-end")) return .End;
		if (k == "center") return .Center;
		if (k == "space-between") return .SpaceBetween;
		if (k == "space-around") return .SpaceAround;
		if (k == "space-evenly") return .SpaceEvenly;
		if ((k == "stretch") || (k == "normal")) return .Stretch;
		return null;
	}

	public static Align? AlignNamed(StringView k)
	{
		if (k == "auto") return .Auto;
		if ((k == "start") || (k == "flex-start")) return .Start;
		if ((k == "end") || (k == "flex-end")) return .End;
		if (k == "center") return .Center;
		if ((k == "stretch") || (k == "normal")) return .Stretch;
		if (k == "baseline") return .Baseline;
		return null;
	}

	public static GridAutoFlow? AutoFlowNamed(StringView k)
	{
		if (k == "row") return .Row;
		if (k == "column") return .Column;
		return null;
	}

	public static Dock? DockNamed(StringView k)
	{
		if (k == "fill") return .Fill;
		if (k == "left") return .Left;
		if (k == "top") return .Top;
		if (k == "right") return .Right;
		if (k == "bottom") return .Bottom;
		if (k == "start") return .Start;
		if (k == "end") return .End;
		return null;
	}

	/// The layout fields a sheet sets as one property each, from `from` into `to` where code has
	/// not pinned them (the margin and the gaps' percentages are the caller's).
	public static void TakeFreeLayoutFields(Node node, LayoutStyle from, LayoutStyle to)
	{
		bool Free(StyleSlot slot) => !node.IsStylePinned(slot);
		if (Free(.SlotWidth)) to.Width = from.Width;
		if (Free(.SlotHeight)) to.Height = from.Height;
		if (Free(.SlotMinWidth)) to.MinWidth = from.MinWidth;
		if (Free(.SlotMinHeight)) to.MinHeight = from.MinHeight;
		if (Free(.SlotMaxWidth)) to.MaxWidth = from.MaxWidth;
		if (Free(.SlotMaxHeight)) to.MaxHeight = from.MaxHeight;
		if (Free(.SlotTop)) to.Top = from.Top;
		if (Free(.SlotRight)) to.Right = from.Right;
		if (Free(.SlotBottom)) to.Bottom = from.Bottom;
		if (Free(.SlotLeft)) to.Left = from.Left;
		if (Free(.SlotFlexBasis)) to.Basis = from.Basis;
		if (Free(.SlotFlexGrow)) to.Grow = from.Grow;
		if (Free(.SlotFlexShrink)) to.Shrink = from.Shrink;
		if (Free(.SlotOrder)) to.Order = from.Order;
		if (Free(.SlotZIndex)) to.ZIndex = from.ZIndex;
		if (Free(.SlotRowGap)) to.RowGap = from.RowGap;
		if (Free(.SlotColumnGap)) to.ColumnGap = from.ColumnGap;
		if (Free(.SlotDisplay)) to.Kind = from.Kind;
		if (Free(.SlotPosition)) to.Placement = from.Placement;
		if (Free(.SlotBoxSizing)) to.Sizing = from.Sizing;
		if (Free(.SlotOverflowX)) to.OverflowX = from.OverflowX;
		if (Free(.SlotOverflowY)) to.OverflowY = from.OverflowY;
		if (Free(.SlotFlexDirection)) to.Direction = from.Direction;
		if (Free(.SlotFlexWrap)) to.Wrap = from.Wrap;
		if (Free(.SlotJustifyContent)) to.JustifyContent = from.JustifyContent;
		if (Free(.SlotAlignContent)) to.AlignContent = from.AlignContent;
		if (Free(.SlotAlignItems)) to.AlignItems = from.AlignItems;
		if (Free(.SlotJustifyItems)) to.JustifyItems = from.JustifyItems;
		if (Free(.SlotAlignSelf)) to.AlignSelf = from.AlignSelf;
		if (Free(.SlotJustifySelf)) to.JustifySelf = from.JustifySelf;
		if (Free(.SlotGridAutoFlow)) to.AutoFlow = from.AutoFlow;
		if (Free(.SlotDock)) to.DockSide = from.DockSide;
		if (Free(.SlotGridTemplateColumns))
		{
			to.Columns.Clear();
			to.Columns.AddRange(from.Columns);
		}
		if (Free(.SlotGridTemplateRows))
		{
			to.Rows.Clear();
			to.Rows.AddRange(from.Rows);
		}
		if (Free(.SlotGridAutoRows)) to.AutoRows = from.AutoRows;
		if (Free(.SlotGridAutoColumns)) to.AutoColumns = from.AutoColumns;
		if (Free(.SlotGridColumn)) to.Column = from.Column;
		if (Free(.SlotGridRow)) to.Row = from.Row;
		if (Free(.SlotScrollBehavior)) to.Scrolling = from.Scrolling;
		if (Free(.SlotOverscrollBehavior)) to.Overscroll = from.Overscroll;
		if (Free(.SlotScrollbarWidth)) to.BarWidth = from.BarWidth;
		if (Free(.SlotScrollbarVisibility)) to.BarVisibility = from.BarVisibility;
	}

	// A sheet's length as layout takes it: a percentage, pixels, or (a calc() with a percentage
	// part) both, the units other than % resolved now.
	public static LayoutLength ToLayoutLength(LengthValue l, LengthContext lengths)
	{
		if (l.Unit == .Percent)
			return LayoutLength.Percent(l.Value);
		let px = ResolveLengthValue(l, lengths, 0.0f); // a calc()'s percent term drops out at base 0
		return (l.PercentPart != 0.0f) ? LayoutLength.Calc(px, l.PercentPart) : LayoutLength.Px(px);
	}

	// One track size: a length or percentage, auto, min-content, max-content, <n>fr.
	public static LayoutLength? TrackLength(StringView t, LengthContext lengths)
	{
		if (t == "auto")
			return LayoutLength();
		if ((t == "min-content") || (t == "max-content"))
			return LayoutLength(); // sized by content, as auto
		let l = ParseLengthValue(t);
		if (l.HasValue)
			return ToLayoutLength(l.Value, lengths);
		return null;
	}

	public static float? Fraction(StringView t)
	{
		if ((t.Length < 3) || (t.Substring(t.Length - 2, 2) != "fr"))
			return null;
		return ParseLength(t.Substring(0, t.Length - 2));
	}

	public static GridTrack? ParseTrack(StringView t, LengthContext lengths)
	{
		let fr = Fraction(t);
		if (fr.HasValue)
			return GridTrack.Flex(fr.Value);
		if ((t.Length > 8) && (t.Substring(0, 7) == "minmax(") && (t[t.Length - 1] == ')'))
		{
			let args = scope List<StringView>();
			SplitTopLevel(t.Substring(7, t.Length - 8), ',', args);
			if (args.Count != 2)
				return null;
			let lo = TrackLength(ParseUtil.Trim(args[0]), lengths);
			if (!lo.HasValue)
				return null;
			let hiFr = Fraction(ParseUtil.Trim(args[1]));
			if (hiFr.HasValue)
				return GridTrack(lo.Value, LayoutLength(), hiFr.Value);
			let hi = TrackLength(ParseUtil.Trim(args[1]), lengths);
			if (!hi.HasValue)
				return null;
			return GridTrack(lo.Value, hi.Value, 0.0f);
		}
		let l = TrackLength(t, lengths);
		if (l.HasValue)
			return GridTrack(l.Value, l.Value, 0.0f);
		return null;
	}

	/// A track list: sizes separated by spaces, `repeat(<n>, <sizes>)` among them, added to
	/// `outTracks`; false when it does not parse.
	public static bool ParseGridTracks(StringView text, LengthContext lengths, List<GridTrack> outTracks)
	{
		if (ParseUtil.Trim(text) == "none")
			return true;
		let parts = scope List<StringView>();
		SplitTopLevel(ParseUtil.Trim(text), ' ', parts);
		for (let part in parts)
		{
			if ((part.Length > 8) && (part.Substring(0, 7) == "repeat(") && (part[part.Length - 1] == ')'))
			{
				let args = scope List<StringView>();
				SplitTopLevel(part.Substring(7, part.Length - 8), ',', args);
				if (args.Count != 2)
					return false;
				let count = ParseLength(ParseUtil.Trim(args[0]));
				if (!count.HasValue || (count.Value < 1.0f))
					return false;
				let unit = scope List<GridTrack>();
				let sizes = scope List<StringView>();
				SplitTopLevel(ParseUtil.Trim(args[1]), ' ', sizes);
				for (let size in sizes)
				{
					let track = ParseTrack(size, lengths);
					if (!track.HasValue)
						return false;
					unit.Add(track.Value);
				}
				for (int32 n = 0; n < (int32)count.Value; n++)
					outTracks.AddRange(unit);
				continue;
			}
			let track = ParseTrack(part, lengths);
			if (!track.HasValue)
				return false;
			outTracks.Add(track.Value);
		}
		return true;
	}

	// grid-column / grid-row: `2`, `1 / 3`, `span 2`, `2 / span 3`, `auto`.
	public static GridPlacement? ParseGridPlacement(StringView text)
	{
		let sides = scope List<StringView>();
		SplitTopLevel(ParseUtil.Trim(text), '/', sides);
		if (sides.IsEmpty || (sides.Count > 2))
			return null;
		int32? SpanOf(StringView side)
		{
			let t = ParseUtil.Trim(side);
			if ((t.Length > 5) && (t.Substring(0, 5) == "span "))
			{
				let n = ParseLength(ParseUtil.Trim(t.Substring(5, t.Length - 5)));
				if (n.HasValue && (n.Value >= 1.0f))
					return (int32)n.Value;
			}
			return null;
		}
		int32? LineOf(StringView side)
		{
			let t = ParseUtil.Trim(side);
			if (t == "auto")
				return 0;
			let n = ParseLength(t);
			if (n.HasValue && (n.Value >= 1.0f))
				return (int32)n.Value;
			return null;
		}
		var placement = GridPlacement();
		let firstSpan = SpanOf(sides[0]);
		if (firstSpan.HasValue)
			placement.Span = firstSpan.Value;
		else
		{
			let line = LineOf(sides[0]);
			if (!line.HasValue)
				return null;
			placement.Start = line.Value;
		}
		if (sides.Count == 2)
		{
			let span = SpanOf(sides[1]);
			if (span.HasValue)
				placement.Span = span.Value;
			else
			{
				let end = LineOf(sides[1]);
				if (!end.HasValue || (placement.Start <= 0) || (end.Value <= placement.Start))
					return null;
				placement.Span = end.Value - placement.Start;
			}
		}
		return placement;
	}

	public static float PixelsOf(StyleValue v, LengthContext lengths, float percentBase, float fallback)
	{
		return ((v != null) && (v.Kind == .Length)) ? ResolveLengthValue(v.Length, lengths, percentBase) : fallback;
	}

	public static void ToBoxGradient(GradientValue g, BoxGradient outGradient)
	{
		outGradient.Kind = (g.Kind == .Linear) ? .Linear : ((g.Kind == .Radial) ? .Radial : .Conic);
		outGradient.Angle = g.Angle;
		outGradient.Repeating = g.Repeating;
		let settled = scope List<GradientStopValue>();
		SettleStops(g.Stops, settled);
		for (let stop in settled)
			outGradient.Stops.Add(GradientStop(stop.Position, stop.StopColor));
	}

	// mix-blend-mode: the blends VG composites (plus-lighter is additive); another is normal.
	public static VGBlendMode BlendModeOf(StringView keyword)
	{
		if (keyword == "multiply")
			return .Multiply;
		if (keyword == "screen")
			return .Screen;
		if (keyword == "plus-lighter")
			return .Additive;
		return .Normal;
	}

	public static bool AnyBoxProperty(ResolvedStyle style)
	{
		for (let p in style.Properties)
		{
			StringView n = p.Name;
			if ((n == "background-color") || (n == "background-image") || (n == "box-shadow") || (n == "filter") ||
				(n == "backdrop-filter") || (n == "mix-blend-mode") || (n == "text-shadow") || (n == "text-outline") ||
				(n == "text-glow") || (n == "background-size") || (n == "background-position") ||
				((n.Length > 7) && (n.Substring(0, 7) == "border-")))
				return true;
		}
		return false;
	}

	// An image's path and, after `#xywh=`, the region of it to draw (a sprite of an atlas, as Media
	// Fragments write one: `atlas.png#xywh=0,32,16,16`); no region: all of it.
	public static StringView ImagePath(StringView url, out Rectangle region)
	{
		region = .();
		StringView fragment = "#xywh=";
		for (int i = 0; i + fragment.Length <= url.Length; i++)
		{
			if (url.Substring(i, fragment.Length) != fragment)
				continue;
			float[4] v = default;
			int n = 0;
			let parts = scope List<StringView>();
			SplitTopLevel(url.Substring(i + fragment.Length, url.Length - i - fragment.Length), ',', parts);
			for (let part in parts)
			{
				let number = ParseLength(ParseUtil.Trim(part));
				if (number.HasValue && (n < 4))
					v[n++] = number.Value;
			}
			if (n == 4)
				region = .(v[0], v[1], v[2], v[3]);
			return url.Substring(0, i);
		}
		return url;
	}

	// One to four values, as margins take them: top, right, bottom, left.
	private static void Spread(ref float[4] v, int count)
	{
		if (count == 1)
		{
			v[1] = v[0];
			v[2] = v[0];
			v[3] = v[0];
		}
		else if (count == 2)
		{
			v[2] = v[0];
			v[3] = v[1];
		}
		else if (count == 3)
			v[3] = v[1];
	}

	private static void Spread(ref bool[4] v, int count)
	{
		if (count == 1)
		{
			v[1] = v[0];
			v[2] = v[0];
			v[3] = v[0];
		}
		else if (count == 2)
		{
			v[2] = v[0];
			v[3] = v[1];
		}
		else if (count == 3)
			v[3] = v[1];
	}

	// border-image: `url(skin.png) <slice>{1,4} [fill] [/ <width>{1,4} [/ <outset>]] [stretch |
	// repeat | round | space]{1,2}`. A slice is image pixels or a percentage of the image; a width
	// a length, or a number times the border's width.
	public static void ParseBorderImage(StringView value, IResourceProvider resources, LengthContext lengths, BorderWidths borders,
		ref BorderImage outImage)
	{
		let spaced = scope String(); // a top-level '/' parted from what touches it (one in a url() is the path's)
		int depth = 0;
		for (let c in value)
		{
			depth += (c == '(') ? 1 : 0;
			if ((c == ')') && (depth > 0))
				depth--;
			if ((c == '/') && (depth == 0))
				spaced.Append(" / ");
			else
				spaced.Append(c);
		}
		StringView source = default;
		float[4] slice = default;
		int slices = 0;
		bool[4] sliceIsPercent = default;
		float[4] width = .(-1.0f, -1.0f, -1.0f, -1.0f);
		int widths = 0;
		BorderImageRepeat[2] repeats = .(.Stretch, .Stretch);
		int repeatCount = 0;
		int section = 0; // 0 slices, 1 widths, 2 outsets
		float[4] borderOf = .(borders.Top, borders.Right, borders.Bottom, borders.Left);
		let tokens = scope List<StringView>();
		SplitTopLevel(spaced, ' ', tokens);
		for (let token in tokens)
		{
			if (SplitFunction(token, let name, let arguments) && (name == "url"))
			{
				source = ParseUtil.Trim(arguments);
				if ((source.Length >= 2) && ((source[0] == '"') || (source[0] == '\'')) && (source[source.Length - 1] == source[0]))
					source = source.Substring(1, source.Length - 2);
			}
			else if (token == "/")
				section++;
			else if (token == "fill")
				outImage.Fill = true;
			else if ((token == "stretch") || (token == "repeat") || (token == "round") || (token == "space"))
			{
				if (repeatCount < 2)
					repeats[repeatCount++] = (token == "stretch") ? .Stretch : ((token == "round") ? .Round : .Repeat);
			}
			else if ((section == 0) && (slices < 4))
			{
				let percent = (token.Length > 1) && (token[token.Length - 1] == '%');
				let n = ParseLength(percent ? token.Substring(0, token.Length - 1) : token);
				if (n.HasValue)
				{
					sliceIsPercent[slices] = percent;
					slice[slices++] = n.Value;
				}
			}
			else if ((section == 1) && (widths < 4))
			{
				bool plain = token.Length != 0; // a bare number (ParseLength would read "6px" as 6 too)
				for (let c in token)
					plain = plain && (ParseUtil.IsDigit(c) || (c == '.') || (c == '-') || (c == '+'));
				let n = plain ? ParseLength(token) : null;
				if (n.HasValue)
					width[widths] = -2.0f - n.Value; // a multiple of the border's, settled below
				else
				{
					let l = ParseLengthValue(token);
					if (l.HasValue)
						width[widths] = ResolveLengthValue(l.Value, lengths, 0.0f);
				}
				widths++;
			}
		}
		if ((source.Length == 0) || (resources == null))
			return;
		float iw = 0.0f;
		float ih = 0.0f;
		if (IsSvgSource(source)) // by its name or written inline: sliced in its own units
		{
			outImage.Svg = resources.Svg(source);
			if ((outImage.Svg == null) || (outImage.Svg.Width <= 0.0f) || (outImage.Svg.Height <= 0.0f))
			{
				outImage.Svg = null; // a picture of no size has nothing to slice
				return;
			}
			iw = outImage.Svg.Width;
			ih = outImage.Svg.Height;
		}
		else
		{
			let path = ImagePath(source, let region);
			outImage.Image = resources.LoadImage(path);
			if (outImage.Image == null)
				return;
			outImage.Source = region;
			iw = (region.Width > 0.0f) ? region.Width : (float)outImage.Image.Width;
			ih = (region.Width > 0.0f) ? region.Height : (float)outImage.Image.Height;
		}
		if (slices == 0)
		{
			slices = 1;
			slice[0] = 100.0f;
			sliceIsPercent[0] = true; // CSS's initial slice: 100%
		}
		Spread(ref slice, slices);
		Spread(ref sliceIsPercent, slices);
		for (int i = 0; i < 4; i++)
			outImage.Slice[i] = sliceIsPercent[i] ? slice[i] * (((i % 2) == 0) ? ih : iw) * 0.01f : slice[i];
		if (widths > 0)
		{
			Spread(ref width, widths);
			for (int i = 0; i < 4; i++)
				outImage.Width[i] = (width[i] <= -2.0f) ? (-2.0f - width[i]) * borderOf[i] : width[i];
		}
		outImage.RepeatX = repeats[0];
		outImage.RepeatY = (repeatCount > 1) ? repeats[1] : repeats[0];
	}

	// One axis of a layer's size or position: a length, a percentage, or (`allowAuto`) auto.
	public static LayerLength? ParseLayerLength(StringView t, LengthContext lengths, bool allowAuto)
	{
		if (t == "auto")
			return allowAuto ? (LayerLength?)LayerLength(0.0f, 0.0f, true) : null;
		let l = ParseLengthValue(t);
		if (!l.HasValue)
			return null;
		return LayerLength(ResolveLengthValue(l.Value, lengths, 0.0f), l.Value.PercentPart, false);
	}

	// background-size for one layer: cover, contain, or one or two of a length, a percentage (of
	// the box) and auto (one given: the height auto).
	public static void ParseLayerSize(StringView t, LengthContext lengths, BoxLayer outLayer)
	{
		if ((t == "cover") || (t == "contain"))
		{
			outLayer.Size = (t == "cover") ? .Cover : .Contain;
			return;
		}
		let parts = scope List<StringView>();
		SplitTopLevel(t, ' ', parts);
		if (parts.IsEmpty || (parts.Count > 2))
			return;
		let w = ParseLayerLength(parts[0], lengths, true);
		let h = (parts.Count > 1) ? ParseLayerLength(parts[1], lengths, true) : (LayerLength?)LayerLength(0.0f, 0.0f, true);
		if (!w.HasValue || !h.HasValue)
			return;
		outLayer.Size = (w.Value.Auto && h.Value.Auto) ? .Auto : .Lengths;
		outLayer.Width = w.Value;
		outLayer.Height = h.Value;
	}

	// background-position for one layer: one or two of left, center, right, top, bottom, a length
	// and a percentage (of the room left over); one given: the other centred.
	public static void ParseLayerPosition(StringView t, LengthContext lengths, BoxLayer outLayer)
	{
		let parts = scope List<StringView>();
		SplitTopLevel(t, ' ', parts);
		if (parts.IsEmpty || (parts.Count > 2))
			return;
		var x = LayerLength(0.0f, 50.0f, false);
		var y = LayerLength(0.0f, 50.0f, false);
		bool xSet = false;
		for (int i = 0; i < parts.Count; i++)
		{
			let p = parts[i];
			if ((p == "left") || (p == "right"))
			{
				x = LayerLength(0.0f, (p == "left") ? 0.0f : 100.0f, false);
				xSet = true;
			}
			else if ((p == "top") || (p == "bottom"))
				y = LayerLength(0.0f, (p == "top") ? 0.0f : 100.0f, false);
			else if (p == "center")
				continue;
			else
			{
				let l = ParseLayerLength(p, lengths, false);
				if (!l.HasValue)
					return;
				if ((i == 0) && !xSet)
				{
					x = l.Value;
					xSet = true;
				}
				else
					y = l.Value;
			}
		}
		outLayer.X = x;
		outLayer.Y = y;
	}

	/// The node's box from the sheet's box properties, in pixels, into `nodeBox` (a new one).
	public static void BuildBox(UINode node, ResolvedStyle style, IResourceProvider resources, LengthContext lengths, NodeBox nodeBox)
	{
		let background = style.Value("background-color");
		if (background != null)
			nodeBox.BackgroundColor = background.ColorValue;
		let layers = style.Value("background-image");
		if (layers != null)
		{
			// background-size and background-position: a comma list, one per layer, the last
			// repeated for layers past it (CSS's rule).
			let sizes = scope List<StringView>();
			SplitTopLevel(style.Get("background-size"), ',', sizes);
			let positions = scope List<StringView>();
			SplitTopLevel(style.Get("background-position"), ',', positions);
			int index = 0;
			for (let layer in layers.Layers)
			{
				let at = index++;
				if (layer.Kind == .Image)
				{
					let outLayer = new BoxLayer();
					outLayer.IsImage = true;
					// An SVG by its name or written inline: paths, drawn at the size it fills.
					StringView path = layer.Image;
					let svg = IsSvgSource(path);
					if ((resources != null) && svg)
						outLayer.Svg = resources.Svg(path);
					else if (resources != null)
					{
						let imagePath = ImagePath(path, let region); // a sprite's region too
						outLayer.Source = region;
						outLayer.Image = resources.LoadImage(imagePath);
					}
					if ((outLayer.Image == null) && (outLayer.Svg == null))
					{
						delete outLayer;
						continue; // not loaded (no provider, or no such image)
					}
					if (!sizes.IsEmpty)
						ParseLayerSize(ParseUtil.Trim(sizes[Math.Min(at, sizes.Count - 1)]), lengths, outLayer);
					if (!positions.IsEmpty)
						ParseLayerPosition(ParseUtil.Trim(positions[Math.Min(at, positions.Count - 1)]), lengths, outLayer);
					nodeBox.Layers.Add(outLayer);
				}
				else if (layer.Kind == .Gradient)
				{
					let outLayer = new BoxLayer();
					ToBoxGradient(layer.Gradient, outLayer.Gradient);
					nodeBox.Layers.Add(outLayer);
				}
				// A colour layer above the bottom is not CSS: skipped.
			}
		}
		// A border per side: its style none or hidden draws nothing, whatever its width.
		void Side(StringView sideName, ref float width, ref Color color, ref BorderLine line)
		{
			let widthName = scope String("border-")..Append(sideName)..Append("-width");
			let styleName = scope String("border-")..Append(sideName)..Append("-style");
			let colorName = scope String("border-")..Append(sideName)..Append("-color");
			let styleValue = style.Value(styleName);
			StringView lineStyle = (styleValue != null) ? (StringView)styleValue.Keyword : "none";
			let drawn = (lineStyle != "none") && (lineStyle != "hidden");
			width = drawn ? Math.Max(0.0f, PixelsOf(style.Value(widthName), lengths, 0.0f, 3.0f)) : 0.0f;
			line = (lineStyle == "dashed") ? .Dashed : ((lineStyle == "dotted") ? .Dotted : .Solid); // double, groove and the rest: solid
			let c = style.Value(colorName);
			color = (c != null) ? c.ColorValue : Color(0.0f, 0.0f, 0.0f, 1.0f);
		}
		Side("top", ref nodeBox.BorderWidths.Top, ref nodeBox.BorderColors.Top, ref nodeBox.BorderLines[0]);
		Side("right", ref nodeBox.BorderWidths.Right, ref nodeBox.BorderColors.Right, ref nodeBox.BorderLines[1]);
		Side("bottom", ref nodeBox.BorderWidths.Bottom, ref nodeBox.BorderColors.Bottom, ref nodeBox.BorderLines[2]);
		Side("left", ref nodeBox.BorderWidths.Left, ref nodeBox.BorderColors.Left, ref nodeBox.BorderLines[3]);
		// A border image over the border's widths.
		let skin = style.Get("border-image");
		if ((skin.Length != 0) && (skin != "none"))
			ParseBorderImage(skin, resources, lengths, nodeBox.BorderWidths, ref nodeBox.Skin);
		// Radii: a percentage of the box's smaller side.
		let size = node.Size;
		let percentBase = Math.Min(size.X, size.Y);
		nodeBox.Radii = CornerRadii(PixelsOf(style.Value("border-top-left-radius"), lengths, percentBase, 0.0f),
			PixelsOf(style.Value("border-top-right-radius"), lengths, percentBase, 0.0f),
			PixelsOf(style.Value("border-bottom-right-radius"), lengths, percentBase, 0.0f),
			PixelsOf(style.Value("border-bottom-left-radius"), lengths, percentBase, 0.0f));
		let shadows = style.Value("box-shadow");
		if (shadows != null)
		{
			for (let s in shadows.Shadows)
			{
				var shadow = BoxShadow();
				shadow.Offset = .(ResolveLengthValue(s.OffsetX, lengths), ResolveLengthValue(s.OffsetY, lengths));
				shadow.Blur = ResolveLengthValue(s.Blur, lengths);
				shadow.Spread = ResolveLengthValue(s.Spread, lengths);
				shadow.ShadowColor = s.ShadowColor;
				shadow.Inset = s.Inset;
				nodeBox.Shadows.Add(shadow);
			}
		}
		// Effects: blurs in sequence add as variances (a blur of a blur is one of the root of the
		// squares' sum).
		float BlurOf(StringView name)
		{
			float variance = 0.0f;
			let filters = style.Value(name);
			if (filters != null)
			{
				for (let f in filters.Filters)
				{
					if (f.Kind == .Blur)
					{
						let sigma = ResolveLengthValue(f.Amount, lengths);
						variance += sigma * sigma;
					}
				}
			}
			return Math.Sqrt(variance);
		}
		nodeBox.FilterBlur = BlurOf("filter");
		nodeBox.BackdropBlur = BlurOf("backdrop-filter");
		let blend = style.Value("mix-blend-mode");
		if (blend != null)
			nodeBox.BlendMode = BlendModeOf(blend.Keyword);
		// Text effects: each set (none included) replaces the inherited one.
		let textShadow = style.Value("text-shadow");
		if (textShadow != null)
		{
			nodeBox.TextEffectsSet |= NodeBox.cTextShadow;
			if (!textShadow.Shadows.IsEmpty)
			{
				let s = textShadow.Shadows[0];
				nodeBox.TextEffects.ShadowOffset = .(ResolveLengthValue(s.OffsetX, lengths), ResolveLengthValue(s.OffsetY, lengths));
				nodeBox.TextEffects.ShadowBlur = ResolveLengthValue(s.Blur, lengths);
				nodeBox.TextEffects.ShadowColor = s.ShadowColor;
			}
		}
		let textOutline = style.Value("text-outline");
		if (textOutline != null)
		{
			nodeBox.TextEffectsSet |= NodeBox.cTextOutline;
			if (!textOutline.Shadows.IsEmpty)
			{
				nodeBox.TextEffects.OutlineWidth = ResolveLengthValue(textOutline.Shadows[0].Spread, lengths);
				nodeBox.TextEffects.OutlineColor = textOutline.Shadows[0].ShadowColor;
			}
		}
		let textGlow = style.Value("text-glow");
		if (textGlow != null)
		{
			nodeBox.TextEffectsSet |= NodeBox.cTextGlow;
			if (!textGlow.Shadows.IsEmpty)
			{
				nodeBox.TextEffects.GlowRadius = ResolveLengthValue(textGlow.Shadows[0].Blur, lengths);
				nodeBox.TextEffects.GlowColor = textGlow.Shadows[0].ShadowColor;
			}
		}
	}

	/// `text` as a value of the property's type (empty when it does not convert). The caller
	/// disposes it.
	public static System.Variant ParseForProperty(GuiPropertyInfo property, StringView value, LengthContext lengths)
	{
		let text = ParseUtil.Trim(value);
		let type = property.ValueType;
		if (type == typeof(float))
		{
			let px = ResolveLength(text, lengths);
			return px.HasValue ? System.Variant.Create(px.Value) : default;
		}
		if (type == typeof(Color))
		{
			let c = ParseColor(text);
			return c.HasValue ? System.Variant.Create(c.Value) : default;
		}
		if (type == typeof(bool))
		{
			let b = ParseBool(text);
			return b.HasValue ? System.Variant.Create(b.Value) : default;
		}
		if ((type == typeof(StringView)) || (type == typeof(String)))
			return TextVariant(text);
		// Any other type a value converts to (a column count, a maximum length).
		var asText = TextVariant(text);
		defer asText.Dispose();
		return ConvertVariant(asText, type);
	}

	/// `value` as text, appended to `outText` (nothing for a value with none: a colour).
	public static void ValueText(System.Variant value, String outText)
	{
		var text = ConvertVariant(value, typeof(String));
		defer text.Dispose();
		outText.Append(TextOf(text));
	}

	/// The property's value on `node` now, as text, into `outText` (cleared first).
	public static void CurrentText(GuiPropertyInfo property, Object node, String outText)
	{
		outText.Clear();
		var current = property.Get(node);
		defer current.Dispose();
		ValueText(current, outText);
	}

	/// The reflected properties a sheet sets by their CSS names (a library's widget's own), each as
	/// a setter-applied property is: the sheet's while it sets it, the node's own value back when
	/// it stops, and code's once code changes it (seen as a value other than the one the sheet last
	/// wrote).
	public static void ApplyReflected(UINode node, ResolvedStyle style, LengthContext lengths)
	{
		let records = node.StyledProperties;
		let typeInfo = node.GuiType;
		let current = scope String();
		let next = scope String();
		for (let p in style.Properties)
		{
			if (ResolvedStyle.IsCustomProperty(p.Name) || (FindStyleProperty(p.Name) != null))
				continue;
			let property = typeInfo.FindCss(p.Name);
			if (property == null)
				continue;
			UINode.StyledProperty record = null;
			for (let r in records)
			{
				if (r.Name == p.Name)
					record = r;
			}
			if (record == null)
			{
				record = new UINode.StyledProperty();
				record.Name.Set(p.Name);
				record.Own = property.Get(node);
				records.Add(record);
			}
			if (record.Code)
				continue;
			CurrentText(property, node, current);
			if ((record.Written.Length != 0) && (current != record.Written))
			{
				record.Code = true; // code set it since: code's now
				continue;
			}
			var value = ParseForProperty(property, p.Value, lengths);
			defer value.Dispose();
			if (!value.HasValue)
				continue;
			// A value it holds already is not written again: a restyle would otherwise run a setter
			// each time (a list rebuilding its rows, which restyled it again, every frame). Compared
			// as text, so a value with none (a colour) is written as before.
			next.Clear();
			ValueText(value, next);
			if ((current.Length != 0) && (next == current))
			{
				record.Written.Set(current);
				continue;
			}
			property.Set(node, value);
			CurrentText(property, node, record.Written);
		}
		// What the sheet set and sets no more: back to the node's own value.
		for (let r in records)
		{
			if (r.Code || (r.Written.Length == 0) || style.Has(r.Name))
				continue;
			let property = typeInfo.FindCss(r.Name);
			if (property == null)
				continue;
			CurrentText(property, node, current);
			if (current != r.Written)
				r.Code = true;
			else
				property.Set(node, r.Own);
			r.Written.Clear();
		}
	}
}
