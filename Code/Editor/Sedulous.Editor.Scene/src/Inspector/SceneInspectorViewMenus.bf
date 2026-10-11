using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// The Add Component picker, and the Paste Component button.
extension SceneInspectorView
{
	/// Add Component: a picker with a search field over every registered component the entity
	/// lacks, by category then name; the pick adds the component as one command.
	private void ShowAddComponentMenu()
	{
		let id = SelectedEntity;
		let e = mEdit.Resolve(id);
		if (!e.IsAssigned || (Context == null))
			return;

		let choices = new List<ComponentChoice>();
		mEdit.Scene.ForEachManager(scope [&](mgr) =>
		{
			let type = mgr.ComponentType;
			let registered = InspectorRegistry.Find(type);
			if ((registered == null) || mgr.HasComponent(e))
				return;
			let choice = new ComponentChoice();
			choice.Label.Set(registered.DisplayName);
			choice.Category.Set(registered.Category);
			choice.Type = type;
			if (type.GetCustomAttribute<DescriptionAttribute>() case .Ok(let description))
				choice.Description.Set(description.Text);
			choices.Add(choice);
		});
		choices.Sort(scope (a, b) =>
		{
			let byCategory = String.Compare(a.Category, b.Category, false);
			return (byCategory != 0) ? byCategory : String.Compare(a.Label, b.Label, false);
		});

		let edit = mEdit;
		let picker = new ComponentPickerDialog(choices);
		picker.OnPicked = new [=edit, =id](type) => { edit.AddComponent(id, type); };
		picker.Show(Context);
	}

	/// The clipboard can change any frame; the button shows while it holds a component.
	private void UpdatePasteButton()
	{
		if ((mPasteButton == null) || (mEditor == null))
			return;
		let hasComponent = !mEditor.ClipboardData("component").IsEmpty;
		let want = hasComponent ? Sedulous.UI.Visibility.Visible : Sedulous.UI.Visibility.Gone;
		if (mPasteButton.Visibility != want)
		{
			mPasteButton.Visibility = want;
			Invalidate();
		}
	}

	/// Pastes the clipboard's component onto the selection, confirming first when it would
	/// overwrite one already there.
	private void PasteSelectedComponent()
	{
		let id = SelectedEntity;
		let e = mEdit.Resolve(id);
		if (!e.IsAssigned || (Context == null) || (mEditor == null))
			return;
		let clip = mEditor.ClipboardData("component");
		if (clip.IsEmpty)
			return;

		let typeId = scope String();
		SceneEditContext.PeekComponentTypeId(clip, typeId);
		let mgr = mEdit.Scene.FindManagerBySerializationId(typeId);
		if ((mgr != null) && mgr.HasComponent(e))
		{
			let registered = InspectorRegistry.Find(mgr.ComponentType);
			let label = (registered != null) ? StringView(registered.DisplayName) : StringView(typeId);
			let message = scope $"This entity already has a {label} component. Pasting overwrites it (you can undo). Continue?";
			let dialog = Dialog.Confirm("Overwrite Component?", message);
			dialog.OnClosed.Add(new [=this, =id](d, result) =>
			{
				if ((result == .OK) && (mEditor != null))
					mEdit.PasteComponent(id, mEditor.ClipboardData("component"));
			});
			dialog.Show(Context);
			return;
		}
		mEdit.PasteComponent(id, clip);
	}
}
