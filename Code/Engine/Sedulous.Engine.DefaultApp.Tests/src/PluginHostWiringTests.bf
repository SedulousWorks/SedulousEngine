using System;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Engine.Composition;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The probe plugin's Engine part: what it found when it loaded, and whether it was unloaded.
class AppProbePart : PluginPart
{
	public static ClientServices Client;
	public static EnginePluginServices EngineServices;
	public static int Loads;
	public static int Unloads;

	public override StringView PluginId => "app_probe";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		Client = context.Find<ClientServices>();
		EngineServices = context.Find<EnginePluginServices>();
		Loads++;
	}

	public override void Unload(PluginContext context) => Unloads++;
}

/// The process's plugin host from the app: made only once the app is configured, it gives the
/// plugins this app's client services (its host and data mount) and the engine's service for
/// Engine parts, and the app's shutdown unloads them.
class PluginHostWiringTests
{
	[Test]
	public static void CreatePluginHostOffersTheAppsServicesAndTheAppsShutdownUnloadsThePlugins()
	{
		AppProbePart.Client = null;
		AppProbePart.EngineServices = null;
		AppProbePart.Loads = 0;
		AppProbePart.Unloads = 0;
		let host = scope StubHost();
		let app = scope DefaultApplication();
		Test.Assert(app.CreatePluginHost(.Player) == null, "not configured: nothing to offer");
		app.Configure(host);
		let plugins = app.CreatePluginHost(.Player);
		Test.Assert(plugins != null);
		defer delete plugins;
		Test.Assert(plugins.Role == .Player);

		let manifest = scope PluginManifest();
		manifest.Id.Set("app_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let probe = scope AppProbePart();
		PluginPart[1] parts = .(probe);
		Test.Assert(plugins.AddLinked(manifest.Write(.. scope .()), parts) case .Ok);
		let report = scope PluginLoadReport();
		plugins.Load(scope StringView[]("app_probe"), report);
		Test.Assert(report.Loaded.Count == 1, (report.Refused.Count > 0) ? report.Refused[0].Reason : "");

		Test.Assert(AppProbePart.Client != null);
		Test.Assert(AppProbePart.Client.Host === host);
		Test.Assert(AppProbePart.Client.Data === app.DataFileSystem);
		Test.Assert(AppProbePart.EngineServices != null);
		Test.Assert(AppProbePart.Unloads == 0);

		host.Subsystems.Startup();
		app.OnStartup(host);
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		Test.Assert(AppProbePart.Unloads == 1);
		Test.Assert(!plugins.IsLoaded("app_probe"));
		host.Subsystems.Dispose();
	}
}
