using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The scene editor's live EDITING tools: what an agent builds a level with on an open scene
/// or prefab page, each call one undo step through the page's command stack, the page dirty
/// after and nothing saved (as component_set). entity_create, entity_update, entity_delete,
/// component_add, component_remove, prefab_spawn, behavior_add and behavior_set. An entity is
/// named by guid, by name, or by slash path; every result carries the entity as entity_inspect
/// shows it. Refused while the page simulates, since Simulate's stop would discard the edit.
static class SceneMcpEditTools
{
	/// How many tools Register registers; SceneMcpTools counts them in its own tripwire.
	public const int cEditToolCount = 8;

	private const String cPage = "the scene or prefab page's asset guid (default: the active page)";
	private const String cEntity = "the entity: its guid, its name, or a slash path";

	public static void Register(McpServer server, EditorContext context)
	{
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("name", "the new entity's name", true);
			schema.Str("parent", "the entity to create it under (default: a scene root)");
			TransformArgs(schema);
			server.RegisterTool("entity_create",
				"Create an empty entity on a scene page, under `parent` or at the root, placed by `position`, `rotation` ([x, y, z, w]) or `yawDegrees`, and `scale`: one undo step. Add components with component_add and behaviours with behavior_add; place a prefab with prefab_spawn instead. Returns the entity as entity_inspect shows it.",
				schema.Build(), .Creates,
				new (arguments, outResult, outError) => Create(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("entity", cEntity, true);
			schema.Str("name", "a new name");
			schema.Str("parent", "a new parent (\"\" moves it to the root); its local transform is kept");
			schema.Boolean("active", "switch it on or off");
			TransformArgs(schema);
			server.RegisterTool("entity_update",
				"Change an entity on a scene page: its name, parent, active flag and local transform (`position`, `rotation` [x, y, z, w] or `yawDegrees`, `scale`; what is given, the rest kept). All of it one undo step. Returns the entity as entity_inspect shows it.",
				schema.Build(), .Adjusts,
				new (arguments, outResult, outError) => Update(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("entity", cEntity, true);
			server.RegisterTool("entity_delete",
				"Delete an entity and everything under it from a scene page: one undo step. Returns the deleted entity's guid.",
				schema.Build(), .Overwrites,
				new (arguments, outResult, outError) => Delete(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("entity", cEntity, true);
			schema.Str("component", "the component's wire name (\"physics.RigidBody\", \"light\"; component_schema lists them) or type name", true);
			server.RegisterTool("component_add",
				"Add a component, at its defaults, to an entity on a scene page: one undo step; component_set then writes its fields. Refused when the entity already has one. Returns the entity as entity_inspect shows it.",
				schema.Build(), .Creates,
				new (arguments, outResult, outError) => AddComponent(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("entity", cEntity, true);
			schema.Str("component", "the component, as entity_inspect names it", true);
			server.RegisterTool("component_remove",
				"Remove a component from an entity on a scene page: one undo step. Returns the entity as entity_inspect shows it.",
				schema.Build(), .Overwrites,
				new (arguments, outResult, outError) => RemoveComponent(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("prefab", "the prefab's guid (asset_list: type PrefabDocument; an imported model's is the `Prefab` beside its manifest)", true);
			schema.Str("parent", "the entity to place it under (default: a scene root)");
			TransformArgs(schema);
			server.RegisterTool("prefab_spawn",
				"Place an instance of a prefab on a scene page, under `parent` or at the root, its root at `position`, `rotation` ([x, y, z, w]) or `yawDegrees`, and `scale`: one undo step, the instance linked to its prefab as the editor's own spawn links it. Returns the instance's root as entity_inspect shows it.",
				schema.Build(), .Creates,
				new (arguments, outResult, outError) => SpawnPrefab(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("entity", cEntity, true);
			schema.Str("script", "the script class asset's guid (asset_list: type ScriptClassAsset); it must be cooked", true);
			PropertiesArg(schema);
			server.RegisterTool("behavior_add",
				"Attach a script behaviour to an entity on a scene page, adding its Script component when it has none, with `properties` set over the class's defaults: one undo step. The class must be cooked (asset_cook): its properties and their types come from the cooked class. Returns the entity as entity_inspect shows it and the behaviour's index.",
				schema.Build(), .Creates,
				new (arguments, outResult, outError) => AddBehavior(context, arguments, outResult, outError));
		}
		{
			let schema = scope SchemaBuilder();
			schema.Str("page", cPage);
			schema.Str("entity", cEntity, true);
			schema.Integer("index", "which of the entity's behaviours (default 0, the first)");
			PropertiesArg(schema);
			schema.Boolean("enabled", "switch the behaviour on or off");
			server.RegisterTool("behavior_set",
				"Set properties of a script behaviour on an entity of a scene page (its `index`, default the first), and its enabled flag: one undo step. `properties` as behavior_add takes them. Returns the entity as entity_inspect shows it.",
				schema.Build(), .Adjusts,
				new (arguments, outResult, outError) => SetBehavior(context, arguments, outResult, outError));
		}
	}

	private static void TransformArgs(SchemaBuilder schema)
	{
		schema.Arr("position", "number", "the local position [x, y, z]");
		schema.Arr("rotation", "number", "the local rotation as a quaternion [x, y, z, w]");
		schema.Number("yawDegrees", "or the local rotation as a turn about +Y, in degrees");
		schema.Arr("scale", "number", "the local scale [x, y, z]");
	}

	private static void PropertiesArg(SchemaBuilder schema)
	{
		let property = JsonValue.MakeObject();
		property.Set("type", JsonValue.MakeString("object"));
		property.Set("description", JsonValue.MakeString("the behaviour's properties by name: a number for a float or int, true/false, a string, [x, y, z] for a vector, [r, g, b, a] for a colour, an entity (guid, name or path) or null for an entity reference, an asset guid or null for an asset reference"));
		schema.Property("properties", property);
	}

	// ---- the tools ----

	private static bool Create(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		Guid parent = .();
		if (!OptionalEntity(edit, arguments, "parent", outError, out parent))
			return false;
		if (!ReadTransform(arguments, edit.Scene, Transform(), outError, let transform, let hasTransform))
			return false;
		let name = McpText(arguments, "name");
		BeginStep(edit);
		let id = edit.CreateEntity(name, parent);
		if (!id.IsNil && hasTransform)
			edit.SetLocalTransform(id, transform);
		EndStep(edit);
		if (id.IsNil)
		{
			outError.Append("the entity was not created (a parent that is gone?)");
			return false;
		}
		return Answer(context, page, edit, id, outResult);
	}

	private static bool Update(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!RequiredEntity(edit, arguments, "entity", outError, let id))
			return false;
		let handle = edit.Resolve(id);
		Guid parent = .();
		let parentArg = arguments.Get("parent");
		let moving = parentArg != null;
		if (moving && !parentArg.AsString().IsEmpty)
		{
			if (!OptionalEntity(edit, arguments, "parent", outError, out parent))
				return false;
			if ((parent == id) || edit.IsSelfOrAncestor(parent, id))
			{
				outError.Append("an entity cannot move under itself or its own descendant");
				return false;
			}
		}
		if (!ReadTransform(arguments, edit.Scene, edit.Scene.GetLocalTransform(handle), outError, let transform, let hasTransform))
			return false;
		BeginStep(edit);
		if (let nameArg = arguments.Get("name"))
			edit.RenameEntity(id, nameArg.AsString());
		if (moving)
			edit.ReparentEntity(id, parent);
		if (let active = arguments.Get("active"))
			edit.SetEntityActive(id, active.AsBool());
		if (hasTransform)
			edit.SetLocalTransform(id, transform);
		EndStep(edit);
		return Answer(context, page, edit, id, outResult);
	}

	private static bool Delete(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!RequiredEntity(edit, arguments, "entity", outError, let id))
			return false;
		BeginStep(edit);
		edit.DestroyEntity(id);
		EndStep(edit);
		outResult.Set("page", SceneMcpTools.PageJson(page));
		outResult.Set("deleted", ComponentJson.GuidJson(id));
		return true;
	}

	private static bool AddComponent(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!RequiredEntity(edit, arguments, "entity", outError, let id))
			return false;
		let name = McpText(arguments, "component");
		let manager = ManagerByName(edit.Scene, name);
		if ((manager == null) || (manager.ComponentType == null))
		{
			outError.AppendF("no component '{}' in this build (component_schema lists them by wire name)", name);
			return false;
		}
		if (manager.HasComponent(edit.Resolve(id)))
		{
			outError.AppendF("'{}' already has a {}", edit.Scene.GetEntityName(edit.Resolve(id)), name);
			return false;
		}
		BeginStep(edit);
		edit.AddComponent(id, manager.ComponentType);
		EndStep(edit);
		return Answer(context, page, edit, id, outResult);
	}

	private static bool RemoveComponent(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!RequiredEntity(edit, arguments, "entity", outError, let id))
			return false;
		let name = McpText(arguments, "component");
		let manager = SceneMcpTools.FindComponentManager(edit.Scene, edit.Resolve(id), name);
		if ((manager == null) || (manager.ComponentType == null))
		{
			outError.AppendF("'{}' has no component '{}' (entity_inspect lists its components)", edit.Scene.GetEntityName(edit.Resolve(id)), name);
			return false;
		}
		BeginStep(edit);
		edit.RemoveComponent(id, manager.ComponentType);
		EndStep(edit);
		return Answer(context, page, edit, id, outResult);
	}

	private static bool SpawnPrefab(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!McpGuid(arguments, "prefab", outError, let prefab))
			return false;
		if (prefab == page.InstanceId)
		{
			outError.Append("a prefab cannot contain an instance of itself");
			return false;
		}
		Guid parent = .();
		if (!OptionalEntity(edit, arguments, "parent", outError, out parent))
			return false;
		if (!ReadTransform(arguments, edit.Scene, Transform(), outError, let transform, let hasTransform))
			return false;
		let payload = (edit.PrefabResolver != null) ? edit.PrefabResolver(prefab) : null;
		if (payload == null)
		{
			outError.AppendF("no prefab {} with content in the project (asset_list: type PrefabDocument; a new prefab has content once written)", prefab);
			return false;
		}
		defer delete payload;
		let bytes = new List<uint8>();
		SceneEditorPage.ReadAll(payload, bytes);
		BeginStep(edit);
		let root = edit.SpawnPrefabInstance(prefab, bytes, parent, hasTransform ? transform : (Transform?)null);
		EndStep(edit);
		if (root.IsNil)
		{
			outError.AppendF("prefab {} did not spawn (log_read, category Prefab, says why)", prefab);
			return false;
		}
		return Answer(context, page, edit, root, outResult);
	}

	private static bool AddBehavior(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!RequiredEntity(edit, arguments, "entity", outError, let id))
			return false;
		if (!McpGuid(arguments, "script", outError, let script))
			return false;
		let scriptClass = CookedClass(context, script, outError);
		if (scriptClass == null)
			return false;
		// Every property checked before anything changes.
		let values = scope List<(uint64 hash, ScriptPropertyValue value)>();
		defer { for (let v in values) if (v.value.Text != null) delete v.value.Text; }
		if (!ReadProperties(edit, scriptClass, arguments.Get("properties"), values, outError))
			return false;

		let handle = edit.Resolve(id);
		let scripts = edit.FindManager(typeof(ScriptComponent));
		if (scripts == null)
		{
			outError.Append("this scene has no script components");
			return false;
		}
		BeginStep(edit);
		if (!scripts.HasComponent(handle))
			edit.AddComponent(id, typeof(ScriptComponent));
		int index = -1;
		let target = scope ComponentTarget(edit, id, typeof(ScriptComponent));
		target.Mutate(scope [&index, &script, &values](p) =>
			{
				let c = (ScriptComponent*)p;
				if (c.Behaviors == null)
					return;
				let behavior = new ScriptBehavior();
				behavior.Script = Ref<ScriptClass>(script);
				for (let v in values)
					behavior.SetOverride(v.hash, Owned(v.value));
				c.Behaviors.Add(behavior);
				index = c.Behaviors.Count - 1;
			}, "");
		EndStep(edit);
		if (index < 0)
		{
			outError.Append("the behaviour was not added (the Script component would not take it)");
			return false;
		}
		Answer(context, page, edit, id, outResult);
		outResult.Set("index", JsonValue.MakeNumber(index));
		return true;
	}

	private static bool SetBehavior(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let edit = EditablePage(context, arguments, outError, let page);
		if (edit == null)
			return false;
		if (!RequiredEntity(edit, arguments, "entity", outError, let id))
			return false;
		let handle = edit.Resolve(id);
		let scripts = edit.FindManager(typeof(ScriptComponent));
		let component = ((scripts != null) && scripts.HasComponent(handle)) ? (ScriptComponent*)scripts.GetComponentAddress(handle) : null;
		let index = (int)(arguments.Get("index")?.AsInt() ?? 0);
		if ((component == null) || (component.Behaviors == null) || (index < 0) || (index >= component.Behaviors.Count))
		{
			outError.AppendF("'{}' has no behaviour {} (entity_inspect lists its Script component's)", edit.Scene.GetEntityName(handle), index);
			return false;
		}
		let scriptClass = CookedClass(context, component.Behaviors[index].Script.Id, outError);
		if (scriptClass == null)
			return false;
		let values = scope List<(uint64 hash, ScriptPropertyValue value)>();
		defer { for (let v in values) if (v.value.Text != null) delete v.value.Text; }
		if (!ReadProperties(edit, scriptClass, arguments.Get("properties"), values, outError))
			return false;
		let enabledArg = arguments.Get("enabled");
		BeginStep(edit);
		let target = scope ComponentTarget(edit, id, typeof(ScriptComponent));
		target.Mutate(scope [&index, &values, &enabledArg](p) =>
			{
				let c = (ScriptComponent*)p;
				if ((c.Behaviors == null) || (index >= c.Behaviors.Count))
					return;
				for (let v in values)
					c.Behaviors[index].SetOverride(v.hash, Owned(v.value));
				if (enabledArg != null)
					c.Behaviors[index].Enabled = enabledArg.AsBool();
			}, "");
		EndStep(edit);
		return Answer(context, page, edit, id, outResult);
	}

	// ---- helpers ----

	/// One call is one undo step: its commands in a group, the group locked when it closes so
	/// the next call's group (the same type) does not coalesce into it.
	private static void BeginStep(SceneEditContext edit) => edit.Commands.BeginGroup("mcp");

	private static void EndStep(SceneEditContext edit)
	{
		edit.Commands.EndGroup();
		edit.Commands.LockGroup();
	}

	/// The page's edit context, when it is a scene page not simulating; null with the reason.
	private static SceneEditContext EditablePage(EditorContext context, JsonValue arguments, String outError, out EditorPage outPage)
	{
		outPage = SceneMcpTools.ResolveScenePage(context, arguments, outError);
		if (outPage == null)
			return null;
		let scenePage = outPage as ISceneEditorPage;
		if (scenePage.IsSimulating)
		{
			outError.AppendF("page '{}' is simulating - edits are locked until simulate_stop", outPage.Title);
			return null;
		}
		return scenePage.EditContext;
	}

	private static bool Answer(EditorContext context, EditorPage page, SceneEditContext edit, Guid id, JsonValue outResult)
	{
		outResult.Set("page", SceneMcpTools.PageJson(page));
		outResult.Set("entity", SceneMcpTools.EntityJson(edit.Scene, edit.Resolve(id), context.Resources));
		return true;
	}

	private static StringView McpText(JsonValue arguments, StringView key)
	{
		let v = arguments.Get(key);
		return ((v != null) && v.IsString) ? v.AsString() : "";
	}

	private static bool McpGuid(JsonValue arguments, StringView key, String outError, out Guid outId)
	{
		outId = .();
		let text = McpText(arguments, key);
		if (Guid.Parse(text) case .Ok(out outId))
			return true;
		outError.AppendF("`{}` takes a guid; '{}' is not one", key, text);
		return false;
	}

	/// An entity of the page's scene by guid, name or slash path.
	private static bool FindEntity(SceneEditContext edit, StringView text, String outError, out Guid outId)
	{
		outId = .();
		let handle = PieRunTool.FindEntity(edit.Scene, text);
		if (!edit.Scene.IsValid(handle))
		{
			outError.AppendF("no entity '{}' in scene '{}'", text, edit.Scene.Name);
			return false;
		}
		outId = edit.Scene.GetEntityId(handle);
		return true;
	}

	private static bool RequiredEntity(SceneEditContext edit, JsonValue arguments, StringView key, String outError, out Guid outId)
	{
		outId = .();
		let text = McpText(arguments, key);
		if (text.IsEmpty)
		{
			outError.AppendF("`{}` names the entity (guid, name or path)", key);
			return false;
		}
		return FindEntity(edit, text, outError, out outId);
	}

	/// Nil when absent or empty.
	private static bool OptionalEntity(SceneEditContext edit, JsonValue arguments, StringView key, String outError, out Guid outId)
	{
		outId = .();
		let text = McpText(arguments, key);
		if (text.IsEmpty)
			return true;
		return FindEntity(edit, text, outError, out outId);
	}

	/// The transform arguments over `current`; `outGiven` when any was.
	private static bool ReadTransform(JsonValue arguments, Sedulous.Scene.Scene scene, Transform current, String outError, out Transform outTransform, out bool outGiven)
	{
		outTransform = current;
		outGiven = false;
		if (let position = arguments.Get("position"))
		{
			if (!SceneMcpTools.ReadFloat3(position, out outTransform.Position))
			{
				outError.Append("`position` takes [x, y, z]");
				return false;
			}
			outGiven = true;
		}
		if (let rotation = arguments.Get("rotation"))
		{
			if (!rotation.IsArray || (rotation.Count != 4))
			{
				outError.Append("`rotation` takes a quaternion [x, y, z, w]");
				return false;
			}
			outTransform.Rotation = .((float)rotation.At(0).AsNumber(), (float)rotation.At(1).AsNumber(), (float)rotation.At(2).AsNumber(), (float)rotation.At(3).AsNumber());
			outGiven = true;
		}
		else if (let yaw = arguments.Get("yawDegrees"))
		{
			if (!yaw.IsNumber)
			{
				outError.Append("`yawDegrees` takes a number");
				return false;
			}
			outTransform.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), (float)yaw.AsNumber() * (Math.PI_f / 180.0f));
			outGiven = true;
		}
		if (let scale = arguments.Get("scale"))
		{
			if (!SceneMcpTools.ReadFloat3(scale, out outTransform.Scale))
			{
				outError.Append("`scale` takes [x, y, z]");
				return false;
			}
			outGiven = true;
		}
		return true;
	}

	/// A manager for a component name, whether or not any entity has one: by wire name or by
	/// the component type's name.
	private static ComponentManagerBase ManagerByName(Sedulous.Scene.Scene scene, StringView name)
	{
		ComponentManagerBase found = null;
		scene.ForEachManager(scope [&found, &name](manager) =>
			{
				if (found != null)
					return;
				let type = manager.ComponentType;
				if ((manager.SerializationTypeId == name) || ((type != null) && (type.GetName(.. scope .()) == name)))
					found = manager;
			});
		return found;
	}

	/// The cooked class, its properties the source of truth for a behaviour's.
	private static ScriptClass CookedClass(EditorContext context, Guid script, String outError)
	{
		let scriptClass = (context.Resources != null) ? context.Resources.Bind<ScriptClass>(script).Get : null;
		if ((scriptClass == null) || scriptClass.ClassName.IsEmpty)
			outError.AppendF("script {} is not a cooked script class (script_create, then asset_cook)", script);
		return scriptClass;
	}

	/// A value's owned copy for SetOverride, which takes the text.
	private static ScriptPropertyValue Owned(ScriptPropertyValue value)
	{
		var copy = value;
		if (value.Text != null)
			copy.Text = new String(value.Text);
		return copy;
	}

	/// Each named property's value, typed by the class's description of it.
	private static bool ReadProperties(SceneEditContext edit, ScriptClass scriptClass, JsonValue properties,
		List<(uint64 hash, ScriptPropertyValue value)> outValues, String outError)
	{
		if (properties == null)
			return true;
		if (!properties.IsObject)
		{
			outError.Append("`properties` takes an object: {\"speed\": 4}");
			return false;
		}
		for (int i < properties.Count)
		{
			let name = properties.KeyAt(i);
			let value = properties.Get(name);
			let desc = scriptClass.FindProperty(name);
			if (desc == null)
			{
				outError.AppendF("{} has no property '{}'; its properties are: ", scriptClass.ClassName, name);
				for (int p < scriptClass.Properties.Count)
					outError.AppendF("{}{}", (p > 0) ? ", " : "", scriptClass.Properties[p].Name);
				return false;
			}
			ScriptPropertyValue parsed = .();
			bool ok = false;
			switch (desc.Type)
			{
			case .Float:
				ok = value.IsNumber;
				parsed = .Float(value.AsNumber());
			case .Int:
				ok = value.IsNumber;
				parsed = .Int(value.AsInt());
			case .Bool:
				ok = value.IsBool;
				parsed = .Bool(value.AsBool());
			case .String:
				ok = value.IsString;
				if (ok)
					parsed = .Str(new String(value.AsString()));
			case .Vec3:
				ok = SceneMcpTools.ReadFloat3(value, let v);
				parsed = .Vec3(v);
			case .Color:
				ok = value.IsArray && (value.Count == 4);
				if (ok)
					parsed = .Colour(.((float)value.At(0).AsNumber(), (float)value.At(1).AsNumber(), (float)value.At(2).AsNumber(), (float)value.At(3).AsNumber()));
			case .Entity:
				if (value.IsNull)
				{
					ok = true;
					parsed = .Entity(.());
				}
				else if (value.IsString)
				{
					ok = FindEntity(edit, value.AsString(), outError, let target);
					if (!ok)
						return false;
					parsed = .Entity(target);
				}
			case .Asset:
				if (value.IsNull)
				{
					ok = true;
					parsed = .Asset(.());
				}
				else if (value.IsString && (Guid.Parse(value.AsString()) case .Ok(let asset)))
				{
					ok = true;
					parsed = .Asset(asset);
				}
			case .None:
			}
			if (!ok)
			{
				if (parsed.Text != null)
					delete parsed.Text;
				outError.AppendF("{}.{} is of type {}: the value does not fit (a number, true/false, a string, [x, y, z], [r, g, b, a], an entity or null, an asset guid or null)", scriptClass.ClassName, name, desc.Type);
				return false;
			}
			outValues.Add((desc.Hash, parsed));
		}
		return true;
	}
}
