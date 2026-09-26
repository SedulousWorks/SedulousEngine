using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The scene editor's live MCP tools, served by the editor's MCP host through the scene
/// editor's tool contribution: selection_get and selection_set, simulate_start and
/// simulate_stop, entity_inspect over an entity's reflected components and component_set
/// writing one of them through the page's undo path (one locked, labelled step per call),
/// over whichever scene or prefab page a call addresses. `page` is the scene
/// asset's guid as page_list reports it, defaulting to the active page when that is a scene
/// page; every result names the page it acted on, since several scene pages may be open, each
/// with its own selection.
static class SceneMcpTools
{
	/// How many tools Register registers; a tripwire like the page tools'.
	public const int cSceneLiveToolCount = 6;

	private const String cPageArgument = "the scene or prefab page's asset guid (default: the active page)";

	public static void Register(McpServer server, EditorContext context)
	{
		let getSchema = scope SchemaBuilder();
		getSchema.Str("page", cPageArgument);
		server.RegisterTool("selection_get",
			"A scene page's entity selection: the entities in order (the first is the primary, the gizmo pivot), each with its name. Defaults to the active page.",
			getSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				WriteSelection(page, outResult);
				return true;
			});

		let setSchema = scope SchemaBuilder();
		setSchema.Str("page", cPageArgument);
		setSchema.Arr("entities", "string", "the entity guids to select, in order", true);
		server.RegisterTool("selection_set",
			"Select entities on a scene page (an empty list clears): the hierarchy, the inspector and the gizmos follow, so this is also how to SHOW the user which entity is meant. The first guid becomes the primary. Every guid must be an entity of that page's scene. Returns the selection as selection_get does.",
			setSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let edit = (page as ISceneEditorPage).EditContext;
				let list = arguments.Get("entities");
				let ids = scope List<Guid>();
				for (int i < list.Count)
				{
					let text = list.At(i).AsString();
					Guid id;
					if (!(Guid.Parse(text) case .Ok(out id)))
					{
						outError.AppendF("invalid entity guid '{}'", text);
						return false;
					}
					if (!edit.Scene.IsValid(edit.Resolve(id)))
					{
						outError.AppendF("no entity with guid '{}' in page '{}' (scene_read shows the scene's entities)", text, page.Title);
						return false;
					}
					ids.Add(id);
				}
				edit.EntitySelection.Set(ids);
				WriteSelection(page, outResult);
				return true;
			});

		RegisterInspectAndSet(server, context);

		let startSchema = scope SchemaBuilder();
		startSchema.Str("page", cPageArgument);
		server.RegisterTool("simulate_start",
			"Start a scene page's edit-mode Simulate: the live scene runs (physics, systems) from a snapshot that simulate_stop restores; edits are locked meanwhile. A no-op when already simulating. Returns {page, simulating}.",
			startSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				(page as ISceneEditorPage).StartSimulation();
				WriteSimulation(page, outResult);
				return true;
			});

		let stopSchema = scope SchemaBuilder();
		stopSchema.Str("page", cPageArgument);
		server.RegisterTool("simulate_stop",
			"Stop a scene page's Simulate and restore the scene from its snapshot. A no-op when not simulating. Returns {page, simulating}.",
			stopSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				(page as ISceneEditorPage).StopSimulation();
				WriteSimulation(page, outResult);
				return true;
			});
	}

	private static void RegisterInspectAndSet(McpServer server, EditorContext context)
	{
		let inspectSchema = scope SchemaBuilder();
		inspectSchema.Str("page", cPageArgument);
		inspectSchema.Str("entity", "the entity's guid (default: the page's primary selection)");
		server.RegisterTool("entity_inspect",
			"An entity of a scene page as the editor's inspector sees it: guid, name, active, parent, children, the local transform, and every component the scene holds for it with its reflected fields (asset references as guids, enums by name, nested structures and lists expanded). Defaults to the page's primary selection.",
			inspectSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let edit = (page as ISceneEditorPage).EditContext;
				Guid id;
				if (!ResolveEntity(page, edit, arguments, outError, out id))
					return false;
				outResult.Set("page", PageJson(page));
				outResult.Set("entity", EntityJson(edit, id));
				return true;
			});

		let setSchema = scope SchemaBuilder();
		setSchema.Str("page", cPageArgument);
		setSchema.Str("entity", "the entity's guid (default: the page's primary selection)");
		setSchema.Str("component", "the component, as entity_inspect names it: its `type` (\"light\", \"physics.RigidBody\") or its `typeName`", true);
		setSchema.Str("property", "the field's name, as entity_inspect shows it", true);
		server.RegisterTool("component_set",
			"Set ONE reflected field of an entity's component on a scene page, through the editor's undo path: one undo step per call, labelled mcp, the page marked dirty, nothing saved (file.save or the page's Save does that). `value` takes the shape entity_inspect shows: numbers, booleans, [x,y,z] vectors, [r,g,b,a] colours, [x,y,z,w] quaternions, an enum case's name, an asset guid (or null) for a reference, an entity guid (or null) for an entity reference. REFUSED while the page simulates, on a read-only field, on a nested structure or a list (not writable here yet), and on a value of the wrong shape: nothing changes then. Returns the field as entity_inspect reads it after the write.",
			setSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let scenePage = page as ISceneEditorPage;
				if (scenePage.IsSimulating)
				{
					outError.AppendF("page '{}' is simulating - edits are locked until simulate_stop", page.Title);
					return false;
				}
				let edit = scenePage.EditContext;
				Guid id;
				if (!ResolveEntity(page, edit, arguments, outError, out id))
					return false;
				let handle = edit.Resolve(id);
				let component = scope String(arguments.Get("component")?.AsString() ?? "");
				let manager = FindComponentManager(edit.Scene, handle, component);
				if ((manager == null) || (manager.ComponentType == null))
				{
					outError.AppendF("entity '{}' has no reflected component '{}' (entity_inspect lists its components)", edit.Scene.GetEntityName(handle), component);
					return false;
				}
				let type = manager.ComponentType;
				let property = scope String(arguments.Get("property")?.AsString() ?? "");
				FieldInfo field = default;
				if (!(type.GetField(property) case .Ok(out field)) || !ComponentJson.IsShown(field))
				{
					outError.AppendF("component '{}' has no field '{}' (entity_inspect lists them)", component, property);
					return false;
				}
				if (field.HasCustomAttribute<ReadOnlyAttribute>())
				{
					outError.AppendF("field '{}' of '{}' is read-only", property, component);
					return false;
				}
				let fieldType = field.FieldType;
				let value = arguments.Get("value");

				// Shape the value first, so a refusal touches nothing; then ONE command in a
				// locked group labelled mcp - one undo step per call that neither the user's
				// scrub of the same field nor the next call merges into.
				let commands = edit.Commands;
				let before = commands.UndoIndex;
				if (ReferenceShape.Is(fieldType))
				{
					Guid target = .();
					if ((value != null) && !value.IsNull && (!value.IsString || !(Guid.Parse(value.AsString()) case .Ok(out target))))
					{
						outError.AppendF("field '{}' is a reference - `value` is an asset guid or null", property);
						return false;
					}
					commands.BeginGroup("mcp");
					edit.SetComponentReference(id, type, property, target, context.Resources);
					commands.EndGroup();
				}
				else if (fieldType.IsEnum)
				{
					int64 raw = 0;
					if (!ComponentJson.EnumValueOf(fieldType, value, out raw))
					{
						outError.AppendF("field '{}' takes one of: {}", property, ComponentJson.EnumNames(fieldType, .. scope .()));
						return false;
					}
					commands.BeginGroup("mcp");
					edit.SetComponentPropertyRaw(id, type, property, raw);
					commands.EndGroup();
				}
				else if (fieldType == typeof(EntityRef))
				{
					Guid target = .();
					if ((value != null) && !value.IsNull && (!value.IsString || !(Guid.Parse(value.AsString()) case .Ok(out target))))
					{
						outError.AppendF("field '{}' is an entity reference - `value` is an entity guid or null", property);
						return false;
					}
					commands.BeginGroup("mcp");
					edit.SetComponentEntityRef(id, type, property, target);
					commands.EndGroup();
				}
				else
				{
					let shape = ComponentJson.Shape(fieldType);
					if (shape == null)
					{
						outError.AppendF("field '{}' of '{}' is a {} - not writable through component_set yet", property, component,
							ComponentJson.IsNested(fieldType) ? (fieldType.IsObject ? "list or object" : "structure") : fieldType.GetFullName(.. scope .()));
						return false;
					}
					let leaf = ComponentJson.LeafVariant(fieldType, value);
					if (!leaf.HasValue)
					{
						outError.AppendF("field '{}' of '{}' takes {} - `value` has the wrong shape (entity_inspect shows the current value)", property, component, shape);
						return false;
					}
					commands.BeginGroup("mcp");
					edit.SetComponentProperty(id, type, property, leaf);
					commands.EndGroup();
				}
				commands.LockGroup();
				if (commands.UndoIndex == before)
				{
					outError.AppendF("field '{}' of '{}' could not be set (the command was refused; see log_read)", property, component);
					return false;
				}
				outResult.Set("page", PageJson(page));
				outResult.Set("entity", ComponentJson.GuidJson(id));
				outResult.Set("component", JsonValue.MakeString(manager.SerializationTypeId));
				outResult.Set("property", JsonValue.MakeString(property));
				outResult.Set("value", ComponentJson.ValueJson(fieldType, (uint8*)manager.GetComponentAddress(handle) + field.MemberOffset));
				outResult.Set("undoSteps", JsonValue.MakeNumber(1));
				return true;
			});
	}

	/// The entity a call addresses: `entity` when given, else the page's primary selection;
	/// false with the reason when there is neither, or no such entity in the page.
	private static bool ResolveEntity(EditorPage page, SceneEditContext edit, JsonValue arguments, String outError, out Guid outId)
	{
		outId = .();
		let entityArg = arguments.Get("entity");
		if ((entityArg != null) && entityArg.IsString)
		{
			let text = entityArg.AsString();
			if (!(Guid.Parse(text) case .Ok(out outId)))
			{
				outError.AppendF("invalid entity guid '{}'", text);
				return false;
			}
		}
		else
		{
			if (edit.EntitySelection.IsEmpty)
			{
				outError.AppendF("page '{}' has no selection - pass `entity`, or selection_set one first", page.Title);
				return false;
			}
			outId = edit.EntitySelection.Primary;
		}
		if (!edit.Scene.IsValid(edit.Resolve(outId)))
		{
			outError.AppendF("no entity with guid '{}' in page '{}' (scene_read shows the scene's entities)", outId, page.Title);
			return false;
		}
		return true;
	}

	/// The manager holding `component` for the entity: by serialization id ("light") or by the
	/// component type's name ("LightComponent").
	private static ComponentManagerBase FindComponentManager(Sedulous.Scene.Scene scene, EntityHandle entity, StringView component)
	{
		ComponentManagerBase found = null;
		scene.ForEachManager(scope [&found, &entity, &component](manager) =>
			{
				if ((found != null) || !manager.HasComponent(entity))
					return;
				let type = manager.ComponentType;
				if ((manager.SerializationTypeId == component) || ((type != null) && (type.GetName(.. scope .()) == component)))
					found = manager;
			});
		return found;
	}

	/// The entity as the agent sees it: identity, hierarchy, transform, and every component the
	/// scene holds for it with its reflected fields.
	private static JsonValue EntityJson(SceneEditContext edit, Guid id)
	{
		let scene = edit.Scene;
		let handle = edit.Resolve(id);
		let json = JsonValue.MakeObject();
		json.Set("guid", ComponentJson.GuidJson(id));
		json.Set("name", JsonValue.MakeString(scene.GetEntityName(handle)));
		json.Set("active", JsonValue.MakeBool(scene.IsActive(handle)));
		let parent = scene.GetParent(handle);
		json.Set("parent", parent.IsAssigned ? ComponentJson.GuidJson(scene.GetEntityId(parent)) : JsonValue.MakeNull());
		let children = JsonValue.MakeArray();
		for (var child = scene.GetFirstChild(handle); child.IsAssigned; child = scene.GetNextSibling(child))
			children.Add(ComponentJson.GuidJson(scene.GetEntityId(child)));
		json.Set("children", children);
		var local = scene.GetLocalTransform(handle);
		let transform = JsonValue.MakeObject();
		transform.Set("position", ComponentJson.ValueJson(typeof(Float3), &local.Position));
		transform.Set("rotation", ComponentJson.ValueJson(typeof(Quaternion), &local.Rotation));
		transform.Set("scale", ComponentJson.ValueJson(typeof(Float3), &local.Scale));
		json.Set("transform", transform);
		let components = JsonValue.MakeArray();
		scene.ForEachManager(scope [&](manager) =>
			{
				if (!manager.HasComponent(handle))
					return;
				let component = JsonValue.MakeObject();
				component.Set("type", JsonValue.MakeString(manager.SerializationTypeId));
				let type = manager.ComponentType;
				let address = manager.GetComponentAddress(handle);
				if ((type != null) && (address != null))
				{
					component.Set("typeName", JsonValue.MakeString(type.GetName(.. scope .())));
					component.Set("properties", ComponentJson.FieldsJson(type, address));
				}
				else
				{
					component.Set("properties", JsonValue.MakeNull()); // unreflected
				}
				components.Add(component);
			});
		json.Set("components", components);
		return json;
	}

	/// The scene page a call addresses: `page` (a guid) when given, else the active page; null
	/// with the reason in outError when it is not a scene page.
	private static EditorPage ResolveScenePage(EditorContext context, JsonValue arguments, String outError)
	{
		EditorPage page = null;
		let pageArg = arguments.Get("page");
		if ((pageArg != null) && pageArg.IsString)
		{
			let text = pageArg.AsString();
			Guid id;
			if (!(Guid.Parse(text) case .Ok(out id)))
			{
				outError.AppendF("invalid page guid '{}'", text);
				return null;
			}
			for (let open in context.OpenPages)
			{
				if (open.InstanceId == id)
				{
					page = open;
					break;
				}
			}
			if (page == null)
			{
				outError.AppendF("no open page for guid '{}' (page_list shows the open ones; page_open opens one)", text);
				return null;
			}
		}
		else
		{
			page = context.ActivePage;
			if (page == null)
			{
				outError.Append("no page is active - page_open a scene first, or pass `page`");
				return null;
			}
		}
		if (!(page is ISceneEditorPage))
		{
			outError.AppendF("page '{}' is not a scene or prefab page - pass `page` with a scene's guid, or page_open one", page.Title);
			return null;
		}
		return page;
	}

	private static JsonValue PageJson(EditorPage page)
	{
		let identity = JsonValue.MakeObject();
		identity.Set("guid", JsonValue.MakeString(page.InstanceId.ToString(.. scope .())));
		identity.Set("title", JsonValue.MakeString(page.Title));
		return identity;
	}

	/// The page's selection as the agent sees it: the page, the entities in order (the first
	/// is the primary, the gizmo pivot), each with its name.
	private static void WriteSelection(EditorPage page, JsonValue outResult)
	{
		let edit = (page as ISceneEditorPage).EditContext;
		let entities = JsonValue.MakeArray();
		for (let id in edit.EntitySelection.Items)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("guid", JsonValue.MakeString(id.ToString(.. scope .())));
			let handle = edit.Resolve(id);
			entry.Set("name", JsonValue.MakeString(edit.Scene.IsValid(handle) ? edit.Scene.GetEntityName(handle) : ""));
			entities.Add(entry);
		}
		outResult.Set("page", PageJson(page));
		outResult.Set("primary", edit.EntitySelection.IsEmpty ? JsonValue.MakeNull() : JsonValue.MakeString(edit.EntitySelection.Primary.ToString(.. scope .())));
		outResult.Set("entities", entities);
	}

	private static void WriteSimulation(EditorPage page, JsonValue outResult)
	{
		outResult.Set("page", PageJson(page));
		outResult.Set("simulating", JsonValue.MakeBool((page as ISceneEditorPage).IsSimulating));
	}
}
