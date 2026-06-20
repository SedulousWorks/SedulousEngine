namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for RangeColor (Min/Max Vector4 pair, HDR-allowed).
/// Two clickable swatches side-by-side; clicking either opens an
/// HDRColorPicker dialog for that endpoint. The picker handles HDR
/// channels natively (Intensity slider + float R/G/B/A fields), so the
/// editor preserves HDR values through the round-trip.
class RangeColorEditor : PropertyEditor
{
	private RangeColor* mPtr;
	private RangeColorSwatch mMinSwatch;
	private RangeColorSwatch mMaxSwatch;

	public this(StringView name, RangeColor* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 6;

		let minLabel = new Label();
		minLabel.SetText("Min");
		minLabel.FontSize.Value = 11;
		minLabel.VAlign.Value = .Middle;
		row.AddView(minLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(28)) });

		mMinSwatch = new RangeColorSwatch(this, isMin: true);
		mMinSwatch.Cursor = .Hand;
		row.AddView(mMinSwatch, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		let maxLabel = new Label();
		maxLabel.SetText("Max");
		maxLabel.FontSize.Value = 11;
		maxLabel.VAlign.Value = .Middle;
		row.AddView(maxLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(28)) });

		mMaxSwatch = new RangeColorSwatch(this, isMin: false);
		mMaxSwatch.Cursor = .Hand;
		row.AddView(mMaxSwatch, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		RefreshSwatches();
		return row;
	}

	private void RefreshSwatches()
	{
		if (mMinSwatch != null) mMinSwatch.Color.Value = ClampToLDR(mPtr.Min);
		if (mMaxSwatch != null) mMaxSwatch.Color.Value = ClampToLDR(mPtr.Max);
	}

	private static Color ClampToLDR(Vector4 c)
	{
		return .(Math.Clamp(c.X, 0, 1), Math.Clamp(c.Y, 0, 1), Math.Clamp(c.Z, 0, 1), Math.Clamp(c.W, 0, 1));
	}

	/// Open an HDRColorPicker for one endpoint. Live picker updates write
	/// straight into mPtr.Min/Max so the simulation reacts during edit;
	/// Cancel restores the value the gesture started with.
	private void OpenPickerFor(bool isMin)
	{
		let host = isMin ? (View)mMinSwatch : (View)mMaxSwatch;
		let ctx = host?.Context;
		if (ctx == null) return;

		let originalColor = isMin ? mPtr.Min : mPtr.Max;
		BeginEdit();

		let picker = new HDRColorPicker();
		picker.SetColor(originalColor);
		picker.SetOriginalColor(originalColor);
		picker.OnColorChanged.Add(new (p, c) =>
		{
			if (isMin) mPtr.Min = c;
			else mPtr.Max = c;
			RefreshSwatches();
			NotifyValueChanged();
		});

		let dialog = new Dialog(isMin ? "Min Color" : "Max Color");
		dialog.SetContent(picker);
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		dialog.OnClosed.Add(new (d, result) =>
		{
			if (result == .OK)
				EndEdit();
			else
			{
				if (isMin) mPtr.Min = originalColor;
				else mPtr.Max = originalColor;
				RefreshSwatches();
				NotifyValueChanged();
				CancelEdit();
			}
		});
		dialog.Show(ctx);
	}

	public override void RefreshView()
	{
		RefreshSwatches();
	}

	/// Clickable swatch view. Mirrors ColorEditor.ClickableColorSwatch.
	private class RangeColorSwatch : ColorView
	{
		private RangeColorEditor mEditor;
		private bool mIsMin;

		public this(RangeColorEditor editor, bool isMin)
		{
			mEditor = editor;
			mIsMin = isMin;
		}

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left) return;
			mEditor.OpenPickerFor(mIsMin);
			e.Handled = true;
		}
	}
}
