using System;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// Rows an editor's grid shows besides values (Raptor's editor-gui spec, 5.3, layer 4, part 3), each
// a property of a source the editor fills (a PropertyBag), chosen by its hint:
//   - a notice (`notice`): its value is what it says, wrapped, styled as a warning (a rigid body
//     with a cooked shape and no collision shape: it has no collider);
//   - an action (`action`): a button its value names; a click commits the row as it is, so whoever
//     keeps the source runs the action on that commit (a zone's Bake).
// The editor's: only the editor uses them; they move to GUI.Toolkit if something else needs them.

class NoticePropertyEditor : SingleControlEditor
{
	public const String cHint = "notice";

	private Label mText ~ _.ReleaseRef();

	public this()
	{
		AddClass("notice");
		mText = new Label();
		mText.AddClass("notice-text");
		Hold(mText);
	}

	public StringView Text => mText.Text;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mText.Text = value.Value.AsString;
	}
}

class ActionPropertyEditor : SingleControlEditor
{
	public const String cHint = "action";

	private Sedulous.GUI.Button mButton ~ _.ReleaseRef();
	private String mLabel = new .() ~ delete _;

	public this()
	{
		AddClass("action");
		mButton = new Sedulous.GUI.Button();
		mButton.SetOnClick(new () => { Run(); });
		Hold(mButton);
	}

	public Sedulous.GUI.Button Button => mButton;

	/// Runs it, as a click does: the row committed as it is.
	public void Run()
	{
		AddRef(); // the action may rebuild the grid
		defer ReleaseRef();
		if (!IsReadOnly)
			ApplyEdit(PropertyWrite(Sedulous.GUI.Variant(mLabel)));
	}

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		mLabel.Set(value.Value.AsString);
		mButton.Text = mLabel;
		mButton.Tooltip = info.Description;
		mButton.Enabled = !IsReadOnly;
	}
}

static class PropertyExtras
{
	/// Notices and actions in `registry`'s grid, by their hints.
	public static void Register(PropertyEditorRegistry registry)
	{
		registry.RegisterHint(NoticePropertyEditor.cHint, new () => new NoticePropertyEditor());
		registry.RegisterHint(ActionPropertyEditor.cHint, new () => new ActionPropertyEditor());
	}
}
