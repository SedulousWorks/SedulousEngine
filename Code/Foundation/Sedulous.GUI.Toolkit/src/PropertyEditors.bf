using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The property grid's first editors, each the core's control as a row's value, mixed when the
// objects differ:
//   - bool: a check box, mixed its indeterminate state;
//   - integer and float: a number field, scrubbed (the scrub previewed, committed on release,
//     cancelled by Escape), its range and step the property's (unbounded when it has no range; a
//     float's step 0.01 when it has none), and the wheel left to the grid;
//   - a number on a slider (hint "slider"): a slider over its range beside its number field, each
//     the same gesture (a drag previewed, committed on release, Escape putting it back), the wheel
//     left to the grid;
//   - string: a one-line field, committed on Return or on leaving it; Escape puts back what it had;
//   - enum: a combo box of its choices;
//   - flags: a button naming the flags set, opening a list of check boxes, a flag that differs
//     between the objects indeterminate; each one set or cleared alone;
//   - Float2, Float3 and Float4: a group hinted with Core's type name, a number field per child on
//     its one row, each labelled with its child's name and editing its child's path, so each is
//     mixed and scrubbed on its own;
//   - colours: a swatch and a hex field; the swatch opens the core's picker as a popup, a drag
//     previewing on every object and the picker's closing committing once (the originals put back
//     first), Escape cancelling; the hex field commits what is typed;
//   - an intensity in exposure stops (hint "stops"): a number field of log2 of the value, so 0
//     stops is x1, writing 2^stops;
//   - an HDR colour (hint "ColorHdr"): its `color` part's editor and its `intensity` part's stops on
//     one row, each its own gesture;
//   - lists: the count (mixed when the objects' differ) and an Add button, a menu of the types when
//     the list takes several; an element added at the end.
// Mixed, a field shows the placeholder "Mixed" and a button says so.

static
{
	/// What a field or a button shows for values that differ.
	public static StringView MixedValueText() => "Mixed";
}

// An editor of one control filling it.
[GuiReflect]
abstract class SingleControlEditor : PropertyEditor
{
	// A child it holds (its derived editor keeps the reference).
	private Node mControl = null;

	protected void Hold(Node control)
	{
		mControl = control;
		AddChild(control);
	}

	public override void OnLayout()
	{
		if (mControl != null)
			mControl.Arrange(ContentBounds);
	}

	protected override void OnTextStyleChange()
	{
		if (let control = mControl as UINode)
			ShareTextStyle(control);
	}
}

[GuiReflect]
class BoolPropertyEditor : SingleControlEditor
{
	private Sedulous.GUI.CheckBox mBox ~ _.ReleaseRef();

	public this()
	{
		AddClass("bool");
		mBox = new Sedulous.GUI.CheckBox();
		mBox.SetOnToggled(new (@checked) => { ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(@checked))); });
		Hold(mBox);
	}

	public Sedulous.GUI.CheckBox CheckBox => mBox;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mBox.Checked = value.Value.AsBool;
		mBox.Indeterminate = value.Mixed;
		mBox.Enabled = !IsReadOnly;
	}
}

[GuiReflect]
class NumberPropertyEditor : SingleControlEditor
{
	private NumberField mField ~ _.ReleaseRef();
	private bool mInteger = false;
	// A gesture under way (a scrub's previews).
	private bool mBegun = false;

	public override bool IsTyping => mField.IsEditing;

	public this()
	{
		AddClass("number");
		mField = new NumberField();
		mField.StepsOnWheel = false; // the wheel scrolls the grid
		mField.Placeholder = MixedValueText();
		mField.SetOnValueChanging(new (value) =>
			{
				Begin();
				PreviewEdit(PropertyWrite(ValueOf(value)));
			});
		mField.SetOnValueChanged(new (value) =>
			{
				Begin();
				mBegun = false;
				CommitEdit(PropertyWrite(ValueOf(value)));
			});
		mField.SetOnValueCancelled(new () =>
			{
				if (!mBegun)
					return;
				mBegun = false;
				CancelEdit();
			});
		Hold(mField);
	}

	public NumberField Field => mField;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mBegun = false;
		mInteger = info.Kind == .Integer;
		mField.IsInteger = mInteger;
		// Unbounded, it snaps to its step from zero and goes past the field's own range.
		mField.Min = info.HasRange ? info.Min : 0.0;
		mField.Max = info.HasRange ? info.Max : 100.0;
		mField.AllowLesser = !info.HasRange;
		mField.AllowGreater = !info.HasRange;
		mField.Step = (info.Step > 0.0) ? info.Step : (mInteger ? 1.0 : 0.01);
		mField.Value = value.Value.AsFloat;
		mField.IsMixed = value.Mixed;
		mField.Enabled = !IsReadOnly;
	}

	private Sedulous.GUI.Variant ValueOf(double value)
	{
		return mInteger ? Sedulous.GUI.Variant((int64)((value < 0.0) ? value - 0.5 : value + 0.5)) : Sedulous.GUI.Variant(value);
	}

	private void Begin()
	{
		if (mBegun)
			return;
		mBegun = true;
		BeginEdit();
	}
}

/// A number over its range: a slider beside its field. Either is one gesture: previewed as it goes,
/// committed on release (the field: on Return or leaving it), Escape putting it back.
[GuiReflect]
class SliderPropertyEditor : PropertyEditor
{
	private Sedulous.GUI.Slider mSlider ~ _.ReleaseRef();
	private NumberField mField ~ _.ReleaseRef();
	private bool mInteger = false;
	// A gesture under way (a drag's or a scrub's previews).
	private bool mBegun = false;

	public override bool IsTyping => mField.IsEditing;

	public this()
	{
		AddClass("slider-field");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.ColumnGap = 8.0f;
			});
		mSlider = new Sedulous.GUI.Slider();
		mSlider.StepsOnWheel = false; // the wheel scrolls the grid
		mSlider.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 1.0f;
				s.Basis = LayoutLength.Px(0.0f);
				s.MinWidth = LayoutLength.Px(0.0f);
			});
		mSlider.SetOnValueChanging(new (value) =>
			{
				Begin();
				mField.Value = value;
				PreviewEdit(PropertyWrite(ValueOf(value)));
			});
		mSlider.SetOnValueChanged(new (value) => { Commit(value); });
		mSlider.SetOnValueCancelled(new () =>
			{
				mField.Value = mSlider.Range.Value; // back with it
				Cancel();
			});
		AddChild(mSlider);
		mField = new NumberField();
		mField.StepsOnWheel = false;
		mField.Placeholder = MixedValueText();
		mField.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(64.0f);
				s.Shrink = 0.0f;
			});
		mField.SetOnValueChanging(new (value) =>
			{
				Begin();
				mSlider.Value = value;
				PreviewEdit(PropertyWrite(ValueOf(value)));
			});
		mField.SetOnValueChanged(new (value) => { Commit(value); });
		mField.SetOnValueCancelled(new () =>
			{
				mSlider.Value = mField.Range.Value; // back with it
				Cancel();
			});
		AddChild(mField);
	}

	public Sedulous.GUI.Slider Slider => mSlider;
	public NumberField Field => mField;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mBegun = false;
		mInteger = info.Kind == .Integer;
		// A slider needs both ends: without a range it runs 0 to 1.
		let lo = info.HasRange ? info.Min : 0.0;
		let hi = info.HasRange ? info.Max : 1.0;
		let step = (info.Step > 0.0) ? info.Step : (mInteger ? 1.0 : 0.01);
		mSlider.Min = lo;
		mSlider.Max = hi;
		mSlider.Step = step;
		mField.IsInteger = mInteger;
		mField.Min = lo;
		mField.Max = hi;
		mField.AllowLesser = false;
		mField.AllowGreater = false;
		mField.Step = step;
		mSlider.Value = value.Value.AsFloat;
		mField.Value = value.Value.AsFloat;
		mField.IsMixed = value.Mixed;
		mSlider.Enabled = !IsReadOnly;
		mField.Enabled = !IsReadOnly;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mField);
	}

	private Sedulous.GUI.Variant ValueOf(double value)
	{
		return mInteger ? Sedulous.GUI.Variant((int64)((value < 0.0) ? value - 0.5 : value + 0.5)) : Sedulous.GUI.Variant(value);
	}

	private void Begin()
	{
		if (mBegun)
			return;
		mBegun = true;
		BeginEdit();
	}

	private void Commit(double value)
	{
		Begin();
		mBegun = false;
		mSlider.Value = value;
		mField.Value = value;
		CommitEdit(PropertyWrite(ValueOf(value)));
	}

	private void Cancel()
	{
		if (!mBegun)
			return;
		mBegun = false;
		CancelEdit();
	}
}

[GuiReflect]
class StringPropertyEditor : SingleControlEditor
{
	private TextField mField ~ _.ReleaseRef();
	private String mShown = new .() ~ delete _;

	public override bool IsTyping => mField.IsFocused;

	public this()
	{
		AddClass("string");
		mField = new TextField();
		mField.Placeholder = MixedValueText();
		mField.SetOnTextChanged(new (text) => { ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(text))); });
		Hold(mField);
	}

	public TextField Field => mField;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mShown.Set(value.Mixed ? StringView() : value.Value.AsString);
		mField.Placeholder = value.Mixed ? MixedValueText() : StringView();
		mField.Text = mShown;
		mField.IsReadOnly = IsReadOnly;
	}

	// Escape puts back what it had (the field then has nothing new to commit).
	protected override void OnKeyDown(KeyEvent e)
	{
		if (((KeyCode)e.KeyCode == .Escape) && (e.Modifiers == 0) && (mField.Text != mShown))
		{
			mField.Text = mShown;
			e.Handled = true;
		}
	}
}

[GuiReflect]
class EnumPropertyEditor : SingleControlEditor
{
	private Sedulous.GUI.ComboBox mCombo ~ _.ReleaseRef();
	private List<PropertyChoice> mChoices = new .() ~ DeleteContainerAndItems!(_);
	// Showing a value, not the user picking one.
	private bool mBinding = false;

	public this()
	{
		AddClass("enum");
		mCombo = new Sedulous.GUI.ComboBox();
		mCombo.Placeholder = MixedValueText();
		mCombo.SetOnSelectionChanged(new (index) =>
			{
				if (mBinding || (index < 0) || (index >= mChoices.Count))
					return;
				ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(mChoices[index].Value)));
			});
		Hold(mCombo);
	}

	public Sedulous.GUI.ComboBox ComboBox => mCombo;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mBinding = true;
		if (!SameChoices(info.Choices))
		{
			ClearAndDeleteItems!(mChoices);
			for (let choice in info.Choices)
			{
				let copy = new PropertyChoice();
				copy.Set(choice);
				mChoices.Add(copy);
			}
			mCombo.ItemsText = "";
			for (let choice in mChoices)
				mCombo.AddItem(choice.Name);
		}
		int32 selected = -1;
		if (!value.Mixed)
		{
			for (int i = 0; i < mChoices.Count; ++i)
			{
				if (mChoices[i].Value == value.Value.AsInt)
					selected = (int32)i;
			}
		}
		mCombo.SelectedIndex = selected;
		mCombo.Enabled = !IsReadOnly;
		mBinding = false;
	}

	private bool SameChoices(List<PropertyChoice> choices)
	{
		if (choices.Count != mChoices.Count)
			return false;
		for (int i = 0; i < choices.Count; ++i)
		{
			if ((choices[i].Value != mChoices[i].Value) || (choices[i].Name != mChoices[i].Name))
				return false;
		}
		return true;
	}
}

/// The list a flags editor opens: a check box per flag.
[GuiReflect]
class PropertyFlagsList : UIWidget
{
	public this()
	{
		Tag = "propertyflagslist";
		Padding = Thickness(6.0f, 4.0f, 6.0f, 4.0f);
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.RowGap = 2.0f;
			});
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (!BoxFills)
			ctx.VG.FillRect(localBounds.ToRectangle(), .(0.18f, 0.20f, 0.25f, 1.0f));
		base.OnDraw(ctx, localBounds);
	}
}

[GuiReflect]
class FlagsPropertyEditor : SingleControlEditor
{
	private Sedulous.GUI.Button mButton ~ _.ReleaseRef();
	private PropertyFlagsList mList ~ _.ReleaseRef();
	private System.Collections.List<CheckBox> mBoxes = new .() ~ { for (let b in _) b.ReleaseRef(); delete _; };
	private System.Collections.List<PropertyChoice> mChoices = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mBits = 0;
	private uint64 mMixedBits = 0;

	public this()
	{
		AddClass("flags");
		mButton = new Sedulous.GUI.Button(); // the sheet's `propertyeditor.flags button` draws it as a field
		mButton.SetOnClick(new () => { OpenList(); });
		Hold(mButton);
		mList = new PropertyFlagsList();
	}

	public Sedulous.GUI.Button Button => mButton;

	/// The list, while it is open.
	public PropertyFlagsList List
	{
		get
		{
			let dispatcher = mList.EventDispatcher;
			return ((dispatcher != null) && dispatcher.IsPopupOpen(mList)) ? mList : null;
		}
	}

	/// The list's check box for choice `index`, while it is open.
	public CheckBox GetFlagBox(int index) => ((this.List != null) && (index >= 0) && (index < mBoxes.Count)) ? mBoxes[index] : null;

	public void OpenList()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher == null) || mChoices.IsEmpty || IsReadOnly)
			return;
		ShareTextStyle(mList, false);
		ShowBoxes();
		let options = new PopupOptions();
		options.Anchor = mButton;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 0.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.FitContent = true;
		dispatcher.OpenPopup(this, mList, options);
	}

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		ClearAndDeleteItems!(mChoices);
		for (let choice in info.Choices)
		{
			let copy = new PropertyChoice();
			copy.Set(choice);
			mChoices.Add(copy);
		}
		mBits = (uint64)value.Value.AsInt;
		mMixedBits = value.MixedBits;
		mButton.Text = Summary(.. scope String());
		mButton.Enabled = !IsReadOnly;
		if (this.List != null)
			ShowBoxes();
	}

	// The flags set (those that differ said to), "None" when none is.
	private void Summary(String text)
	{
		if (mMixedBits != 0)
		{
			text.Append(MixedValueText());
			return;
		}
		for (let choice in mChoices)
		{
			if ((choice.Value != 0) && ((mBits & (uint64)choice.Value) == (uint64)choice.Value))
			{
				if (text.Length != 0)
					text.Append(", ");
				text.Append(choice.Name);
			}
		}
		if (text.Length == 0)
			text.Append("None");
	}

	// A check box per flag, made as the choices need them, each showing its bit.
	private void ShowBoxes()
	{
		while (mBoxes.Count < mChoices.Count)
		{
			let @box = new CheckBox();
			let index = mBoxes.Count;
			@box.SetOnToggled(new (@checked) => { SetFlag(index, @checked); });
			mList.AddChild(@box);
			mBoxes.Add(@box);
		}
		for (int i = 0; i < mBoxes.Count; ++i)
		{
			let @box = mBoxes[i];
			@box.Displayed = i < mChoices.Count;
			if (i >= mChoices.Count)
				continue;
			let bit = (uint64)mChoices[i].Value;
			@box.Text = mChoices[i].Name;
			@box.Checked = ((mBits & bit) == bit) && (bit != 0);
			@box.Indeterminate = (mMixedBits & bit) != 0;
		}
	}

	private void SetFlag(int index, bool set)
	{
		if (index >= mChoices.Count)
			return;
		let bit = (uint64)mChoices[index].Value;
		ApplyEdit(PropertyWrite(Sedulous.GUI.Variant((int64)(set ? bit : 0)), bit));
	}
}

/// A group's number children side by side on its row (Float2, Float3, Float4): each a number
/// editor of its own path after its name.
[GuiReflect]
class FloatsPropertyEditor : PropertyEditor
{
	private List<Label> mLabels = new .() ~ { for (let l in _) l.ReleaseRef(); delete _; };
	private List<NumberPropertyEditor> mFields = new .() ~ { for (let f in _) f.ReleaseRef(); delete _; };
	private int mShown = 0;

	public override bool IsTyping
	{
		get
		{
			for (int i = 0; (i < mShown) && (i < mFields.Count); ++i)
			{
				if (mFields[i].IsTyping)
					return true;
			}
			return false;
		}
	}

	public this()
	{
		AddClass("floats");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Stretch;
				s.ColumnGap = 6.0f;
			});
	}

	public int PartCount => mShown;
	public NumberPropertyEditor GetPart(int index) => ((index >= 0) && (index < mShown)) ? mFields[index] : null;
	public Label GetPartLabel(int index) => ((index >= 0) && (index < mShown)) ? mLabels[index] : null;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		let host = Host;
		mShown = 0;
		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		if (host != null)
			host.GetChildProperties(Path, parts);
		for (let part in parts)
		{
			if (!part.Visible || ((part.Kind != .Float) && (part.Kind != .Integer)))
				continue;
			if (mShown == mFields.Count)
				AddPart();
			let path = JoinPropertyPath(Path, part.Name, .. scope String());
			part.ReadOnly = part.ReadOnly || IsReadOnly;
			mLabels[mShown].Text = part.ShownName;
			var partValue = host.ReadPropertyValue(path, part.Kind);
			mFields[mShown].Bind(host, path, part, partValue);
			partValue.Dispose();
			++mShown;
		}
		for (int i = 0; i < mFields.Count; ++i)
		{
			mLabels[i].Displayed = i < mShown;
			mFields[i].Displayed = i < mShown;
		}
	}

	protected override void OnTextStyleChange()
	{
		for (int i = 0; i < mFields.Count; ++i)
		{
			ShareTextStyle(mLabels[i]);
			ShareTextStyle(mFields[i]);
		}
	}

	private void AddPart()
	{
		let label = new Label();
		label.AddClass("component");
		label.SetTextAlignment(.Start, .Middle);
		label.HitTestVisible = false;
		label.EditLayoutStyle(scope (s) => { s.Shrink = 0.0f; });
		let field = new NumberPropertyEditor();
		field.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 1.0f;
				s.Shrink = 1.0f;
				s.Basis = LayoutLength.Px(0.0f);
				s.MinWidth = LayoutLength.Px(0.0f);
			});
		ShareTextStyle(label);
		ShareTextStyle(field);
		AddChild(label);
		AddChild(field);
		mLabels.Add(label);
		mFields.Add(field);
	}
}

/// The popup a colour editor opens: the core's picker on a panel.
[GuiReflect]
class PropertyColorPopup : UIWidget
{
	private ColorPicker mPicker ~ _.ReleaseRef();

	public this()
	{
		Tag = "propertycolorpopup";
		Padding = Thickness(8.0f, 8.0f, 8.0f, 8.0f);
		EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(300.0f); });
		mPicker = new ColorPicker();
		AddChild(mPicker);
	}

	public ColorPicker Picker => mPicker;

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		if (!BoxFills)
			ctx.VG.FillRect(localBounds.ToRectangle(), .(0.18f, 0.20f, 0.25f, 1.0f));
		base.OnDraw(ctx, localBounds);
	}
}

[GuiReflect]
class ColorPropertyEditor : PropertyEditor
{
	private ColorSwatch mSwatch ~ _.ReleaseRef();
	private TextField mHex ~ _.ReleaseRef();
	private PropertyColorPopup mPopup ~ _.ReleaseRef();
	private Color mColor = .();
	private Color mPicked = .();
	private bool mShowsAlpha = true;
	// A gesture under way in the open picker.
	private bool mPicking = false;

	public override bool IsTyping => mHex.IsFocused;

	public this()
	{
		AddClass("color");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Stretch;
				s.ColumnGap = 6.0f;
			});
		mSwatch = new ColorSwatch();
		mSwatch.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(40.0f);
				s.Shrink = 0.0f;
			});
		mSwatch.SetOnClick(new () => { OpenPicker(); });
		AddChild(mSwatch);
		mHex = new TextField();
		mHex.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 1.0f;
				s.Basis = LayoutLength.Px(0.0f);
				s.MinWidth = LayoutLength.Px(0.0f);
			});
		mHex.SetOnTextChanged(new (text) => { TypedHex(text); });
		AddChild(mHex);
		mPopup = new PropertyColorPopup();
		mPopup.Picker.SetOnColorChanging(new (color) => { Picked(color); });
		mPopup.Picker.SetOnColorChanged(new (color) => { Picked(color); });
	}

	public ColorSwatch Swatch => mSwatch;
	public TextField HexField => mHex;

	/// The picker, while it is open.
	public ColorPicker Picker
	{
		get
		{
			let dispatcher = mPopup.EventDispatcher;
			return ((dispatcher != null) && dispatcher.IsPopupOpen(mPopup)) ? mPopup.Picker : null;
		}
	}

	/// Opens the picker on the colour shown; its drags preview, its closing commits.
	public void OpenPicker()
	{
		let dispatcher = EventDispatcher;
		if ((dispatcher == null) || IsReadOnly || (Picker != null))
			return;
		ShareTextStyle(mPopup, false);
		mPopup.Picker.ShowsAlpha = mShowsAlpha;
		mPopup.Picker.ColorValue = mColor;
		mPopup.Picker.SetOriginal(mColor); // beside the new one, a click putting it back
		mPicking = false;
		mPicked = mColor;
		let options = new PopupOptions();
		options.Anchor = mSwatch;
		options.Placement.Side = .Below;
		options.Placement.Align = .Start;
		options.Placement.Gap = 2.0f;
		options.Placement.Shrink = true;
		options.TakesFocus = true;
		options.FitContent = true;
		options.OnClosed = new (reason) => { Closed(reason == .Escape); };
		dispatcher.OpenPopup(this, mPopup, options);
	}

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mShowsAlpha = info.ShowsAlpha;
		mColor = (value.Value.Kind == .Color) ? value.Value.AsColor : Color();
		if (!mShowsAlpha)
			mColor.A = 1.0f;
		mSwatch.ColorValue = mColor;
		mSwatch.IsMixed = value.Mixed;
		mSwatch.ShowsAlpha = mShowsAlpha;
		mSwatch.Enabled = !IsReadOnly;
		mHex.Placeholder = value.Mixed ? MixedValueText() : StringView();
		if (value.Mixed)
			mHex.Text = default;
		else
			mHex.Text = FormatHexColor(mColor, mShowsAlpha, .. scope String());
		mHex.IsReadOnly = IsReadOnly;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mSwatch);
		ShareTextStyle(mHex);
	}

	// A step of the picker: the gesture begun on the first, each previewed.
	private void Picked(Color picked)
	{
		var color = picked;
		if (!mShowsAlpha)
			color.A = 1.0f;
		if (!mPicking)
		{
			mPicking = true;
			BeginEdit();
		}
		mPicked = color;
		mSwatch.ColorValue = color;
		mSwatch.IsMixed = false;
		mHex.Placeholder = default;
		mHex.Text = FormatHexColor(color, mShowsAlpha, .. scope String()); // the row shows the pick as it goes
		PreviewEdit(PropertyWrite(Sedulous.GUI.Variant(color)));
	}

	// The picker closed: what it picked committed once, or given up with Escape.
	private void Closed(bool escaped)
	{
		if (!mPicking)
			return;
		mPicking = false;
		if (escaped)
			CancelEdit();
		else
			CommitEdit(PropertyWrite(Sedulous.GUI.Variant(mPicked)));
	}

	private void TypedHex(StringView text)
	{
		let parsed = ParseColor(ParseUtil.Trim(text));
		if (!parsed.HasValue)
		{
			mHex.Text = FormatHexColor(mColor, mShowsAlpha, .. scope String()); // not a colour: what it was
			return;
		}
		var color = parsed.Value;
		if (!mShowsAlpha)
			color.A = 1.0f;
		ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(color)));
	}
}

/// An intensity shown in exposure stops: log2 of its value (0 stops: x1), 2^stops written.
[GuiReflect]
class StopsPropertyEditor : SingleControlEditor
{
	private NumberField mField ~ _.ReleaseRef();
	private bool mBegun = false;

	public override bool IsTyping => mField.IsEditing;

	public this()
	{
		AddClass("stops");
		mField = new NumberField();
		mField.StepsOnWheel = false;
		mField.Placeholder = MixedValueText();
		mField.Suffix = " EV";
		mField.Min = -16.0;
		mField.Max = 16.0;
		mField.Step = 0.1;
		mField.SetOnValueChanging(new (stops) =>
			{
				Begin();
				PreviewEdit(PropertyWrite(Sedulous.GUI.Variant((double)Math.Pow(2.0f, (float)stops))));
			});
		mField.SetOnValueChanged(new (stops) =>
			{
				Begin();
				mBegun = false;
				CommitEdit(PropertyWrite(Sedulous.GUI.Variant((double)Math.Pow(2.0f, (float)stops))));
			});
		mField.SetOnValueCancelled(new () =>
			{
				if (!mBegun)
					return;
				mBegun = false;
				CancelEdit();
			});
		Hold(mField);
	}

	public NumberField Field => mField;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mBegun = false;
		let linear = value.Value.AsFloat;
		mField.Value = (linear > 0.0) ? (double)(Math.Log((float)linear) / Math.Log(2.0f)) : -16.0;
		mField.IsMixed = value.Mixed;
		mField.Enabled = !IsReadOnly;
	}

	private void Begin()
	{
		if (mBegun)
			return;
		mBegun = true;
		BeginEdit();
	}
}

/// An HDR colour on one row: its `color` part's swatch and hex, its `intensity` part's stops.
[GuiReflect]
class HdrColorPropertyEditor : PropertyEditor
{
	private ColorPropertyEditor mColor ~ _.ReleaseRef();
	private StopsPropertyEditor mStops ~ _.ReleaseRef();

	public override bool IsTyping => mColor.IsTyping || mStops.IsTyping;

	public this()
	{
		AddClass("colorhdr");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Stretch;
				s.ColumnGap = 6.0f;
			});
		mColor = new ColorPropertyEditor();
		mColor.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 3.0f;
				s.Basis = LayoutLength.Px(0.0f);
				s.MinWidth = LayoutLength.Px(0.0f);
			});
		AddChild(mColor);
		mStops = new StopsPropertyEditor();
		mStops.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 2.0f;
				s.Basis = LayoutLength.Px(0.0f);
				s.MinWidth = LayoutLength.Px(0.0f);
			});
		AddChild(mStops);
	}

	public ColorPropertyEditor ColorPart => mColor;
	public StopsPropertyEditor IntensityPart => mStops;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		let host = Host;
		if (host == null)
			return;
		let parts = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(parts); }
		host.GetChildProperties(Path, parts);
		for (let part in parts)
		{
			let path = JoinPropertyPath(Path, part.Name, .. scope String());
			part.ReadOnly = part.ReadOnly || IsReadOnly;
			if (part.Kind == .Color)
			{
				var partValue = host.ReadPropertyValue(path, part.Kind);
				mColor.Bind(host, path, part, partValue);
				partValue.Dispose();
			}
			else if (part.Kind == .Float)
			{
				var partValue = host.ReadPropertyValue(path, part.Kind);
				mStops.Bind(host, path, part, partValue);
				partValue.Dispose();
			}
		}
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mColor);
		ShareTextStyle(mStops);
	}
}

/// A list's row: how many elements, and Add.
[GuiReflect]
class ListPropertyEditor : PropertyEditor
{
	private Label mCount ~ _.ReleaseRef();
	private Button mAdd ~ _.ReleaseRef();
	private Sedulous.GUI.Menu mMenu ~ _?.ReleaseRef();
	private List<String> mTypes = new .() ~ DeleteContainerAndItems!(_);
	private int mSize = 0;

	public this()
	{
		AddClass("list");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.ColumnGap = 8.0f;
			});
		mCount = new Label();
		mCount.AddClass("count");
		mCount.HitTestVisible = false;
		mCount.EditLayoutStyle(scope (s) => { s.Grow = 1.0f; });
		AddChild(mCount);
		mAdd = new Button();
		mAdd.AddClass("add");
		mAdd.Text = "Add";
		mAdd.SetOnClick(new () => { Add(); });
		AddChild(mAdd);
	}

	public Label CountLabel => mCount;
	public Button AddButton => mAdd;
	/// The menu of the types an add chooses from, while it is open.
	public Sedulous.GUI.Menu TypeMenu => ((mMenu != null) && mMenu.IsOpen) ? mMenu : null;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mSize = (int)((value.Value.AsInt < 0) ? 0 : value.Value.AsInt);
		ClearAndDeleteItems!(mTypes);
		for (let type in info.ElementTypes)
			mTypes.Add(new String(type));
		if (value.Mixed)
			mCount.Text = MixedValueText();
		else if (mSize == 1)
			mCount.Text = "1 element";
		else
			mCount.Text = scope String()..AppendF("{} elements", mSize);
		let full = (info.MaxCount != 0) && !value.Mixed && (mSize >= (int)info.MaxCount);
		mAdd.Displayed = (info.ListOps & PropertyListAdd) != 0;
		mAdd.Enabled = !IsReadOnly && !full;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mCount);
		ShareTextStyle(mAdd);
	}

	// At the end; of a type picked from a menu when the list takes several.
	private void Add()
	{
		if (mTypes.Count <= 1)
		{
			Insert(mTypes.IsEmpty ? StringView() : (StringView)mTypes[0]);
			return;
		}
		if (mMenu != null)
			mMenu.ReleaseRef();
		mMenu = new Sedulous.GUI.Menu();
		ShareTextStyle(mMenu, false);
		mMenu.SetAutoWidth(true);
		for (let type in mTypes)
		{
			let picked = new String(type);
			mMenu.AddItem(type, new [=this, =picked] () => { Insert(picked); } ~ delete picked);
		}
		let below = mAdd.ScreenBounds;
		let top = RootNode;
		if (top != null)
			mMenu.Open(this, top.ConvertToNodeSpace(.(below.X, below.Y + below.Height)));
	}

	private void Insert(StringView type)
	{
		let edit = scope ListEdit();
		edit.Kind = .Insert;
		edit.Index = mSize;
		edit.ElementType.Set(type);
		EditList(edit);
	}
}
