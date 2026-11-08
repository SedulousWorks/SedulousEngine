using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Resource;
using Sedulous.Run;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Composition;

namespace Sedulous.Engine.Composition.Tests;

/// A scene manager a plugin contributes.
class ServicesProbeManager : SceneSystem
{
}

/// The probe plugin's Engine part: a domain, a domain with scene content (refused), and a scene
/// manager, all through EnginePluginServices.
class ServicesProbePart : PluginPart
{
	public static int DomainTypes = 0;
	public static bool RefusedSceneDomain = false;
	public static bool FoundServices = false;

	private ResourceModule mResources = new .("services_probe", => RegisterProbeTypes, null) ~ delete _;
	private DomainModule mDomain ~ delete _;
	private DomainModule mSceneDomain = new .("services_scene", => InstallNothing) ~ delete _;

	public this()
	{
		mDomain = new .("services_probe", null, new .(mResources));
	}

	private static void RegisterProbeTypes() => DomainTypes++;
	private static void InstallNothing(Sedulous.Scene.Scene scene) {}
	public static void InstallProbeManager(Sedulous.Scene.Scene scene) => scene.AddSystem<ServicesProbeManager>();

	public static uint64 ManagerType
	{
		get
		{
			let name = scope String();
			typeof(ServicesProbeManager).GetFullName(name);
			return TypeIdOf(name);
		}
	}

	public override StringView PluginId => "services_probe";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		let services = context.Find<EnginePluginServices>();
		FoundServices = services != null;
		if (services == null)
			return;
		services.AddDomain(mDomain);
		RefusedSceneDomain = !services.AddDomain(mSceneDomain);
		var contribution = SceneModuleContribution();
		contribution.Id = "services_probe";
		contribution.Install = => InstallProbeManager;
		contribution.SystemType = ManagerType;
		services.AddSceneManager(contribution);
	}
}

/// A run listener a plugin adds: it counts what it hears and its deletion.
class ProbeRunListener : IRunListener
{
	public static int Created = 0;
	public static int Started = 0;
	public static int Stopping = 0;
	public static int Deleted = 0;

	public static void Reset()
	{
		Created = 0;
		Started = 0;
		Stopping = 0;
		Deleted = 0;
	}

	public ~this()
	{
		Deleted++;
	}

	public void OnRunCreated(IRun run)
	{
		Created++;
	}

	public void OnRunStarted(IRun run)
	{
		Started++;
	}

	public void OnRunStopping(IRun run)
	{
		Stopping++;
	}
}

/// The probe plugin's Engine part adding a run listener through EnginePluginServices.
class RunListenerProbePart : PluginPart
{
	public static bool Added = false;

	public override StringView PluginId => "run_listener_probe";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		let services = context.Find<EnginePluginServices>();
		Added = (services != null) && services.AddRunListener(new ProbeRunListener());
	}
}

/// What a plugin's Engine part adds through EnginePluginServices: a domain and a scene manager,
/// each reaching what it extends, and both gone when the host unloads.
static class EnginePluginServicesTests
{
	private static bool HasModule(StringView id)
	{
		for (let module in EngineComposition.Modules)
		{
			if (module.Id == id)
				return true;
		}
		return false;
	}

	[Test]
	public static void APartsDomainAndSceneManagerArriveAndLeaveWithThePlugin()
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set("services_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let xml = manifest.Write(.. scope .());
		let probe = scope ServicesProbePart();
		ServicesProbePart.DomainTypes = 0;
		SceneModuleContributions.Global.Remove(ServicesProbePart.ManagerType);

		let subsystems = scope SubsystemManager();
		let services = scope EnginePluginServices();
		{
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			Test.Assert(services.Attach(host));
			PluginPart[1] parts = .(probe);
			Test.Assert(host.AddLinked(xml, parts) case .Ok);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("services_probe"), report);
			Test.Assert(report.Loaded.Count == 1);

			Test.Assert(ServicesProbePart.FoundServices);
			Test.Assert(HasModule("services_probe"));
			Test.Assert(ServicesProbePart.DomainTypes == 1);
			Test.Assert(ServicesProbePart.RefusedSceneDomain);
			Test.Assert(!HasModule("services_scene"));
			Test.Assert(SceneModuleContributions.Global.Contains(ServicesProbePart.ManagerType));

			// A scene made now gets the contributed manager.
			let scratch = scope Sedulous.Scene.Scene("services-probe");
			SceneModuleContributions.Global.InstallAll(scratch);
			Test.Assert(scratch.HasSystem<ServicesProbeManager>());

			host.Unload();
			Test.Assert(!HasModule("services_probe"));
			Test.Assert(!SceneModuleContributions.Global.Contains(ServicesProbePart.ManagerType));
		}
	}

	/// A host whose layers provide nothing: the part finds no service and adds nothing.
	[Test]
	public static void APartOfAHostWithoutTheServiceFindsNone()
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set("services_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let probe = scope ServicesProbePart();
		let subsystems = scope SubsystemManager();
		let host = scope PluginHost(subsystems, .Cook, "0.1.0");
		PluginPart[1] parts = .(probe);
		Test.Assert(host.AddLinked(manifest.Write(.. scope .()), parts) case .Ok);
		ServicesProbePart.FoundServices = true;
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("services_probe"), report);
		Test.Assert(report.Loaded.Count == 1);
		Test.Assert(!ServicesProbePart.FoundServices);
		Test.Assert(!HasModule("services_probe"));
		host.Unload();
	}

	private static String RunListenerManifest()
	{
		let manifest = scope PluginManifest();
		manifest.Id.Set("run_listener_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		return manifest.Write(.. new .());
	}

	/// A run listener a part adds hears the runs made before it (caught up: created, and started
	/// when a session is under way) and the transitions after; the unload unsubscribes and
	/// deletes it, so the runs' later transitions reach nothing.
	[Test]
	public static void APartsRunListenerHearsTheRunsUntilTheUnload()
	{
		ProbeRunListener.Reset();
		let playing = scope RunBase("playing");
		let idle = scope RunBase("idle");
		let runs = scope RunRegistry();
		runs.Add(playing);
		runs.Add(idle);
		playing.Start();

		let subsystems = scope SubsystemManager();
		subsystems.SetRunManager(runs);
		let services = scope EnginePluginServices();
		let xml = RunListenerManifest();
		defer delete xml;
		let probe = scope RunListenerProbePart();
		{
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			Test.Assert(services.Attach(host));
			PluginPart[1] parts = .(probe);
			Test.Assert(host.AddLinked(xml, parts) case .Ok);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("run_listener_probe"), report);
			Test.Assert(report.Loaded.Count == 1);

			Test.Assert(RunListenerProbePart.Added);
			Test.Assert(ProbeRunListener.Created == 2, "caught up on both runs");
			Test.Assert(ProbeRunListener.Started == 1, "and on the one playing");
			Test.Assert(services.FindRunListener<ProbeRunListener>() != null);

			idle.Start();
			playing.Stop();
			Test.Assert(ProbeRunListener.Started == 2);
			Test.Assert(ProbeRunListener.Stopping == 1);

			host.Unload();
			Test.Assert(ProbeRunListener.Deleted == 1, "the unload deletes it");
			Test.Assert(services.FindRunListener<ProbeRunListener>() == null);
			idle.Stop();
			let later = scope RunBase("later");
			runs.Add(later);
			Test.Assert((ProbeRunListener.Stopping == 1) && (ProbeRunListener.Created == 2), "unsubscribed: it hears nothing more");
		}
	}

	/// In a host without runs (no run manager on its subsystems), a run listener is refused and
	/// deleted.
	[Test]
	public static void ARunListenerWithoutRunsIsRefused()
	{
		ProbeRunListener.Reset();
		let subsystems = scope SubsystemManager();
		let services = scope EnginePluginServices();
		let host = scope PluginHost(subsystems, .Cook, "0.1.0");
		Test.Assert(services.Attach(host));
		Test.Assert(!services.AddRunListener(new ProbeRunListener()));
		Test.Assert(ProbeRunListener.Deleted == 1);
		Test.Assert(services.FindRunListener<ProbeRunListener>() == null);
	}

	/// A listener no unload took out goes with the service: unsubscribed and deleted.
	[Test]
	public static void ARunListenerLeftOverGoesWithTheService()
	{
		ProbeRunListener.Reset();
		let run = scope RunBase("run");
		let runs = scope RunRegistry();
		runs.Add(run);
		let subsystems = scope SubsystemManager();
		subsystems.SetRunManager(runs);
		{
			let services = scope EnginePluginServices();
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			Test.Assert(services.Attach(host));
			Test.Assert(services.AddRunListener(new ProbeRunListener()));
			Test.Assert(ProbeRunListener.Created == 1);
		}
		Test.Assert(ProbeRunListener.Deleted == 1);
		run.Start();
		Test.Assert(ProbeRunListener.Started == 0, "unsubscribed as it went");
	}
}
