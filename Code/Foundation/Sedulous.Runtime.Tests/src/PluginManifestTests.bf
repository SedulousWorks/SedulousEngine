using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// The plugin manifest: its reader and writer, a manifest written by hand in the documented
/// shape, a package's Plugin.xml loaded from its folder, and the checks a host refuses a plugin
/// by.
class PluginManifestTests
{
	/// A manifest of every field, built in code.
	private static void Everything(PluginManifest manifest)
	{
		manifest.Id.Set("everything");
		manifest.Name.Set("Every Part");
		manifest.Version.Set("1.2.3");
		manifest.EngineVersion.Set("0.1");
		manifest.DependsOn.Add(Dependency("online", "0.1"));
		manifest.DependsOn.Add(Dependency("other_thing", "2.0.1"));
		manifest.Provides.Add(new .("online.backend"));
		for (int i < PluginPartKind.Count)
			manifest.Parts.Add(Part(((PluginPartKind)i).ToString(.. scope .())));
		let desktop = new PluginPlatform();
		desktop.Platform.Set("Linux64");
		desktop.Deploy.Add(new .("ThirdParty/linux64/libthing.so"));
		manifest.Platforms.Add(desktop);
		let web = new PluginPlatform();
		web.Platform.Set("Web");
		manifest.Platforms.Add(web);
	}

	/// One that passes every check, for the refusal cases to break one field of.
	private static void Valid(PluginManifest manifest)
	{
		manifest.Id.Set("steam");
		manifest.Name.Set("Steam");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		manifest.Parts.Add(Part("Engine"));
	}

	private static PluginDependency Dependency(StringView id, StringView version)
	{
		let dependency = new PluginDependency();
		dependency.Id.Set(id);
		dependency.Version.Set(version);
		return dependency;
	}

	private static PluginManifestPart Part(StringView kind)
	{
		let part = new PluginManifestPart();
		part.Kind.Set(kind);
		return part;
	}

	private static bool Refuses(PluginManifest manifest, StringView engineVersion, StringView expected)
	{
		let whyNot = scope String();
		if (manifest.Check(engineVersion, whyNot))
			return false;
		return whyNot.Contains(expected);
	}

	[Test]
	public static void WrittenAndReadBackEveryFieldSurvives()
	{
		let written = scope PluginManifest();
		Everything(written);
		let xml = scope String();
		Test.Assert(written.Write(xml) case .Ok);

		let read = scope PluginManifest();
		Test.Assert(PluginManifest.Read(xml, read) case .Ok, xml);
		Test.Assert(read.Id == "everything");
		Test.Assert(read.Name == "Every Part");
		Test.Assert(read.Version == "1.2.3");
		Test.Assert(read.EngineVersion == "0.1");
		Test.Assert(read.DependsOn.Count == 2);
		Test.Assert(read.DependsOn[1].Id == "other_thing");
		Test.Assert(read.DependsOn[1].Version == "2.0.1");
		Test.Assert((read.Provides.Count == 1) && (read.Provides[0] == "online.backend"));
		for (int i < PluginPartKind.Count)
			Test.Assert(read.HasPart((PluginPartKind)i));
		Test.Assert(read.FindPlatform("Linux64") != null);
		Test.Assert(read.FindPlatform("Linux64").Deploy.Count == 1);
		Test.Assert(read.FindPlatform("Linux64").Deploy[0] == "ThirdParty/linux64/libthing.so");
		Test.Assert(read.FindPlatform("Web") != null);
		Test.Assert(read.FindPlatform("Web").Deploy.IsEmpty);
		Test.Assert(read.FindPlatform("Win64") == null, "not listed: unsupported");
	}

	/// The shape a plugin author writes by hand (and a part compiles in): the version envelope,
	/// then the fields, each record an object, an empty list a bare array.
	private const String cHandWritten = """
		<root>
			<array name="dataVersions" count="1">
				<u64 name="type">17008328439509122599</u64>
				<u32 name="version">1</u32>
			</array>
			<object>
				<string name="id">probe</string>
				<string name="name">Probe</string>
				<string name="version">0.2.0</string>
				<string name="engineVersion">0.1</string>
				<array name="dependsOn" count="1">
					<object>
						<string name="id">probe_base</string>
						<string name="version">0.1</string>
					</object>
				</array>
				<array name="provides" count="0"/>
				<array name="parts" count="2">
					<object>
						<string name="kind">Engine</string>
					</object>
					<object>
						<string name="kind">Editor</string>
					</object>
				</array>
				<array name="platforms" count="1">
					<object>
						<string name="platform">Linux64</string>
						<array name="deploy" count="0"/>
					</object>
				</array>
			</object>
		</root>
		""";

	[Test]
	public static void AManifestWrittenByHandInTheDocumentedShapeReads()
	{
		let read = scope PluginManifest();
		Test.Assert(PluginManifest.Read(cHandWritten, read) case .Ok);
		Test.Assert(read.Id == "probe");
		Test.Assert(read.Version == "0.2.0");
		Test.Assert((read.DependsOn.Count == 1) && (read.DependsOn[0].Id == "probe_base"));
		Test.Assert(read.Provides.IsEmpty);
		Test.Assert(read.HasPart(.Engine) && read.HasPart(.Editor) && !read.HasPart(.Pipeline));
		Test.Assert(read.FindPlatform("Linux64") != null);
		Test.Assert(read.Check("0.1.0", scope .()));

		// What the writer writes for it reads back the same: one shape, by hand or by code.
		let again = scope PluginManifest();
		Test.Assert(PluginManifest.Read(read.Write(.. scope .()), again) case .Ok);
		Test.Assert((again.Id == "probe") && (again.DependsOn.Count == 1) && (again.Parts.Count == 2));
	}

	/// The engine's own packages' manifests, as their parts compile them in.
	private const String cImguiManifest = Compiler.ReadText("../../Plugins/Imgui/Plugin.xml");

	/// Each engine package's Plugin.xml reads and passes the checks for the engine it names.
	[Test]
	public static void TheEnginesPackagesManifestsReadAndPassTheirChecks()
	{
		let imgui = scope PluginManifest();
		Test.Assert(PluginManifest.Read(cImguiManifest, imgui) case .Ok);
		Test.Assert(imgui.Id == "imgui");
		Test.Assert(imgui.HasPart(.Engine));
		Test.Assert((imgui.FindPlatform("Linux64") != null) && (imgui.FindPlatform("Win64") != null) && (imgui.FindPlatform("Web") != null));
		let whyNot = scope String();
		Test.Assert(imgui.Check(scope $"{imgui.EngineVersion}.0", whyNot), whyNot);
	}

	[Test]
	public static void APackagesManifestIsLoadedFromItsFolderNotFoundWithoutOne()
	{
		let dir = "scratch_plugin_manifest";
		if (System.IO.Directory.Exists(dir))
			System.IO.Directory.DelTree(dir).IgnoreError();
		System.IO.Directory.CreateDirectory(dir).IgnoreError();
		defer { System.IO.Directory.DelTree(dir).IgnoreError(); }
		let manifest = scope PluginManifest();
		Everything(manifest);
		Test.Assert(System.IO.File.WriteAllText(scope $"{dir}/{PluginManifest.cFileName}", manifest.Write(.. scope .())) case .Ok);

		let loaded = scope PluginManifest();
		Test.Assert(PluginManifest.Load(dir, loaded) case .Ok);
		Test.Assert(loaded.Id == "everything");

		let none = scope PluginManifest();
		Test.Assert(PluginManifest.Load("scratch_plugin_manifest_none", none) case .Err(.NotFound));
	}

	[Test]
	public static void VersionsAreMajorMinorOrMajorMinorPatch()
	{
		let two = PluginVersion.Parse("0.1");
		Test.Assert(two case .Ok);
		Test.Assert((two.Value.Major == 0) && (two.Value.Minor == 1) && (two.Value.Patch == 0));
		let three = PluginVersion.Parse("12.30.4");
		Test.Assert(three case .Ok);
		Test.Assert((three.Value.Major == 12) && (three.Value.Minor == 30) && (three.Value.Patch == 4));
		Test.Assert(PluginVersion.Parse("4294967295.0") case .Ok);

		StringView[?] bad = .("", "1", "1.", ".1", "1..2", "1.2.3.4", "1.2-dev", "-1.2", "4294967296.0");
		for (let text in bad)
			Test.Assert(PluginVersion.Parse(text) case .Err, scope String(text));
	}

	[Test]
	public static void TheEngineSatisfiesAPluginOfItsMajorAtOrBelowItsVersionBeforeOneOfItsMinor()
	{
		Test.Assert(PluginVersion.EngineSatisfies(.(0, 1, 0), .(0, 1, 0)));
		Test.Assert(PluginVersion.EngineSatisfies(.(0, 1, 4), .(0, 1, 2)));
		Test.Assert(!PluginVersion.EngineSatisfies(.(0, 1, 1), .(0, 1, 2)));
		Test.Assert(!PluginVersion.EngineSatisfies(.(0, 2, 0), .(0, 1, 0)), "a 0.x minor may break plugins");
		Test.Assert(!PluginVersion.EngineSatisfies(.(0, 1, 0), .(0, 2, 0)));
		Test.Assert(PluginVersion.EngineSatisfies(.(1, 3, 0), .(1, 2, 9)), "after 1.0 a newer minor keeps them");
		Test.Assert(!PluginVersion.EngineSatisfies(.(1, 2, 0), .(1, 3, 0)));
		Test.Assert(!PluginVersion.EngineSatisfies(.(2, 0, 0), .(1, 0, 0)));
	}

	[Test]
	public static void IdsAreLowerCaseIdentifiers()
	{
		Test.Assert(PluginManifest.IsValidId("steam"));
		Test.Assert(PluginManifest.IsValidId("online_local2"));
		StringView[?] bad = .("", "Steam", "2steam", "_steam", "steam-api", "steam.api");
		for (let id in bad)
			Test.Assert(!PluginManifest.IsValidId(id), scope String(id));
	}

	[Test]
	public static void AValidManifestPassesAndEachBrokenFieldIsRefusedWithItsReason()
	{
		{
			let valid = scope PluginManifest();
			Valid(valid);
			let whyNot = scope String();
			Test.Assert(valid.Check("0.1.0", whyNot));
			Test.Assert(whyNot.IsEmpty);
		}
		{
			let manifest = scope PluginManifest();
			Valid(manifest);
			manifest.Id.Set("Steam API");
			Test.Assert(Refuses(manifest, "0.1.0", "Steam API"));
		}
		{
			let manifest = scope PluginManifest();
			Valid(manifest);
			manifest.Parts.Add(Part("Runtime"));
			Test.Assert(Refuses(manifest, "0.1.0", "unknown part kind 'Runtime'"));
		}
		{
			let manifest = scope PluginManifest();
			Valid(manifest);
			manifest.Parts.Add(Part("Engine"));
			Test.Assert(Refuses(manifest, "0.1.0", "listed twice"));
		}
		{
			let manifest = scope PluginManifest();
			Valid(manifest);
			manifest.EngineVersion.Set("0.2");
			Test.Assert(Refuses(manifest, "0.1.0", "needs engine 0.2"));
			Test.Assert(Refuses(manifest, "0.1.0", "this engine is 0.1.0"));
		}
		{
			let version = scope PluginManifest();
			Valid(version);
			version.Version.Set("one");
			Test.Assert(Refuses(version, "0.1.0", "version 'one'"));
			let engine = scope PluginManifest();
			Valid(engine);
			engine.EngineVersion.Set("latest");
			Test.Assert(Refuses(engine, "0.1.0", "engineVersion 'latest'"));
		}
		{
			let itself = scope PluginManifest();
			Valid(itself);
			itself.DependsOn.Add(Dependency("steam", "0.1"));
			Test.Assert(Refuses(itself, "0.1.0", "dependency 'steam'"));
			let badId = scope PluginManifest();
			Valid(badId);
			badId.DependsOn.Add(Dependency("On Line", "0.1"));
			Test.Assert(Refuses(badId, "0.1.0", "dependency 'On Line'"));
			let badVersion = scope PluginManifest();
			Valid(badVersion);
			badVersion.DependsOn.Add(Dependency("online", "soon"));
			Test.Assert(Refuses(badVersion, "0.1.0", "version 'soon'"));
		}
	}
}
