using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Net.Replication;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.SceneSurface;
using Sedulous.Editor.Mcp;
using static Sedulous.Integration.Mcp.McpCalls;

namespace Sedulous.Integration.Mcp;

/// The scene tools as an agent uses them: author, validate, write, read back byte for
/// byte, and the real refusals, over XML a REAL SaveScene wrote so the tools are proven
/// against the editor's own text. Then host_info's live state.
static class SceneFlowTests
{
	[Test]
	public static void SceneToolsAuthorValidateReadBackAndRefuse()
	{
		let dir = Scratch("mcp_scene_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		SceneTools.Register(server, session);
		ProjectResources.Register(server, session);
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "SceneFix"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));

		// The seed: two entities, one the other's child, and a REAL component record on the
		// full manager set, exactly the set the validate scratch carries, so validation
		// exercises a genuine component payload end to end.
		let seedGuid = scope String();
		{
			let authored = scope Scene("arena");
			EngineSceneComposition.AddAllSceneManagers(authored);
			let hero = authored.CreateEntity("hero");
			let torch = authored.CreateEntity("torch");
			authored.SetParent(torch, hero);
			authored.GetSystem<NetworkComponentManager>().Add(hero);
			let instance = session.Project.SourceDb.RootGroup.CreateInstance("seed", McpTools.cSceneDocument);
			Test.Assert(instance != null);
			Test.Assert(SceneStorage.SaveScene(authored, instance) case .Ok);
			instance.Id.ToString(seedGuid);
		}
		let read = CallOk(server, "scene_read", With(Obj(), "guid", seedGuid));
		defer delete read;
		Test.Assert(read.Get("name").AsString() == "seed");
		let seedXml = scope String(read.Get("xml").AsString());
		Test.Assert(!seedXml.IsEmpty);
		Test.Assert(seedXml.Contains("net.Network"), "the component record is in the text");

		// scene_validate on the raw xml confirms the structure AND the payload: FULL.
		let valid = CallOk(server, "scene_validate", With(Obj(), "xml", seedXml));
		defer delete valid;
		Test.Assert(valid.Get("valid").AsBool());
		Test.Assert(valid.Get("sceneName").AsString() == "arena");
		Test.Assert(valid.Get("entityCount").AsInt() == 2);
		Test.Assert(valid.Get("rootCount").AsInt() == 1);
		Test.Assert(valid.Get("componentValidation").AsString() == "full");
		Test.Assert(valid.Get("warnings").Count == 0, scope $"{valid.Get("warnings").Count} warnings");

		// A record of a GENUINELY unknown component type is skipped with a captured
		// warning: still valid, the reader's contract is skip and warn, and the agent is
		// told what was skipped.
		{
			let mangled = scope String(seedXml);
			mangled.Replace("net.Network", "bogus.NoSuchComponent");
			let report = CallOk(server, "scene_validate", With(Obj(), "xml", mangled));
			defer delete report;
			Test.Assert(report.Get("valid").AsBool());
			Test.Assert(report.Get("warnings").Count >= 1, "the skipped record is reported");
		}

		// scene_write creates a new scene from the xml; the stored stream is byte identical.
		let written = CallOk(server, "scene_write", With(With(With(Obj(), "xml", seedXml), "name", "authored"), "group", "levels"));
		defer delete written;
		Test.Assert(written.Get("written").AsBool());
		let newGuid = scope String(written.Get("guid").AsString());
		let readBack = CallOk(server, "scene_read", With(Obj(), "guid", newGuid));
		defer delete readBack;
		Test.Assert(readBack.Get("xml").AsString() == seedXml, "verbatim storage");
		let storedValid = CallOk(server, "scene_validate", With(Obj(), "guid", newGuid));
		defer delete storedValid;
		Test.Assert(storedValid.Get("valid").AsBool());

		// The refusals, each with its reason.
		let garbage = scope String();
		CallErr(server, "scene_write", With(With(Obj(), "xml", "<not a scene>"), "name", "broken"), garbage);
		Test.Assert(garbage.Contains("refused"));
		let redirect = scope String();
		CallErr(server, "prefab_read", With(Obj(), "guid", newGuid), redirect);
		Test.Assert(redirect.Contains("scene_read"), "a scene through the prefab tool redirects");
		let taken = scope String();
		CallErr(server, "scene_write", With(With(Obj(), "xml", seedXml), "name", "seed"), taken);
		Test.Assert(taken.Contains("already exists"), "a new asset never overwrites a same named one");
		let neither = scope String();
		CallErr(server, "scene_validate", Obj(), neither);
		let both = scope String();
		CallErr(server, "scene_validate", With(With(Obj(), "xml", "x"), "guid", newGuid), both);
		Test.Assert(neither.Contains("exactly one") && both.Contains("exactly one"));

		// A single root scene is a legal prefab; two roots are refused with the reason.
		let okPrefab = CallOk(server, "prefab_write", With(With(Obj(), "xml", seedXml), "name", "goodprefab"));
		defer delete okPrefab;
		Test.Assert(okPrefab.Get("written").AsBool());
		{
			let twoRoots = scope Scene("pair");
			EngineSceneComposition.AddAllSceneManagers(twoRoots);
			twoRoots.CreateEntity("a");
			twoRoots.CreateEntity("b");
			let instance = session.Project.SourceDb.RootGroup.CreateInstance("pair", McpTools.cSceneDocument);
			Test.Assert(SceneStorage.SaveScene(twoRoots, instance) case .Ok);
			let pairRead = CallOk(server, "scene_read", With(Obj(), "guid", instance.Id.ToString(.. scope .())));
			defer delete pairRead;
			let refused = scope String();
			CallErr(server, "prefab_write", With(With(Obj(), "xml", pairRead.Get("xml").AsString()), "name", "badprefab"), refused);
			Test.Assert(refused.Contains("ONE root"));
		}

		// The scenes double as read only resources, listed LIVE from the source database:
		// the written scene appears with no re-registration, byte identical to scene_read.
		let listed = Ask(server, "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"resources/list\"}");
		defer delete listed;
		let resources = listed.Get("result").Get("resources");
		let uri = scope $"project://scene/{newGuid}";
		let entry = Named(resources, "uri", uri);
		Test.Assert(entry != null, "the written scene is listed");
		Test.Assert(entry.Get("mimeType").AsString() == "application/xml");
		Test.Assert(entry.Get("name").AsString() == "levels/authored");
		let fetched = Ask(server, scope $"{{\"jsonrpc\":\"2.0\",\"id\":8,\"method\":\"resources/read\",\"params\":{{\"uri\":\"{uri}\"}}}}");
		defer delete fetched;
		Test.Assert(fetched.Get("result").Get("contents").At(0).Get("text").AsString() == seedXml);
	}

	[Test]
	public static void HostInfoReportsPidStampVersionsAndLiveState()
	{
		let dir = Scratch("mcp_host_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		let server = scope McpServer();
		server.SetServerInfo("test-host", "9.9.9");
		let session = scope ProjectSession();
		let owner = scope ProjectOwner();
		ProjectOpenTools.Register(server, session, owner);
		ProjectInfoTool.Register(server, session);
		McpHostInfo.Register(server, "stamp-abc123", new (outState) =>
			{
				outState.Set("projectOpen", JsonValue.MakeBool(session.IsOpen));
			});
		let info = CallOk(server, "host_info", Obj());
		defer delete info;
		Test.Assert(info.Get("pid").AsNumber() > 0);
		Test.Assert(info.Get("buildStamp").AsString() == "stamp-abc123");
		Test.Assert(info.Get("serverName").AsString() == "test-host");
		Test.Assert(info.Get("serverVersion").AsString() == "9.9.9");
		Test.Assert(!info.Get("protocolVersion").AsString().IsEmpty);
		Test.Assert(!info.Get("host").Get("projectOpen").AsBool());

		// LIVE, not captured at registration.
		delete CallOk(server, "project_create", With(With(Obj(), "directory", dir), "name", "H"));
		delete CallOk(server, "project_open", With(Obj(), "directory", dir));
		let after = CallOk(server, "host_info", Obj());
		defer delete after;
		Test.Assert(after.Get("host").Get("projectOpen").AsBool());
	}
}
