using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Resource;
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
}
