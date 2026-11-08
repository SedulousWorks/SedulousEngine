using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Runtime;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;
using Sedulous.Engine.Project;
using Sedulous.Engine.Script;
using Sedulous.Script.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using ShaderGallery;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The tracked sample projects (Data/SampleProjects: PaperKid, Shader Gallery, Sky Hopper, Masquerade) must stay
/// readable at the CURRENT data versions: a wire version bump or a key rename that forgets to
/// upgrade their sources leaves them refused by the strict readers. This registers the whole pipeline the way
/// the cook tool does, opens a scratch copy (so opening never writes into the tracked tree),
/// reads every instance back, and cooks it through the tools an agent uses. It registers
/// what it needs itself (the pipeline types; the component reflection and the script surface
/// are comptime here), so it holds when run alone. A sample with game code of its own (the
/// Shader Gallery's, Sky Hopper's and PaperKid's Code/) has its package linked here, as its own
/// editor links it, and reads with the package loaded, so its behaviours' records and its levels'
/// blocks resolve rather than stay unknown.
static class SampleProjectTests
{
	/// Every instance under a group, recursively, reads back. A scene or prefab is its STREAM,
	/// not its document: the entities, components and system settings carry their own data
	/// versions, so the stream loads into a scratch scene of the full composition the way a
	/// page opens it.
	private static int ReadAllInstances(Group group)
	{
		int read = 0;
		for (let instance in group.Instances)
		{
			let object = instance.ReadObject();
			Test.Assert(object != null, scope $"sample project instance refused: {instance.Name}");
			if (object != null)
				delete object;
			if ((instance.TypeName == McpDocumentNames.cSceneDocument) || (instance.TypeName == McpDocumentNames.cPrefabDocument))
			{
				let scratch = scope Scene(instance.Name);
				EngineSceneComposition.AddAllSceneManagers(scratch);
				Test.Assert(SceneStorage.LoadScene(instance, scratch) case .Ok, scope $"sample project scene stream refused: {instance.Name}");
			}
			read++;
		}
		for (let child in group.Groups)
			read += ReadAllInstances(child);
		return read;
	}

	/// The sample's tree from `source` into `dir`, less what builds, cooks and the editor write
	/// there (a local Build Project's Code/build alone is gigabytes): of Code/, only the package's
	/// manifest, its parts being linked into this binary.
	private static bool CopySample(StringView source, StringView dir)
	{
		if (!CreateDirectory(dir))
			return false;
		let names = scope List<(String name, bool isDirectory)>();
		defer
		{
			for (let entry in names)
				delete entry.name;
		}
		ListDirectory(source, scope [&](name, isDirectory) => { names.Add((new String(name), isDirectory)); });
		bool ok = true;
		for (let entry in names)
		{
			let from = PathJoin(source, entry.name, .. scope .());
			let to = PathJoin(dir, entry.name, .. scope .());
			if (!entry.isDirectory)
				ok = ExportTemplates.CopyFile(source, entry.name, dir, entry.name) && ok;
			else if (entry.name == ProjectLayout.CodeDir)
				ok = CreateDirectory(to) && ExportTemplates.CopyFile(from, "Plugin.xml", to, "Plugin.xml") && ok;
			else if ((entry.name != ProjectLayout.CacheDir) && (entry.name != ProjectLayout.EditorDir) && (entry.name != "Dist")
				&& !entry.name.StartsWith(ProjectLayout.CookedDir))
				ok = ExportTemplates.CopyTree(from, to) && ok;
		}
		return ok;
	}

	/// Reads every instance of the sample in Data/SampleProjects/`name` from a scratch copy,
	/// cooks it through the tools an agent uses, and checks every script override it stores names
	/// a property of its cooked class. The floors catch a group silently skipped or a cook that
	/// built less than the sample has. With `packageId`, the sample's own package (linked here)
	/// is loaded while it reads, as in the project's own editor, and `checkGameCode` sees the
	/// project then.
	private static void CheckSampleProject(StringView name, StringView scratch, int readFloor, int cookedFloor, int overrideFloor,
		StringView packageId = default, function void(EditorProject project) checkGameCode = null)
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();

		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		Test.Assert(!dataRoot.IsEmpty, "the Data/.dataroot walk from the test binary");
		let source = PathJoin(dataRoot, scope $"SampleProjects/{name}", .. scope .());
		Test.Assert(DirectoryExists(source));

		let dir = Scratch(scratch, .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(CopySample(source, dir), "the sample copies to scratch");
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let engineServices = scope EnginePluginServices();
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, .Editor, EngineVersion.String);
			if (!packageId.IsEmpty)
			{
				Test.Assert(project.Settings.FindPlugin(packageId) != null, scope $"{name} enables its package");
				Test.Assert(engineServices.Attach(host));
				Test.Assert(host.AddRegistered() case .Ok);
				host.Load((Span<EnabledPlugin>)project.Settings.Plugins, scope .());
				Test.Assert(host.IsLoaded(packageId), scope $"{name}'s package loads");
			}
			let read = ReadAllInstances(project.SourceDb.RootGroup);
			Test.Assert(read >= readFloor, scope $"{name}: read {read} instances");
			if (checkGameCode != null)
				checkGameCode(project);
			if (!packageId.IsEmpty)
				host.Unload();
		}

		// And it COOKS, through the same tools an agent uses.
		let builders = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllImporters(importers);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		let operations = scope InlineProjectOperations(session, builders, "", "");
		AssetWriteTools.Register(server, session, importers, operations);
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let force = Obj();
		force.Set("force", JsonValue.MakeBool(true));
		let cooked = CallOk(server, "asset_cook", force);
		defer delete cooked;
		Test.Assert(cooked.Get("cooked").AsInt() >= cookedFloor, scope $"{name}: cooked {cooked.Get("cooked").AsInt()}");
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"{name}: {cooked.Get("failed").AsInt()} failed");

		// Every script override a scene or prefab stores, a behaviour's or the Level's, names a
		// property its cooked class declares: the key is the property name's hash, so a hash
		// change that forgets to rehash the sources leaves overrides that silently apply to
		// nothing.
		{
			let project = EditorProject.Open(dir);
			Test.Assert(project != null);
			defer delete project;
			let overrides = CheckOverrides(project, project.SourceDb.RootGroup);
			Test.Assert(overrides >= overrideFloor, scope $"{name}: {overrides} overrides checked");
		}
		// The MCP host's plugins (the sample's package, when it enables one this binary links) go
		// before its project, and both before the session that names them.
		session.Plugins = null;
		DeleteAndNullify!(owner.Plugins);
		session.Project = null;
		DeleteAndNullify!(owner.Project);
	}

	[Test]
	public static void EveryPaperKidSourceReadsAtTheCurrentDataVersionsAndCooks()
	{
		// 222 instances: 6 scenes (five blocks and the title), 19 kit prefabs, 18 audio clips, 4
		// fonts, 5 meshes, 5 navigation zones, 7 UI documents and their sheet, 4 particle effects,
		// their sprite and the minimap's render texture, 2 animation clips and a material, the two
		// render profiles, the toon shader, the input map, and the 13 Blender models with their
		// prefabs, meshes, materials, skeletons and clips (144). 184 cook: all but the scenes and
		// the 32 prefabs, which stage rather than cook. No script overrides: the behaviours and the
		// blocks' level are the game's code, its package loaded to read the scenes. Raise the floors
		// when the sample grows.
		CheckSampleProject("PaperKid", "scratch_paperkid_versions", 222, 184, 0, "paperkid", => CheckPaperKid);
	}

	/// Block1 runs the game's level with its own numbers and carries the bike, its camera and the
	/// minimap's markers with the values the block gives them, not the defaults, and no script;
	/// the title's street carries its strollers and its pets (their clips set); the kit's prefabs
	/// carry their behaviours with their values (each lane's direction, each obstacle's reach,
	/// each burst's life).
	private static void CheckPaperKid(EditorProject project)
	{
		let block = FindInstance(project.SourceDb.RootGroup, "Block1", McpDocumentNames.cSceneDocument);
		Test.Assert(block != null, "Block1");
		if (block == null)
			return;
		let scene = scope Scene(block.Name);
		EngineSceneComposition.AddAllSceneManagers(scene); // the package's behaviour managers and level among them
		Test.Assert(SceneStorage.LoadScene(block, scene) case .Ok, "Block1's stream");
		let level = scene.GetSystem<PaperKid.Block>();
		Test.Assert(level != null, "the game's level came with its package");
		if (level != null)
		{
			Test.Assert(level.Active, "Block1 runs it");
			Test.Assert((level.TimeLimit == 55.0f) && (level.Quota == 4) && (level.Papers == 8) && (level.TrafficSpeed == 7.5f)
				&& (level.PedestrianSpeed == 1.4f) && (level.Ring == 24.0f) && (level.CrashPenalty == 5.0f), "Block1's numbers, not the defaults");
		}
		let levelScripts = scene.GetSystem<ScriptSceneSystem>();
		Test.Assert((levelScripts == null) || (levelScripts.Settings.Script.Id == Guid.Empty), "no level script left");
		let bikes = scene.GetSystem<BehaviourManager<PaperKid.Bike>>();
		Test.Assert((bikes != null) && (bikes.Count == 1), "one Bike, resolved");
		if ((bikes == null) || (bikes.Count != 1))
			return;
		let bike = bikes.OwnerHandles[0];
		Test.Assert(scene.GetEntityName(bike) == "Bike");
		let cameras = scene.GetSystem<BehaviourManager<PaperKid.FollowCamera>>();
		Test.Assert((cameras != null) && (cameras.Count == 1) && (cameras.Instances[0].Target.Id == scene.GetEntityId(bike)),
			"the camera follows the bike");
		let markers = scene.GetSystem<BehaviourManager<PaperKid.MapMarkers>>();
		Test.Assert((markers != null) && (markers.Count == 1) && (markers.Instances[0].Bike.Id == scene.GetEntityId(bike))
			&& (markers.Instances[0].Span == 84.0f), "the minimap marks the bike, over the block's span");
		let scripts = scene.GetSystem<ScriptComponentManager>();
		Test.Assert((scripts == null) || (scripts.ComponentCount == 0), "no script behaviour left");

		let start = FindInstance(project.SourceDb.RootGroup, "Start", McpDocumentNames.cSceneDocument);
		Test.Assert(start != null, "Start");
		if (start != null)
		{
			let street = scope Scene(start.Name);
			EngineSceneComposition.AddAllSceneManagers(street);
			Test.Assert(SceneStorage.LoadScene(start, street) case .Ok, "Start's stream");
			let strollers = street.GetSystem<BehaviourManager<PaperKid.Stroller>>();
			Test.Assert((strollers != null) && (strollers.Count == 5), "the title's three cars and two walkers");
			let pets = street.GetSystem<BehaviourManager<PaperKid.Pet>>();
			Test.Assert((pets != null) && (pets.Count == 2), "the dog and the cat");
			if (pets != null)
			{
				for (let pet in pets.Instances)
				{
					Test.Assert((pet.WalkClip.Id != Guid.Empty) && (pet.IdleClip.Id != Guid.Empty) && (pet.SitClip.Id != Guid.Empty)
						&& (pet.LieClip.Id != Guid.Empty) && (pet.OwnClip.Id != Guid.Empty), "a pet's clips");
				}
			}
			let titleLevel = street.GetSystem<PaperKid.Block>();
			Test.Assert((titleLevel == null) || !titleLevel.Active, "the title runs no block");
		}

		CheckKitPiece<PaperKid.Vehicle>(project, "Car", scope (vehicle) => vehicle.Direction == 1);
		CheckKitPiece<PaperKid.Obstacle>(project, "Car", scope (obstacle) => obstacle.Radius == 2.0f);
		CheckKitPiece<PaperKid.Vehicle>(project, "CarOuter", scope (vehicle) => vehicle.Direction == -1);
		CheckKitPiece<PaperKid.Pedestrian>(project, "Pedestrian", scope (walker) => walker.WalkClip.Id != Guid.Empty);
		CheckKitPiece<PaperKid.Obstacle>(project, "Pedestrian", scope (obstacle) => obstacle.Radius == 0.8f);
		CheckKitPiece<PaperKid.Obstacle>(project, "Bin", scope (obstacle) => obstacle.Radius == 0.85f);
		CheckKitPiece<PaperKid.Subscriber>(project, "DeliveryZone", scope (subscriber) => subscriber.Value == 100);
		CheckKitPiece<PaperKid.Paper>(project, "Newspaper", scope (paper) => paper.Lifetime == 6.0f);
		CheckKitPiece<PaperKid.Fx>(project, "FxConfetti", scope (fx) => fx.Lifetime == 4.0f);
		CheckKitPiece<PaperKid.Fx>(project, "FxSparkle", scope (fx) => fx.Lifetime == 1.5f);
		CheckKitPiece<PaperKid.Fx>(project, "FxDust", scope (fx) => fx.Lifetime == 1.5f);
		CheckKitPiece<PaperKid.Fx>(project, "FxPuff", scope (fx) => fx.Lifetime == 1.0f);
	}

	/// The kit's prefab `name` carries one `T`, for which `check` holds.
	private static void CheckKitPiece<T>(EditorProject project, StringView name, delegate bool(T behaviour) check) where T : Behaviour, new, delete
	{
		let prefab = FindInstance(project.SourceDb.RootGroup, name, McpDocumentNames.cPrefabDocument);
		Test.Assert(prefab != null, scope $"the {name} prefab");
		if (prefab == null)
			return;
		let piece = scope Scene(prefab.Name);
		EngineSceneComposition.AddAllSceneManagers(piece);
		Test.Assert(SceneStorage.LoadScene(prefab, piece) case .Ok, scope $"{name}'s stream");
		let behaviours = piece.GetSystem<BehaviourManager<T>>();
		let typeName = typeof(T).GetName(.. scope .());
		Test.Assert((behaviours != null) && (behaviours.Count == 1), scope $"{name} carries one {typeName}");
		if ((behaviours != null) && (behaviours.Count == 1))
			Test.Assert(check(behaviours.Instances[0]), scope $"{name}'s {typeName}, with the kit's values");
	}

	[Test]
	public static void TheShaderGallerySourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 50 instances: 11 lesson shaders (surface and low-level, every program compiled by the
		// cook) and their materials, the hall's 3 materials, 4 textures and the sky, 4 Blender
		// models with their meshes and prefabs, the 3 primitives, the hall, the list and its
		// sheet, the font and the input map. At least 44 cook; the hall and the 4 prefabs stage
		// rather than cook. No script overrides: the camera's behaviour is the game's code, its
		// package loaded to read the hall.
		CheckSampleProject("ShaderGallery", "scratch_shadergallery_versions", 50, 44, 0, "shadergallery", => CheckGallery);
	}

	/// The hall's camera carries the game's Gallery behaviour, resolved into its manager with the
	/// values the hall gives it (its starting yaw and pitch, and the lesson list's document), not
	/// the defaults.
	private static void CheckGallery(EditorProject project)
	{
		let hall = FindInstance(project.SourceDb.RootGroup, "Hall", McpDocumentNames.cSceneDocument);
		let list = FindInstance(project.SourceDb.RootGroup, "Gallery", "GuiDocumentAsset");
		Test.Assert((hall != null) && (list != null), "the hall and the lesson list");
		if ((hall == null) || (list == null))
			return;
		let scene = scope Scene(hall.Name);
		EngineSceneComposition.AddAllSceneManagers(scene); // the package's Gallery manager among them
		Test.Assert(SceneStorage.LoadScene(hall, scene) case .Ok, "the hall's stream");
		let galleries = scene.GetSystem<BehaviourManager<Gallery>>();
		Test.Assert((galleries != null) && (galleries.Count == 1), "one Gallery, resolved");
		if ((galleries == null) || (galleries.Count != 1))
			return;
		Test.Assert(scene.GetEntityName(galleries.OwnerHandles[0]) == "Camera");
		let gallery = galleries.Instances[0];
		Test.Assert((gallery.StartYaw == -20.0f) && (gallery.StartPitch == -8.0f), "the hall's values, not the defaults");
		Test.Assert(gallery.LessonList.Id == list.Id, "the lesson list's document");
	}

	[Test]
	public static void TheSkyHopperSourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 262 instances: 5 levels and 35 prefabs (the kit's 30 models and the 5 effects), 30 model
		// manifests, 65 materials, 42 clips, 26 static and 7 skinned meshes, 4 skeletons, 10 collision
		// shapes, 12 audio clips, 9 UI documents and their sheet, 6 icons, 5 particle effects, 2
		// fonts, the toon shader, the environment profile and the input map. 222 cook: all but the
		// levels and the prefabs, which stage rather than cook. No script overrides: the behaviours
		// are the game's code, its package loaded to read the levels. Raise the floors when the
		// sample grows.
		CheckSampleProject("SkyHopper", "scratch_skyhopper_versions", 262, 222, 0, "skyhopper", => CheckSkyHopper);
	}

	/// Level1's entities carry the game's behaviours, resolved into their managers with the values
	/// the level gives them, not the defaults (the player's jump, the camera's target, the gem's
	/// event, each enemy's walk clip), every coin among them and no script left; and each effect's
	/// prefab carries its timed life.
	private static void CheckSkyHopper(EditorProject project)
	{
		let level = FindInstance(project.SourceDb.RootGroup, "Level1", McpDocumentNames.cSceneDocument);
		Test.Assert(level != null, "Level1");
		if (level == null)
			return;
		let scene = scope Scene(level.Name);
		EngineSceneComposition.AddAllSceneManagers(scene); // the package's behaviour managers among them
		Test.Assert(SceneStorage.LoadScene(level, scene) case .Ok, "Level1's stream");
		let players = scene.GetSystem<BehaviourManager<SkyHopper.PlayerController>>();
		Test.Assert((players != null) && (players.Count == 1), "one PlayerController, resolved");
		if ((players == null) || (players.Count != 1))
			return;
		let player = players.OwnerHandles[0];
		Test.Assert(scene.GetEntityName(player) == "Player");
		Test.Assert(players.Instances[0].JumpSpeed == 10.0f, "the level's jump, not the default");
		let cameras = scene.GetSystem<BehaviourManager<SkyHopper.FollowCamera>>();
		Test.Assert((cameras != null) && (cameras.Count == 1) && (cameras.Instances[0].Target.Id == scene.GetEntityId(player)),
			"the camera follows the player");
		let pickups = scene.GetSystem<BehaviourManager<SkyHopper.Pickup>>();
		Test.Assert((pickups != null) && (pickups.Count == 1) && (pickups.Instances[0].TakenEvent == .GemCollected)
			&& (pickups.Instances[0].ChimePitch == 1.5f), "the level's gem");
		let coins = scene.GetSystem<BehaviourManager<SkyHopper.Coin>>();
		Test.Assert((coins != null) && (coins.Count == 9), "Level1's nine coins");
		let enemies = scene.GetSystem<BehaviourManager<SkyHopper.Enemy>>();
		Test.Assert((enemies != null) && (enemies.Count == 2), "Level1's two enemies");
		if (enemies != null)
		{
			for (let enemy in enemies.Instances)
				Test.Assert(enemy.WalkClip.Id != Guid.Empty, "an enemy's walk clip");
		}
		let scripts = scene.GetSystem<ScriptComponentManager>();
		Test.Assert((scripts == null) || (scripts.ComponentCount == 0), "no script behaviour left");

		for (let name in StringView[5]("FxCoinSparkle", "FxConfetti", "FxDust", "FxPoof", "FxStompStars"))
		{
			let prefab = FindInstance(project.SourceDb.RootGroup, name, McpDocumentNames.cPrefabDocument);
			Test.Assert(prefab != null, scope $"the {name} prefab");
			if (prefab == null)
				continue;
			let effect = scope Scene(prefab.Name);
			EngineSceneComposition.AddAllSceneManagers(effect);
			Test.Assert(SceneStorage.LoadScene(prefab, effect) case .Ok, scope $"{name}'s stream");
			let lives = effect.GetSystem<BehaviourManager<SkyHopper.TimedLife>>();
			Test.Assert((lives != null) && (lives.Count == 1), scope $"{name} removes itself");
		}
	}

	/// The first instance under `group` named `name` whose type name ends with `typeName`, or null.
	private static Instance FindInstance(Group group, StringView name, StringView typeName)
	{
		for (let instance in group.Instances)
		{
			if ((instance.Name == name) && instance.TypeName.EndsWith(typeName))
				return instance;
		}
		for (let child in group.Groups)
		{
			if (let found = FindInstance(child, name, typeName))
				return found;
		}
		return null;
	}

	[Test]
	public static void TheMasqueradeSourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 338 instances: 3 maps and 3 hunter prefabs, 6 rigged costumes with their clips and
		// materials (the masks and fabrics on 2 custom shaders), the palace, canal and garden kits,
		// 3 navigation zones, 6 scripts, 4 UI documents, 10 generated sounds and music, the
		// profiles, the input map, the font, the sky and the primitives. 293 cook: all but the
		// maps, the prefabs and the model manifests. The 957 overrides are the guests', bots',
		// player's, camera's and Ball's settings and references. Raise the floors when the sample
		// grows.
		CheckSampleProject("Masquerade", "scratch_masquerade_versions", 338, 293, 957);
	}

	/// The number of script overrides checked under `group`: a behaviour's against its cooked
	/// class, and a scene's Level script's against its own.
	private static int CheckOverrides(EditorProject project, Group group)
	{
		int count = 0;
		for (let instance in group.Instances)
		{
			if ((instance.TypeName != McpDocumentNames.cSceneDocument) && (instance.TypeName != McpDocumentNames.cPrefabDocument))
				continue;
			let scene = scope Scene(instance.Name);
			EngineSceneComposition.AddAllSceneManagers(scene);
			if (!(SceneStorage.LoadScene(instance, scene) case .Ok))
				continue;
			let scripts = scene.GetSystem<ScriptComponentManager>();
			for (let component in scripts.Dense)
			{
				for (let behavior in component.Behaviors)
					count += CheckDeclared(project, instance.Name, behavior.Script.Id, behavior.Overrides);
			}
			for (let system in scene.Systems)
			{
				if (system.SettingsType != typeof(SceneScriptSettings))
					continue;
				let level = (SceneScriptSettings)Internal.UnsafeCastToObject(system.SettingsInstance);
				if (level.Script.Id != Guid.Empty)
					count += CheckDeclared(project, instance.Name, level.Script.Id, level.Overrides);
			}
		}
		for (let child in group.Groups)
			count += CheckOverrides(project, child);
		return count;
	}

	/// Each override names a property the script's cooked class declares; answers how many.
	private static int CheckDeclared(EditorProject project, StringView owner, Guid script, List<ScriptPropertyOverride> overrides)
	{
		let stored = project.CookedDb.ReadObject(script);
		defer delete stored;
		let source = stored as ScriptClassSource;
		Test.Assert(source != null, scope $"{owner}: the script is cooked");
		if (source == null)
			return 0;
		for (let o in overrides)
		{
			bool declared = false;
			for (let property in source.Properties)
				declared |= property.Hash == o.Hash;
			Test.Assert(declared, scope $"{owner}: override {o.Hash} names no property of {source.ClassName}");
		}
		return overrides.Count;
	}
}
