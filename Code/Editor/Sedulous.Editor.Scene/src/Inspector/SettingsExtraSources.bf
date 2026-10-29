using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Physics;
using Sedulous.Script.Resource;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Script;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

// Rows of a scene settings block that reflection does not show, each a source under its block's
// section while the scene is selected (Raptor's editor-gui spec, 5.3, layer 4, part 4), registered
// by the block's type as inspector extras:
//   - the physics block's collision groups: a list of groups, each its name and the groups it
//     collides with (flags named by the groups). A pair collides both ways or neither, so a toggle
//     writes both; a new group collides with every group; only the last group is removed, as a
//     body keeps its group by index (removing another renumbers the ones after it, a remap of
//     every body this does not make). A scene without groups shows one, Default.
//   - the scene script block's level properties: its Level class's properties by their kinds, as
//     a behaviour's are (ScriptPropertyRows), each an override on the block while it differs.
// Every edit is the edit context's MutateSceneSettings: one undo step.

class CollisionGroupsSource : IPropertySource
{
	private const String cGroups = "groups";
	private const uint32 cEveryGroup = 0xFFFFFFFF;

	// A path's group (-1: none) and row ("name", "collides"; empty: the group itself).
	private struct Place
	{
		public bool List = false;
		public int Group = -1;
		public StringView Row = default;

		public this() {}
	}

	private SceneEditContext mEdit;
	private uint64 mSignature = 0;

	/// `edit` is borrowed and outlives it.
	public this(SceneEditContext edit)
	{
		mEdit = edit;
		mSignature = Signature();
	}

	/// Tells the grid when the groups changed outside it (an undo).
	public void Refresh()
	{
		let signature = Signature();
		if (signature != mSignature)
		{
			mSignature = signature;
			NotifyPropertiesChanged(); // the flags' names are the groups'
		}
		else
			NotifyValuesChanged();
	}

	// === IPropertySource ===

	public override int ObjectCount => 1;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		let count = Count();
		if (count == 0)
			return;
		if (parent.IsEmpty)
		{
			let list = new PropertyInfo();
			list.Name.Set(cGroups);
			list.DisplayName.Set("Collision Groups");
			list.Description.Set("A body's group is its index here; a pair of groups collides both ways or neither.");
			list.Kind = .List;
			list.ListOps = PropertyListAdd | PropertyListRemove;
			list.MaxCount = (uint32)PhysicsWorldSettings.CollisionGroupCount;
			outInfos.Add(list);
			return;
		}
		let place = Parse(parent);
		if (place.List)
		{
			for (int i < count)
			{
				let group = new PropertyInfo();
				i.ToString(group.Name);
				group.DisplayName.AppendF("{}: {}", i, NameOf(i, .. scope String()));
				group.Kind = .Group;
				outInfos.Add(group);
			}
			return;
		}
		if ((place.Group < 0) || (place.Group >= count) || !place.Row.IsEmpty)
			return;
		let name = new PropertyInfo();
		name.Name.Set("name");
		name.DisplayName.Set("Name");
		name.Kind = .String;
		outInfos.Add(name);
		let collides = new PropertyInfo();
		collides.Name.Set("collides");
		collides.DisplayName.Set("Collides With");
		collides.Kind = .Flags;
		for (int j < count)
			collides.AddChoice(NameOf(j, .. scope String()), (int64)(1UL << j));
		outInfos.Add(collides);
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		let place = Parse(path);
		if (place.List)
			return Sedulous.GUI.Variant((int64)Count());
		if ((place.Group < 0) || (place.Group >= Count()))
			return .();
		switch (place.Row)
		{
		case "name":
			return Sedulous.GUI.Variant(NameOf(place.Group, .. scope String())).Copy();
		case "collides":
			let shown = (Count() >= 32) ? (uint64)cEveryGroup : ((1UL << Count()) - 1);
			return Sedulous.GUI.Variant((int64)(MaskOf(place.Group) & shown));
		default:
			return .();
		}
	}

	public override void BeginEdit(StringView path) {}
	public override void PreviewEdit(StringView path, PropertyWrite write) {}
	public override void CancelEdit(StringView path) {}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		let place = Parse(path);
		if ((place.Group < 0) || (place.Group >= Count()))
			return;
		let group = place.Group;
		switch (place.Row)
		{
		case "name":
			var name = write.Value.AsString;
			name.Trim();
			Mutate(scope (settings) => { settings.GroupNames[group].Set(name); });
		case "collides":
			let value = (uint64)write.Value.AsInt;
			let mask = write.Mask;
			Mutate(scope (settings) =>
				{
					for (int other < settings.GroupCollides.Count)
					{
						if ((mask & (1UL << other)) == 0)
							continue;
						let collides = (value & (1UL << other)) != 0;
						// Both ways: the pair's two rows.
						if (collides)
						{
							settings.GroupCollides[group] |= 1u << other;
							settings.GroupCollides[other] |= 1u << group;
						}
						else
						{
							settings.GroupCollides[group] &= ~(1u << other);
							settings.GroupCollides[other] &= ~(1u << group);
						}
					}
				});
		default:
		}
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		if (!Parse(path).List)
			return false;
		let count = Count();
		switch (edit.Kind)
		{
		case .Insert:
			// At the end whatever the place asked: a body's group is its index.
			if (count >= PhysicsWorldSettings.CollisionGroupCount)
				return false;
			Mutate(scope (settings) =>
				{
					settings.GroupNames.Add(new String()..AppendF("Group {}", count));
					settings.GroupCollides.Add(cEveryGroup);
					for (var mask in ref settings.GroupCollides)
						mask |= 1u << count; // every group collides with the new one
				});
			return true;
		case .Remove:
			if ((count <= 1) || (edit.Index + 1 != count))
				return false; // only the last: the others keep their bodies' indices
			let last = count - 1;
			Mutate(scope (settings) =>
				{
					delete settings.GroupNames[last];
					settings.GroupNames.RemoveAt(last);
					settings.GroupCollides.RemoveAt(last);
					for (var mask in ref settings.GroupCollides)
						mask |= 1u << last; // a group added there later collides with everything
				});
			return true;
		default:
			return false;
		}
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object) => .();
	public override bool Revert(StringView path) => false;
	public override void GetRevertText(StringView path, String outText) {}
	public override void CopyValue(StringView path, String outText) {}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		reason.Set("A collision group does not paste");
		return false;
	}

	// === The groups ===

	private PhysicsSceneSettings Settings()
	{
		let system = mEdit.FindSystemBySettingsType(typeof(PhysicsSceneSettings));
		let values = (system != null) ? system.SettingsInstance : null;
		return (values != null) ? (PhysicsSceneSettings)Internal.UnsafeCastToObject(values) : null;
	}

	// At least one: a scene without groups has Default, colliding with everything.
	private int Count()
	{
		let settings = Settings();
		return (settings != null) ? Math.Max(1, settings.GroupNames.Count) : 0;
	}

	private void NameOf(int group, String outName)
	{
		let settings = Settings();
		if ((settings != null) && (group < settings.GroupNames.Count) && !settings.GroupNames[group].IsEmpty)
			outName.Append(settings.GroupNames[group]);
		else if (group == 0)
			outName.Append("Default");
		else
			outName.AppendF("Group {}", group);
	}

	// A group without a mask of its own collides with everything.
	private uint32 MaskOf(int group)
	{
		let settings = Settings();
		return ((settings != null) && (group < settings.GroupCollides.Count)) ? settings.GroupCollides[group] : cEveryGroup;
	}

	private uint64 Signature()
	{
		let count = Count();
		var hash = Mix(14695981039346656037UL, (uint64)count);
		for (int i < count)
			hash = Mix(hash, (uint64)NameOf(i, .. scope String()).GetHashCode());
		return hash;
	}

	private static uint64 Mix(uint64 hash, uint64 value) => (hash ^ value) &* 1099511628211UL;

	// One undo step: every group named and masked first, so an edit never leaves a row without its
	// own.
	private void Mutate(delegate void(PhysicsSceneSettings settings) mutate)
	{
		let count = Count();
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		let masks = scope List<uint32>();
		for (int i < count)
		{
			names.Add(NameOf(i, .. new String()));
			masks.Add(MaskOf(i));
		}
		mEdit.MutateSceneSettings(typeof(PhysicsSceneSettings), scope [&] (system) =>
			{
				let values = system.SettingsInstance;
				if (values == null)
					return;
				let settings = (PhysicsSceneSettings)Internal.UnsafeCastToObject(values);
				ClearAndDeleteItems(settings.GroupNames);
				for (let name in names)
					settings.GroupNames.Add(new String(name));
				settings.GroupCollides.Clear();
				settings.GroupCollides.AddRange(masks);
				mutate(settings);
			});
		Refresh();
	}

	private static Place Parse(StringView path)
	{
		var place = Place();
		if (!path.StartsWith(cGroups))
			return place;
		var rest = path.Substring(cGroups.Length);
		if (rest.IsEmpty)
		{
			place.List = true;
			return place;
		}
		if (rest[0] != '.')
			return place;
		rest = rest.Substring(1);
		var at = 0;
		var index = 0;
		while ((at < rest.Length) && rest[at].IsDigit)
			index = index * 10 + (rest[at++] - '0');
		if (at == 0)
			return place;
		place.Group = index;
		if (at + 1 < rest.Length)
			place.Row = rest.Substring(at + 1);
		return place;
	}
}

class LevelScriptSource : IPropertySource
{
	private SceneEditContext mEdit;
	// Null in a host with no editor context: the Level class is then only what is bound.
	private EditorContext mContext;
	private uint64 mSignature = 0;

	/// `edit` and `context` are borrowed and outlive it.
	public this(SceneEditContext edit, EditorContext context)
	{
		mEdit = edit;
		mContext = context;
		mSignature = Signature();
	}

	/// Tells the grid when the level's class or values changed outside it (an undo, a cook).
	public void Refresh()
	{
		let signature = Signature();
		if (signature != mSignature)
		{
			mSignature = signature;
			NotifyPropertiesChanged();
		}
		else
			NotifyValuesChanged();
	}

	// === IPropertySource ===

	public override int ObjectCount => 1;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		let type = Class();
		if (type == null)
			return;
		if (parent.IsEmpty)
		{
			ScriptPropertyRows.Describe(type, outInfos);
			return;
		}
		ScriptPropertyRows.ParseRow(parent, let row, let part);
		let property = ScriptPropertyRows.Find(type, row);
		if ((property != null) && (part < 0))
			ScriptPropertyRows.Parts(property, outInfos);
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		let type = Class();
		let settings = Settings();
		if ((type == null) || (settings == null))
			return .();
		ScriptPropertyRows.ParseRow(path, let row, let part);
		let property = ScriptPropertyRows.Find(type, row);
		if (property == null)
			return .();
		let over = settings.FindOverride(property.Hash);
		return ScriptPropertyRows.ToGrid((over != null) ? over.Value : property.Default, property.Type, part);
	}

	public override void BeginEdit(StringView path) {}
	public override void PreviewEdit(StringView path, PropertyWrite write) {}
	public override void CancelEdit(StringView path) {}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		let type = Class();
		if (type == null)
			return;
		ScriptPropertyRows.ParseRow(path, let row, let part);
		let property = ScriptPropertyRows.Find(type, row);
		if (property == null)
			return;
		let hash = property.Hash;
		let kind = property.Type;
		let fallback = property.Default;
		let value = write.Value;
		Mutate(scope (settings) =>
			{
				let over = settings.FindOverride(hash);
				settings.SetOverride(hash, ScriptPropertyRows.FromGrid((over != null) ? over.Value : fallback, kind, part, value));
			});
	}

	public override bool EditList(StringView path, ListEdit edit) => false;

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		let type = Class();
		if (type == null)
			return .();
		ScriptPropertyRows.ParseRow(path, let row, let part);
		let property = ScriptPropertyRows.Find(type, row);
		return (property != null) ? ScriptPropertyRows.ToGrid(property.Default, property.Type, part) : .();
	}

	public override bool Revert(StringView path)
	{
		let type = Class();
		if (type == null)
			return false;
		ScriptPropertyRows.ParseRow(path, let row, let part);
		let property = ScriptPropertyRows.Find(type, row);
		if (property == null)
			return false;
		let hash = property.Hash;
		Mutate(scope (settings) => { settings.RemoveOverride(hash); });
		return true;
	}

	public override void GetRevertText(StringView path, String outText) => outText.Append("Revert to the script's default");
	public override void CopyValue(StringView path, String outText) {}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		reason.Set("A level property does not paste");
		return false;
	}

	// === The level ===

	private SceneScriptSettings Settings()
	{
		let system = mEdit.FindSystemBySettingsType(typeof(SceneScriptSettings));
		let values = (system != null) ? system.SettingsInstance : null;
		return (values != null) ? (SceneScriptSettings)Internal.UnsafeCastToObject(values) : null;
	}

	// The Level class bound, through the editor's resources while the reference has not resolved.
	private ScriptClass Class()
	{
		let settings = Settings();
		if (settings == null)
			return null;
		if (settings.Script.Get != null)
			return settings.Script.Get;
		if (settings.Script.Id.IsNil || (mContext == null) || (mContext.Resources == null))
			return null;
		return mContext.Resources.Bind<ScriptClass>(settings.Script.Id).Get;
	}

	private uint64 Signature()
	{
		let settings = Settings();
		var hash = Mix(14695981039346656037UL, (settings != null) ? (uint64)settings.Script.Id.GetHashCode() : 0);
		return Mix(hash, (Class() != null) ? 1 : 0);
	}

	private static uint64 Mix(uint64 hash, uint64 value) => (hash ^ value) &* 1099511628211UL;

	private void Mutate(delegate void(SceneScriptSettings settings) mutate)
	{
		mEdit.MutateSceneSettings(typeof(SceneScriptSettings), scope [&] (system) =>
			{
				let values = system.SettingsInstance;
				if (values != null)
					mutate((SceneScriptSettings)Internal.UnsafeCastToObject(values));
			});
		Refresh();
	}
}
