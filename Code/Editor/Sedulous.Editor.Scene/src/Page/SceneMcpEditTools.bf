using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The scene editor's live EDITING tools: what an agent builds a level with on an open scene
/// or prefab page, each call one undo step through the page's command stack, the page dirty
/// after and nothing saved (as component_set). entity_create, entity_update, entity_delete,
/// component_add, component_remove and prefab_spawn. An entity is named by guid, by name,
/// or by slash path; every result carries the entity as entity_inspect shows it. Refused
/// while the page simulates, since Simulate's stop would discard the edit.
static class SceneMcpEditTools
{
	/// How many tools Register registers; SceneMcpTools counts them in its own tripwire.
	public const int cEditToolCount = 6;

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
				"Create an empty entity on a scene page, under `parent` or at the root, placed by `position`, `rotation` ([x, y, z, w]) or `yawDegrees`, and `scale`: one undo step. Add components (a native behaviour among them) with component_add; place a prefab with prefab_spawn instead. Returns the entity as entity_inspect shows it.",
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
	}

	private static void TransformArgs(SchemaBuilder schema)
	{
		schema.Arr("position", "number", "the local position [x, y, z]");
		schema.Arr("rotation", "number", "the local rotation as a quaternion [x, y, z, w]");
		schema.Number("yawDegrees", "or the local rotation as a turn about +Y, in degrees");
		schema.Arr("scale", "number", "the local scale [x, y, z]");
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
		outResult.Set("deleted", FieldJson.GuidJson(id));
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
		bytes.Resize(Math.Max((int)payload.Size(), 0));
		payload.Seek(0, .Begin);
		bytes.Count = Math.Max(payload.Read(Span<uint8>(bytes.Ptr, bytes.Count)), 0);
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
		let handle = ComponentJson.FindEntity(edit.Scene, text);
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
}
