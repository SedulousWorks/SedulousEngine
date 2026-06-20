namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

/// Property editor for a single HDR-allowed Vector4 color (mirrors
/// RangeColorEditor's swatch + picker pattern but for a single endpoint).
/// Clicking the swatch opens HDRColorPicker; live updates write through
/// the field pointer captured at construction; Cancel restores the
/// snapshot taken on dialog open.
class Vector4ColorEditor : PropertyEditor
{
	private Vector4* mPtr;
	private Vector4ColorSwatch mSwatch;

	public this(StringView name, Vector4* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		mSwatch = new Vector4ColorSwatch(this);
		mSwatch.Cursor = .Hand;
		RefreshSwatch();
		return mSwatch;
	}

	private void RefreshSwatch()
	{
		if (mSwatch != null) mSwatch.Color.Value = ClampToLDR(*mPtr);
	}

	private static Color32 ClampToLDR(Vector4 c)
	{
		let r = (uint8)Math.Clamp((int32)(c.X * 255), 0, 255);
		let g = (uint8)Math.Clamp((int32)(c.Y * 255), 0, 255);
		let b = (uint8)Math.Clamp((int32)(c.Z * 255), 0, 255);
		let a = (uint8)Math.Clamp((int32)(c.W * 255), 0, 255);
		return .(r, g, b, a);
	}

	private void OpenPicker()
	{
		let ctx = mSwatch?.Context;
		if (ctx == null) return;

		let originalColor = *mPtr;
		BeginEdit();

		let picker = new HDRColorPicker();
		picker.SetColor(originalColor);
		picker.SetOriginalColor(originalColor);
		picker.OnColorChanged.Add(new (p, c) =>
		{
			*mPtr = c;
			RefreshSwatch();
			NotifyValueChanged();
		});

		let dialog = new Dialog(scope String(Name));
		dialog.SetContent(picker);
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		dialog.OnClosed.Add(new (d, result) =>
		{
			if (result == .OK)
				EndEdit();
			else
			{
				*mPtr = originalColor;
				RefreshSwatch();
				NotifyValueChanged();
				CancelEdit();
			}
		});
		dialog.Show(ctx);
	}

	public override void RefreshView()
	{
		RefreshSwatch();
	}

	private class Vector4ColorSwatch : ColorView
	{
		private Vector4ColorEditor mEditor;
		public this(Vector4ColorEditor editor) { mEditor = editor; }

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left) return;
			mEditor.OpenPicker();
			e.Handled = true;
		}
	}
}
