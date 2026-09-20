using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// The Add Component menu, grouped by category, and the Paste Component button.
extension SceneInspectorView
{
	private class MenuEntry
	{
		public String Label = new .() ~ delete _;
		public String Category = new .() ~ delete _;
		public Type Type = null;
	}

	private void ShowAddComponentMenu()
	{
		let id = SelectedEntity;
		let e = mEdit.Resolve(id);
		if (!e.IsAssigned || (Context == null))
			return;

		let edit = mEdit;
		let menu = new ContextMenu();
		defer menu.ReleaseRef();

		// Every registered component the entity lacks, sorted by category then label.
		let entries = scope List<MenuEntry>();
		defer { ClearAndDeleteItems(entries); }
		mEdit.Scene.ForEachManager(scope [&](mgr) =>
		{
			let type = mgr.ComponentType;
			let registered = InspectorRegistry.Find(type);
			if ((registered == null) || mgr.HasComponent(e))
				return;
			let entry = new MenuEntry();
			entry.Label.Set(registered.DisplayName);
			entry.Category.Set(registered.Category);
			entry.Type = type;
			entries.Add(entry);
		});
		entries.Sort(scope (a, b) =>
		{
			let byCategory = String.Compare(a.Category, b.Category, false);
			return (byCategory != 0) ? byCategory : String.Compare(a.Label, b.Label, false);
		});

		ContextMenu section = null;
		let sectionName = scope String();
		for (let entry in entries)
		{
			if ((section == null) || (entry.Category != sectionName))
			{
				let item = menu.AddSubmenu(entry.Category);
				section = item.Submenu;
				sectionName.Set(entry.Category);
			}
			if (section != null)
			{
				let type = entry.Type;
				section.AddItem(entry.Label, new [=edit, =id, =type]() => { edit.AddComponent(id, type); });
			}
		}
		let screenPos = mAddButton.LocalToScreen(.(0.0f, 0.0f));
		menu.Show(Context, screenPos.X, screenPos.Y);
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
