using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// View's box model: the effective layout style, chrome resolution, measure and arrange.
extension View
{
	/// The inline placement intent, as SetLayout stored it.
	private LayoutStyle mLayout = .();
	/// The inline intent with the cascade filled in behind it.
	private LayoutStyle mEffectiveLayout = .();
	private bool mStyledOverflowHidden = false;

	/// This view's EFFECTIVE placement: every declared inline field, with the undeclared ones
	/// filled from the cascade. Read by whichever container holds the view.
	public LayoutStyle Layout => mEffectiveLayout;

	/// The inline intent ALONE, with undeclared fields reading as their defaults. Survives
	/// reparenting unchanged, which is the point of keeping it separate.
	public LayoutStyle DeclaredLayout => mLayout;

	/// Replaces the inline placement intent.
	public void SetLayout(LayoutStyle layout)
	{
		if (mLayout == layout)
			return;
		mLayout = layout;
		RefreshEffectiveLayout();
		Invalidate();
	}

	/// In the parent's flow: neither Gone nor absolutely positioned.
	///
	/// Containers lay out only in-flow children; the base ViewGroup places the absolute ones
	/// against its content box afterwards.
	public static bool IsInFlow(View child) =>
		(child.Visibility != .Gone) && (child.Layout.Position.Value != .Absolute);

	/// Clips children to the border box, by the ClipsContent field OR `overflow: hidden`.
	public bool EffectiveClipsContent => ClipsContent || mStyledOverflowHidden;

	/// MeasuredSize plus this view's margins: what a parent aggregates and places.
	public Float2 MarginBoxSize
	{
		get
		{
			let margin = mEffectiveLayout.Margin.Value;
			return .(MeasuredSize.X + margin.TotalHorizontal,
				MeasuredSize.Y + margin.TotalVertical);
		}
	}

	// ---- Effective layout ----------------------------------------------------------------------

	/// Whether a rule actually sets a property, so only those pay for keyword and variable
	/// resolution. This runs at the top of EVERY measure.
	private bool StyleSets(StyleProperty property) =>
		EnsureStyleCache().Winners[(int)property] != null;

	/// Recomputes the effective LayoutStyle from the inline value and the cascade.
	///
	/// The effective copy marks sheet filled fields DECLARED too: a consumer asks whether
	/// Right is set and must not have to care where the value came from. The inline mLayout
	/// keeps its own flags.
	public void RefreshEffectiveLayout()
	{
		var e = mLayout;
		mStyledOverflowHidden = false;

		RefreshSizeSpec(.Width, ref e.Width);
		RefreshSizeSpec(.Height, ref e.Height);

		if (!e.Margin.IsDeclared && StyleSets(.Margin))
		{
			let margin = ResolveStyle(.Margin).AsThickness;
			if (margin != null)
				e.Margin = margin.Value;
		}

		RefreshUnit(.MinWidth, ref e.MinWidth);
		RefreshUnit(.MinHeight, ref e.MinHeight);
		RefreshUnit(.MaxWidth, ref e.MaxWidth);
		RefreshUnit(.MaxHeight, ref e.MaxHeight);

		RefreshNumber(.Top, ref e.Top);
		RefreshNumber(.Right, ref e.Right);
		RefreshNumber(.Bottom, ref e.Bottom);
		RefreshNumber(.Left, ref e.Left);
		RefreshNumber(.FlexGrow, ref e.FlexGrow);
		RefreshNumber(.FlexShrink, ref e.FlexShrink);
		RefreshUnit(.FlexBasis, ref e.FlexBasis);

		if (!e.ZIndex.IsDeclared && StyleSets(.ZIndex))
			e.ZIndex = (int32)ResolveStyleFloat(.ZIndex, 0.0f);

		if (!e.Position.IsDeclared && StyleSets(.Position))
		{
			let word = scope String();
			ResolveStyleString(.Position, word);
			e.Position = (word == "absolute") ? Position.Absolute : Position.Static;
		}

		if ((e.AlignSelf == null) && StyleSets(.AlignSelf))
		{
			let word = scope String();
			ResolveStyleString(.AlignSelf, word);
			switch (word)
			{
			case "start", "flex-start": e.AlignSelf = .Start;
			case "end", "flex-end": e.AlignSelf = .End;
			case "center": e.AlignSelf = .Center;
			case "stretch": e.AlignSelf = .Stretch;
			case "baseline": e.AlignSelf = .Baseline;
			default:
			}
		}

		if (StyleSets(.Overflow))
		{
			let word = scope String();
			ResolveStyleString(.Overflow, word);
			mStyledOverflowHidden = word == "hidden";
		}

		mEffectiveLayout = e;
	}

	/// A size spec from the cascade: the `match` and `wrap` keywords, or a length.
	private void RefreshSizeSpec(StyleProperty property, ref Declared<SizeSpec> field)
	{
		if (field.IsDeclared || !StyleSets(property))
			return;

		let value = ResolveStyle(property);

		let word = value.AsString;
		if (word != null)
		{
			switch (word.Value)
			{
			case "match", "match-parent", "fill", "stretch":
				field = SizeSpec.Match();
			case "wrap", "wrap-content", "auto":
				field = SizeSpec.Wrap();
			default:
			}
			return;
		}

		let number = value.AsFloat;
		if (number != null)
		{
			field = SizeSpec.Fixed(Unit.Dp(number.Value));
			return;
		}

		let length = value.AsLength;
		if (length != null)
			field = SizeSpec.Fixed(length.Value);
	}

	private void RefreshUnit(StyleProperty property, ref Declared<Unit> field)
	{
		if (field.IsDeclared || !StyleSets(property))
			return;

		let value = ResolveStyle(property);

		let number = value.AsFloat;
		if (number != null)
		{
			field = Unit.Dp(number.Value);
			return;
		}

		let length = value.AsLength;
		if (length != null)
			field = length.Value;
	}

	/// An inset or flex factor. Absolute lengths resolve here; a PERCENT inset has no
	/// reference box at refresh time and contributes nought.
	private void RefreshNumber(StyleProperty property, ref Declared<float> field)
	{
		if (field.IsDeclared || !StyleSets(property))
			return;
		field = ResolveStyleLength(property, 0.0f, field.Value);
	}

	// ---- Chrome --------------------------------------------------------------------------------

	/// Resolves this view's chrome ONCE. The single source every measure, arrange and content
	/// bounds consumer converges on.
	public BoxMetrics ResolveBoxMetrics()
	{
		BoxMetrics metrics = .();
		metrics.Margin = mEffectiveLayout.Margin.Value;

		// A themed padding wins OUTRIGHT over the control's fallback rather than merging with
		// it; the fallback is what a control states when the theme says nothing.
		let styled = ResolveStyle(.Padding).AsThickness;
		let stylePadding = (styled != null) ? styled.Value : DefaultStylePadding();

		Thickness drawablePadding = .();
		let background = ResolveStyleDrawable(.Background);
		if (background != null)
			drawablePadding = background.DrawablePadding;

		let fieldPadding = OwnPaddingField();

		metrics.Padding = .(
			Max(Max(stylePadding.Left, drawablePadding.Left), fieldPadding.Left),
			Max(Max(stylePadding.Top, drawablePadding.Top), fieldPadding.Top),
			Max(Max(stylePadding.Right, drawablePadding.Right), fieldPadding.Right),
			Max(Max(stylePadding.Bottom, drawablePadding.Bottom), fieldPadding.Bottom));

		let borderWidth = ResolveStyleFloat(.BorderWidth, 0.0f);
		metrics.Border = .(borderWidth, borderWidth, borderWidth, borderWidth);
		return metrics;
	}

	// ---- Measure -------------------------------------------------------------------------------

	/// Measures this view.
	///
	/// The BASE owns two things uniformly: the MARGIN, deflated from the incoming constraints
	/// so no parent has to, and the FIXED size spec, resolved here once in logical units.
	/// Match and Wrap stay parent negotiated looseness, since resolving Match here would
	/// defeat a container's deliberate cross axis demotion.
	public void Measure(BoxConstraints constraints)
	{
		// This view's effective layout, and its children's: a container reads child.Layout
		// before measuring each child.
		RefreshEffectiveLayout();
		RefreshChildEffectiveLayouts();

		let metrics = ResolveBoxMetrics();
		// Not named `box`: that is a Beef keyword.
		var measureBox = constraints.Deflate(metrics.Margin);

		let layout = mEffectiveLayout;
		let widthSpec = layout.Width.Value;
		let heightSpec = layout.Height.Value;
		let clampsWidth = (layout.MinWidth.Value != Unit()) || (layout.MaxWidth.Value != Unit());
		let clampsHeight = (layout.MinHeight.Value != Unit()) || (layout.MaxHeight.Value != Unit());

		if ((widthSpec.kind == .Fixed) || (heightSpec.kind == .Fixed) || clampsWidth
			|| clampsHeight)
		{
			let root = Root();
			let dpiScale = (root != null) ? Max(root.DpiScale, 0.01f) : 1.0f;

			// A percentage resolves against the CONTAINING box on the same axis, being the
			// incoming constraint's maximum after margin and nought when unbounded; em
			// against the computed font size. Both are computed only when something needs
			// them, since resolving the font size is not free.
			let relative = widthSpec.fixedSize.IsRelative || heightSpec.fixedSize.IsRelative
				|| layout.MinWidth.Value.IsRelative || layout.MaxWidth.Value.IsRelative
				|| layout.MinHeight.Value.IsRelative || layout.MaxHeight.Value.IsRelative;
			let fontSize = relative ? ResolveStyleLength(.FontSize, 0.0f, 16.0f) : 0.0f;
			let referenceWidth = BoxConstraints.IsBounded(measureBox.MaxWidth) ? measureBox.MaxWidth : 0.0f;
			let referenceHeight = BoxConstraints.IsBounded(measureBox.MaxHeight) ? measureBox.MaxHeight : 0.0f;

			if (widthSpec.kind == .Fixed)
			{
				let width = Max(0.0f, widthSpec.ResolveFixed(dpiScale, referenceWidth, fontSize));
				measureBox.MinWidth = width;
				measureBox.MaxWidth = width;
			}
			if (heightSpec.kind == .Fixed)
			{
				let height = Max(0.0f,
					heightSpec.ResolveFixed(dpiScale, referenceHeight, fontSize));
				measureBox.MinHeight = height;
				measureBox.MaxHeight = height;
			}

			// The clamps narrow the constraint band, a Fixed size included. Max wins over min
			// where they cross, as in CSS.
			if (clampsWidth)
			{
				if (layout.MinWidth.Value != Unit())
				{
					let minWidth = Max(0.0f,
						layout.MinWidth.Value.Resolve(dpiScale, referenceWidth, fontSize));
					measureBox.MinWidth = Max(measureBox.MinWidth, minWidth);
					measureBox.MaxWidth = Max(measureBox.MaxWidth, minWidth);
				}
				if (layout.MaxWidth.Value != Unit())
				{
					let maxWidth = Max(0.0f,
						layout.MaxWidth.Value.Resolve(dpiScale, referenceWidth, fontSize));
					measureBox.MaxWidth = Min(measureBox.MaxWidth, maxWidth);
					measureBox.MinWidth = Min(measureBox.MinWidth, maxWidth);
				}
			}
			if (clampsHeight)
			{
				if (layout.MinHeight.Value != Unit())
				{
					let minHeight = Max(0.0f,
						layout.MinHeight.Value.Resolve(dpiScale, referenceHeight, fontSize));
					measureBox.MinHeight = Max(measureBox.MinHeight, minHeight);
					measureBox.MaxHeight = Max(measureBox.MaxHeight, minHeight);
				}
				if (layout.MaxHeight.Value != Unit())
				{
					let maxHeight = Max(0.0f,
						layout.MaxHeight.Value.Resolve(dpiScale, referenceHeight, fontSize));
					measureBox.MaxHeight = Min(measureBox.MaxHeight, maxHeight);
					measureBox.MinHeight = Min(measureBox.MinHeight, maxHeight);
				}
			}
		}

		let chrome = metrics.Chrome;
		let content = OnMeasureContent(measureBox.Deflate(chrome));
		if (content.X >= 0.0f)
		{
			MeasuredSize = .(measureBox.ConstrainWidth(content.X + chrome.TotalHorizontal),
				measureBox.ConstrainHeight(content.Y + chrome.TotalVertical));
		}
		else
		{
			// The control handles its own chrome.
			OnMeasure(measureBox);
		}

		// An absolute child never feeds MeasuredSize; it is measured against the content box
		// this view has just settled on.
		MeasureAbsoluteChildren(Max(0.0f, MeasuredSize.X - chrome.TotalHorizontal),
			Max(0.0f, MeasuredSize.Y - chrome.TotalVertical));
	}

	// ---- Arrange -------------------------------------------------------------------------------

	/// Arranges this view, the rectangle given being the MARGIN box.
	///
	/// The base insets by margin once, so every container honours margins identically without
	/// repeating the arithmetic.
	///
	/// The border box is then ROUNDED to the device grid, EDGE by edge: x and x plus width
	/// each snap and the width is the difference between the snapped edges. Rounding the
	/// width directly would leave gaps between adjacent boxes. Rounding on the local grid
	/// composes to the global one because every ancestor rounds too.
	public void Layout(float x, float y, float width, float height)
	{
		let margin = mEffectiveLayout.Margin.Value;
		var left = x + margin.Left;
		var top = y + margin.Top;
		var boxWidth = Max(0.0f, width - margin.TotalHorizontal);
		var boxHeight = Max(0.0f, height - margin.TotalVertical);

		let root = Root();
		let dpi = (root != null) ? Max(root.DpiScale, 0.01f) : 1.0f;

		let right = Round((left + boxWidth) * dpi) / dpi;
		let bottom = Round((top + boxHeight) * dpi) / dpi;
		left = Round(left * dpi) / dpi;
		top = Round(top * dpi) / dpi;
		boxWidth = Max(0.0f, right - left);
		boxHeight = Max(0.0f, bottom - top);

		Bounds = .(left, top, boxWidth, boxHeight);
		OnLayout(left, top, boxWidth, boxHeight);
		LayoutAbsoluteChildren();
	}

	// ---- Seams ---------------------------------------------------------------------------------

	/// The absolute child hooks, which ViewGroup implements; a leaf has no children.
	protected virtual void MeasureAbsoluteChildren(float contentWidth, float contentHeight) {}
	protected virtual void LayoutAbsoluteChildren() {}

	/// Refreshes every child's effective layout, since a container reads child.Layout before
	/// measuring. ViewGroup implements it.
	protected virtual void RefreshChildEffectiveLayouts() {}

	/// The container field padding channel that ResolveBoxMetrics merges. ViewGroup overrides
	/// it with its Padding field; a leaf has none.
	protected virtual Thickness OwnPaddingField() => .();

	/// A control's FALLBACK padding when no style sets one, stated once per control.
	protected virtual Thickness DefaultStylePadding() => .();

	/// The CONTENT box measure seam: margin, spec, padding and border are already deflated,
	/// and the answer is the content size, which the base re-inflates and clamps.
	///
	/// A negative answer, which is the default, falls back to OnMeasure. A control that
	/// implements this carries no padding arithmetic of its own.
	protected virtual Float2 OnMeasureContent(BoxConstraints contentConstraints) =>
		.(-1.0f, -1.0f);

	/// The older measure seam, where the control handles its own chrome. Receives the post
	/// margin, post spec box.
	protected virtual void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(0.0f), constraints.ConstrainHeight(0.0f));
	}

	protected virtual void OnLayout(float left, float top, float width, float height) {}
}
