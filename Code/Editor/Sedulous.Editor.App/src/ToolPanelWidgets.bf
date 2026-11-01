using System;
using System.Collections;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// What every viewport tool's panel is made of (Raptor's editor-gui spec, 5.3, layer 5, part 3), so
// every panel reads the same (the catalog's 17: three mode-picker styles, two ways to build a check
// row): a segmented row of exclusive choices (a mode, a layer, by word or by picture), a named
// slider with its number, a named check and a line of help. The body asks each control's value of
// the tool again when Sync runs (the host runs it each frame), since a tool's keys change it too
// (1 to 4 its mode, Shift + wheel its radius).

/// One choice of a segmented row: its word, or its picture (asked again until it has one, as a
/// thumbnail arrives later) with `Icon` meanwhile; what it does, its tooltip.
class ToolPanelChoice
{
	public String Label = new .() ~ delete _;
	public String Tooltip = new .() ~ delete _;
	/// A picture's stand-in (an asset type's icon).
	public String Icon = new .() ~ delete _;
	/// Null: its word. A picture's, borrowed (the image takes a reference of its own). OWNED.
	public delegate Drawable() Picture ~ delete _;
}

class ToolPanelBody : UIWidget
{
	private class ChoicePicture
	{
		/// The button's, which keeps it.
		public Image Image = null;
		public delegate Drawable() Ask ~ delete _;
		public bool Shown = false;
	}

	private class ChoiceRow
	{
		/// The row's, which keeps them.
		public List<Sedulous.GUI.Button> Buttons = new .() ~ delete _;
		public List<ChoicePicture> Pictures = new .() ~ DeleteContainerAndItems!(_);
		public delegate int32() Get ~ delete _;
		public delegate void(int32 index) Set ~ delete _;
	}

	private class SliderRow
	{
		/// The row's, which keeps them.
		public Slider Slider = null;
		public NumberField Number = null;
		public delegate double() Get ~ delete _;
		public delegate void(double value) Set ~ delete _;
	}

	private class CheckRow
	{
		/// The body's, which keeps it.
		public CheckBox Box = null;
		public delegate bool() Get ~ delete _;
		public delegate void(bool on) Set ~ delete _;
	}

	private class NoteRow
	{
		/// The body's, which keeps it.
		public Label Label = null;
		public delegate void(String outText) Text ~ delete _;
	}

	private List<ChoiceRow> mChoices = new .() ~ DeleteContainerAndItems!(_);
	private List<SliderRow> mSlides = new .() ~ DeleteContainerAndItems!(_);
	private List<CheckRow> mChecks = new .() ~ DeleteContainerAndItems!(_);
	private List<NoteRow> mNotes = new .() ~ DeleteContainerAndItems!(_);
	/// AddPicture's: shown, not chosen.
	private List<ChoicePicture> mPictures = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		AddClass("tool-panel-body");
	}

	/// A row of exclusive choices under `name` (empty: no heading): `get` the chosen one's index,
	/// `set` choosing. Takes the choices' pictures and both delegates; the choices stay the
	/// caller's.
	public void AddChoices(StringView name, Span<ToolPanelChoice> choices, delegate int32() get, delegate void(int32 index) set)
	{
		if (!name.IsEmpty)
			AddHeading(name);
		let row = new Panel();
		row.AddClass("segmented");
		let group = new ChoiceRow();
		group.Get = get;
		group.Set = set;
		let index = mChoices.Count;
		for (int i < choices.Length)
		{
			let choice = choices[i];
			let button = new Sedulous.GUI.Button();
			button.AddClass("segment");
			button.IsToggle = true;
			button.Tooltip = choice.Tooltip;
			let picture = new ChoicePicture();
			if (choice.Picture != null)
			{
				row.AddClass("pictures"); // a row of them wraps
				button.AddClass("picture");
				let image = new Image();
				image.AddClass("segment-picture");
				image.Source = choice.Icon;
				image.HitTestVisible = false;
				button.AddChild(image);
				image.ReleaseRef(); // the button's keeps it
				picture.Image = image;
				picture.Ask = choice.Picture;
				choice.Picture = null; // ours now
			}
			else
				button.Text = choice.Label;
			let at = (int32)i;
			button.SetOnClick(new [=this, =index, =at] () =>
				{
					let owner = mChoices[index];
					if (owner.Set != null)
						owner.Set(at);
					Sync();
				});
			group.Buttons.Add(button);
			group.Pictures.Add(picture);
			row.AddChild(button);
			button.ReleaseRef(); // the row's keeps it
		}
		mChoices.Add(group);
		AddChild(row);
		row.ReleaseRef(); // ours keeps it
	}

	/// A picture shown, not chosen, under `name` (a terrain's base layer, which erasing reveals):
	/// `shown`'s picture once it has one, its icon meanwhile, its tooltip. Takes its picture; the
	/// choice stays the caller's.
	public void AddPicture(StringView name, ToolPanelChoice shown)
	{
		if (!name.IsEmpty)
			AddHeading(name);
		let row = new Panel();
		row.AddClass("segmented");
		row.AddClass("pictures");
		let frame = new Panel();
		frame.AddClass("segment");
		frame.AddClass("picture");
		frame.AddClass("shown"); // not a button: nothing to choose
		frame.Tooltip = shown.Tooltip;
		let image = new Image();
		image.AddClass("segment-picture");
		image.Source = shown.Icon;
		image.HitTestVisible = false;
		frame.AddChild(image);
		image.ReleaseRef(); // the frame's keeps it
		row.AddChild(frame);
		frame.ReleaseRef(); // the row's keeps it
		let picture = new ChoicePicture();
		picture.Image = image;
		picture.Ask = shown.Picture;
		shown.Picture = null; // ours now
		mPictures.Add(picture);
		AddChild(row);
		row.ReleaseRef(); // ours keeps it
	}

	/// A slider named `name` with its number beside it, between `min` and `max` by `step`. Takes
	/// both delegates.
	public void AddSlider(StringView name, double min, double max, double step, delegate double() get, delegate void(double value) set)
	{
		let row = new Panel();
		row.AddClass("hud-row");
		let label = new Label();
		label.AddClass("hud-name");
		label.Text = name;
		row.AddChild(label);
		label.ReleaseRef();
		let field = new Panel();
		field.AddClass("slider-field");
		let slider = new Slider();
		slider.Min = min;
		slider.Max = max;
		slider.Step = step;
		let number = new NumberField();
		number.Min = min;
		number.Max = max;
		number.Step = step;
		let slide = new SliderRow();
		slide.Slider = slider;
		slide.Number = number;
		slide.Get = get;
		slide.Set = set;
		let index = mSlides.Count;
		slider.SetOnValueChanging(new [=this, =index] (value) => { Take(index, value); });
		slider.SetOnValueChanged(new [=this, =index] (value) => { Take(index, value); });
		number.SetOnValueChanged(new [=this, =index] (value) => { Take(index, value); });
		field.AddChild(slider);
		slider.ReleaseRef();
		field.AddChild(number);
		number.ReleaseRef();
		row.AddChild(field);
		field.ReleaseRef();
		mSlides.Add(slide);
		AddChild(row);
		row.ReleaseRef();
	}

	/// A check named `name`. Takes both delegates.
	public void AddCheck(StringView name, delegate bool() get, delegate void(bool on) set)
	{
		let check = new CheckBox();
		check.Text = name;
		let index = mChecks.Count;
		check.SetOnToggled(new [=this, =index] (on) =>
			{
				let owner = mChecks[index];
				if (owner.Set != null)
					owner.Set(on);
				Sync();
			});
		let row = new CheckRow();
		row.Box = check;
		row.Get = get;
		row.Set = set;
		mChecks.Add(row);
		AddChild(check);
		check.ReleaseRef();
	}

	/// A line of help (how the keys work it).
	public void AddHelp(StringView text)
	{
		let help = new String(text);
		AddNote(new [=help] (outText) => { outText.Append(help); } ~ delete help);
	}

	/// A note `text` (taken) asks again each Sync, hidden while it says nothing.
	public void AddNote(delegate void(String outText) text)
	{
		let label = new Label();
		label.AddClass("hud-help");
		let note = new NoteRow();
		note.Label = label;
		note.Text = text;
		mNotes.Add(note);
		AddChild(label);
		label.ReleaseRef();
	}

	/// Each control as the tool has it now.
	public void Sync()
	{
		for (let group in mChoices)
		{
			let chosen = (group.Get != null) ? group.Get() : -1;
			for (int i < group.Buttons.Count)
			{
				let on = i == chosen;
				if (group.Buttons[i].Checked != on)
					group.Buttons[i].Checked = on;
				let picture = group.Pictures[i];
				if ((picture.Ask != null) && !picture.Shown)
				{
					if (let drawable = picture.Ask())
					{
						picture.Image.SetDrawable(drawable);
						picture.Shown = true;
					}
				}
			}
		}
		for (let picture in mPictures)
		{
			if ((picture.Ask != null) && !picture.Shown)
			{
				if (let drawable = picture.Ask())
				{
					picture.Image.SetDrawable(drawable);
					picture.Shown = true;
				}
			}
		}
		for (let slide in mSlides)
		{
			if (slide.Get == null)
				continue;
			let value = slide.Get();
			if (slide.Slider.Value != value)
				slide.Slider.Value = value;
			if (!slide.Number.IsEditing && (slide.Number.Value != value))
				slide.Number.Value = value;
		}
		for (let check in mChecks)
		{
			if ((check.Get != null) && (check.Box.Checked != check.Get()))
				check.Box.Checked = check.Get();
		}
		let text = scope String();
		for (let note in mNotes)
		{
			text.Clear();
			if (note.Text != null)
				note.Text(text);
			if (note.Label.Text != text)
				note.Label.Text = text;
			note.Label.Displayed = !text.IsEmpty;
		}
	}

	// === For tests ===

	public Sedulous.GUI.Button ChoiceAt(int group, int index)
		=> ((group < mChoices.Count) && (index < mChoices[group].Buttons.Count)) ? mChoices[group].Buttons[index] : null;
	public int ChoiceCount(int group) => (group < mChoices.Count) ? mChoices[group].Buttons.Count : 0;
	public NumberField NumberAt(int index) => (index < mSlides.Count) ? mSlides[index].Number : null;
	public Slider SliderAt(int index) => (index < mSlides.Count) ? mSlides[index].Slider : null;
	public CheckBox CheckAt(int index) => (index < mChecks.Count) ? mChecks[index].Box : null;
	/// The `index`th shown picture's image (AddPicture's); null: none.
	public Image PictureAt(int index) => (index < mPictures.Count) ? mPictures[index].Image : null;

	private void AddHeading(StringView name)
	{
		let heading = new Label();
		heading.AddClass("hud-heading");
		heading.Text = name;
		AddChild(heading);
		heading.ReleaseRef();
	}

	private void Take(int index, double value)
	{
		let owner = mSlides[index];
		if (owner.Set != null)
			owner.Set(value);
		Sync();
	}
}
