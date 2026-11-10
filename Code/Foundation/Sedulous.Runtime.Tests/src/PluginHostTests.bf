using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// A type a part registers, to show the recording reverses it on unload.
[Serializable]
class HostProbeSettings
{
	public int32 Value;
}

/// A subsystem a part adds and its unload removes.
class HostProbeSubsystem : Subsystem
{
}

/// A part that logs its load and unload as "load:<id>:<Kind>" and "unload:<id>:<Kind>".
class LoggedPart : PluginPart
{
	private String mId = new .() ~ delete _;
	private PluginPartKind mKind;

	public this(StringView id, PluginPartKind kind)
	{
		mId.Set(id);
		mKind = kind;
	}

	public override StringView PluginId => mId;
	public override PluginPartKind Kind => mKind;

	public override void Load(PluginContext context) => PluginHostTests.Record("load", context, mKind);
	public override void Unload(PluginContext context) => PluginHostTests.Record("unload", context, mKind);
}

/// A service a host provides, and one it does not.
class ClockService
{
	public int Ticks;
}

class AbsentService
{
}

/// A part that uses the services its host provides.
class ServiceUserPart : PluginPart
{
	public static bool SawAbsent = true;

	public override StringView PluginId => "service_user";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		if (let clock = context.Find<ClockService>())
			clock.Ticks++;
		SawAbsent = context.Find<AbsentService>() != null;
	}
}

/// The registrar's Engine part: registers a serializable type and adds a subsystem.
class RegistrarPart : PluginPart
{
	public override StringView PluginId => "registrar";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		GlobalSerializableRegistry.Register(HostProbeSettings.TypeId, () => new HostProbeSettings());
		context.Subsystems.AddSubsystem<HostProbeSubsystem>();
		PluginHostTests.Record("load", context, .Engine);
	}

	public override void Unload(PluginContext context)
	{
		context.Subsystems.RemoveSubsystem<HostProbeSubsystem>();
		PluginHostTests.Record("unload", context, .Engine);
	}
}

/// The plugin host: which of the plugins compiled in it enables for a project's ids and its
/// role, in what order, which it refuses and why, and that unload reverses everything.
class PluginHostTests
{
	/// Every load and unload, in call order.
	private static List<String> sLog = new .() ~ DeleteContainerAndItems!(_);

	public static void Record(StringView what, PluginContext context, PluginPartKind kind)
	{
		sLog.Add(new $"{what}:{context.PluginId}:{kind}");
	}

	private static void ClearLog() => ClearAndDeleteItems!(sLog);

	/// The platforms a test plugin supports unless it names its own.
	private static StringView[3] sEveryPlatform = .("Linux64", "Win64", "Web");

	/// The parts compiled into the test, and the manifests their plugins carry.
	private class Linked
	{
		public List<PluginPart> Parts = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Manifests = new .() ~ DeleteContainerAndItems!(_);
		public List<List<PluginPart>> Sets = new .() ~ DeleteContainerAndItems!(_);

		/// A plugin of `id` whose manifest lists `kinds`, compiled in with `parts`.
		public void Add(StringView id, Span<PluginPartKind> kinds, Span<PluginPart> parts, StringView dependsOn = "",
			StringView dependsOnVersion = "0.1", StringView provides = "", StringView version = "0.1.0", StringView engineVersion = "0.1",
			Span<StringView> platforms = default)
		{
			let manifest = scope PluginManifest();
			manifest.Id.Set(id);
			manifest.Name.Set(id);
			manifest.Version.Set(version);
			manifest.EngineVersion.Set(engineVersion);
			if (!dependsOn.IsEmpty)
			{
				let dependency = new PluginDependency();
				dependency.Id.Set(dependsOn);
				dependency.Version.Set(dependsOnVersion);
				manifest.DependsOn.Add(dependency);
			}
			if (!provides.IsEmpty)
				manifest.Provides.Add(new .(provides));
			for (let kind in kinds)
			{
				let part = new PluginManifestPart();
				kind.ToString(part.Kind);
				manifest.Parts.Add(part);
			}
			for (let platform in (platforms.IsEmpty ? (Span<StringView>)sEveryPlatform : platforms))
			{
				let entry = new PluginPlatform();
				entry.Platform.Set(platform);
				manifest.Platforms.Add(entry);
			}
			let xml = new String();
			Test.Assert(manifest.Write(xml) case .Ok);
			Manifests.Add(xml);
			let group = new List<PluginPart>();
			for (let part in parts)
			{
				group.Add(part);
				if (!Parts.Contains(part))
					Parts.Add(part);
			}
			Sets.Add(group);
		}

		/// A logged part, kept with the set.
		public PluginPart Logged(StringView id, PluginPartKind kind) => new LoggedPart(id, kind);

		public void AddTo(PluginHost host)
		{
			for (int i < Manifests.Count)
				Test.Assert(host.AddLinked(Manifests[i], (Span<PluginPart>)Sets[i]) case .Ok);
		}
	}

	/// alpha (all four parts) <- beta (Engine) <- gamma (Engine, Pipeline); two online backends for
	/// one slot; one built for an older engine; a dependency cycle; an impostor whose part is
	/// another plugin's; the registrar.
	private static void AddStandardPlugins(Linked linked)
	{
		PluginPartKind[4] all = .(.Engine, .Pipeline, .Tooling, .Editor);
		PluginPartKind[1] engine = .(.Engine);
		PluginPartKind[2] enginePipeline = .(.Engine, .Pipeline);
		let alphaEngine = linked.Logged("alpha", .Engine);
		linked.Add("alpha", all, scope PluginPart[](alphaEngine, linked.Logged("alpha", .Pipeline),
			linked.Logged("alpha", .Tooling), linked.Logged("alpha", .Editor)));
		linked.Add("beta", engine, scope PluginPart[](linked.Logged("beta", .Engine)), "alpha");
		linked.Add("gamma", enginePipeline, scope PluginPart[](linked.Logged("gamma", .Engine), linked.Logged("gamma", .Pipeline)), "beta");
		linked.Add("online_local", engine, scope PluginPart[](linked.Logged("online_local", .Engine)), "", "0.1", "online.backend");
		linked.Add("online_steam", engine, scope PluginPart[](linked.Logged("online_steam", .Engine)), "", "0.1", "online.backend");
		linked.Add("old", engine, scope PluginPart[](linked.Logged("old", .Engine)), "", "0.1", "", "0.1.0", "0.0");
		linked.Add("loop_a", engine, scope PluginPart[](linked.Logged("loop_a", .Engine)), "loop_b");
		linked.Add("loop_b", engine, scope PluginPart[](linked.Logged("loop_b", .Engine)), "loop_a");
		linked.Add("impostor", engine, scope PluginPart[](alphaEngine));
		linked.Add("registrar", engine, scope PluginPart[](new RegistrarPart()));
	}

	private static bool Same(List<String> lines, params StringView[] expected)
	{
		if (lines.Count != expected.Count)
			return false;
		for (int i < lines.Count)
		{
			if (lines[i] != expected[i])
				return false;
		}
		return true;
	}

	private static bool RefusedWith(PluginLoadReport report, StringView id, StringView reason)
	{
		let refusal = report.FindRefusal(id);
		return (refusal != null) && refusal.Reason.Contains(reason);
	}

	[Test]
	public static void DependenciesLoadFirstAndUnloadLastWhateverOrderTheProjectListsThem()
	{
		ClearLog();
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);

		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("gamma", "beta", "alpha"), report);
		Test.Assert(report.Refused.IsEmpty);
		Test.Assert(Same(report.Loaded, "alpha", "beta", "gamma"));
		// A player takes Engine parts only: alpha's Pipeline, Tooling and Editor parts stay out.
		Test.Assert(Same(sLog, "load:alpha:Engine", "load:beta:Engine", "load:gamma:Engine"));

		host.Unload();
		Test.Assert(Same(sLog, "load:alpha:Engine", "load:beta:Engine", "load:gamma:Engine",
			"unload:gamma:Engine", "unload:beta:Engine", "unload:alpha:Engine"));
		Test.Assert(!host.IsLoaded("alpha"));
		ClearLog();
	}

	[Test]
	public static void EachRoleLoadsThePartsTheTableGivesItInKindOrder()
	{
		let linked = scope Linked();
		AddStandardPlugins(linked);
		for (int r < HostRole.Count)
		{
			let role = (HostRole)r;
			ClearLog();
			let subsystems = scope SubsystemManager();
			let host = scope PluginHost(subsystems, role, "0.1.0");
			linked.AddTo(host);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("alpha"), report);
			Test.Assert(report.Loaded.Count == 1);
			switch (role)
			{
			case .Player:
				Test.Assert(Same(sLog, "load:alpha:Engine"));
			case .Cook:
				Test.Assert(Same(sLog, "load:alpha:Engine", "load:alpha:Pipeline"));
			case .Export, .Mcp:
				Test.Assert(Same(sLog, "load:alpha:Engine", "load:alpha:Pipeline", "load:alpha:Tooling"));
			case .Editor:
				Test.Assert(Same(sLog, "load:alpha:Engine", "load:alpha:Pipeline", "load:alpha:Tooling", "load:alpha:Editor"));
			}
			host.Unload();
		}
		ClearLog();
	}

	[Test]
	public static void AMissingOrRefusedDependencyDisablesItsDependentsEachWithAMessage()
	{
		ClearLog();
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);

		// alpha is not enabled: beta needs it, and gamma needs beta.
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("beta", "gamma", "online_local"), report);
		Test.Assert(Same(report.Loaded, "online_local"));
		Test.Assert(RefusedWith(report, "beta", "needs 'alpha', which is not enabled"));
		Test.Assert(RefusedWith(report, "gamma", "needs 'beta', which was refused"));
		Test.Assert(Same(sLog, "load:online_local:Engine"));
		host.Unload();
		ClearLog();
	}

	[Test]
	public static void ADependencyOlderThanAskedIsRefused()
	{
		ClearLog();
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		PluginPartKind[1] engine = .(.Engine);
		linked.Add("alpha", engine, scope PluginPart[](linked.Logged("alpha", .Engine)));
		linked.Add("beta", engine, scope PluginPart[](linked.Logged("beta", .Engine)), "alpha", "0.2");
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("alpha", "beta"), report);
		Test.Assert(Same(report.Loaded, "alpha"));
		Test.Assert(RefusedWith(report, "beta", "needs 'alpha' 0.2 or later; it is 0.1.0"));
		host.Unload();
		ClearLog();
	}

	[Test]
	public static void OneProviderPerSlotTheFirstEnabledKeepsIt()
	{
		ClearLog();
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("online_steam", "online_local"), report);
		Test.Assert(Same(report.Loaded, "online_steam"));
		Test.Assert(RefusedWith(report, "online_local", "provides 'online.backend', which 'online_steam' already provides"));
		host.Unload();
		ClearLog();
	}

	[Test]
	public static void RefusedBeforeAnythingLoadsUnknownWrongEngineCycleImpostor()
	{
		ClearLog();
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("nowhere", "old", "loop_a", "loop_b", "impostor"), report);
		Test.Assert(report.Loaded.IsEmpty);
		Test.Assert(RefusedWith(report, "nowhere", "is not in this build"));
		Test.Assert(RefusedWith(report, "old", "needs engine 0.0; this engine is 0.1.0"));
		Test.Assert(RefusedWith(report, "loop_a", "dependency cycle"));
		Test.Assert(RefusedWith(report, "loop_b", "dependency cycle"));
		Test.Assert(RefusedWith(report, "impostor", "is not this plugin's"));
		Test.Assert(sLog.IsEmpty);
	}

	[Test]
	public static void APartTheManifestListsButTheBuildLacksIsRefusedForTheRolesThatLoadIt()
	{
		let linked = scope Linked();
		// Lists a Pipeline part but compiles in only its Engine part, as a player build would.
		PluginPartKind[2] enginePipeline = .(.Engine, .Pipeline);
		linked.Add("alpha", enginePipeline, scope PluginPart[](linked.Logged("alpha", .Engine)));
		{
			ClearLog();
			let subsystems = scope SubsystemManager();
			let player = scope PluginHost(subsystems, .Player, "0.1.0");
			linked.AddTo(player);
			let report = scope PluginLoadReport();
			player.Load(scope StringView[]("alpha"), report);
			Test.Assert(report.Loaded.Count == 1);
			player.Unload();
		}
		{
			ClearLog();
			let subsystems = scope SubsystemManager();
			let cook = scope PluginHost(subsystems, .Cook, "0.1.0");
			linked.AddTo(cook);
			let report = scope PluginLoadReport();
			cook.Load(scope StringView[]("alpha"), report);
			Test.Assert(RefusedWith(report, "alpha", "its Pipeline part is not in this build"));
			Test.Assert(sLog.IsEmpty);
		}
		ClearLog();
	}

	[Test]
	public static void ADormantPluginRegistersNothingALoadedOnesRegistrationsAreReversedOnUnload()
	{
		ClearLog();
		GlobalSerializableRegistry.Unregister(HostProbeSettings.TypeId);
		Test.Assert(!GlobalSerializableRegistry.IsRegistered(HostProbeSettings.TypeId));
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		{
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			linked.AddTo(host);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("alpha"), report);
			Test.Assert(report.Loaded.Count == 1);
			// The registrar is compiled in but not enabled: nothing of it ran.
			Test.Assert(!GlobalSerializableRegistry.IsRegistered(HostProbeSettings.TypeId));
			Test.Assert(!subsystems.HasSubsystem<HostProbeSubsystem>());
		}
		{
			let host = scope PluginHost(subsystems, .Player, "0.1.0");
			linked.AddTo(host);
			let report = scope PluginLoadReport();
			host.Load(scope StringView[]("registrar"), report);
			Test.Assert(report.Loaded.Count == 1);
			Test.Assert(GlobalSerializableRegistry.IsRegistered(HostProbeSettings.TypeId));
			Test.Assert(subsystems.HasSubsystem<HostProbeSubsystem>());
			host.Unload();
			Test.Assert(!GlobalSerializableRegistry.IsRegistered(HostProbeSettings.TypeId), "reversed by the recording");
			Test.Assert(!subsystems.HasSubsystem<HostProbeSubsystem>(), "removed by its unload");
		}
		ClearLog();
	}

	/// The host says which loaded plugin registered a type, lists
	/// a plugin's types, and knows none once it unloads; the engine's types belong to no plugin.
	[Test]
	public static void ATypesOwnerIsThePluginWhoseLoadRegisteredIt()
	{
		ClearLog();
		GlobalSerializableRegistry.Unregister(HostProbeSettings.TypeId);
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("alpha", "registrar"), report);
		Test.Assert(report.Loaded.Count == 2);
		Test.Assert(host.OwnerOf(HostProbeSettings.TypeId) == "registrar");
		Test.Assert(host.OwnerOf(PluginManifest.TypeId).IsEmpty, "the engine's");
		let types = scope List<uint64>();
		host.TypesOf("registrar", types);
		Test.Assert((types.Count == 1) && (types[0] == HostProbeSettings.TypeId));
		types.Clear();
		host.TypesOf("alpha", types);
		Test.Assert(types.IsEmpty, "alpha registered nothing");
		Test.Assert(host.Loaded.Length == 2);
		Test.Assert(host.IsLoaded("registrar") && host.IsLoaded("alpha"));
		host.Unload();
		Test.Assert(host.OwnerOf(HostProbeSettings.TypeId).IsEmpty);
		host.TypesOf("registrar", types);
		Test.Assert(types.IsEmpty);
		Test.Assert(host.Loaded.IsEmpty);
		ClearLog();
	}

	[Test]
	public static void APluginListedTwiceLoadsOnceAndAManifestThatDoesNotReadIsInternal()
	{
		ClearLog();
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		AddStandardPlugins(linked);
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);
		Test.Assert(host.Knows("alpha") && !host.Knows("nowhere"));
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("alpha", "alpha"), report);
		Test.Assert(Same(report.Loaded, "alpha"));
		Test.Assert(Same(sLog, "load:alpha:Engine"));
		host.Unload();

		Test.Assert(host.AddLinked("<root>not a manifest", .()) case .Err(.Internal));
		ClearLog();
	}

	[Test]
	public static void APartFindsTheServicesItsHostProvidesByTypeAndNullForTheRest()
	{
		let subsystems = scope SubsystemManager();
		let linked = scope Linked();
		PluginPartKind[1] engine = .(.Engine);
		linked.Add("service_user", engine, scope PluginPart[](new ServiceUserPart()));
		let clock = scope ClockService();
		let replacement = scope ClockService();
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		linked.AddTo(host);
		Test.Assert(host.Provide(clock));
		Test.Assert(host.Provide(replacement), "one per type: this one replaces the first");
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("service_user"), report);
		Test.Assert(report.Loaded.Count == 1);
		Test.Assert(clock.Ticks == 0);
		Test.Assert(replacement.Ticks == 1);
		Test.Assert(!ServiceUserPart.SawAbsent);
		Test.Assert(!host.Provide(clock), "loaded plugins read the table: it is fixed now");
		host.Unload();
	}

	[Test]
	public static void TheRolesPartTable()
	{
		for (int r < HostRole.Count)
			Test.Assert(((HostRole)r).Loads(.Engine));
		Test.Assert(!HostRole.Player.Loads(.Pipeline));
		Test.Assert(HostRole.Cook.Loads(.Pipeline));
		Test.Assert(!HostRole.Cook.Loads(.Tooling));
		Test.Assert(HostRole.Mcp.Loads(.Tooling));
		Test.Assert(HostRole.Export.Loads(.Tooling));
		Test.Assert(!HostRole.Mcp.Loads(.Editor));
		Test.Assert(!HostRole.Export.Loads(.Editor));
		Test.Assert(HostRole.Editor.Loads(.Editor));
	}
}
