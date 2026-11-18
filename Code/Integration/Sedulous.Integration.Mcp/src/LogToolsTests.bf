using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The log tools as the correlation loop: a marker, the engine's lines after it, the
/// filters, a quiet high water read, and the known issues register.
static class LogToolsTests
{
	private static bool AnyEntryContains(JsonValue entries, StringView needle)
	{
		for (int i < entries.Count)
			if (entries.At(i).Get("message").AsString().Contains(needle))
				return true;
		return false;
	}

	[Test]
	public static void MarkersIncrementalReadsFiltersAndKnownIssues()
	{
		// The host shape: ONE buffer on the global composite, for the test's scope.
		let buffer = new EditorLogBuffer();
		let composite = new CompositeLogger();
		composite.Add(buffer, true);
		InitGlobalLogger(composite, true);
		defer ShutdownGlobalLogger();

		// A stand in known issues register on disk.
		let issuesPath = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "mcp_known_issues.md", .. scope .());
		defer DeleteFile(issuesPath);
		let text = "# Known Issues\n- I99: the teapot renders upside down\n";
		Test.Assert(WriteFile(issuesPath, .((uint8*)text.Ptr, text.Length)) case .Ok);

		let server = scope McpServer();
		LogTools.Register(server, buffer, issuesPath);

		// log_write drops an Agent marker and reports its sequence.
		let marker = CallOk(server, "log_write", With(Obj(), "message", "before-risky-op"));
		defer delete marker;
		Test.Assert(marker.Get("written").AsBool());
		let markerSeq = marker.Get("sequence").AsNumber();
		Test.Assert(markerSeq > 0);

		// The engine speaks after the marker.
		GlobalLog(.Warning, "Cook: teapot failed to cook");
		GlobalLog(.Information, "Scene: loaded arena");

		// Everything: the marker is there, category Agent.
		let all = CallOk(server, "log_read", Obj());
		defer delete all;
		Test.Assert(AnyEntryContains(all.Get("entries"), "before-risky-op"));
		Test.Assert(Named(all.Get("entries"), "category", "Agent") != null);
		Test.Assert(all.Get("lastSequence").AsNumber() >= markerSeq + 2);

		// From the marker: only what came after it.
		let after = CallOk(server, "log_read", With(Obj(), "sinceSequence", markerSeq));
		defer delete after;
		Test.Assert(after.Get("entries").Count == 2);
		Test.Assert(AnyEntryContains(after.Get("entries"), "teapot failed to cook"));
		Test.Assert(!AnyEntryContains(after.Get("entries"), "before-risky-op"));

		// Filters: minLevel drops the info line; category keeps only the scene line.
		let warnings = CallOk(server, "log_read", With(With(Obj(), "sinceSequence", markerSeq), "minLevel", "warning"));
		defer delete warnings;
		Test.Assert((warnings.Get("entries").Count == 1) && AnyEntryContains(warnings.Get("entries"), "teapot failed to cook"));
		let sceneOnly = CallOk(server, "log_read", With(With(Obj(), "sinceSequence", markerSeq), "category", "Scene"));
		defer delete sceneOnly;
		Test.Assert((sceneOnly.Get("entries").Count == 1) && AnyEntryContains(sceneOnly.Get("entries"), "loaded arena"));

		// A read from the high water is quiet.
		let quiet = CallOk(server, "log_read", With(Obj(), "sinceSequence", all.Get("lastSequence").AsNumber()));
		defer delete quiet;
		Test.Assert(quiet.Get("entries").Count == 0);
		Test.Assert(quiet.Get("dropped").AsInt() == 0);

		// An empty marker is refused.
		let empty = scope String();
		CallErr(server, "log_write", With(Obj(), "message", ""), empty);
		Test.Assert(empty.Contains("empty"));

		// The register, verbatim, with its path.
		let issues = CallOk(server, "known_issues", Obj());
		defer delete issues;
		Test.Assert(issues.Get("text").AsString().Contains("teapot renders upside down"));
		Test.Assert(issues.Get("path").AsString() == issuesPath);

		// A host with no register still has the tool, erring with guidance.
		let bare = scope McpServer();
		LogTools.Register(bare, buffer, "");
		let guidance = scope String();
		CallErr(bare, "known_issues", Obj(), guidance);
		Test.Assert(guidance.Contains("checkout"));
		// It names the file the hosts look for, and both places they look.
		Test.Assert(guidance.Contains("KnownIssues.md") && guidance.Contains("Documentation/Shipping"), guidance);
	}

	/// log_read gives each line's references: those its log call attached, and the project's files
	/// and assets found in its text.
	[Test]
	public static void LogReadGivesEachLinesReferences()
	{
		let dir = "scratch_mcp_log_references";
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "Refs") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let session = scope ProjectSession();
		session.Project = project;

		let buffer = new EditorLogBuffer();
		let composite = new CompositeLogger();
		composite.Add(buffer, true);
		InitGlobalLogger(composite, true);
		defer ShutdownGlobalLogger();
		let server = scope McpServer();
		LogTools.Register(server, buffer, "", session);

		let root = PathJoin(Directory.GetCurrentDirectory(.. scope .()), dir, .. scope .());
		let file = PathJoin(root, "Code/Player.as", .. scope .());
		GlobalLog(.Warning, "Script: {}:12:3: unknown global 'speed'", file);
		let asset = LogReference.ForAsset(Guid.Parse("0e9b3a52-1c1f-4c2e-9d3b-5a7f1e2d3c4b").Value);
		defer delete asset;
		GlobalLogAt(.Warning, asset, "Cook: Crate did not cook");
		GlobalLog(.Information, "Scene: nothing to follow");

		let read = CallOk(server, "log_read", Obj());
		defer delete read;
		let entries = read.Get("entries");
		Test.Assert(entries.Count == 3);
		let source = entries.At(0).Get("references");
		Test.Assert(source.Count == 1);
		Test.Assert(source.At(0).Get("kind").AsString() == "source");
		Test.Assert(source.At(0).Get("fields").At(0).AsString() == file);
		Test.Assert(source.At(0).Get("fields").At(1).AsString() == "12");
		Test.Assert(source.At(0).Get("fields").At(2).AsString() == "3");
		Test.Assert(source.At(0).Get("start").AsNumber() == 0.0);
		Test.Assert(source.At(0).Get("length").AsNumber() == (double)(file.Length + 5));
		let attached = entries.At(1).Get("references");
		Test.Assert(attached.Count == 1);
		Test.Assert(attached.At(0).Get("kind").AsString() == "asset");
		Test.Assert(attached.At(0).Get("length").AsNumber() == 0.0);
		Test.Assert(!entries.At(2).Has("references"));

	}
}
