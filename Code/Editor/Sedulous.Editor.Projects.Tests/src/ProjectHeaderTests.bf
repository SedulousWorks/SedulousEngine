using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;

namespace Sedulous.Editor.Projects.Tests;

/// A project's header (its name and stamp, read without the settings' schema), its stamp against a
/// given engine version, the open gate against one, and the manifest backup that never parses.
static class ProjectHeaderTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	private static void ReadManifest(StringView dir, String outText)
	{
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(PathJoin(dir, ProjectLayout.ManifestFile, .. scope .()), bytes) case .Ok);
		outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
	}

	private static void WriteManifest(StringView dir, StringView text)
	{
		Test.Assert(WriteFile(PathJoin(dir, ProjectLayout.ManifestFile, .. scope .()), .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	/// The scaffold's manifest with its stamp made `stamp` (empty: the key taken out).
	private static void Restamp(StringView dir, StringView stamp)
	{
		let text = ReadManifest(dir, .. scope .());
		let written = scope $"<string name=\"engineVersion\">{EngineVersion.String}</string>";
		Test.Assert(text.Contains(written), text);
		let replacement = scope String();
		if (!stamp.IsEmpty)
			replacement.AppendF("<string name=\"engineVersion\">{}</string>", stamp);
		text.Replace(written, replacement);
		WriteManifest(dir, text);
	}

	/// The scaffold's manifest as an engine with newer settings writes it: its data version one
	/// past this build's, and a field this build does not know before the two keys.
	private static void MakeNewerSettings(StringView dir)
	{
		let text = ReadManifest(dir, .. scope .());
		let version = scope $"<u32 name=\"version\">{ProjectSettings.DataVersion}</u32>";
		Test.Assert(text.Contains(version), text);
		text.Replace(version, scope $"<u32 name=\"version\">{ProjectSettings.DataVersion + 1}</u32>");
		text.Replace("<string name=\"name\">", "<u32 name=\"aFieldFromLater\">7</u32><string name=\"name\">");
		WriteManifest(dir, text);
	}

	[Test]
	public static void AManifestAtANewerDataVersionStillGivesItsNameAndStamp()
	{
		let dir = Scratch("scratch_header_newer", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let header = scope ProjectHeader();
		Test.Assert(ProjectHeader.Read(dir, header) case .Err(.NotFound), "no folder");
		Test.Assert(ProjectScaffold.Create(dir, "Later Game") case .Ok);
		Test.Assert(ProjectHeader.Read(dir, header) case .Ok);
		Test.Assert((header.Name == "Later Game") && (header.EngineVersion == EngineVersion.String));

		MakeNewerSettings(dir);
		Restamp(dir, "0.9.0");
		let probed = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(dir, probed) case .Err, "the settings refuse a newer data version");
		Test.Assert(ProjectHeader.Read(dir, header) case .Ok);
		Test.Assert(header.Name == "Later Game", header.Name);
		Test.Assert(header.EngineVersion == "0.9.0", header.EngineVersion);

		// A folder with no manifest, and a manifest that is not one.
		Test.Assert(DeleteFile(PathJoin(dir, ProjectLayout.ManifestFile, .. scope .())));
		Test.Assert(ProjectHeader.Read(dir, header) case .Err(.NotFound));
		WriteManifest(dir, "not xml at all <<<");
		Test.Assert(ProjectHeader.Read(dir, header) case .Err(.InvalidArgument));
		Test.Assert(header.Name.IsEmpty && header.EngineVersion.IsEmpty, "nothing is kept from a read that failed");
		WriteManifest(dir, "<root/>");
		Test.Assert(ProjectHeader.Read(dir, header) case .Err(.InvalidArgument), "no object");
	}

	[Test]
	public static void AnUnstampedOrMalformedStampReadsAsItIsAndComparesUnstamped()
	{
		let dir = Scratch("scratch_header_stamps", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(ProjectScaffold.Create(dir, "Stamps") case .Ok);
		let header = scope ProjectHeader();

		Restamp(dir, "");
		Test.Assert(ProjectHeader.Read(dir, header) case .Ok);
		Test.Assert((header.Name == "Stamps") && header.EngineVersion.IsEmpty, "a manifest from before the stamp");
		Test.Assert(ProjectRegistry.CompareEngineVersions(header.EngineVersion, "0.1.0") == .Unstamped);

		Test.Assert(ProjectScaffold.Create(Scratch("scratch_header_stamps", .. scope .()), "Stamps") case .Ok);
		Restamp(dir, "1.2");
		Test.Assert(ProjectHeader.Read(dir, header) case .Ok);
		Test.Assert(header.EngineVersion == "1.2");
		Test.Assert(ProjectRegistry.CompareEngineVersions(header.EngineVersion, "0.1.0") == .Unstamped);

		for (let malformed in StringView[?]("", "abc", "1.2", "1..2", "1.2.3.4", ".1.2", "1.2.", "0.2.0-beta", " 0.1.0"))
		{
			Test.Assert(ProjectRegistry.CompareEngineVersions(malformed, "0.1.0") == .Unstamped, scope String(malformed));
			Test.Assert(ProjectRegistry.CompareEngineVersions("0.1.0", malformed) == .Unstamped, "nothing is said against an engine that does not read");
			uint32[3] parts;
			Test.Assert(!ProjectRegistry.ParseEngineVersion(malformed, out parts) && (parts[0] == 0) && (parts[1] == 0) && (parts[2] == 0));
		}
		uint32[3] read;
		Test.Assert(ProjectRegistry.ParseEngineVersion("10.20.30", out read) && (read[0] == 10) && (read[1] == 20) && (read[2] == 30));
	}

	[Test]
	public static void OlderSameAndNewerAgainstAGivenEngine()
	{
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.1.0", "0.1.0") == .Same);
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.2.0", "0.2.0") == .Same);
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.1.0", "0.2.0") == .ProjectOlder);
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.1.9", "0.2.0") == .ProjectOlder, "by minor before patch");
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.2.0", "0.1.0") == .ProjectNewer);
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.1.1", "0.1.0") == .ProjectNewer);
		Test.Assert(ProjectRegistry.CompareEngineVersions("1.0.0", "0.2.0") == .ProjectNewer, "by major first");
		Test.Assert(ProjectRegistry.CompareEngineVersions("0.10.0", "0.2.0") == .ProjectNewer, "numbers, not text");
		// This engine's own is the case against EngineVersion.String.
		Test.Assert(ProjectRegistry.CompareProjectEngineVersion("0.0.1") == ProjectRegistry.CompareEngineVersions("0.0.1", EngineVersion.String));

		// The gate against an SDK's version, for a project stamped 0.1.0 and one stamped 0.2.0.
		EditorProjectsSerializables.RegisterAll();
		let controller = scope ProjectManagerController(scope Settings());
		let decision = scope ProjectOpenDecision();
		let dir = Scratch("scratch_header_gate", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(ProjectScaffold.Create(dir, "Gated") case .Ok);
		Restamp(dir, "0.1.0");
		controller.DecideOpen(dir, "0.1.0", decision);
		Test.Assert((decision.Gate == .OpenDirectly) && decision.PromptBody.IsEmpty);
		controller.DecideOpen(dir, "0.2.0", decision);
		Test.Assert(decision.Gate == .PromptOlderBackup);
		Test.Assert(decision.PromptBody.Contains("engine 0.1.0") && decision.PromptBody.Contains("this editor is 0.2.0"), decision.PromptBody);

		Test.Assert(ProjectScaffold.Create(Scratch("scratch_header_gate", .. scope .()), "Gated") case .Ok);
		Restamp(dir, "0.2.0");
		controller.DecideOpen(dir, "0.2.0", decision);
		Test.Assert(decision.Gate == .OpenDirectly);
		controller.DecideOpen(dir, "0.1.0", decision);
		Test.Assert(decision.Gate == .PromptNewerEngine);
		Test.Assert(decision.PromptBody.Contains("engine 0.2.0") && decision.PromptBody.Contains("this editor (0.1.0)"), decision.PromptBody);
		Test.Assert(decision.Header.Name == "Gated");

		// A manifest whose settings a newer engine wrote is still a project to the gate.
		MakeNewerSettings(dir);
		controller.DecideOpen(dir, "0.1.0", decision);
		Test.Assert(decision.Gate == .PromptNewerEngine);
		Test.Assert(decision.Header.EngineVersion == "0.2.0");
		WriteManifest(dir, "<<<");
		controller.DecideOpen(dir, "0.2.0", decision);
		Test.Assert(decision.Gate == .NotAProject);
	}

	[Test]
	public static void TheBackupCopiesTheBytesOfAManifestItCannotParse()
	{
		let dir = Scratch("scratch_header_backup", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let backup = scope String();
		Test.Assert(ProjectRegistry.BackupProjectManifest(dir, backup) case .Err(.NotFound), "no folder");
		Test.Assert(CreateDirectory(dir));
		Test.Assert(ProjectRegistry.BackupProjectManifest(dir, backup) case .Err(.NotFound), "no manifest");

		let damaged = "<root><object><string name=\"name\">Half";
		WriteManifest(dir, damaged);
		Test.Assert(ProjectRegistry.BackupProjectManifest(dir, backup..Clear()) case .Ok);
		Test.Assert(backup.EndsWith(".unstamped.bak"), backup);
		let copied = scope List<uint8>();
		Test.Assert(ReadFile(backup, copied) case .Ok);
		Test.Assert(StringView((char8*)copied.Ptr, copied.Count) == damaged, "byte for byte");

		// A manifest at a newer data version: named for its stamp, its bytes as they are.
		RemoveDirectoryRecursive(dir);
		Test.Assert(ProjectScaffold.Create(dir, "Backed") case .Ok);
		Restamp(dir, "0.3.0");
		MakeNewerSettings(dir);
		Test.Assert(ProjectRegistry.BackupProjectManifest(dir, backup..Clear()) case .Ok);
		Test.Assert(backup.EndsWith(scope $"{ProjectLayout.ManifestFile}.0.3.0.bak"), backup);
		Test.Assert(ReadFile(backup, copied..Clear()) case .Ok);
		Test.Assert(StringView((char8*)copied.Ptr, copied.Count) == ReadManifest(dir, .. scope .()));
	}
}
