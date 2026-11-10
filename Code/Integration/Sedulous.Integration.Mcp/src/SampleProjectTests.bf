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
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.VFS;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using ShaderGallery;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The tracked sample projects (Data/SampleProjects: PaperKid, Shader Gallery, Sky Hopper, Lamplight, Snowline, Masquerade) must stay
/// readable at the CURRENT data versions: a wire version bump or a key rename that forgets to
/// upgrade their sources leaves them refused by the strict readers. This registers the whole pipeline the way
/// the cook tool does, opens a scratch copy (so opening never writes into the tracked tree),
/// reads every instance back, and cooks it through the tools an agent uses. It registers
/// what it needs itself (the pipeline types; the component reflection is
/// comptime here), so it holds when run alone. A sample with game code of its own (the
/// Shader Gallery's, Sky Hopper's, PaperKid's, Lamplight's, Snowline's and Masquerade's Code/) has its package linked here, as its own
/// editor links it, and reads with the package loaded, so its behaviours' records and its levels'
/// blocks resolve rather than stay unknown.
static class SampleProjectTests
{
	/// Every instance under a group, recursively, reads back. A scene or prefab is its STREAM,
	/// not its document: the entities, components and system settings carry their own data
	/// versions, so the stream loads into a scratch scene of the full composition the way a
	/// page opens it.
	public static int ReadAllInstances(Group group)
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
				// A scene saved while scripts ran reads with its script block dropped, not kept.
				for (let record in scratch.UnresolvedSettingsRecords)
					Test.Assert(record.SystemId != "script", scope $"{instance.Name} keeps its script block");
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
				ok = FileCopy.CopyFile(source, entry.name, dir, entry.name) && ok;
			else if (entry.name == ProjectLayout.CodeDir)
				ok = CreateDirectory(to) && FileCopy.CopyFile(from, "Plugin.xml", to, "Plugin.xml") && ok;
			else if ((entry.name != ProjectLayout.CacheDir) && (entry.name != ProjectLayout.EditorDir) && (entry.name != "Dist")
				&& !entry.name.StartsWith(ProjectLayout.CookedDir))
				ok = FileCopy.CopyTree(from, to) && ok;
		}
		return ok;
	}

	/// Reads every instance of the sample in Data/SampleProjects/`name` from a scratch copy and
	/// cooks it through the tools an agent uses. The floors catch a group silently skipped or a
	/// cook that built less than the sample has. With `packageId`, the sample's own package (linked here)
	/// is loaded while it reads, as in the project's own editor, and `checkGameCode` sees the
	/// project then.
	private static void CheckSampleProject(StringView name, StringView scratch, int readFloor, int cookedFloor,
		StringView packageId = default, function void(EditorProject project) checkGameCode = null)
	{
		PipelineRegistration.RegisterPipelineTypes();

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
		let operations = scope InlineProjectOperations(session, builders, "");
		AssetWriteTools.Register(server, session, importers, operations);
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let force = Obj();
		force.Set("force", JsonValue.MakeBool(true));
		let cooked = CallOk(server, "asset_cook", force);
		defer delete cooked;
		Test.Assert(cooked.Get("cooked").AsInt() >= cookedFloor, scope $"{name}: cooked {cooked.Get("cooked").AsInt()}");
		Test.Assert(cooked.Get("failed").AsInt() == 0, scope $"{name}: {cooked.Get("failed").AsInt()} failed");

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
		// the 32 prefabs, which stage rather than cook. The behaviours and the
		// blocks' level are the game's code, its package loaded to read the scenes. Raise the floors
		// when the sample grows.
		CheckSampleProject("PaperKid", "scratch_paperkid_versions", 222, 184, "paperkid", => CheckPaperKid);
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
		Test.Assert(!HasScriptComponent(scene), "no script behaviour left");

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
		// rather than cook. The camera's behaviour is the game's code, its
		// package loaded to read the hall.
		CheckSampleProject("ShaderGallery", "scratch_shadergallery_versions", 50, 44, "shadergallery", => CheckGallery);
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
		// levels and the prefabs, which stage rather than cook. The behaviours
		// are the game's code, its package loaded to read the levels. Raise the floors when the
		// sample grows.
		CheckSampleProject("SkyHopper", "scratch_skyhopper_versions", 262, 222, "skyhopper", => CheckSkyHopper);
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
		Test.Assert(!HasScriptComponent(scene), "no script behaviour left");

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

	[Test]
	public static void TheLamplightSourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 250 instances: 6 scenes (the five levels and the test room) and 36 prefabs (the kits'
		// and the loot's 33 models, the thief, the guard and the pebble), 35 model manifests, 86
		// materials, 34 static and 2 skinned meshes, 2 skeletons, 9 clips and 2 animation graphs,
		// 16 sounds, 5 UI documents and their sheet, 6 navigation zones, 4 physical materials, the
		// rain, the font, the input map and the environment and post profiles. 208 cook: all but
		// the scenes and the prefabs, which stage rather than cook. The
		// behaviours and the game are the game's code, its package loaded to read the levels. Raise
		// the floors when the sample grows.
		CheckSampleProject("Lamplight", "scratch_lamplight_versions", 250, 208, "lamplight", => CheckLamplight);
	}

	/// The Gardens' entities carry the game's behaviours, resolved into their managers with the
	/// values the level gives them, not the defaults (the thief's camera and pebble, the rig's
	/// target, the guard's thief and collision group, the gate's lock, the lamps' slots and
	/// materials, the loot's values and the one target, the surfaces underfoot), a cutaway on
	/// every wall piece and no script left; and the pebble's prefab carries its behaviour.
	private static void CheckLamplight(EditorProject project)
	{
		let gardens = FindInstance(project.SourceDb.RootGroup, "Gardens", McpDocumentNames.cSceneDocument);
		Test.Assert(gardens != null, "Gardens");
		let pebble = FindInstance(project.SourceDb.RootGroup, "Pebble", McpDocumentNames.cPrefabDocument);
		Test.Assert(pebble != null, "the Pebble prefab");
		if ((gardens == null) || (pebble == null))
			return;
		let scene = scope Scene(gardens.Name);
		EngineSceneComposition.AddAllSceneManagers(scene); // the package's behaviour managers among them
		Test.Assert(SceneStorage.LoadScene(gardens, scene) case .Ok, "the Gardens' stream");
		let thieves = scene.GetSystem<BehaviourManager<Lamplight.Thief>>();
		Test.Assert((thieves != null) && (thieves.Count == 1), "one Thief, resolved");
		if ((thieves == null) || (thieves.Count != 1))
			return;
		let player = thieves.OwnerHandles[0];
		let playerId = scene.GetEntityId(player);
		Test.Assert(scene.GetEntityName(player) == "Player");
		let thief = thieves.Instances[0];
		Test.Assert(thief.Pebble.Id == pebble.Id, "the thief throws the Pebble prefab");
		let rigs = scene.GetSystem<BehaviourManager<Lamplight.CameraRig>>();
		Test.Assert((rigs != null) && (rigs.Count == 1) && (rigs.Instances[0].Target.Id == playerId), "the camera follows the thief");
		if ((rigs != null) && (rigs.Count == 1))
			Test.Assert(thief.Camera.Id == scene.GetEntityId(rigs.OwnerHandles[0]), "the thief moves by the rig's camera");
		let meters = scene.GetSystem<BehaviourManager<Lamplight.LightMeter>>();
		Test.Assert((meters != null) && (meters.Count == 1) && (meters.OwnerHandles[0] == player), "the thief's light meter");
		let steps = scene.GetSystem<BehaviourManager<Lamplight.Footsteps>>();
		Test.Assert((steps != null) && (steps.Count == 1) && (steps.OwnerHandles[0] == player), "the thief's footsteps");
		if ((steps != null) && (steps.Count == 1))
		{
			let feet = steps.Instances[0];
			Test.Assert((feet.Wood.Id != Guid.Empty) && (feet.Stone.Id != Guid.Empty) && (feet.Gravel.Id != Guid.Empty)
				&& (feet.Grass.Id != Guid.Empty), "the surfaces underfoot");
		}
		let guards = scene.GetSystem<BehaviourManager<Lamplight.Guard>>();
		Test.Assert((guards != null) && (guards.Count == 1), "the Gardens' guard");
		if ((guards != null) && (guards.Count == 1))
		{
			let guard = guards.Instances[0];
			Test.Assert((guard.Thief.Id == playerId) && (guard.Group == 2) && !guard.Route.IsNil && !guard.Lantern.IsNil
				&& !guard.Meter.IsNil, "the guard's thief, round, lantern, meter and group");
		}
		let doors = scene.GetSystem<BehaviourManager<Lamplight.Door>>();
		Test.Assert((doors != null) && (doors.Count == 1), "the north gate");
		if ((doors != null) && (doors.Count == 1))
		{
			let gate = doors.Instances[0];
			Test.Assert(gate.Locked && (gate.LockAlong == 1.08f) && (gate.Thief.Id == playerId), "the gate's lock, not the defaults");
		}
		let lamps = scene.GetSystem<BehaviourManager<Lamplight.Lamp>>();
		Test.Assert((lamps != null) && (lamps.Count == 4), "the four lantern posts");
		if (lamps != null)
		{
			for (let lamp in lamps.Instances)
			{
				Test.Assert((lamp.ChimneySlot == -1) && !lamp.Light.IsNil && (lamp.FlameLit.Id != Guid.Empty)
					&& (lamp.FlameOut.Id != Guid.Empty), "a lantern's light, its glass's slot and its materials");
			}
		}
		let loot = scene.GetSystem<BehaviourManager<Lamplight.Loot>>();
		Test.Assert((loot != null) && (loot.Count == 5), "three purses, a candlestick and the key");
		if (loot != null)
		{
			int targets = 0;
			int worth = 0;
			for (let piece in loot.Instances)
			{
				if (piece.Target)
					targets++;
				worth += piece.Value;
			}
			Test.Assert((targets == 1) && (worth == 155), "one target, and each piece's value");
		}
		let exits = scene.GetSystem<BehaviourManager<Lamplight.Exit>>();
		Test.Assert((exits != null) && (exits.Count == 1), "the way out");
		let checkpoints = scene.GetSystem<BehaviourManager<Lamplight.Checkpoint>>();
		Test.Assert((checkpoints != null) && (checkpoints.Count == 1), "the crossing's checkpoint");
		let walls = scene.GetSystem<BehaviourManager<Lamplight.CutawayWall>>();
		Test.Assert((walls != null) && (walls.Count == 102), "a cutaway on every wall piece");
		Test.Assert(!HasScriptComponent(scene), "no script behaviour left");

		CheckKitPiece<Lamplight.Pebble>(project, "Pebble", scope (stone) => stone.Lifetime == 6.0f);
	}

	[Test]
	public static void TheSnowlineSourcesReadAtTheCurrentDataVersionsAndCook()
	{
		// 142 instances: 3 courses and 17 prefabs (the gates', the finish's, the gem's burst and the
		// track mark's, and the 10 models'), 10 model manifests, 36 materials, 12 static meshes and
		// a skinned one, the rider's skeleton, 10 clips and its animation graph, a collision shape,
		// 15 sounds, 5 UI documents and their sheet, 9 textures, 3 terrains with their heightfields,
		// splatmaps and vegetation masks, 4 particle effects, the font, the input map and the
		// environment and post profiles. 122 cook: all but the courses and the prefabs, which stage
		// rather than cook. The behaviours and the game are the game's code,
		// its package loaded to read the courses. Raise the floors when the sample grows.
		CheckSampleProject("Snowline", "scratch_snowline_versions", 142, 122, "snowline", => CheckSnowline);
	}

	/// Ridge's entities carry the game's behaviours, resolved into their managers with the values
	/// the course gives them, not the defaults (the board's course line and track mark, the
	/// camera's target and seat, each gate's index and width, the finish's medal times, the
	/// kickers' lip, the gap, each medal's ghost, the avalanche's course and release), every gem
	/// among them and no script left; and the track mark's and the gem's burst's prefabs carry
	/// their behaviours.
	private static void CheckSnowline(EditorProject project)
	{
		let ridge = FindInstance(project.SourceDb.RootGroup, "Ridge", McpDocumentNames.cSceneDocument);
		Test.Assert(ridge != null, "Ridge");
		let trackMark = FindInstance(project.SourceDb.RootGroup, "TrackMark", McpDocumentNames.cPrefabDocument);
		Test.Assert(trackMark != null, "the TrackMark prefab");
		if ((ridge == null) || (trackMark == null))
			return;
		let scene = scope Scene(ridge.Name);
		EngineSceneComposition.AddAllSceneManagers(scene); // the package's behaviour managers among them
		Test.Assert(SceneStorage.LoadScene(ridge, scene) case .Ok, "Ridge's stream");
		let course = scene.FindEntityByName("Course");
		Test.Assert(scene.IsValid(course), "the course line");
		let courseId = scene.GetEntityId(course);
		let boards = scene.GetSystem<BehaviourManager<Snowline.Board>>();
		Test.Assert((boards != null) && (boards.Count == 1), "one Board, resolved");
		if ((boards == null) || (boards.Count != 1))
			return;
		let rider = boards.OwnerHandles[0];
		Test.Assert(scene.GetEntityName(rider) == "Rider");
		let board = boards.Instances[0];
		Test.Assert((board.Course.Id == courseId) && (board.TrackMark.Id == trackMark.Id) && !board.Autopilot,
			"the board rides the course line and leaves the TrackMark prefab");
		let cameras = scene.GetSystem<BehaviourManager<Snowline.FollowCamera>>();
		Test.Assert((cameras != null) && (cameras.Count == 1) && (cameras.Instances[0].Target.Id == scene.GetEntityId(rider))
			&& (cameras.Instances[0].Distance == 5.5f) && (cameras.Instances[0].LookHeight == 0.9f), "the camera follows the rider, close");
		let gates = scene.GetSystem<BehaviourManager<Snowline.Gate>>();
		Test.Assert((gates != null) && (gates.Count == 9), "Ridge's nine gates");
		if (gates != null)
		{
			int32 indices = 0;
			for (let gate in gates.Instances)
			{
				Test.Assert((gate.HalfWidth == 4.0f) && (gate.Index >= 0) && (gate.Index < 9), "a gate's width and place");
				indices |= (int32)1 << gate.Index;
			}
			Test.Assert(indices == 0x1FF, "each gate its own place down the course");
		}
		let finishes = scene.GetSystem<BehaviourManager<Snowline.Finish>>();
		Test.Assert((finishes != null) && (finishes.Count == 1) && (finishes.Instances[0].Gold == 29.0f)
			&& (finishes.Instances[0].Silver == 33.0f) && (finishes.Instances[0].Bronze == 40.0f), "Ridge's medal times");
		let gems = scene.GetSystem<BehaviourManager<Snowline.Gem>>();
		Test.Assert((gems != null) && (gems.Count == 25), "Ridge's gems");
		let kickers = scene.GetSystem<BehaviourManager<Snowline.Kicker>>();
		Test.Assert((kickers != null) && (kickers.Count == 4), "three kickers and the gap's");
		if (kickers != null)
		{
			for (let kicker in kickers.Instances)
				Test.Assert(Math.Abs(kicker.RampRun - 3.8827f) < 0.001f, "a kicker's lip, the course's, not the default");
		}
		let gaps = scene.GetSystem<BehaviourManager<Snowline.Gap>>();
		Test.Assert((gaps != null) && (gaps.Count == 1) && (gaps.Instances[0].Short == 13.5f) && (gaps.Instances[0].Reach == 30.0f),
			"the crevasse");
		let ghosts = scene.GetSystem<BehaviourManager<Snowline.Ghost>>();
		Test.Assert((ghosts != null) && (ghosts.Count == 3), "a ghost per medal");
		if (ghosts != null)
		{
			int32 medals = 0;
			for (let ghost in ghosts.Instances)
			{
				Test.Assert(ghost.FinishDistance > 0.0f, "a ghost's run to the finish");
				medals |= (int32)1 << (int32)ghost.Medal;
			}
			Test.Assert(medals == 0x7, "gold, silver and bronze");
		}
		let avalanches = scene.GetSystem<BehaviourManager<Snowline.Avalanche>>();
		Test.Assert((avalanches != null) && (avalanches.Count == 1) && (avalanches.Instances[0].Course.Id == courseId)
			&& (avalanches.Instances[0].ReleaseAt == 270.0f), "the avalanche on the course line, released where Ridge says");
		let playerGhosts = scene.GetSystem<BehaviourManager<Snowline.PlayerGhost>>();
		Test.Assert((playerGhosts != null) && (playerGhosts.Count == 1), "the player's ghost");
		Test.Assert(!HasScriptComponent(scene), "no script behaviour left");

		CheckKitPiece<Snowline.TrackMark>(project, "TrackMark", scope (mark) => mark.Life == 6.0f);
		CheckKitPiece<Snowline.Expire>(project, "GemSparkle", scope (burst) => burst.Life == 1.2f);
	}

	/// The first instance under `group` named `name` whose type name ends with `typeName`, or null.
	public static Instance FindInstance(Group group, StringView name, StringView typeName)
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
		// 332 instances: 3 maps and 3 hunter prefabs, 6 rigged costumes with their clips and
		// materials (the masks and fabrics on 2 custom shaders), the palace, canal and garden kits,
		// 3 navigation zones, 7 UI documents and their sheet, 10 generated sounds and music, the
		// profiles, the input map, the font, the sky and the primitives. 287 cook: all but the
		// maps, the prefabs and the model manifests. The behaviours and the
		// game are the game's code, its package loaded to read the maps. Raise the floors when the
		// sample grows.
		CheckSampleProject("Masquerade", "scratch_masquerade_versions", 332, 287, "masquerade", => CheckMasquerade);
	}

	/// The Palace's entities carry the game's behaviours, resolved into their managers with the
	/// values the map gives them, not the defaults (the ball's seats, crowd, places, players and
	/// hunter prefab, the player's camera and crowd, the camera's target and seat, every guest's
	/// places and players), the orchestra on the dais, the round's replicated fields at their
	/// starting values, and no script left; and the hunter prefab carries its Player.
	private static void CheckMasquerade(EditorProject project)
	{
		let palace = FindInstance(project.SourceDb.RootGroup, "Palace", McpDocumentNames.cSceneDocument);
		Test.Assert(palace != null, "the Palace");
		let hunter = FindInstance(project.SourceDb.RootGroup, "HunterPalace", McpDocumentNames.cPrefabDocument);
		Test.Assert(hunter != null, "the HunterPalace prefab");
		if ((palace == null) || (hunter == null))
			return;
		let scene = scope Scene(palace.Name);
		EngineSceneComposition.AddAllSceneManagers(scene); // the package's behaviour managers among them
		Test.Assert(SceneStorage.LoadScene(palace, scene) case .Ok, "the Palace's stream");
		let player = scene.FindEntityByName("Player");
		let camera = scene.FindEntityByName("Camera");
		let crowd = scene.FindEntityByName("Crowd");
		Test.Assert(scene.IsValid(player) && scene.IsValid(camera) && scene.IsValid(crowd), "the player, the camera and the crowd");
		let playerId = scene.GetEntityId(player);
		let crowdId = scene.GetEntityId(crowd);
		let balls = scene.GetSystem<BehaviourManager<Masquerade.Ball>>();
		Test.Assert((balls != null) && (balls.Count == 1), "one Ball, resolved");
		if ((balls == null) || (balls.Count != 1))
			return;
		Test.Assert(scene.GetEntityName(balls.OwnerHandles[0]) == "Ball");
		let ball = balls.Instances[0];
		Test.Assert((ball.Player.Id == playerId) && (ball.Crowd.Id == crowdId) && (ball.HunterPrefab.Id == hunter.Id),
			"the ball's player, crowd and the Palace's hunter prefab");
		Test.Assert(scene.IsValid(scene.FindEntity(ball.Bot1.Id)) && scene.IsValid(scene.FindEntity(ball.Bot2.Id))
			&& scene.IsValid(scene.FindEntity(ball.Bot3.Id)) && (ball.Spots.Id != Guid.Empty) && (ball.Players.Id != Guid.Empty),
			"the three bots, the places and the players");
		Test.Assert((ball.RoundSeconds == 240.0f) && (ball.TargetPoints == 100) && (ball.MissPoints == 25)
			&& (ball.Owner0 == 0) && (ball.Owner1 == -1) && (ball.Owner3 == -1) && (ball.Target0 == 1) && (ball.Target3 == 0),
			"the round's settings and its seats at their start");
		let players = scene.GetSystem<BehaviourManager<Masquerade.Player>>();
		Test.Assert((players != null) && (players.Count == 1) && (players.OwnerHandles[0] == player), "the player's hunter");
		if ((players != null) && (players.Count == 1))
		{
			Test.Assert((players.Instances[0].Camera.Id == scene.GetEntityId(camera)) && (players.Instances[0].Crowd.Id == crowdId),
				"the player moves by the camera and shoulders through the crowd");
		}
		let rigs = scene.GetSystem<BehaviourManager<Masquerade.CameraRig>>();
		Test.Assert((rigs != null) && (rigs.Count == 1) && (rigs.Instances[0].Target.Id == playerId)
			&& (rigs.Instances[0].Distance == 7.0f) && (rigs.Instances[0].Height == 9.0f), "the camera follows the player, high");
		let guests = scene.GetSystem<BehaviourManager<Masquerade.Guest>>();
		Test.Assert((guests != null) && (guests.Count == 153), "150 guests and the three bots");
		if (guests != null)
		{
			for (let guest in guests.Instances)
				Test.Assert((guest.Spots.Id == ball.Spots.Id) && (guest.Players.Id == ball.Players.Id), "a guest's places and players");
		}
		let orchestras = scene.GetSystem<BehaviourManager<Masquerade.Orchestra>>();
		Test.Assert((orchestras != null) && (orchestras.Count == 1) && (scene.GetEntityName(orchestras.OwnerHandles[0]) == "Dais"),
			"the orchestra on the dais");
		Test.Assert(!HasScriptComponent(scene), "no script behaviour left");

		CheckKitPiece<Masquerade.Player>(project, "HunterPalace", scope (joiner) => (joiner.Camera.Id == Guid.Empty) && (joiner.SprintSpeed == 3.0f));
	}

	/// Whether an entity of `scene` still carries a script component: the engine has none, so a
	/// record of one in a scene of the current stream version reads as unresolved and is kept for
	/// the save (an older scene's is dropped as it reads).
	private static bool HasScriptComponent(Scene scene)
	{
		for (let record in scene.UnresolvedComponents)
		{
			if (record.TypeId == "script")
				return true;
		}
		return false;
	}
}
