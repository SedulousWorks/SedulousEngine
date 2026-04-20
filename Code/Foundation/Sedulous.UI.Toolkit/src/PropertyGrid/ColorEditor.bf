using Sedulous.Core.Mathematics;
using System;
namespace Sedulous.UI.Toolkit;

/// Color property editor - ColorView swatch that opens a ColorPicker popup on click.
/// BeginEdit when picker opens, EndEdit on OK, CancelEdit on Cancel.
public class ColorEditor : PropertyEditor
{
	private Color mValue;
	private ColorView mSwatch;

	public Color Value
	{
		get => mValue;
		set { mValue = value; if (mSwatch != null) mSwatch.Color = value; }
	}

	public delegate void(Color) Setter ~ delete _;

	public this(StringView name, Color initialValue, delegate void(Color) setter = null,
		StringView category = default) : base(name, category)
	{
		mValue = initialValue;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		mSwatch = new ClickableColorSwatch(this);
		mSwatch.Color = mValue;
		mSwatch.Cursor = .Hand;
		return mSwatch;
	}

	/// ColorView that opens a ColorPicker dialog on click.
	private class ClickableColorSwatch : ColorView
	{
		private ColorEditor mEditor;

		public this(ColorEditor editor) { mEditor = editor; }

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left || Context == null) return;

			let originalColor = mEditor.mValue;
			mEditor.BeginEdit();

			let picker = new ColorPicker();
			picker.SetColor(mEditor.mValue);
			picker.SetOriginalColor(mEditor.mValue);
			picker.OnColorChanged.Add(new (p, color) =>
			{
				mEditor.mValue = color;
				mEditor.mSwatch.Color = color;
				mEditor.Setter?.Invoke(color);
				mEditor.NotifyValueChanged();
			});

			let dialog = new Dialog("Color Picker");
			dialog.SetContent(picker);
			dialog.AddButton("OK", .OK);
			dialog.AddButton("Cancel", .Cancel);
			dialog.OnClosed.Add(new (d, result) =>
			{
				if (result == .OK)
				{
					mEditor.EndEdit();
				}
				else
				{
					mEditor.mValue = originalColor;
					mEditor.mSwatch.Color = originalColor;
					mEditor.Setter?.Invoke(originalColor);
					mEditor.CancelEdit();
				}
			});
			dialog.Show(Context);
			e.Handled = true;
		}
	}

	public override void RefreshView()
	{
		if (mSwatch != null) mSwatch.Color = mValue;
	}
}
