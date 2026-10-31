using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A colour property: a swatch that opens a [[ColorPicker]] dialog when clicked.
///
/// The dialog reports every change LIVE, so the object being edited updates while the picker is
/// open and the user judges the colour against the real thing rather than against the swatch.
/// Cancelling therefore has to put the original back explicitly; there is no "not applied yet"
/// state to fall out of.
class ColorEditor : PropertyEditor
{
	/// A swatch that opens the dialog. Sedulous's ColorView has no click event, so the press is
	/// taken by a subclass.
	private class ClickableSwatch : ColorView
	{
		private ColorEditor mEditor;

		public this(ColorEditor editor)
		{
			mEditor = editor;
			Cursor = .Hand;
		}

		public override void OnMouseDown(MouseEventArgs e)
		{
			if ((e.Button != .Left) || (Context == null))
				return;

			mEditor.OpenPicker(Context);
			e.Handled = true;
		}
	}

	/// OWNED.
	public delegate void(Color) Setter ~ delete _;

	private Color mValue;
	/// BORROWED: the cached editor view owns it.
	private ColorView mSwatch = null;

	/// CONSUMES the setter.
	public this(StringView name, Color initialValue, delegate void(Color) setter = null,
		StringView category = default) : base(name, category)
	{
		Setter = setter;
		mValue = initialValue;
	}

	public Color Value => mValue;

	public void SetValue(Color value)
	{
		mValue = value;
		if (mSwatch != null)
			mSwatch.Color.Value = value;
	}

	public override void RefreshView()
	{
		if (mSwatch != null)
			mSwatch.Color.Value = mValue;
	}

	protected override View CreateEditorView()
	{
		let swatch = new ClickableSwatch(this);
		mSwatch = swatch;
		mSwatch.Color.Value = mValue;
		return swatch;
	}

	private void OpenPicker(UIContext context)
	{
		// Remembered BEFORE the transaction opens, because every change from here on is applied
		// straight through and cancelling has to restore this.
		let originalColor = mValue;
		BeginEdit();

		let picker = new ColorPicker();
		picker.SetColor(mValue);
		picker.SetOriginalColor(mValue);
		picker.OnColorChanged.Add(new (sender, color) => { Apply(color); });

		let dialog = new Dialog("Color Picker");
		dialog.SetContent(picker);
		dialog.AddButton("OK", .OK);
		dialog.AddButton("Cancel", .Cancel);
		dialog.OnClosed.Add(new (sender, result) =>
			{
				if (result == .OK)
				{
					EndEdit();
					return;
				}

				Apply(originalColor);
				CancelEdit();
			});

		dialog.Show(context);
	}

	private void Apply(Color color)
	{
		mValue = color;
		if (mSwatch != null)
			mSwatch.Color.Value = color;
		if (Setter != null)
			Setter(color);

		NotifyValueChanged();
	}
}
