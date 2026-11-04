using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// A scene system's settings block as a property source, for the inspector while the scene is
// selected (ruling 12; Raptor's editor-gui spec, 5.3, layer 4, part 4). A block's values are its
// own, or a profile's while it uses one (shared by every scene that does): each property shows and
// edits where the edit context says it lands (SettingsEditProfile: the profile's values, or the
// block's own for its scene-only fields, its source and profile reference). Two field sources of
// the block's type stand for the two, and each call goes to the one its property's top-level name
// lands in. Every edit is one undo step: on the block's own values the edit context's
// MutateSceneSettings, on a profile's a command that puts its values back, found again (a profile
// may move), and notes the profile edited, so the page's save writes it to the profile's asset.

class SceneSettingsSource : IPropertySource
{
	// What either field source tells reaches this one's client.
	private class Forwarder : IPropertySourceClient
	{
		private SceneSettingsSource mOwner;

		public this(SceneSettingsSource owner)
		{
			mOwner = owner;
		}

		public void OnPropertiesChanged() => mOwner.NotifyPropertiesChanged();
		public void OnValuesChanged() => mOwner.NotifyValuesChanged();
	}

	private SceneEditContext mEdit;
	private Type mType;
	private Forwarder mForwarder ~ delete _;
	// The block's own values.
	private FieldPropertySource mOwn ~ delete _;
	// A profile's, while the block uses one.
	private FieldPropertySource mProfile ~ delete _;
	private Guid mProfileId = .Empty;
	// Counts the edits, each a group of its own.
	private uint64 mEdits = 0;

	/// `edit` is borrowed and outlives it.
	public this(SceneEditContext edit, Type settingsType)
	{
		mEdit = edit;
		mType = settingsType;
		mForwarder = new .(this);
		mOwn = new FieldPropertySource(settingsType, 1,
			new [=this] (object) => mEdit.SettingsEditTarget(mType, .Empty),
			new [=this] (apply) =>
			{
				mEdit.Commands.BeginGroup(scope $"inspector.settings.{++mEdits}"); // never coalesced with the last
				mEdit.MutateSceneSettings(mType, scope [&] (system) =>
					{
						if (let values = system.SettingsInstance)
							apply(0, values);
					});
				mEdit.Commands.EndGroup();
			});
		mOwn.Client = mForwarder;
		mProfile = new FieldPropertySource(settingsType, 1,
			new [=this] (object) => mProfileId.IsNil ? null : mEdit.SettingsEditTarget(mType, mProfileId),
			new [=this] (apply) => { CommitProfile(apply); });
		mProfile.Client = mForwarder;
		Bind();
	}

	public ~this()
	{
		mOwn.Client = null;
		mProfile.Client = null;
	}

	public Type SettingsType => mType;

	/// The values found again (a block or a profile may have moved), the grid told when one changed.
	public void Refresh()
	{
		let bound = Bind(); // a profile taken or let go: the rows told already
		// Called every frame while the settings show: the grid hears of it only when a value moved.
		// Both sources are looked at, so each remembers what it showed.
		let own = mOwn.TakeChanges();
		let profile = mProfile.TakeChanges();
		if (!bound && (own || profile))
			NotifyValuesChanged();
	}

	// === IPropertySource ===

	public override int ObjectCount => 1;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		// Both stand for the same type, so the rows are the block's; their values each one's.
		if (let source = SourceOf(parent))
			source.GetProperties(parent, outInfos);
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		let source = SourceOf(path);
		return (source != null) ? source.GetValue(path, object) : .();
	}

	public override void BeginEdit(StringView path)
	{
		if (let source = SourceOf(path))
			source.BeginEdit(path);
	}

	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		if (let source = SourceOf(path))
			source.PreviewEdit(path, write);
	}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		if (let source = SourceOf(path))
			source.CommitEdit(path, write);
	}

	public override void CancelEdit(StringView path)
	{
		if (let source = SourceOf(path))
			source.CancelEdit(path);
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		let source = SourceOf(path);
		return (source != null) && source.EditList(path, edit);
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		let source = SourceOf(path);
		return (source != null) ? source.GetDefault(path, object) : .();
	}

	public override bool Revert(StringView path)
	{
		let source = SourceOf(path);
		return (source != null) && source.Revert(path);
	}

	public override void GetRevertText(StringView path, String outText)
	{
		if (let source = SourceOf(path))
			source.GetRevertText(path, outText);
	}

	public override void CopyValue(StringView path, String outText)
	{
		if (let source = SourceOf(path))
			source.CopyValue(path, outText);
	}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		let source = SourceOf(path);
		return (source != null) && source.PasteValue(path, text, reason);
	}

	// === Where an edit lands ===

	// The profile in use now, the grid told when it changed (which values each row shows may
	// have); false when it did not.
	private bool Bind()
	{
		let system = mEdit.FindSystemBySettingsType(mType);
		let profile = (system != null) ? system.SettingsProfile : Guid.Empty;
		if (profile == mProfileId)
			return false;
		mProfileId = profile;
		NotifyPropertiesChanged();
		return true;
	}

	// The source `path`'s top-level property lands in: the profile's while the block uses one,
	// else the block's own.
	private FieldPropertySource SourceOf(StringView path)
	{
		var top = path;
		let dot = top.IndexOf('.');
		if (dot >= 0)
			top = top.Substring(0, dot);
		let profile = top.IsEmpty ? Guid.Empty : mEdit.SettingsEditProfile(mType, top);
		if (!profile.IsNil && (profile == mProfileId) && (mEdit.SettingsEditTarget(mType, profile) != null))
			return mProfile;
		return (mEdit.SettingsEditTarget(mType, .Empty) != null) ? mOwn : null;
	}

	// A profile's edit, one undo step: its values before and after, put back by the command.
	private void CommitProfile(delegate void(int object, void* value) apply)
	{
		let values = mEdit.SettingsEditTarget(mType, mProfileId);
		if (values == null)
			return;
		let command = new SettingsProfileEditCommand(mEdit, mType, mProfileId);
		mProfile.ReadValues(0, command.Paths, command.Before);
		apply(0, values);
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		mProfile.ReadValues(0, paths, command.After);
		mProfile.WriteValues(0, command.Paths, command.Before); // as it was, so the command's Execute is the change
		mEdit.Commands.BeginGroup(scope $"inspector.settings.{++mEdits}"); // never coalesced with the last
		mEdit.Commands.Execute(command);
		mEdit.Commands.EndGroup();
	}
}

/// An edit of a settings profile's values in the scene's inspector: each value before and after,
/// written back into the profile's values found again, the profile noted edited each way.
class SettingsProfileEditCommand : EditorCommand
{
	public List<String> Paths = new .() ~ DeleteContainerAndItems!(_);
	public List<Sedulous.GUI.Variant> Before = new .() ~ { for (var value in ref _) value.Dispose(); delete _; };
	public List<Sedulous.GUI.Variant> After = new .() ~ { for (var value in ref _) value.Dispose(); delete _; };
	private SceneEditContext mEdit;
	private Type mType;
	private Guid mProfile;

	public this(SceneEditContext edit, Type settingsType, Guid profile)
	{
		mEdit = edit;
		mType = settingsType;
		mProfile = profile;
	}

	public override bool Execute() => Put(After);

	public override void Undo()
	{
		Put(Before);
	}

	public override StringView TypeId => "inspector_settings_profile";

	private bool Put(List<Sedulous.GUI.Variant> values)
	{
		if (mEdit.SettingsEditTarget(mType, mProfile) == null)
			return false;
		let source = scope FieldPropertySource(mType, 1,
			new [=this] (object) => mEdit.SettingsEditTarget(mType, mProfile),
			new (apply) => {});
		source.WriteValues(0, Paths, values);
		mEdit.ResolveRestoredResources(); // a reference's id written: bound to what it names
		mEdit.NoteSettingsProfileEdited(mType, mProfile);
		return true;
	}
}
