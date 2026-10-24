using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.GUI;

namespace Sedulous.GUI.Tests;

/// An editable label "layer 1", 120 by 24, beside a focusable panel, counting what it commits. The
/// root and the tree go with it.
class EditableBed
{
	public SceneRoot Root = SceneFixtures.NewScene(300.0f, 200.0f) ~ _.ReleaseRef();
	public EditableLabel Editable = new .() ~ _.ReleaseRef();
	public Panel Other = new .() ~ _.ReleaseRef();
	public int Commits = 0;
	public int ChangeEvents = 0;

	public this()
	{
		Root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		Editable.Text = "layer 1";
		Editable.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(120.0f);
				s.Height = LayoutLength.Px(24.0f);
			});
		Root.AddChild(Editable);
		Other.TabFocusable = true;
		Other.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(20.0f);
				s.Height = LayoutLength.Px(20.0f);
			});
		Root.AddChild(Other);
		Root.UpdateLayout();
		Editable.SetOnTextCommitted(new (text) => { ++Commits; });
		Editable.AddEventListener(.Changed, new (e) => { ++ChangeEvents; });
	}

	public EventDispatcher D => Root.EventDispatcher;

	public void Key(KeyCode k)
	{
		D.InjectKeyDown((uint32)k);
	}

	public void Retype(StringView text)
	{
		Editable.Editor.Model.SelectAll();
		D.InjectText(text);
	}
}

/// EditableLabel: edited in place by a double click or F2, committed by Return or focus leaving,
/// cancelled by Escape, refused by a validator, kept editing through its field's context menu, and
/// multiline in a text area whose lines its box follows.
class EditableLabelTests
{
	private static bool Near(float a, float b) => TextFixtures.Near(a, b);

	[Test]
	public static void ADoubleClickEditsItInPlaceAllSelectedReturnCommits()
	{
		let b = scope EditableBed();
		b.D.InjectMouseDown(.(20.0f, 12.0f), .Left);
		b.D.InjectMouseUp(.(20.0f, 12.0f), .Left);
		Test.Assert(!b.Editable.IsEditing); // one click: no
		b.D.InjectMouseDown(.(20.0f, 12.0f), .Left);
		b.D.InjectMouseUp(.(20.0f, 12.0f), .Left);
		Test.Assert(b.Editable.IsEditing);
		let editor = b.Editable.Editor;
		Test.Assert(editor.IsFocused);
		Test.Assert(editor.Text == "layer 1");
		b.Root.UpdateLayout();
		Test.Assert(Near(editor.Size.X, 120.0f)); // over its whole box

		b.D.InjectText("sky"); // all selected: replaced
		b.Key(.Return);
		Test.Assert(!b.Editable.IsEditing);
		Test.Assert(b.Editable.Text == "sky");
		Test.Assert(b.Editable.IsFocused); // the label keeps the focus
		Test.Assert(b.Commits == 1);
		Test.Assert(b.ChangeEvents == 1);
	}

	[Test]
	public static void ItsFieldsTextLiesWhereTheLabelsWasTheFieldsPaddingReachingPastIt()
	{
		let b = scope EditableBed();
		b.Editable.Padding = .(2.0f, 3.0f, 2.0f, 3.0f);
		b.Editable.BeginEdit();
		let editor = b.Editable.Editor;
		Test.Assert(editor != null);
		editor.Padding = .(6.0f, 6.0f, 6.0f, 6.0f);
		b.Root.UpdateLayout();
		// A label 24 tall, its content 18: the field's content as tall, not 24 less its padding.
		let content = b.Editable.ContentBounds;
		let field = editor.ContentBounds;
		Test.Assert(Near(editor.Position.X + field.X, content.X));
		Test.Assert(Near(editor.Position.Y + field.Y, content.Y));
		Test.Assert(Near(field.Width, content.Width));
		Test.Assert(Near(field.Height, 18.0f));
		Test.Assert(Near(editor.Size.Y, 30.0f));
	}

	[Test]
	public static void ItsFieldsContextMenuKeepsItEditingTheSelectionThereToCut()
	{
		let b = scope EditableBed();
		b.Editable.BeginEdit();
		let editor = b.Editable.Editor;
		Test.Assert(editor != null);
		editor.Model.Select(.(0, 5)); // "layer"
		b.D.InjectMouseDown(.(20.0f, 12.0f), .Right);
		b.D.InjectMouseUp(.(20.0f, 12.0f), .Right);
		Test.Assert(editor.ContextMenu != null);
		Test.Assert(editor.ContextMenu.IsOpen);
		Test.Assert(b.Editable.IsEditing);
		Test.Assert(editor.SelectedText == "layer");
		Test.Assert(b.Commits == 0);
		// Cut, from the menu: the field has the focus back, still editing.
		let cut = editor.ContextMenu.GetChildAt(0) as MenuItem;
		Test.Assert(cut != null);
		cut.HandleActivate();
		Test.Assert(!editor.ContextMenu.IsOpen);
		Test.Assert(b.Editable.IsEditing);
		Test.Assert(editor.IsFocused);
		Test.Assert(editor.Text == " 1");
	}

	[Test]
	public static void F2EditsItEscapeCancelsFocusLeavingCommits()
	{
		let b = scope EditableBed();
		b.Editable.RequestFocus();
		b.Key(.F2);
		Test.Assert(b.Editable.IsEditing);
		b.Retype("gone");
		b.Key(.Escape);
		Test.Assert(!b.Editable.IsEditing);
		Test.Assert(b.Editable.Text == "layer 1");
		Test.Assert(b.Commits == 0);

		b.Key(.F2);
		b.Retype("kept");
		b.Other.RequestFocus();
		Test.Assert(!b.Editable.IsEditing);
		Test.Assert(b.Editable.Text == "kept");
		Test.Assert(b.Other.IsFocused); // focus stays where it went
		Test.Assert(b.Commits == 1);
	}

	[Test]
	public static void AValidatorKeepsReturnEditingAndFocusLeavingPutsTheOldTextBack()
	{
		let b = scope EditableBed();
		b.Editable.SetValidator(new (text) => text.Length != 0);
		b.Editable.BeginEdit();
		b.Retype("");
		b.D.InjectKeyDown((uint32)KeyCode.Delete); // empty it
		b.Key(.Return);
		Test.Assert(b.Editable.IsEditing);
		Test.Assert(b.Editable.Editor.HasClass("invalid"));
		b.Other.RequestFocus();
		Test.Assert(!b.Editable.IsEditing);
		Test.Assert(b.Editable.Text == "layer 1");
		Test.Assert(b.Commits == 0);
	}

	[Test]
	public static void MultilineItEditsInATextAreaReturnBreaksALineCtrlReturnCommitsItsBoxFollowingTheLines()
	{
		let font = scope CachedFont(new MockFont(), null);
		let root = SceneFixtures.NewScene(300.0f, 200.0f);
		defer root.ReleaseRef();
		let label = new EditableLabel();
		defer label.ReleaseRef();
		root.EditLayoutStyle(scope (s) => { s.AlignItems = .Start; });
		label.Font = font;
		label.IsMultiline = true;
		Test.Assert(label.GetTextStyle().WhiteSpace == .PreWrap);
		Test.Assert(label.TextAlignV == .Top);
		label.Text = "note";
		label.EditLayoutStyle(scope (s) => { s.Width = LayoutLength.Px(120.0f); });
		root.AddChild(label);
		let committed = scope String();
		label.SetOnTextCommitted(new [&] (text) => { committed.Set(text); });
		root.UpdateLayout();
		Test.Assert(Near(label.Size.Y, 12.0f));

		label.BeginEdit();
		Test.Assert(label.Editor is TextArea);
		let d = root.EventDispatcher;
		label.Editor.Model.SelectAll();
		d.InjectText("one");
		d.InjectKeyDown((uint32)KeyCode.Return);
		d.InjectText("two");
		d.InjectKeyDown((uint32)KeyCode.Return);
		Test.Assert(label.IsEditing);
		Test.Assert(label.Text == "note"); // the label's text until it commits
		root.UpdateLayout();
		// Three lines typed (the last empty), the box and the area's text as tall.
		Test.Assert(Near(label.Size.Y, 36.0f));
		Test.Assert(Near(label.Editor.ContentBounds.Height, 36.0f));

		d.InjectKeyDown((uint32)KeyCode.Return, KeyModCtrl);
		Test.Assert(!label.IsEditing);
		Test.Assert(label.Text == "one\ntwo\n");
		Test.Assert(committed == "one\ntwo\n");
		root.UpdateLayout();
		Test.Assert(Near(label.Size.Y, 36.0f));

		// Escape puts it back, the box shrinking to the old lines.
		label.BeginEdit();
		label.Editor.Text = "a\nb\nc\nd";
		root.UpdateLayout();
		Test.Assert(Near(label.Size.Y, 48.0f));
		d.InjectKeyDown((uint32)KeyCode.Escape);
		Test.Assert(!label.IsEditing);
		root.UpdateLayout();
		Test.Assert(Near(label.Size.Y, 36.0f));

		// A text area alone submits on Ctrl+Return too.
		let area = new TextArea();
		defer area.ReleaseRef();
		root.AddChild(area);
		int submits = 0;
		area.SetOnSubmit(new [&] (text) => { ++submits; });
		area.RequestFocus();
		d.InjectKeyDown((uint32)KeyCode.Return, KeyModCtrl);
		Test.Assert(submits == 1);
		Test.Assert(area.Text.Length == 0);
	}
}
