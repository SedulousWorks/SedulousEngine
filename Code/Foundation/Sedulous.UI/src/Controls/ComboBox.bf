namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Drop-down selector. Displays the selected item with a dropdown arrow.
/// Opens a ContextMenu as a popup list on click.
public class ComboBox : View, IPopupOwner
{
	private List<String> mItems = new .() ~ { for (let s in _) delete s; delete _; };
	private int mSelectedIndex = -1;
	private bool mIsOpen;

	private Color? mTextColor;
	private float? mFontSize;
	private float mArrowAreaWidth = 24;

	public Event<delegate void(ComboBox, int)> OnSelectionChanged ~ _.Dispose();

	public int SelectedIndex
	{
		get => mSelectedIndex;
		set
		{
			let clamped = Math.Clamp(value, -1, mItems.Count - 1);
			if (mSelectedIndex != clamped)
			{
				mSelectedIndex = clamped;
				InvalidateVisual();
				OnSelectionChanged(this, clamped);
			}
		}
	}

	public StringView SelectedText =>
		(mSelectedIndex >= 0 && mSelectedIndex < mItems.Count) ? mItems[mSelectedIndex] : "";

	public int ItemCount => mItems.Count;
	public bool IsOpen => mIsOpen;

	public Color TextColor
	{
		get => mTextColor ?? Context?.Theme?.GetColor("ComboBox.Text") ?? .(220, 225, 235, 255);
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("ComboBox.FontSize", 14) ?? 14;
		set { mFontSize = value; InvalidateLayout(); }
	}

	public this()
	{
		IsFocusable = true;
		Cursor = .Hand;
	}

	/// Add an item. Returns the item index.
	public int AddItem(StringView text)
	{
		let index = mItems.Count;
		mItems.Add(new String(text));
		InvalidateLayout();
		return index;
	}

	/// Remove an item by index.
	public void RemoveItem(int index)
	{
		if (index < 0 || index >= mItems.Count) return;
		delete mItems[index];
		mItems.RemoveAt(index);
		if (mSelectedIndex >= mItems.Count)
			mSelectedIndex = mItems.Count - 1;
		InvalidateLayout();
	}

	/// Remove all items.
	public void ClearItems()
	{
		for (let s in mItems) delete s;
		mItems.Clear();
		mSelectedIndex = -1;
		InvalidateLayout();
	}

	// === Measurement ===

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let fontSize = FontSize;
		float maxTextW = 0, textH = fontSize;

		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				textH = font.Font.Metrics.LineHeight;
				for (let item in mItems)
				{
					let w = font.Font.MeasureString(item);
					if (w > maxTextW) maxTextW = w;
				}
			}
		}

		let padding = Thickness(8, 6);
		MeasuredSize = .(wSpec.Resolve(padding.TotalHorizontal + maxTextW + mArrowAreaWidth),
						 hSpec.Resolve(padding.TotalVertical + textH));
	}

	// === Drawing ===

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let radius = ctx.Theme?.GetDimension("ComboBox.CornerRadius", 4) ?? 4;

		// Background.
		var bgColor = ctx.Theme?.GetColor("ComboBox.Background") ?? .(40, 42, 52, 255);
		if (IsHovered) bgColor = Palette.ComputeHover(bgColor);
		ctx.VG.FillRoundedRect(bounds, radius, bgColor);

		// Border — accent when open.
		let borderColor = mIsOpen
			? (ctx.Theme?.Palette.PrimaryAccent ?? .(80, 160, 255, 255))
			: (ctx.Theme?.GetColor("ComboBox.Border", .(80, 85, 100, 255)) ?? .(80, 85, 100, 255));
		ctx.VG.StrokeRoundedRect(bounds, radius, borderColor, 1);

		// Selected text.
		if (mSelectedIndex >= 0 && mSelectedIndex < mItems.Count && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let textBounds = RectangleF(8, 0, Width - 16 - mArrowAreaWidth, Height);
				ctx.VG.DrawText(mItems[mSelectedIndex], font, textBounds, .Left, .Middle, TextColor);
			}
		}

		// Dropdown arrow (VG triangle).
		let arrowX = Width - mArrowAreaWidth * 0.5f;
		let arrowY = Height * 0.5f;
		let arrowSize = 4.0f;
		let arrowColor = ctx.Theme?.GetColor("ComboBox.ArrowColor") ?? .(180, 185, 200, 255);
		ctx.VG.BeginPath();
		ctx.VG.MoveTo(arrowX - arrowSize, arrowY - arrowSize * 0.5f);
		ctx.VG.LineTo(arrowX + arrowSize, arrowY - arrowSize * 0.5f);
		ctx.VG.LineTo(arrowX, arrowY + arrowSize * 0.5f);
		ctx.VG.ClosePath();
		ctx.VG.Fill(arrowColor);

		// Focus ring.
		if (IsFocused)
			ctx.DrawFocusRing(bounds, radius);
	}

	// === Input ===

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (!IsEffectivelyEnabled || e.Button != .Left) return;

		if (mIsOpen)
			CloseDropdown();
		else
			OpenDropdown();
		e.Handled = true;
	}

	public override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEffectivelyEnabled) return;

		if (e.Key == .Space || e.Key == .Return)
		{
			if (!mIsOpen) OpenDropdown();
			e.Handled = true;
		}
		else if (e.Key == .Up)
		{
			if (mSelectedIndex > 0) SelectedIndex = mSelectedIndex - 1;
			e.Handled = true;
		}
		else if (e.Key == .Down)
		{
			if (mSelectedIndex < mItems.Count - 1) SelectedIndex = mSelectedIndex + 1;
			e.Handled = true;
		}
		else if (e.Key == .Escape && mIsOpen)
		{
			CloseDropdown();
			e.Handled = true;
		}
	}

	/// Open the dropdown popup.
	public void OpenDropdown()
	{
		if (mIsOpen || mItems.Count == 0 || Context == null) return;

		let menu = new ContextMenu();
		for (int i = 0; i < mItems.Count; i++)
		{
			let capturedIndex = i;
			menu.AddItem(mItems[i], new () => { SelectedIndex = capturedIndex; });
		}

		// Position below this ComboBox.
		float screenX = Bounds.X, screenY = Bounds.Y + Height;
		var v = Parent;
		while (v != null)
		{
			screenX += v.Bounds.X;
			screenY += v.Bounds.Y;
			v = v.Parent;
		}

		let screen = RectangleF(0, 0, Context.Root.ViewportSize.X, Context.Root.ViewportSize.Y);
		menu.Measure(.AtMost(screen.Width), .AtMost(screen.Height));

		// Flip above if clipping bottom.
		if (screenY + menu.MeasuredSize.Y > screen.Height)
			screenY = screenY - Height - menu.MeasuredSize.Y;

		Context.PopupLayer.ShowPopup(menu, this, screenX, screenY,
			closeOnClickOutside: true, isModal: false, ownsView: true);
		mIsOpen = true;
		InvalidateVisual();
	}

	/// Close the dropdown.
	public void CloseDropdown()
	{
		mIsOpen = false;
		InvalidateVisual();
	}

	/// IPopupOwner — called when dropdown is closed externally.
	public void OnPopupClosed(View popup)
	{
		mIsOpen = false;
		InvalidateVisual();
	}
}
