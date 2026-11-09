using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// A prefab as a resource: PrefabFactory loads the record's scene stream into a PrefabResource,
/// and PrefabPayloads opens loaded prefabs for a spawn.
static class PrefabResourceTests
{
	/// Spawns the loaded prefab into a fresh scene and returns its root's rounds, or -1.
	private static int32 SpawnedRounds(PrefabResource prefab)
	{
		let scene = scope Scene("level");
		let ammo = scene.AddSystem<AmmoManager>();
		let payload = prefab.OpenPayload();
		defer delete payload;
		let root = PrefabSpawn.Spawn(scene, payload, prefab.Id);
		if (!root.IsAssigned)
			return -1;
		Test.Assert(scene.GetEntityName(root) == "Turret");
		Test.Assert(scene.GetChildCount(root) == 1, "the child came with it");
		let rounds = ammo.Get(root);
		return (rounds != null) ? rounds.Rounds : -2;
	}

	/// The turret captured in the binary wire, under a prefab record of its own.
	private static Guid StoreBinaryTurret(PrefabDatabaseFixture fixture, StringView name, int32 rounds)
	{
		let template = scope Scene(name);
		let ammo = template.AddSystem<AmmoManager>();
		let root = template.CreateEntity("Turret");
		ammo.Add(root).Rounds = rounds;
		let barrel = template.CreateEntity("Barrel");
		template.SetParent(barrel, root);
		let captured = scope MemoryStream();
		Test.Assert(PrefabCapture.Capture(template, root, captured, .Binary) case .Ok);

		let instance = fixture.Database.RootGroup.CreateInstance(name, PrefabDatabaseFixture.cPrefabTypeName);
		let document = scope PrefabDocument();
		document.Name.Set(name);
		Test.Assert(instance.WriteObject(document) case .Ok);
		Test.Assert(instance.WriteData(SceneStorage.cStreamName, captured.Bytes, .Binary) case .Ok);
		return instance.Id;
	}

	[Test]
	public static void ATextPrefabAndABinaryOneBind()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_bind");
		let text = fixture.StoreTurret("turret", 30);
		let binary = StoreBinaryTurret(fixture, "packed", 12);
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);

		let fromText = manager.Bind<PrefabResource>(text);
		Test.Assert(fromText.State == .Ready);
		Test.Assert(fromText.Get.Id == text);
		Test.Assert(fromText.Get.Name == "turret");
		Test.Assert(fromText.Get.Encoding == .Text, "a source's text is kept as it is");
		Test.Assert(fromText.Get.PayloadSize > 0);
		Test.Assert(SpawnedRounds(fromText.Get) == 30);

		let fromBinary = manager.Bind<PrefabResource>(binary);
		Test.Assert(fromBinary.State == .Ready);
		Test.Assert(fromBinary.Get.Encoding == .Binary);
		Test.Assert(SpawnedRounds(fromBinary.Get) == 12);

		// One handle per prefab: binding again shares the product.
		Test.Assert(manager.Bind<PrefabResource>(text).Get === fromText.Get);
	}

	[Test]
	public static void AReferenceToAPrefabReachesReady()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_ref");
		let turret = fixture.StoreTurret("turret", 7);
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);

		var reference = Ref<PrefabResource>(turret);
		Test.Assert(reference.State == .Unloaded);
		reference.Bind(manager);
		Test.Assert(reference.State == .Ready);
		Test.Assert(reference.Get.Id == turret);
		Test.Assert(SpawnedRounds(reference.Get) == 7);
	}

	[Test]
	public static void AnUnknownIdOrARecordThatIsNoPrefabFails()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_fail");
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);

		let unknown = manager.Bind<PrefabResource>(Guid.Create());
		Test.Assert(unknown.State == .Failed);
		Test.Assert(unknown.Get == null);

		// A prefab record with no scene stream.
		let empty = fixture.Database.RootGroup.CreateInstance("empty", PrefabDatabaseFixture.cPrefabTypeName);
		Test.Assert(manager.Bind<PrefabResource>(empty.Id).State == .Failed);

		// A scene, stream and all: never loaded through a prefab reference.
		let level = scope Scene("level");
		level.CreateEntity("Ground");
		let sceneRecord = fixture.Database.RootGroup.CreateInstance("level", "Sedulous.Scene.Resource.SceneDocument");
		Test.Assert(SceneStorage.SaveScene(level, sceneRecord) case .Ok);
		Test.Assert(manager.Bind<PrefabResource>(sceneRecord.Id).State == .Failed);
	}

	[Test]
	public static void AnAsyncBindCompletesOnPump()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_async");
		let turret = fixture.StoreTurret("turret", 9);
		let tasks = scope TaskPool(2);
		let manager = scope ResourceManager(fixture.Database, tasks);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<PrefabResource>(turret);
		Test.Assert(proxy.State == .Pending, "the load is on a worker");
		Test.Assert(proxy.Get == null);

		for (int attempt < 2000)
		{
			manager.Pump();
			if (proxy.State != .Pending)
				break;
			Thread.Sleep(1);
		}
		Test.Assert(proxy.State == .Ready);
		Test.Assert(SpawnedRounds(proxy.Get) == 9);
		Test.Assert(manager.PendingCount == 0);
	}

	/// A composer that gives a scratch scene the turret's manager, as the application's gives every
	/// manager it has.
	private static SceneComposer TurretComposer() => new .(new (scene) => { scene.AddSystem<AmmoManager>(); });

	[Test]
	public static void ATextPrefabLoadsInTheBinaryFormatGivenAComposer()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_transcode");
		let turret = fixture.StoreTurret("turret", 30);
		let composer = TurretComposer();
		defer delete composer;
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory(composer);
		manager.AddFactory(factory);

		let loaded = manager.Bind<PrefabResource>(turret);
		Test.Assert(loaded.State == .Ready);
		Test.Assert(loaded.Get.Encoding == .Binary, "transcoded as it loaded");
		Test.Assert(loaded.Get.Name == "turret");
		Test.Assert(SpawnedRounds(loaded.Get) == 30, "nothing lost on the way");

		// The stored record is untouched: the source stays text.
		let stored = fixture.Database.GetInstance(turret).ReadData(SceneStorage.cStreamName);
		defer delete stored;
		Test.Assert(SceneStreamFormat.DetectEncoding(stored) == .Text);
	}

	[Test]
	public static void AnAsyncLoadTranscodesOnPump()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_transcode_async");
		let turret = fixture.StoreTurret("turret", 7);
		let composer = TurretComposer();
		defer delete composer;
		let tasks = scope TaskPool(2);
		let manager = scope ResourceManager(fixture.Database, tasks);
		let factory = scope PrefabFactory(composer);
		manager.AddFactory(factory);

		let proxy = manager.BindAsync<PrefabResource>(turret);
		for (int attempt < 2000)
		{
			manager.Pump();
			if (proxy.State != .Pending)
				break;
			Thread.Sleep(1);
		}
		Test.Assert(proxy.State == .Ready);
		Test.Assert(proxy.Get.Encoding == .Binary);
		Test.Assert(SpawnedRounds(proxy.Get) == 7);
	}

	[Test]
	public static void APrefabWithAComponentNoManagerReadsStaysText()
	{
		// The composer knows no ammo: the binary would be written without it, so the text is
		// kept, and a scene that has the manager spawns the prefab whole.
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_transcode_absent");
		let turret = fixture.StoreTurret("turret", 30);
		let composer = scope SceneComposer(new (scene) => {});
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory(composer);
		manager.AddFactory(factory);

		let loaded = manager.Bind<PrefabResource>(turret);
		Test.Assert(loaded.State == .Ready);
		Test.Assert(loaded.Get.Encoding == .Text, "kept as stored");
		Test.Assert(SpawnedRounds(loaded.Get) == 30, "its ammo kept");
	}

	[Test]
	public static void TheSceneModulesFactoryTakesTheHostsComposer()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_transcode_module");
		let turret = fixture.StoreTurret("turret", 4);
		let composer = TurretComposer();
		defer delete composer;
		let services = scope ResourceServiceTable();
		services.Add(typeof(SceneComposer), composer);

		let modules = scope ResourceModule[](SceneResources.Module);
		let factories = scope ResourceFactorySet();
		factories.Create(modules, services);
		Test.Assert(factories.Count == 1);
		let manager = scope ResourceManager(fixture.Database);
		factories.Register(manager);
		Test.Assert(manager.Bind<PrefabResource>(turret).Get.Encoding == .Binary);

		// A host offering none still loads prefabs, as stored.
		let headless = scope ResourceFactorySet();
		headless.Create(modules, scope NoResourceServices());
		Test.Assert(headless.Count == 1);
		let plain = scope ResourceManager(fixture.Database);
		headless.Register(plain);
		Test.Assert(plain.Bind<PrefabResource>(turret).Get.Encoding == .Text);
	}

	[Test]
	public static void AReloadReadsTheRewrittenStream()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_reload");
		let turret = fixture.StoreTurret("turret", 30);
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);

		let proxy = manager.Bind<PrefabResource>(turret);
		Test.Assert(SpawnedRounds(proxy.Get) == 30);

		// Rewritten on disk: the loaded prefab is what it was until a reload.
		Test.Assert(fixture.StoreTurret("turret", 45) == turret, "the same record rewritten");
		Test.Assert(SpawnedRounds(proxy.Get) == 30);

		manager.Reload(turret);
		Test.Assert(proxy.State == .Ready);
		Test.Assert(SpawnedRounds(proxy.Get) == 45, "the held proxy sees the new bytes");
		Test.Assert(manager.GraveyardCount == 1, "the old prefab waits out the frames in flight");
	}

	/// A prefab whose payload nests an instance of itself: its nested instance is refused, not
	/// spawned again.
	[Test]
	public static void APrefabNestingItselfIsRefused()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_self");
		let loop = fixture.StoreTurret("loop", 3);
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);

		// Its template: a shell holding an instance of the prefab itself, written past the
		// save's own refusal, as a bad edit outside the editor would.
		{
			let template = scope Scene("loop");
			template.AddSystem<AmmoManager>();
			let shell = template.CreateEntity("Shell");
			let plain = manager.Bind<PrefabResource>(loop).Get;
			let payload = plain.OpenPayload();
			defer delete payload;
			Test.Assert(PrefabSpawn.Spawn(template, payload, loop, shell).IsAssigned);
			let captured = scope MemoryStream();
			Test.Assert(PrefabCapture.Capture(template, shell, captured, .Text) case .Ok);
			let record = fixture.Database.GetInstance(loop);
			Test.Assert(record.WriteData(SceneStorage.cStreamName, captured.Bytes, .Text) case .Ok);
		}
		manager.Reload(loop);

		let payloads = scope PrefabPayloads(manager);
		let scene = scope Scene("level");
		scene.AddSystem<AmmoManager>();
		{
			let payload = payloads.Open(loop);
			Test.Assert(payload != null);
			defer delete payload;
			Test.Assert(payloads.Depth == 1);
			Test.Assert(payloads.Open(loop) == null, "open already: it would nest itself");

			let root = PrefabSpawn.Spawn(scene, payload, loop, .Invalid, null, payloads.Resolver);
			Test.Assert(root.IsAssigned);
			Test.Assert(scene.GetEntityName(root) == "Shell");
			Test.Assert(scene.PrefabInstanceCount == 1, "the nested instance of itself was refused");
			Test.Assert(scene.GetChildCount(root) == 0);
		}
		Test.Assert(payloads.Depth == 0, "closed with its stream");
		let again = payloads.Open(loop);
		Test.Assert(again != null, "and open again once closed");
		delete again;
	}

	/// Distinct prefabs open together past the depth limit: the one beyond it is refused.
	[Test]
	public static void AChainDeeperThanTheLimitIsRefused()
	{
		let fixture = scope PrefabDatabaseFixture("scratch_prefab_resource_depth");
		let manager = scope ResourceManager(fixture.Database);
		let factory = scope PrefabFactory();
		manager.AddFactory(factory);
		let payloads = scope PrefabPayloads(manager);

		let open = scope List<IStream>();
		defer { ClearAndDeleteItems!(open); }
		for (int i < PrefabPayloads.cMaxDepth)
		{
			let stream = payloads.Open(fixture.StoreTurret(scope $"link{i}", (int32)i));
			Test.Assert(stream != null);
			open.Add(stream);
		}
		let beyond = fixture.StoreTurret("beyond", 1);
		Test.Assert(payloads.Open(beyond) == null);
		Test.Assert(payloads.Open(Guid.Create()) == null, "an unknown prefab opens nothing");

		delete open.PopBack();
		let inside = payloads.Open(beyond);
		Test.Assert(inside != null, "within the limit once one closed");
		open.Add(inside);
	}
}
