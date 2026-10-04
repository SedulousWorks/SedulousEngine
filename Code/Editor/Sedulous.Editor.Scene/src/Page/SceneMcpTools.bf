using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;
using Sedulous.Editor.Camera;
using Sedulous.Core.IO;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;
using Sedulous.Engine.Navigation;
using Sedulous.Editor.Navigation;

namespace Sedulous.Editor.Scene;

/// The scene editor's live MCP tools, served by the editor's MCP host through the scene
/// editor's tool contribution: selection_get and selection_set, simulate_start and
/// simulate_stop, navigation_bake, entity_inspect over an entity's reflected components and component_set
/// writing one of them through the page's undo path (one locked, labelled step per call),
/// over whichever scene or prefab page a call addresses. `page` is the scene
/// asset's guid as page_list reports it, defaulting to the active page when that is a scene
/// page; every result names the page it acted on, since several scene pages may be open, each
/// with its own selection.
static class SceneMcpTools
{
	/// How many tools Register registers; a tripwire like the page tools'.
	public const int cSceneLiveToolCount = 10 + SceneMcpEditTools.cEditToolCount;

	private const String cPageArgument = "the scene or prefab page's asset guid (default: the active page)";

	public static void Register(McpServer server, EditorContext context)
	{		SceneMcpEditTools.Register(server, context);

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
		RegisterViewportTools(server, context);
		RegisterNavigationBake(server, context);

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

	/// navigation_bake: the inspector's Bake Navigation button for an agent, which could author
	/// a zone but not bake it.
	private static void RegisterNavigationBake(McpServer server, EditorContext context)
	{
		let schema = scope SchemaBuilder();
		schema.Str("page", cPageArgument);
		schema.Str("entity", "the zone's entity: a guid, a name or a slash path (default: the scene's only navigation zone)");
		server.RegisterTool("navigation_bake",
			"Bake a scene page's navigation zone, as the inspector's Bake Navigation button does: collect the static geometry inside the zone's box (static, non-trigger rigid bodies and terrain; render meshes are not read) and write the navmesh into the zone's Navigation Zone asset (the zone component's `Zone`; assign one first, with component_set). `entity` names the zone's entity; without it, the scene's only zone. The scene is not changed; cook (asset_cook) for the game to see the new navmesh. Refused while the page simulates. Returns {page, entity, asset, baked, triangles, message}: baked false with the reason when nothing walkable came out.",
			schema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let scenePage = page as ISceneEditorPage;
				if (scenePage.IsSimulating)
				{
					outError.AppendF("page '{}' is simulating: stop it (simulate_stop) before baking", page.Title);
					return false;
				}
				if (context.Project == null)
				{
					outError.Append("no project is open");
					return false;
				}
				let edit = scenePage.EditContext;
				let scene = edit.Scene;
				let zones = scene.GetSystem<NavMeshZoneComponentManager>();
				EntityHandle zoneEntity = .Invalid;
				if (arguments.Has("entity"))
				{
					if (!ResolveEntity(page, edit, arguments, outError, let id))
						return false;
					zoneEntity = edit.Resolve(id);
					if ((zones == null) || (zones.Get(zoneEntity) == null))
					{
						outError.AppendF("'{}' has no navigation zone component", arguments.Get("entity").AsString());
						return false;
					}
				}
				else
				{
					int count = 0;
					if (zones != null)
					{
						for (let owner in zones.Owners)
						{
							zoneEntity = owner;
							count++;
						}
					}
					if (count != 1)
					{
						outError.AppendF("page '{}' has {} navigation zones: name one with `entity`", page.Title, count);
						return false;
					}
				}
				let zone = zones.Get(zoneEntity);
				let target = zone.Zone.Id.IsNil ? null : context.Project.SourceDb.GetInstance(zone.Zone.Id);
				if (target == null)
				{
					outError.Append("the zone has no Navigation Zone asset: create one (asset_create) and set it as the zone component's `Zone` (component_set) before baking");
					return false;
				}
				scene.UpdateTransforms();
				let result = NavigationBake.BakeNavigationZone(scene, zoneEntity, target,
					NavigationEditorPreferences.ParallelBakeEnabled(context));
				outResult.Set("page", PageJson(page));
				outResult.Set("entity", JsonValue.MakeString(scene.GetEntityId(zoneEntity).ToString(.. scope .())));
				outResult.Set("asset", JsonValue.MakeString(zone.Zone.Id.ToString(.. scope .())));
				outResult.Set("baked", JsonValue.MakeBool(result.Baked));
				outResult.Set("triangles", JsonValue.MakeNumber(result.TriangleCount));
				outResult.Set("message", JsonValue.MakeString(NavigationBake.DescribeBake(result, .. scope .())));
				return true;
			});
	}

	private static void RegisterInspectAndSet(McpServer server, EditorContext context)
	{
		let inspectSchema = scope SchemaBuilder();
		inspectSchema.Str("page", cPageArgument);
		inspectSchema.Str("pie", "instead of a page: a running PIE instance's id (pie_list), reading the scene that game is in");
		inspectSchema.Str("entity", "the entity: a guid, a name or a slash path (default: the page's primary selection; with `pie`, required)");
		server.RegisterTool("entity_inspect",
			"An entity of a scene page as the editor's inspector sees it: guid, name, active, parent, children, the local transform, and every component the scene holds for it with its reflected fields (asset references as guids, enums by name, nested structures and lists expanded). Defaults to the page's primary selection. With `pie`, the entity as the running game has it now, in that instance's current scene.",
			inspectSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				if (arguments.Has("pie"))
					return InspectPie(context, arguments, outResult, outError);
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let edit = (page as ISceneEditorPage).EditContext;
				Guid id;
				if (!ResolveEntity(page, edit, arguments, outError, out id))
					return false;
				outResult.Set("page", PageJson(page));
				outResult.Set("entity", EntityJson(edit.Scene, edit.Resolve(id), context.Resources));
				return true;
			});

		let setSchema = scope SchemaBuilder();
		setSchema.Str("page", cPageArgument);
		setSchema.Str("entity", "the entity: a guid, a name or a slash path (default: the page's primary selection)");
		setSchema.Str("component", "the component, as entity_inspect names it: its `type` (\"light\", \"physics.RigidBody\") or its `typeName`", true);
		setSchema.Str("property", "the field's name, as entity_inspect shows it", true);
		server.RegisterTool("component_set",
			"Set ONE reflected field of an entity's component on a scene page, through the editor's undo path: one undo step per call, labelled mcp, the page marked dirty, nothing saved (file.save or the page's Save does that). `value` takes the shape entity_inspect shows: numbers, booleans, strings, guids, [x,y] and [x,y,z] vectors, [r,g,b,a] colours (sRGB, as a colour picker shows them), [x,y,z,w] quaternions, an enum case's name or number, an asset guid (or null) for a reference, an entity guid (or null) for an entity reference. REFUSED while the page simulates, on a read-only field, on a nested structure or a list (not writable here yet), and on a value of the wrong shape: nothing changes then. Returns the field as entity_inspect reads it after the write.",
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
				else if (fieldType == typeof(String))
				{
					if ((value == null) || !value.IsString)
					{
						outError.AppendF("field '{}' of '{}' takes a string - `value` has the wrong shape (entity_inspect shows the current value)", property, component);
						return false;
					}
					let address = (uint8*)manager.GetComponentAddress(handle) + field.MemberOffset;
					if (*(String*)address == null)
					{
						outError.AppendF("field '{}' of '{}' holds no string to set (its component never allocated one)", property, component);
						return false;
					}
					commands.BeginGroup("mcp");
					edit.SetComponentString(id, type, property, value.AsString());
					commands.EndGroup();
				}
				else
				{
					let shape = ComponentJson.Shape(fieldType);
					if (shape == null)
					{
						let kind = ComponentJson.NestedKind(fieldType);
						if (kind == "list")
							outError.AppendF("field '{}' of '{}' is a list - not writable through component_set yet (scene_write edits the source)", property, component);
						else if (!kind.IsEmpty)
							outError.AppendF("field '{}' of '{}' is a {} - not writable through component_set yet (scene_write edits the source)", property, component, kind);
						else
							outError.AppendF("field '{}' of '{}' is a {} - not writable through component_set yet", property, component, fieldType.GetFullName(.. scope .()));
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

	/// One viewport_screenshot in flight: the tool is re-entered every pump with the same
	/// arguments until the page reports the capture written, or it gives up.
	private class PendingCapture
	{
		/// BORROWED; null while nothing is in flight.
		public EditorPage Page = null;
		public int Pumps = 0;
		/// Per host, so two captures of one page never share a default name.
		public int Serial = 0;
	}

	/// Frames: ten seconds at 60 Hz, then the tool gives up.
	private const int cCapturePumpLimit = 600;

	private static void RegisterViewportTools(McpServer server, EditorContext context)
	{
		let getSchema = scope SchemaBuilder();
		getSchema.Str("page", cPageArgument);
		server.RegisterTool("viewport_camera_get",
			"The pose a scene page's viewport looks from: the editor camera's position, yaw and pitch in degrees (yaw 0 looks down -Z, positive pitch looks up), its forward vector and its orbit focus distance. Defaults to the active page.",
			getSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let camera = (page as ISceneEditorPage).ViewportCamera;
				if (camera == null)
				{
					outError.AppendF("page '{}' has no viewport", page.Title);
					return false;
				}
				WriteCamera(page, camera, outResult);
				return true;
			});

		let setSchema = scope SchemaBuilder();
		setSchema.Str("page", cPageArgument);
		setSchema.Arr("position", "number", "the camera position [x, y, z]");
		setSchema.Number("yawDegrees", "rotation about the up axis; 0 looks down -Z");
		setSchema.Number("pitchDegrees", "tilt; positive looks up, clamped short of straight up or down");
		setSchema.Arr("lookAt", "number", "the point [x, y, z] to aim at from the position");
		server.RegisterTool("viewport_camera_set",
			"Move a scene page's viewport camera - to look at something from somewhere specific before a viewport_screenshot, or to show the user a spot. Sets what is given: `position` ([x, y, z]), then `yawDegrees` and `pitchDegrees`, then `lookAt` ([x, y, z]: aims from the position at that point, horizon level, and moves the orbit focus there; it wins over yaw and pitch). Nothing given changes nothing. Returns the pose as viewport_camera_get does. Editor state only: no scene edit, no undo step.",
			setSchema.Build(), .Adjusts,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
					return false;
				let camera = (page as ISceneEditorPage).ViewportCamera;
				if (camera == null)
				{
					outError.AppendF("page '{}' has no viewport", page.Title);
					return false;
				}
				// Shape everything first: a refusal changes nothing.
				Float3 position = .Zero;
				Float3 lookAt = .Zero;
				let hasPosition = arguments.Has("position");
				let hasLookAt = arguments.Has("lookAt");
				if (hasPosition && !ReadFloat3(arguments.Get("position"), out position))
				{
					outError.Append("`position` takes [x, y, z]");
					return false;
				}
				if (hasLookAt && !ReadFloat3(arguments.Get("lookAt"), out lookAt))
				{
					outError.Append("`lookAt` takes [x, y, z]");
					return false;
				}
				let yaw = arguments.Get("yawDegrees");
				let pitch = arguments.Get("pitchDegrees");
				if (((yaw != null) && !yaw.IsNumber) || ((pitch != null) && !pitch.IsNumber))
				{
					outError.Append("`yawDegrees` and `pitchDegrees` take a number");
					return false;
				}
				if (hasPosition)
					camera.Position = position;
				if (yaw != null)
					camera.Yaw = DegreesToRadians((float)yaw.AsNumber());
				if (pitch != null)
				{
					// Short of the poles, as the mouse look is, so the up vector stays defined.
					camera.Pitch = System.Math.Clamp(DegreesToRadians((float)pitch.AsNumber()), -EditorCamera.cPitchLimit, EditorCamera.cPitchLimit);
				}
				if (hasLookAt)
					camera.LookAt(lookAt);
				WriteCamera(page, camera, outResult);
				return true;
			});

		let shotSchema = scope SchemaBuilder();
		shotSchema.Str("page", cPageArgument);
		shotSchema.Str("path", "the PNG to write (default: a new file under <user-data>/screenshots)");
		let pending = new PendingCapture();
		server.RegisterTool("viewport_screenshot",
			"What a scene page's viewport renders, as a PNG file at the viewport's size: the scene from the editor camera (viewport_camera_set moves it) with what the viewport draws into its image - the grid, the entity markers, the selection's gizmo, the active tool's hint text, the frame rate readout. Panels docked over the viewport are not in it. Brings the page to front (a hidden viewport never renders), waits for the next frame and the GPU, then returns {page, path, width, height}; read the file. `path` is where to write (an existing directory; default: <user-data>/screenshots/<page>-<pid>-<n>.png). Gives up after ten seconds without a rendered frame.",
			shotSchema.Build(), .Creates,
			new (arguments, outResult, outError) =>
			{
				let page = ResolveScenePage(context, arguments, outError);
				if (page == null)
				{
					pending.Page = null;
					return .Failed;
				}
				let scene = page as ISceneEditorPage;
				if (pending.Page == page)
				{
					// Re-entered: the same call, one pump later.
					let capture = scene.LastViewportCapture;
					pending.Pumps++;
					if (capture.State == .Written)
					{
						outResult.Set("page", PageJson(page));
						outResult.Set("path", JsonValue.MakeString(capture.Path));
						outResult.Set("width", JsonValue.MakeNumber(capture.Width));
						outResult.Set("height", JsonValue.MakeNumber(capture.Height));
						pending.Page = null;
						return .Answered;
					}
					if (capture.State == .Failed)
					{
						pending.Page = null;
						outError.AppendF("the capture of page '{}' failed (log_read, category Screenshot, says why)", page.Title);
						return .Failed;
					}
					if (pending.Pumps > cCapturePumpLimit)
					{
						pending.Page = null;
						outError.AppendF("page '{}' rendered no frame in ten seconds - is its viewport visible (an editor window minimised or hidden)?", page.Title);
						return .Failed;
					}
					return .NotFinished;
				}
				if (scene.ViewportCamera == null)
				{
					outError.AppendF("page '{}' has no viewport", page.Title);
					return .Failed;
				}
				let path = scope String();
				let pathArg = arguments.Get("path");
				if ((pathArg != null) && pathArg.IsString)
					path.Set(pathArg.AsString());
				if (path.IsEmpty)
				{
					let directory = scope String();
					PathJoin(GetUserDataDirectory(.. scope .()), "screenshots", directory);
					if (!CreateDirectory(directory))
					{
						outError.AppendF("could not create '{}'", directory);
						return .Failed;
					}
					pending.Serial++;
					PathJoin(directory, scope $"{FileStemOf(page.Title, .. scope .())}-{System.Diagnostics.Process.CurrentId}-{pending.Serial}.png", path);
				}
				context.RevealPage(page); // to front: a background tab's viewport never renders
				if (scene.RequestViewportCapture(path) case .Err)
				{
					outError.AppendF("page '{}' has no viewport", page.Title);
					return .Failed;
				}
				pending.Page = page;
				pending.Pumps = 0;
				return .NotFinished;
			}, pending);
	}

	private static void WriteCamera(EditorPage page, EditorCamera camera, JsonValue outResult)
	{
		outResult.Set("page", PageJson(page));
		outResult.Set("position", ComponentJson.ValueJson(typeof(Float3), &camera.Position));
		outResult.Set("yawDegrees", JsonValue.MakeNumber(RadiansToDegrees(camera.Yaw)));
		outResult.Set("pitchDegrees", JsonValue.MakeNumber(RadiansToDegrees(camera.Pitch)));
		var forward = camera.Forward;
		outResult.Set("forward", ComponentJson.ValueJson(typeof(Float3), &forward));
		outResult.Set("focusDistance", JsonValue.MakeNumber(camera.FocusDistance));
	}

	public static bool ReadFloat3(JsonValue value, out Float3 outValue)
	{
		outValue = .Zero;
		if ((value == null) || !value.IsArray || (value.Count != 3))
			return false;
		for (int i < 3)
		{
			if (!value.At(i).IsNumber)
				return false;
		}
		outValue = .((float)value.At(0).AsNumber(), (float)value.At(1).AsNumber(), (float)value.At(2).AsNumber());
		return true;
	}

	/// A page title as a file stem: letters, digits, '-' and '_' kept, the rest '_'.
	private static void FileStemOf(StringView title, String outStem)
	{
		for (let c in title.RawChars)
			outStem.Append((c.IsLetterOrDigit || (c == '-') || (c == '_')) && (c < (char8)0x80) ? c : '_');
		if (outStem.IsEmpty)
			outStem.Append("page");
	}

	/// The entity a call addresses: `entity` when given, else the page's primary selection;
	/// false with the reason when there is neither, or no such entity in the page.
	/// entity_inspect over a running PIE instance: `entity` by guid, name or path in the
	/// scene that game is in now.
	private static bool InspectPie(EditorContext context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let page = PieMcpTools.ResolvePie(context, arguments, outError);
		if (page == null)
			return false;
		let pie = page as IPieInstancePage;
		let scene = pie.RunningScene;
		if (!pie.IsRunning || (scene == null))
		{
			outError.AppendF("PIE instance '{}' is not running a scene (pie_state says where it is)", pie.PieId);
			return false;
		}
		let entityArg = arguments.Get("entity");
		if ((entityArg == null) || !entityArg.IsString)
		{
			outError.Append("pass `entity` (a guid, a name or a slash path): a running game has no selection");
			return false;
		}
		let handle = PieRunTool.FindEntity(scene, entityArg.AsString());
		if (!scene.IsValid(handle))
		{
			outError.AppendF("no entity '{}' in PIE instance '{}''s scene '{}'", entityArg.AsString(), pie.PieId, scene.Name);
			return false;
		}
		outResult.Set("pie", JsonValue.MakeString(pie.PieId));
		outResult.Set("scene", JsonValue.MakeString(scene.Name));
		outResult.Set("entity", EntityJson(scene, handle, context.Resources));
		return true;
	}

	private static bool ResolveEntity(EditorPage page, SceneEditContext edit, JsonValue arguments, String outError, out Guid outId)
	{
		outId = .();
		let entityArg = arguments.Get("entity");
		if ((entityArg != null) && entityArg.IsString)
		{
			// A guid, or a name or slash path in the page's scene.
			let text = entityArg.AsString();
			if (!(Guid.Parse(text) case .Ok(out outId)))
			{
				let named = PieRunTool.FindEntity(edit.Scene, text);
				if (!edit.Scene.IsValid(named))
				{
					outError.AppendF("no entity '{}' in page '{}' (a guid, a name or a slash path; scene_read shows the scene's entities)", text, page.Title);
					return false;
				}
				outId = edit.Scene.GetEntityId(named);
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
	public static ComponentManagerBase FindComponentManager(Sedulous.Scene.Scene scene, EntityHandle entity, StringView component)
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
	public static JsonValue EntityJson(Sedulous.Scene.Scene scene, EntityHandle handle, ResourceManager resources = null)
	{
		let json = JsonValue.MakeObject();
		json.Set("guid", ComponentJson.GuidJson(scene.GetEntityId(handle)));
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
				// The behaviours are a hidden list the reflected fields leave out: what each one
				// runs and what its properties are set to, named from its cooked class.
				if (type == typeof(ScriptComponent))
					component.Set("behaviors", BehaviorsJson((ScriptComponent*)address, scene, resources));
				components.Add(component);
			});
		json.Set("components", components);
		return json;
	}

	/// A Script component's behaviours: each one's script (its guid, and its class when the
	/// class is cooked), whether it runs, and its property overrides by name (by hash, #n, when
	/// the class is not at hand to name them).
	private static JsonValue BehaviorsJson(ScriptComponent* component, Sedulous.Scene.Scene scene, ResourceManager resources)
	{
		let list = JsonValue.MakeArray();
		if ((component == null) || (component.Behaviors == null))
			return list;
		for (let behavior in component.Behaviors)
		{
			let json = JsonValue.MakeObject();
			let id = behavior.Script.Id;
			json.Set("script", ComponentJson.GuidJson(id));
			let scriptClass = (behavior.Script.Get != null) ? behavior.Script.Get
				: (((resources != null) && id.IsSet) ? resources.Bind<ScriptClass>(id).Get : null);
			json.Set("class", (scriptClass != null) ? JsonValue.MakeString(scriptClass.ClassName) : JsonValue.MakeNull());
			json.Set("enabled", JsonValue.MakeBool(behavior.Enabled));
			let properties = JsonValue.MakeObject();
			for (let o in behavior.Overrides)
			{
				let desc = (scriptClass != null) ? scriptClass.FindProperty(o.Hash) : null;
				let name = (desc != null) ? scope String(desc.Name) : scope $"#{o.Hash}";
				properties.Set(name, PropertyValueJson(o.Value, scene));
			}
			json.Set("properties", properties);
			// Running (a PIE game, a Simulate): the instance's current values of the class's
			// properties, where `properties` holds what is authored.
			if ((behavior.Instance != null) && (scriptClass != null))
			{
				let system = scene.GetSystem<ScriptSceneSystem>();
				let runtime = ((system != null) && (system.Host != null)) ? system.Host.Runtime : null;
				if (runtime != null)
				{
					let live = JsonValue.MakeObject();
					for (let desc in scriptClass.Properties)
					{
						var value = Sedulous.Script.ScriptValue.Nil;
						if (runtime.GetProperty(behavior.Instance, desc.Name, ref value))
							live.Set(desc.Name, PieRunTool.ScriptJson(value, scene));
					}
					json.Set("live", live);
				}
			}
			list.Add(json);
		}
		return list;
	}

	private static JsonValue PropertyValueJson(ScriptPropertyValue value, Sedulous.Scene.Scene scene)
	{
		var value;
		switch (value.Kind)
		{
		case .Float: return JsonValue.MakeNumber(value.Number);
		case .Int: return JsonValue.MakeNumber(value.Number);
		case .Bool: return JsonValue.MakeBool(value.Boolean);
		case .String: return JsonValue.MakeString((value.Text != null) ? StringView(value.Text) : "");
		case .Vec3: return ComponentJson.ValueJson(typeof(Float3), &value.Vector);
		case .Color: return ComponentJson.ValueJson(typeof(Color), &value.Color);
		case .Entity, .Asset: return value.Id.IsSet ? ComponentJson.GuidJson(value.Id) : JsonValue.MakeNull();
		case .None: return JsonValue.MakeNull();
		}
	}

	/// The scene page a call addresses: `page` (a guid) when given, else the active page; null
	/// with the reason in outError when it is not a scene page.
	public static EditorPage ResolveScenePage(EditorContext context, JsonValue arguments, String outError)
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

	public static JsonValue PageJson(EditorPage page)
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
