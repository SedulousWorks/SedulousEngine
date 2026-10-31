using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A drop-down selector: the chosen item and an arrow, opening a list below.
///
/// The list is a dedicated ComboBoxDropdown through the PopupLayer rather than a ContextMenu,
/// because it has to match the box's width and show which item is currently chosen.
class ComboBox : View, IPopupOwner
{
	/// The room set aside on the right for the arrow.
	private const float ArrowAreaWidth = 24.0f;
	private const float TextPadX = 8.0f;
	private const float TextPadY = 6.0f;

	public Event<delegate void(ComboBox, int32)> OnSelectionChanged ~ _.Dispose();

	private List<String> mItems = new .() ~ DeleteContainerAndItems!(_);
	private int32 mSelectedIndex = -1;
	private bool mIsOpen = false;

	/// The widest item, cached. Measure runs every frame, and shaping every item per pass is
	/// O(items) of text work for a number that hardly ever changes.
	///
	/// Keyed on VALUES, never on the font pointer: a freed font's address can come back as a
	/// different font, and a pointer key would then match the wrong thing.
	private uint32 mItemsGeneration = 0;
	private uint32 mMeasuredGeneration = uint32.MaxValue;
	private float mMeasuredFontSize = -1.0f;
	private String mMeasuredFamily = new .() ~ delete _;
	private float mCachedMaxItemWidth = 0.0f;

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
		// The arrows change the selection, so focus must not spend them on moving away.
		WantsArrowKeys = true;
		Cursor = .Hand;
	}

	// ---- Items ------------------------------------------------------------------------------

	public int32 ItemCount => (int32)mItems.Count;
	public bool IsOpen => mIsOpen;

	/// Borrowed.
	public StringView ItemAt(int32 index) => mItems[index];

	public int32 AddItem(StringView text)
	{
		let index = (int32)mItems.Count;
		mItems.Add(new String(text));
		mItemsGeneration++;
		Invalidate();
		return index;
	}

	public void RemoveItem(int32 index)
	{
		if ((index < 0) || (index >= mItems.Count))
			return;

		delete mItems[index];
		mItems.RemoveAt(index);
		mItemsGeneration++;

		// Pulled back into range WITHOUT reporting: removing an item is not the user choosing
		// a different one.
		if (mSelectedIndex >= mItems.Count)
			mSelectedIndex = (int32)mItems.Count - 1;

		Invalidate();
	}

	public void ClearItems()
	{
		ClearAndDeleteItems!(mItems);
		mItemsGeneration++;
		mSelectedIndex = -1;
		Invalidate();
	}

	// ---- Selection --------------------------------------------------------------------------

	public int32 SelectedIndex => mSelectedIndex;

	/// Minus one means nothing chosen, which is the empty state.
	public void SetSelectedIndex(int32 value)
	{
		let clamped = Clamp(value, -1, (int32)mItems.Count - 1);
		if (mSelectedIndex == clamped)
			return;

		mSelectedIndex = clamped;
		Invalidate();
		OnSelectionChanged(this, clamped);
	}

	public StringView SelectedText =>
		((mSelectedIndex >= 0) && (mSelectedIndex < mItems.Count)) ? mItems[mSelectedIndex] : "";

	// ---- Opening ----------------------------------------------------------------------------

	/// Opens the list below the box, flipping it above when there is no room underneath.
	public void OpenDropdown()
	{
		if (mIsOpen || mItems.IsEmpty || (Context == null))
			return;

		let root = Context.ActiveInputRoot;
		if (root == null)
			return;

		let dropdown = new ComboBoxDropdown(this);
		let logical = root.LogicalSize;
		dropdown.Measure(BoxConstraints.Loose(logical.X, logical.Y));

		// A small gap, so the list sits just below the box's border rather than over it.
		let gap = 2.0f;
		let anchor = LocalToScreen(.(0, Height));
		var y = anchor.Y + gap;
		if (y + dropdown.MeasuredSize.Y > logical.Y)
			y = anchor.Y - Height - gap - dropdown.MeasuredSize.Y;

		// ShowPopup CONSUMES the reference, and closing releases it, so the layer is the only
		// owner from here.
		root.GetPopupLayer().ShowPopup(dropdown, this, anchor.X, y, true, false, true);

		mIsOpen = true;
		Invalidate();
	}

	/// Marks the box closed. The popup itself is taken down by whoever is closing it.
	public void CloseDropdown()
	{
		mIsOpen = false;
		Invalidate();
	}

	// ---- IPopupOwner ------------------------------------------------------------------------

	/// The list closing for ANY reason, a click outside included, puts the box back.
	public void OnPopupClosed(View popup)
	{
		mIsOpen = false;
		Invalidate();
	}

	public View OwnerView => this;

	// ---- Input ------------------------------------------------------------------------------

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled() || (e.Button != .Left))
			return;

		if (mIsOpen)
			CloseDropdown();
		else
			OpenDropdown();

		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled())
			return;

		switch (e.Key)
		{
		case .Space, .Return:
			if (!mIsOpen)
				OpenDropdown();
			e.Handled = true;
		case .Up:
			// The arrows step the selection WITHOUT opening, so a closed box can be cycled
			// through in place.
			if (mSelectedIndex > 0)
				SetSelectedIndex(mSelectedIndex - 1);
			e.Handled = true;
		case .Down:
			if (mSelectedIndex < mItems.Count - 1)
				SetSelectedIndex(mSelectedIndex + 1);
			e.Handled = true;
		case .Escape:
			if (mIsOpen)
			{
				CloseDropdown();
				e.Handled = true;
			}
		default:
		}
	}

	public override void OnActivate()
	{
		if (IsEffectivelyEnabled())
			OpenDropdown();
	}

	// ---- Measure and draw -------------------------------------------------------------------

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = ResolveStyleFloat(.FontSize, 14.0f);
		var maxTextWidth = 0.0f;
		var textHeight = fontSize;

		if ((Context != null) && (Context.FontService != null))
		{
			let family = scope String();
			ResolveStyleFontFamily(family);

			if (let font = Context.FontService.GetFont(family, fontSize))
			{
				textHeight = font.Font.Metrics.LineHeight;
				maxTextWidth = MaxItemWidth(font, family, fontSize);
			}
		}

		// Wide enough for the LONGEST item, so the box does not resize as the choice changes.
		MeasuredSize = .(
			constraints.ConstrainWidth(TextPadX * 2 + maxTextWidth + ArrowAreaWidth),
			constraints.ConstrainHeight(TextPadY * 2 + textHeight));
	}

	private float MaxItemWidth(CachedFont font, StringView family, float fontSize)
	{
		if ((mMeasuredGeneration == mItemsGeneration) && (mMeasuredFontSize == fontSize) &&
			(mMeasuredFamily == family))
			return mCachedMaxItemWidth;

		var widest = 0.0f;
		for (let item in mItems)
			widest = Max(widest, font.Font.MeasureString(item));

		mCachedMaxItemWidth = widest;
		mMeasuredGeneration = mItemsGeneration;
		mMeasuredFontSize = fontSize;
		mMeasuredFamily.Set(family);
		return widest;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let state = GetControlState();

		let background = ResolveStyleDrawable(.Background);
		if (background != null)
		{
			background.Draw(ctx, bounds, state);
		}
		else
		{
			var color = Color(40 / 255.0f, 42 / 255.0f, 52 / 255.0f, 1.0f);
			if (IsHovered())
				color = Palette.ComputeHover(color);

			ctx.VG.FillRect(bounds, color);
		}

		// An OPEN box is ringed, which is what ties it to the list hanging below it.
		if (mIsOpen)
			DrawOpenRing(ctx, bounds, background);

		DrawSelectedText(ctx);
		DrawArrow(ctx, state);
	}

	private void DrawOpenRing(UIDrawContext ctx, Rectangle bounds, Drawable background)
	{
		let accent = ResolveStyleColor(.AccentColor, Color(80 / 255.0f, 160 / 255.0f, 1.0f, 1.0f));

		// The ring follows the background's own corners, so a rounded box does not get a
		// square ring drawn across it.
		if (let rounded = background as RoundedRectDrawable)
		{
			if (!rounded.Radii.IsZero)
				ctx.VG.StrokeRoundedRect(bounds, rounded.Radii, accent, 2.0f);
			else
				ctx.VG.StrokeRect(bounds, accent, 2.0f);

			return;
		}

		let radius = ResolveStyleFloat(.CornerRadius);
		if (radius > 0)
			ctx.VG.StrokeRoundedRect(bounds, radius, accent, 2.0f);
		else
			ctx.VG.StrokeRect(bounds, accent, 2.0f);
	}

	private void DrawSelectedText(UIDrawContext ctx)
	{
		if ((mSelectedIndex < 0) || (mSelectedIndex >= mItems.Count) || (ctx.FontService == null))
			return;

		let family = scope String();
		ResolveStyleFontFamily(family);
		let font = ctx.FontService.GetFont(family, ResolveStyleFloat(.FontSize, 14.0f));
		if (font == null)
			return;

		let color = ResolveStyleColor(.TextColor, Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		ctx.VG.DrawText(mItems[mSelectedIndex], font,
			.(TextPadX, 0, Width - TextPadX * 2 - ArrowAreaWidth, Height), .Left, .Middle, color);
	}

	private void DrawArrow(UIDrawContext ctx, ControlState state)
	{
		let arrowX = Width - ArrowAreaWidth * 0.5f;
		let arrowY = Height * 0.5f;

		if (let arrow = ResolvePartDrawable("arrow", .Background, state))
		{
			arrow.Draw(ctx, .(arrowX - 4.0f, arrowY - 4.0f, 8.0f, 8.0f));
			return;
		}

		let color = ResolvePartColor("arrow", .TextColor, state,
			Color(180 / 255.0f, 185 / 255.0f, 200 / 255.0f, 1.0f));
		let a = 4.0f;

		ctx.VG.BeginPath();
		ctx.VG.MoveTo(arrowX - a, arrowY - a * 0.5f);
		ctx.VG.LineTo(arrowX + a, arrowY - a * 0.5f);
		ctx.VG.LineTo(arrowX, arrowY + a * 0.5f);
		ctx.VG.ClosePath();
		ctx.VG.Fill(color);
	}
}
