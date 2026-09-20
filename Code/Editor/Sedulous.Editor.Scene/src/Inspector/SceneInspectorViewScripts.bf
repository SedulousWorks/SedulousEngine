using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Script.Resource;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Engine.Script;

namespace Sedulous.Editor.Scene;

/// The script rows: a component's behaviors, each with its class, enabled flag, update
/// interval, ordering, and the class's properties as override rows; and the level script's
/// property rows on the Scene tab.
extension SceneInspectorView
{
	private ScriptComponent* LiveScript(Guid id)
	{
		let e = mEdit.Resolve(id);
		let manager = mEdit.Scene.GetSystem<ScriptComponentManager>();
		return ((manager != null) && e.IsAssigned) ? manager.Get(e) : null;
	}

	/// An in place edit of the script component as one undo step, through the paste path.
	private void MutateScriptComponent(Guid id, delegate void(ScriptComponent* c) mutate)
	{
		let target = scope ComponentTarget(mEdit, id, typeof(ScriptComponent));
		target.Mutate(scope [=mutate](p) => { mutate((ScriptComponent*)p); });
	}

	/// The behavior's class, bound or reached through the resource manager.
	private ScriptClass BehaviorClass(ScriptBehavior behavior)
	{
		if (behavior.Script.Get != null)
			return behavior.Script.Get;
		if (behavior.Script.Id.IsNil || (mEditor.Resources == null))
			return null;
		return mEditor.Resources.Bind<ScriptClass>(behavior.Script.Id).Get;
	}

	/// What a rebuild watches: the behavior count, each class id, flag and override count.
	private static uint64 ScriptBehaviorsSignature(ScriptComponent* c)
	{
		var hash = (uint64)c.Behaviors.Count;
		for (let b in c.Behaviors)
		{
			hash = (hash &* 0x9E3779B97F4A7C15UL) ^ (uint64)b.Script.Id.GetHashCode();
			let flags = (b.Enabled ? 1UL : 0UL) | ((uint64)b.Overrides.Count << 1);
			hash = (hash &* 0x9E3779B97F4A7C15UL) ^ flags;
		}
		return hash;
	}

	private void BuildScriptBehaviors(Guid id, StringView category)
	{
		let component = LiveScript(id);
		if (component == null)
			return;

		for (int i < component.Behaviors.Count)
			BuildScriptBehaviorRows(id, category, i);

		let add = new ButtonEditor("+ Add Behavior", new [=this, =id]() =>
		{
			MutateScriptComponent(id, scope (c) => { c.Behaviors.Add(new ScriptBehavior()); });
		}, category);
		mGrid.AddProperty(add);

		// A hidden row whose refresher asks for a rebuild when the behaviors' shape changes.
		let signature = ScriptBehaviorsSignature(component);
		let watcher = new ButtonEditor("", new () => {}, category);
		watcher.SetRowVisible(false);
		AddEditor(watcher, new [=this, =id, =signature]() =>
		{
			let c = LiveScript(id);
			if ((c != null) && (ScriptBehaviorsSignature(c) != signature))
				mForceRebuild = true;
		});
	}

	private void BuildScriptBehaviorRows(Guid id, StringView category, int index)
	{
		let component = LiveScript(id);
		if ((component == null) || (index >= component.Behaviors.Count))
			return;
		let behavior = component.Behaviors[index];

		let assetName = behavior.Script.Id.IsNil ? "(none)" : AssetNameFor(behavior.Script.Id, .. scope .());
		let picker = new ResourceRefEditor("Script", assetName, category);
		picker.OnPick = new [=this, =id, =index]() =>
		{
			if ((Context == null) || (mEditor.Project == null))
				return;
			let dialog = new AssetPickerDialog(mEditor, scope StringView[]("ScriptClassAsset"));
			dialog.OnPicked = new [=this, =id, =index](picked) =>
			{
				MutateScriptComponent(id, scope [=index, =picked](c) =>
				{
					if (index >= c.Behaviors.Count)
						return;
					c.Behaviors[index].Script = Ref<ScriptClass>(picked);
					ClearAndDeleteItems(c.Behaviors[index].Overrides); // the metadata changed
				});
			};
			dialog.Show(Context);
		};
		AddEditor(picker, new [=this, =id, =index, =picker]() =>
		{
			let c = LiveScript(id);
			if ((c == null) || (index >= c.Behaviors.Count))
				return;
			let target = c.Behaviors[index].Script.Id;
			picker.SetValueText(target.IsNil ? "(none)" : AssetNameFor(target, .. scope .()));
		});

		let enabled = new BoolEditor("Enabled", behavior.Enabled, new [=this, =id, =index](value) =>
		{
			MutateScriptComponent(id, scope [=index, =value](c) =>
			{
				if (index < c.Behaviors.Count)
					c.Behaviors[index].Enabled = value;
			});
		}, category);
		mGrid.AddProperty(enabled);

		let interval = new FloatEditor("Update Interval", behavior.UpdateInterval, 0.0, 3600.0, 0.05, 3,
			new [=this, =id, =index](value) =>
			{
				MutateScriptComponent(id, scope [=index, =value](c) =>
				{
					if (index < c.Behaviors.Count)
						c.Behaviors[index].UpdateInterval = (float)((value < 0.0) ? 0.0 : value);
				});
			}, category);
		interval.SetTooltip("Seconds between onUpdate calls (0 = every frame)");
		mGrid.AddProperty(interval);

		let up = new ButtonEditor("Move Up", new [=this, =id, =index]() =>
		{
			MutateScriptComponent(id, scope [=index](c) =>
			{
				if ((index > 0) && (index < c.Behaviors.Count))
					Swap!(c.Behaviors[index], c.Behaviors[index - 1]);
			});
		}, category);
		up.SetButtonEnabled(index > 0);
		mGrid.AddProperty(up);

		let remove = new ButtonEditor("Remove Behavior", new [=this, =id, =index]() =>
		{
			MutateScriptComponent(id, scope [=index](c) =>
			{
				if (index < c.Behaviors.Count)
				{
					delete c.Behaviors[index];
					c.Behaviors.RemoveAt(index);
				}
			});
		}, category);
		mGrid.AddProperty(remove);

		let scriptClass = BehaviorClass(behavior);
		if (scriptClass == null)
			return;
		for (let property in scriptClass.Properties)
		{
			let hash = property.Hash;
			let access = new ScriptPropertyAccess();
			Keep(access);
			access.Effective = new [=this, =id, =index, =hash, =property]() =>
			{
				let c = LiveScript(id);
				if ((c != null) && (index < c.Behaviors.Count))
				{
					if (let over = c.Behaviors[index].FindOverride(hash))
						return over.Value;
				}
				return property.Default;
			};
			access.SetOverride = new [=this, =id, =index, =hash](value) =>
			{
				MutateScriptComponent(id, scope [=index, =hash, =value](c) =>
				{
					if (index < c.Behaviors.Count)
						c.Behaviors[index].SetOverride(hash, value);
				});
			};
			access.RemoveOverride = new [=this, =id, =index, =hash]() =>
			{
				MutateScriptComponent(id, scope [=index, =hash](c) =>
				{
					if (index < c.Behaviors.Count)
						c.Behaviors[index].RemoveOverride(hash);
				});
			};
			BuildScriptPropertyRow(category, property, access);
		}
	}

	private void BuildScriptPropertyRow(StringView category, ScriptPropertyDesc property,
		ScriptPropertyAccess access)
	{
		let name = property.Name;
		switch (property.Type)
		{
		case .Float:
			let editor = new FloatEditor(name, access.Effective().Number, -1e9, 1e9, 0.1, 3,
				new [=access](v) => { access.SetOverride(ScriptPropertyValue.Float(v)); }, category);
			if (!property.Description.IsEmpty)
				editor.SetTooltip(property.Description);
			AddEditor(editor, new [=access, =editor]() => { editor.SetValue(access.Effective().Number); });
		case .Int:
			let editor = new IntEditor(name, (int64)access.Effective().Number, int64.MinValue, int64.MaxValue,
				new [=access](v) => { access.SetOverride(ScriptPropertyValue.Int(v)); }, category);
			if (!property.Description.IsEmpty)
				editor.SetTooltip(property.Description);
			AddEditor(editor, new [=access, =editor]() => { editor.SetValue((int64)access.Effective().Number); });
		case .Bool:
			let editor = new BoolEditor(name, access.Effective().Boolean,
				new [=access](v) => { access.SetOverride(ScriptPropertyValue.Bool(v)); }, category);
			if (!property.Description.IsEmpty)
				editor.SetTooltip(property.Description);
			AddEditor(editor, new [=access, =editor]() => { editor.SetValue(access.Effective().Boolean); });
		case .String:
			let text = access.Effective().Text;
			let editor = new StringEditor(name, (text != null) ? StringView(text) : StringView(),
				new [=access](v) => { access.SetOverride(ScriptPropertyValue.Str(new String(v))); }, category);
			if (!property.Description.IsEmpty)
				editor.SetTooltip(property.Description);
			AddEditor(editor, new [=access, =editor]() =>
			{
				let now = access.Effective().Text;
				editor.SetValue((now != null) ? StringView(now) : StringView());
			});
		case .Color:
			let editor = new ColorEditor(name, access.Effective().Color,
				new [=access](v) => { access.SetOverride(ScriptPropertyValue.Colour(v)); }, category);
			if (!property.Description.IsEmpty)
				editor.SetTooltip(property.Description);
			AddEditor(editor, new [=access, =editor]() => { editor.SetValue(access.Effective().Color); });
		case .Vec3:
			let editor = new Float3Editor(name, access.Effective().Vector, -1e9f, 1e9f, 0.1f,
				new [=access](v) => { access.SetOverride(ScriptPropertyValue.Vec3(v)); }, category);
			if (!property.Description.IsEmpty)
				editor.SetTooltip(property.Description);
			AddEditor(editor, new [=access, =editor]() => { editor.SetValue(access.Effective().Vector); });
		case .Entity:
			BuildScriptEntityPropertyRow(category, property, access);
		case .Asset:
			BuildScriptAssetPropertyRow(category, property, access);
		default:
		}
	}

	private void EntityNameFor(Guid target, String outName)
	{
		if (target.IsNil)
		{
			outName.Set("(none)");
			return;
		}
		let h = mEdit.Scene.FindEntity(target);
		outName.Set(h.IsAssigned ? mEdit.Scene.GetEntityName(h) : "(missing)");
	}

	/// An entity valued script property: picked from a menu of every entity.
	private void BuildScriptEntityPropertyRow(StringView category, ScriptPropertyDesc property,
		ScriptPropertyAccess access)
	{
		let editor = new ResourceRefEditor(property.Name, EntityNameFor(access.Effective().Id, .. scope .()), category);
		if (!property.Description.IsEmpty)
			editor.SetTooltip(property.Description);
		editor.OnPick = new [=this, =access]() =>
		{
			if (Context == null)
				return;
			let menu = new ContextMenu();
			defer menu.ReleaseRef();
			menu.AddItem("(none)", new [=access]() => { access.RemoveOverride(); });
			menu.AddSeparator();
			mEdit.Scene.ForEachEntity(scope [&](handle) =>
			{
				let target = mEdit.Scene.GetEntityId(handle);
				menu.AddItem(mEdit.Scene.GetEntityName(handle), new [=access, =target]() =>
				{
					access.SetOverride(ScriptPropertyValue.Entity(target));
				});
			});
			let pos = mAddButton.LocalToScreen(.(0.0f, 0.0f));
			menu.Show(Context, pos.X, pos.Y);
		};
		AddEditor(editor, new [=this, =access, =editor]() =>
		{
			editor.SetValueText(EntityNameFor(access.Effective().Id, .. scope .()));
		});
	}

	/// An asset valued script property: picked from the browser, narrowed to the declared
	/// asset type.
	private void BuildScriptAssetPropertyRow(StringView category, ScriptPropertyDesc property,
		ScriptPropertyAccess access)
	{
		let assetType = new String(property.AssetType);
		Keep(assetType);
		let editor = new ResourceRefEditor(property.Name, AssetNameFor(access.Effective().Id, .. scope .()), category);
		if (!property.Description.IsEmpty)
			editor.SetTooltip(property.Description);
		editor.OnPick = new [=this, =access, =assetType]() =>
		{
			if ((Context == null) || (mEditor.Project == null))
				return;
			let typeName = scope String(assetType);
			typeName.Append("Asset");
			let dialog = new AssetPickerDialog(mEditor, scope StringView[](typeName));
			dialog.OnPicked = new [=access](picked) => { access.SetOverride(ScriptPropertyValue.Asset(picked)); };
			dialog.Show(Context);
		};
		AddEditor(editor, new [=this, =access, =editor]() =>
		{
			editor.SetValueText(AssetNameFor(access.Effective().Id, .. scope .()));
		});
	}

	/// The level script's properties as override rows on the settings block.
	private void BuildSceneScriptPropertyRows(Type settingsType, StringView category)
	{
		let edit = mEdit;
		let system = edit.FindSystemBySettingsType(settingsType);
		if (system == null)
			return;
		let live = (SceneScriptSettings)Internal.UnsafeCastToObject(system.SettingsInstance);

		var scriptClass = live.Script.Get;
		if ((scriptClass == null) && !live.Script.Id.IsNil && (mEditor.Resources != null))
			scriptClass = mEditor.Resources.Bind<ScriptClass>(live.Script.Id).Get;
		if (scriptClass == null)
			return; // no Level bound, or not yet cooked: nothing to author

		for (let property in scriptClass.Properties)
		{
			let hash = property.Hash;
			let access = new ScriptPropertyAccess();
			Keep(access);
			access.Effective = new [=edit, =settingsType, =hash, =property]() =>
			{
				if (let s = edit.FindSystemBySettingsType(settingsType))
				{
					let now = (SceneScriptSettings)Internal.UnsafeCastToObject(s.SettingsInstance);
					if (let over = now.FindOverride(hash))
						return over.Value;
				}
				return property.Default;
			};
			access.SetOverride = new [=edit, =settingsType, =hash](value) =>
			{
				let target = scope SettingsTarget(edit, settingsType);
				target.Mutate(scope [=hash, =value](p) =>
				{
					((SceneScriptSettings)Internal.UnsafeCastToObject(p)).SetOverride(hash, value);
				});
			};
			access.RemoveOverride = new [=edit, =settingsType, =hash]() =>
			{
				let target = scope SettingsTarget(edit, settingsType);
				target.Mutate(scope [=hash](p) =>
				{
					((SceneScriptSettings)Internal.UnsafeCastToObject(p)).RemoveOverride(hash);
				});
			};
			BuildScriptPropertyRow(category, property, access);
		}
	}
}
