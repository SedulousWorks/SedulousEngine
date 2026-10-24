using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using static Sedulous.GUI.Toolkit.Tests.ToolkitFixtures;

namespace Sedulous.GUI.Toolkit.Tests;

/// Records each call as text: "begin p", "preview p=v", "commit p=v", "commit p=v&mask", "cancel p".
class RecordingEditHost : IPropertyEditHost
{
	public List<String> Calls = new .() ~ DeleteContainerAndItems!(_);

	public void BeginPropertyEdit(StringView path)
	{
		Calls.Add(new String()..AppendF("begin {}", path));
	}

	public void PreviewPropertyEdit(StringView path, PropertyWrite write)
	{
		let value = scope String();
		write.Value.ToString(value);
		Calls.Add(new String()..AppendF("preview {}={}", path, value));
	}

	public void CommitPropertyEdit(StringView path, PropertyWrite write)
	{
		let value = scope String();
		write.Value.ToString(value);
		if (write.Mask == ~(uint64)0)
			Calls.Add(new String()..AppendF("commit {}={}", path, value));
		else
			Calls.Add(new String()..AppendF("commit {}={}&{}", path, value, write.Mask));
	}

	public void CancelPropertyEdit(StringView path)
	{
		Calls.Add(new String()..AppendF("cancel {}", path));
	}

	public bool EditPropertyList(StringView path, ListEdit edit)
	{
		Calls.Add(new String()..AppendF("list {} {} {}", path, (int)edit.Kind, edit.Index));
		return true;
	}

	public void GetChildProperties(StringView path, List<PropertyInfo> outInfos) { }

	public PropertyValue ReadPropertyValue(StringView path, PropertyKind kind) => .();

	public StringView Last => Calls.IsEmpty ? StringView() : (StringView)Calls.Back;

	public void Clear()
	{
		ClearAndDeleteItems!(Calls);
	}
}

/// A root 400 by 300 whose editors the bed holds, a host recording their calls. The root goes with
/// it, and the editors and infos it made.
class EditorBed
{
	public SceneRoot Root ~ _.ReleaseRef();
	public RecordingEditHost Host = new .() ~ delete _;
	private List<Node> mMade = new .() ~ { for (let node in _) node.ReleaseRef(); delete _; };
	private List<PropertyInfo> mInfos = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		Root = NewRoot(400.0f, 300.0f);
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
	}

	public T Editor<T>(PropertyInfo info, PropertyValue value, StringView path = "p") where T : PropertyEditor, new
	{
		let editor = new T();
		editor.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(160.0f);
				s.Height = LayoutLength.Px(24.0f);
			});
		Root.AddChild(editor);
		mMade.Add(editor);
		editor.Bind(Host, path, info, value);
		Root.UpdateLayout();
		return editor;
	}

	/// An info of `kind` named "p", held by the bed.
	public PropertyInfo Info(PropertyKind kind)
	{
		let info = new PropertyInfo();
		info.Name.Set("p");
		info.Kind = kind;
		mInfos.Add(info);
		return info;
	}

	public EventDispatcher D => Root.EventDispatcher;

	public static uint32 K(KeyCode k) => (uint32)k;

	public void Click(Float2 at)
	{
		D.InjectMouseMove(at);
		D.InjectMouseDown(at, .Left);
		D.InjectMouseUp(at, .Left);
		Root.UpdateLayout();
	}

	public static PropertyValue Value(Sedulous.GUI.Variant value, bool mixed = false)
	{
		var result = PropertyValue();
		result.Value = value;
		result.Mixed = mixed;
		return result;
	}

	public static Float2 Centre(Node node)
	{
		let r = node.ScreenBounds;
		return .(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f);
	}
}

/// The property grid's editors: chosen by hint, then kind, else a row saying none fits; each shows a
/// value or the mixed state, and edits as a gesture (a scrub previewed and committed on release or
/// cancelled by Escape; a click, a pick or a typed value committed at once; a flag written alone,
/// through its mask).
class PropertyEditorTests
{
	[Test]
	public static void ChosenByHintThenKindElseARowThatSaysNoneFits()
	{
		let registry = scope PropertyEditorRegistry();
		RegisterDefaultPropertyEditors(registry);
		let bed = scope EditorBed();
		let info = bed.Info(.Float);
		let number = registry.Choose(info);
		Test.Assert(number != PropertyEditorRegistry.cNoEditor);
		let made = registry.Create(number);
		Test.Assert(made is NumberPropertyEditor);
		made.ReleaseRef();

		info.Hint.Set("slider"); // no editor takes the hint: the kind's does
		Test.Assert(registry.Choose(info) == number);
		let before = registry.Generation;
		registry.RegisterHint("slider", new () => new BoolPropertyEditor());
		Test.Assert(registry.Generation != before);
		let slider = registry.Choose(info);
		Test.Assert(slider != number);
		let sliderMade = registry.Create(slider);
		Test.Assert(sliderMade is BoolPropertyEditor);
		sliderMade.ReleaseRef();

		info.Kind = .Group;
		info.Hint.Set("curve");
		Test.Assert(registry.Choose(info) == PropertyEditorRegistry.cNoEditor);
		let unknown = bed.Editor<UnknownPropertyEditor>(info, .());
		Test.Assert(unknown.Message == "No editor for curve");
		info.Hint.Clear();
		unknown.Bind(bed.Host, "p", info, .());
		Test.Assert(unknown.Message == "No editor for group");
	}

	[Test]
	public static void ABoolShowsMixedAsIndeterminateAndAClickCommitsAtOnce()
	{
		let bed = scope EditorBed();
		let editor = bed.Editor<BoolPropertyEditor>(bed.Info(.Bool), EditorBed.Value(Sedulous.GUI.Variant(false), true), "visible");
		Test.Assert(editor.CheckBox.Indeterminate);
		bed.Click(EditorBed.Centre(editor.CheckBox));
		Test.Assert(bed.Host.Calls.Count == 2);
		Test.Assert(bed.Host.Calls[0] == "begin visible");
		Test.Assert(bed.Host.Calls[1] == "commit visible=true");

		let locked = bed.Info(.Bool);
		locked.ReadOnly = true;
		editor.Bind(bed.Host, "visible", locked, EditorBed.Value(Sedulous.GUI.Variant(true)));
		bed.Click(EditorBed.Centre(editor.CheckBox));
		Test.Assert(bed.Host.Calls.Count == 2); // read only: nothing
	}

	[Test]
	public static void ANumbersScrubPreviewsCommitsOnReleaseOrCancelsOnEscape()
	{
		let bed = scope EditorBed();
		let info = bed.Info(.Float);
		info.HasRange = true;
		info.Min = 0.0;
		info.Max = 1000.0;
		info.Step = 1.0;
		let editor = bed.Editor<NumberPropertyEditor>(info, EditorBed.Value(Sedulous.GUI.Variant(10.0)), "speed");
		let field = editor.Field;
		CheckNear(field.Value, 10.0);
		Test.Assert(!field.StepsOnWheel); // the grid scrolls

		let centre = EditorBed.Centre(field);
		let at = Float2(centre.X - 40.0f, centre.Y);
		bed.D.InjectMouseDown(at, .Left);
		bed.D.InjectMouseMove(.(at.X + 20.0f, at.Y)); // five steps
		bed.D.InjectMouseMove(.(at.X + 40.0f, at.Y)); // ten
		bed.D.InjectMouseUp(.(at.X + 40.0f, at.Y), .Left);
		Test.Assert(bed.Host.Calls.Count == 4);
		Test.Assert(bed.Host.Calls[0] == "begin speed");
		Test.Assert(bed.Host.Calls[1] == "preview speed=15");
		Test.Assert(bed.Host.Calls[2] == "preview speed=20");
		Test.Assert(bed.Host.Calls[3] == "commit speed=20");

		bed.Host.Clear();
		bed.D.InjectMouseDown(at, .Left);
		bed.D.InjectMouseMove(.(at.X + 20.0f, at.Y));
		bed.D.InjectKeyDown(EditorBed.K(.Escape));
		bed.D.InjectMouseUp(.(at.X + 20.0f, at.Y), .Left);
		Test.Assert(bed.Host.Calls.Count == 3);
		Test.Assert(bed.Host.Last == "cancel speed");
		CheckNear(field.Value, 20.0);
	}

	[Test]
	public static void AnIntegerWritesWholeNumbersMixedShowsThePlaceholder()
	{
		let bed = scope EditorBed();
		let editor = bed.Editor<NumberPropertyEditor>(bed.Info(.Integer), EditorBed.Value(Sedulous.GUI.Variant((int64)3), true), "count");
		let field = editor.Field;
		Test.Assert(field.IsMixed);
		Test.Assert(field.Text.Length == 0);
		Test.Assert(field.Placeholder == MixedValueText());
		field.RequestFocus();
		bed.D.InjectKeyDown(EditorBed.K(.Up)); // a step from mixed sets them all
		Test.Assert(bed.Host.Calls.Count == 3);
		Test.Assert(bed.Host.Calls[1] == "preview count=4");
		Test.Assert(bed.Host.Calls[2] == "commit count=4");
	}

	[Test]
	public static void TextCommitsOnReturnAndEscapePutsBackWhatItHad()
	{
		let bed = scope EditorBed();
		let editor = bed.Editor<StringPropertyEditor>(bed.Info(.String), EditorBed.Value(Sedulous.GUI.Variant("Lamp")), "name");
		let field = editor.Field;
		Test.Assert(field.Text == "Lamp");
		field.RequestFocus();
		field.SelectAll();
		bed.D.InjectText("Torch");
		bed.D.InjectKeyDown(EditorBed.K(.Escape));
		Test.Assert(field.Text == "Lamp");
		Test.Assert(bed.Host.Calls.IsEmpty);
		field.SelectAll();
		bed.D.InjectText("Torch");
		bed.D.InjectKeyDown(EditorBed.K(.Return));
		Test.Assert(bed.Host.Calls.Count == 2);
		Test.Assert(bed.Host.Calls[1] == "commit name=Torch");

		editor.Bind(bed.Host, "name", bed.Info(.String), EditorBed.Value(Sedulous.GUI.Variant("Lamp"), true));
		Test.Assert(field.Text.Length == 0);
		Test.Assert(field.Placeholder == MixedValueText());
	}

	[Test]
	public static void AnEnumPicksAmongItsChoicesMixedSelectsNone()
	{
		let bed = scope EditorBed();
		let info = bed.Info(.Enum);
		info.AddChoice("Point", 0);
		info.AddChoice("Spot", 2);
		info.AddChoice("Area", 5);
		let editor = bed.Editor<EnumPropertyEditor>(info, EditorBed.Value(Sedulous.GUI.Variant((int64)2)), "type");
		let combo = editor.ComboBox;
		Test.Assert(combo.ItemCount == 3);
		Test.Assert(combo.SelectedIndex == 1);
		Test.Assert(bed.Host.Calls.IsEmpty); // showing is not editing

		combo.SelectByUser(2);
		Test.Assert(bed.Host.Calls.Count == 2);
		Test.Assert(bed.Host.Calls[1] == "commit type=5");

		editor.Bind(bed.Host, "type", info, EditorBed.Value(Sedulous.GUI.Variant((int64)2), true));
		Test.Assert(combo.SelectedIndex == -1);
		Test.Assert(combo.Placeholder == MixedValueText());
		Test.Assert(bed.Host.Calls.Count == 2);
	}

	[Test]
	public static void FlagsNameWhatIsSetAndWriteOneFlagAloneADifferingFlagIsIndeterminate()
	{
		let bed = scope EditorBed();
		let info = bed.Info(.Flags);
		info.AddChoice("Cast", 1);
		info.AddChoice("Receive", 2);
		info.AddChoice("Static", 4);
		var value = EditorBed.Value(Sedulous.GUI.Variant((int64)0b001));
		let editor = bed.Editor<FlagsPropertyEditor>(info, value, "shadows");
		Test.Assert(editor.Button.Text == "Cast");
		value.MixedBits = 0b010;
		value.Mixed = true;
		editor.Bind(bed.Host, "shadows", info, value);
		Test.Assert(editor.Button.Text == MixedValueText());

		bed.Click(EditorBed.Centre(editor.Button));
		Test.Assert(editor.List != null);
		Test.Assert(editor.GetFlagBox(0).Checked);
		Test.Assert(editor.GetFlagBox(1).Indeterminate);
		Test.Assert(!editor.GetFlagBox(2).Checked);
		bed.Click(EditorBed.Centre(editor.GetFlagBox(2)));
		Test.Assert(bed.Host.Calls.Count == 2);
		Test.Assert(bed.Host.Calls[1] == "commit shadows=4&4");
		Test.Assert(editor.List != null); // open for the next

		value.MixedBits = 0;
		value.Mixed = false;
		value.Value = Sedulous.GUI.Variant((int64)0);
		editor.Bind(bed.Host, "shadows", info, value);
		Test.Assert(editor.Button.Text == "None");
	}

	[Test]
	public static void AColoursPickerPreviewsItsDragsAndCommitsOnceOnClosingOrCancelsOnEscape()
	{
		let bed = scope EditorBed();
		let info = bed.Info(.Color);
		let editor = bed.Editor<ColorPropertyEditor>(info, EditorBed.Value(Sedulous.GUI.Variant(Color(1.0f, 0.0f, 0.0f, 1.0f))), "tint");
		Test.Assert(editor.HexField.Text == "#FF0000");
		Test.Assert(editor.Picker == null);
		bed.Click(EditorBed.Centre(editor.Swatch));
		let picker = editor.Picker;
		Test.Assert(picker != null);
		CheckNear(picker.ColorValue.R, 1.0f);
		Test.Assert(bed.Host.Calls.IsEmpty); // opening is not editing

		// Two steps of the plane: begun, previewed twice; still open, nothing committed.
		let plane = picker.Plane;
		let r = plane.ScreenBounds;
		bed.D.InjectMouseDown(.(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f), .Left);
		bed.D.InjectMouseUp(.(r.X + r.Width * 0.5f, r.Y + r.Height * 0.5f), .Left);
		Test.Assert(bed.Host.Calls.Count == 3);
		Test.Assert(bed.Host.Calls[0] == "begin tint");
		Test.Assert(StringView(bed.Host.Calls[1]).Substring(0, 13) == "preview tint=");
		// Closed (a press elsewhere): committed once.
		bed.D.ClosePopup(editor.Picker.Parent);
		Test.Assert(bed.Host.Calls.Count == 4);
		Test.Assert(bed.Host.Last.Substring(0, 12) == "commit tint=");

		// Escape gives the pick up.
		bed.Host.Clear();
		bed.Click(EditorBed.Centre(editor.Swatch));
		Test.Assert(editor.Picker != null);
		bed.D.InjectMouseDown(.(r.X + 5.0f, r.Y + 5.0f), .Left);
		bed.D.InjectMouseUp(.(r.X + 5.0f, r.Y + 5.0f), .Left);
		bed.D.InjectKeyDown(EditorBed.K(.Escape));
		Test.Assert(editor.Picker == null);
		Test.Assert(bed.Host.Last == "cancel tint");
	}

	[Test]
	public static void AColoursHexFieldCommitsWhatIsTypedMixedIsHatchedWithoutAlphaNoneShows()
	{
		let bed = scope EditorBed();
		let info = bed.Info(.Color);
		info.ShowsAlpha = false;
		let editor = bed.Editor<ColorPropertyEditor>(info, EditorBed.Value(Sedulous.GUI.Variant(Color(0.0f, 0.0f, 1.0f, 0.5f))), "tint");
		Test.Assert(editor.HexField.Text == "#0000FF"); // no alpha shown
		let hex = editor.HexField;
		hex.RequestFocus();
		hex.SelectAll();
		bed.D.InjectText("#00FF0080");
		bed.D.InjectKeyDown(EditorBed.K(.Return));
		Test.Assert(bed.Host.Calls.Count == 2);
		Test.Assert(bed.Host.Calls[1] == "commit tint=#00FF00FF"); // its alpha left out

		editor.Bind(bed.Host, "tint", info, EditorBed.Value(Sedulous.GUI.Variant(Color()), true));
		Test.Assert(editor.Swatch.IsMixed);
		Test.Assert(editor.HexField.Placeholder == MixedValueText());
	}

	[Test]
	public static void AColoursRowShowsThePickAsItGoesAndThePickersChannelFieldsHaveRoom()
	{
		let bed = scope EditorBed();
		let editor = bed.Editor<ColorPropertyEditor>(bed.Info(.Color), EditorBed.Value(Sedulous.GUI.Variant(Color(1.0f, 0.0f, 0.0f, 1.0f))), "tint");
		bed.Click(EditorBed.Centre(editor.Swatch));
		let picker = editor.Picker;
		Test.Assert(picker != null);
		bed.Root.UpdateLayout();
		let r = picker.Plane.ScreenBounds;
		bed.D.InjectMouseDown(.(r.X + 2.0f, r.Y + 2.0f), .Left); // near white
		Test.Assert(editor.HexField.Text != "#FF0000");
		Test.Assert(editor.HexField.Text == picker.HexField.Text);
		bed.D.InjectMouseUp(.(r.X + 2.0f, r.Y + 2.0f), .Left);
		for (int32 i = 0; i < 4; ++i)
			Test.Assert(picker.GetChannelField(i).ScreenBounds.Width >= 44.0f); // "255" beside its arrows
	}

	// What no Raptor test covers: a list's row says its count and adds at its end; the kinds' names.
	[Test]
	public static void AListsRowSaysItsCountAndAddsAtItsEndAndTheKindsHaveNames()
	{
		let bed = scope EditorBed();
		let info = bed.Info(.List);
		info.ListOps = PropertyListAdd;
		info.MaxCount = 4;
		let editor = bed.Editor<ListPropertyEditor>(info, EditorBed.Value(Sedulous.GUI.Variant((int64)3)), "tags");
		Test.Assert(editor.CountLabel.Text == "3 elements");
		Test.Assert(editor.AddButton.Enabled);
		bed.Click(EditorBed.Centre(editor.AddButton));
		Test.Assert(bed.Host.Last == "list tags 0 3");
		editor.Bind(bed.Host, "tags", info, EditorBed.Value(Sedulous.GUI.Variant((int64)1)));
		Test.Assert(editor.CountLabel.Text == "1 element");
		editor.Bind(bed.Host, "tags", info, EditorBed.Value(Sedulous.GUI.Variant((int64)4)));
		Test.Assert(!editor.AddButton.Enabled); // at its most
		Test.Assert(PropertyKindName(.Color) == "colour");
		Test.Assert(PropertyKindName(.Flags) == "flags");
	}
}
