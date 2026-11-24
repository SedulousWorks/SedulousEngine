using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Pipeline.Registration;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;
using Sedulous.VFS;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// sequence_read and sequence_edit: an agent authors a cutscene through the real JSON-RPC path,
/// whatever the track kinds (each says what it holds), and reads it back; a refused edit refuses the
/// call and writes nothing.
static class McpSequenceTests
{
	static JsonValue Edits(StringView text) => JsonValue.Parse(text);

	static JsonValue Which(StringView guid) => With(Obj(), "guid", guid);

	[Test]
	public static void AnAgentAuthorsACutsceneWithSequenceEditAndReadsItBack()
	{
		let dir = Scratch("mcp_sequence_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		PipelineRegistration.RegisterPipelineTypes(); // the domains' track kinds among them
		defer PipelineRegistration.Teardown();
		let builders = scope BuilderRegistry();
		let importers = scope ImporterRegistry();
		PipelineRegistration.RegisterAllBuilders(builders, FindDataRoot(.. scope .()));
		PipelineRegistration.RegisterAllImporters(importers);
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllCreators(creators);

		let server = scope McpServer();
		AllowScratch(server);
		let logBuffer = scope EditorLogBuffer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		let operations = scope InlineProjectOperations(session, builders, "", "");
		EngineTools.Register(server, session, builders, importers, creators, logBuffer, scope EngineToolPaths(), operations);
		ProjectOpenTools.Register(server, session, owner);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "Cut"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		let made = CallOk(server, "asset_create", With(With(Obj(), "creator", "Sequence"), "name", "Arrival"));
		defer delete made;
		let guid = scope String(made.Get("guid").AsString());
		var announced = 0;
		session.OnAssetWritten = new [&announced] (id) => { announced++; };

		let args = Which(guid);
		args.Set("edits", Edits("""
			[
			{"op":"add_part","name":"Hero"},
			{"op":"add_track","kind":"Property","part":"Hero","component":"Transform","property":"Position"},
			{"op":"key","track":0,"channel":"x","time":0,"value":0},
			{"op":"key","track":0,"channel":"x","time":2,"value":10},
			{"op":"add_track","kind":"Clip","part":"Hero"},
			{"op":"section","track":1,"start":0.5,"length":1,"fields":{"Speed":2,"Loop":true}},
			{"op":"add_track","kind":"EventSequenceTrack"},
			{"op":"key","track":2,"time":1.5},
			{"op":"set","track":2,"path":"Keys.0.Name","value":"cue"},
			{"op":"set","track":2,"path":"Keys.0.Value","value":"gate"},
			{"op":"marker","time":1,"name":"line","hold":true}
			]
			"""));
		let edited = CallOk(server, "sequence_edit", args);
		defer delete edited;
		Test.Assert(announced == 1);
		Test.Assert(edited.Get("results").At(5).Get("section").AsInt() == 0);

		let sequence = CallOk(server, "sequence_read", Which(guid));
		defer delete sequence;
		Test.Assert(sequence.Get("parts").At(0).AsString() == "Hero");
		Test.Assert(Math.Abs(sequence.Get("length").AsNumber() - 2.0) < 1e-4);
		Test.Assert(sequence.Get("tracks").Count == 3);
		let walk = sequence.Get("tracks").At(0);
		Test.Assert(walk.Get("kindName").AsString() == "Property");
		Test.Assert(walk.Get("part").AsString() == "Hero");
		Test.Assert(Math.Abs(walk.Get("channels").At(0).Get("keys").At(1).Get("value").AsNumber() - 10.0) < 1e-4);
		let clip = sequence.Get("tracks").At(1);
		Test.Assert(clip.Get("kind").AsString() == "ClipSequenceTrack");
		Test.Assert(Math.Abs(clip.Get("sections").At(0).Get("start").AsNumber() - 0.5) < 1e-4);
		Test.Assert(Math.Abs(clip.Get("fields").Get("Sections").At(0).Get("Speed").AsNumber() - 2.0) < 1e-4);
		Test.Assert(clip.Get("fields").Get("Sections").At(0).Get("Loop").AsBool());
		let cues = sequence.Get("tracks").At(2);
		Test.Assert(cues.Get("part").IsNull);
		Test.Assert(cues.Get("fields").Get("Keys").At(0).Get("Name").AsString() == "cue");
		Test.Assert(sequence.Get("markers").At(0).Get("hold").AsBool());
		var clipKind = false;
		for (int i < sequence.Get("kinds").Count)
			clipKind |= sequence.Get("kinds").At(i).Get("kindName").AsString() == "Clip";
		Test.Assert(clipKind);

		// A refused edit (a field the kind does not have) refuses the call; the edits before it in the
		// same call are not written either.
		let bad = Which(guid);
		bad.Set("edits", Edits("[{\"op\":\"add_part\",\"name\":\"Mentor\"},{\"op\":\"set\",\"track\":1,\"path\":\"Sections.0.Nothing\",\"value\":1}]"));
		let refused = CallErr(server, "sequence_edit", bad, .. scope .());
		Test.Assert(refused.Contains("Nothing was written"));
		Test.Assert(announced == 1);
		let again = CallOk(server, "sequence_read", Which(guid));
		defer delete again;
		Test.Assert(again.Get("parts").Count == 1);

		// A kind that plays on a part asks for one; an unknown kind names the known ones.
		let partless = Which(guid);
		partless.Set("edits", Edits("[{\"op\":\"add_track\",\"kind\":\"Clip\"}]"));
		Test.Assert(CallErr(server, "sequence_edit", partless, .. scope .()).Contains("give `part`"));
		let unknown = Which(guid);
		unknown.Set("edits", Edits("[{\"op\":\"add_track\",\"kind\":\"Juggle\"}]"));
		Test.Assert(CallErr(server, "sequence_edit", unknown, .. scope .()).Contains("Camera Cut"));
	}
}
