using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The scene editor's MCP tools over a real EditorContext holding pages that implement
/// ISceneEditorPage (a headless scene and edit context behind each) beside one that does not:
/// page addressing (the active page, an explicit page, a page that is not a scene), the
/// selection round trip with names and the primary, the refusals for unknown entities and
/// pages, and the simulate control reflecting the page's state.
class SceneMcpToolsTests
{
	/// A page that IS a scene page to the rest of the editor: a headless scene and its edit
	/// context, the simulate state as a flag. No UI, no viewport.
	class HeadlessScenePage : EditorPage, ISceneEditorPage
	{
		private String mTitle = new .() ~ delete _;
		private Sedulous.Scene.Scene mScene = new .("headless") ~ delete _;
		private SceneEditContext mEdit ~ delete _;
		private bool mSimulating = false;

		public this(StringView title, Guid asset)
		{
			mTitle.Set(title);
			InstanceId = asset;
			mEdit = new .(mScene, Commands);
		}

		public override StringView Title => mTitle;
		public override Result<void, ErrorCode> Save() => .Ok;
		public SceneEditContext EditContext => mEdit;
		public void StartSimulation() { mSimulating = true; }
		public void StopSimulation() { mSimulating = false; }
		public void PauseSimulation(bool paused) {}
		public bool IsSimulating => mSimulating;
	}

	class PlainPage : EditorPage
	{
		public this(Guid asset)
		{
			InstanceId = asset;
		}

		public override StringView Title => "a material";
		public override Result<void, ErrorCode> Save() => .Ok;
	}

	/// A tools/call's answer: the payload when it succeeded, OWNED, or the error text.
	class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
	}

	private static Answer Call(McpServer server, StringView tool, StringView argumentsJson)
	{
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let reply = scope String();
		Test.Assert(server.HandleLine(line, reply) == .Answered);
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		let answer = new Answer();
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	[Test]
	public static void PageAddressingTheSelectionRoundTripItsRefusalsAndTheSimulateControl()
	{
		var rng = Sedulous.Core.Random(7);
		let sceneA = Guid.Generate(ref rng);
		let sceneB = Guid.Generate(ref rng);
		let material = Guid.Generate(ref rng);

		let context = scope EditorContext();
		let pageA = new HeadlessScenePage("Bistro", sceneA);
		let pageB = new HeadlessScenePage("Menu", sceneB);
		let plain = new PlainPage(material);
		context.AdoptPage(pageA);
		context.AdoptPage(pageB);
		context.AdoptPage(plain);
		Test.Assert(context.OpenPages.Count == 3);
		let lamp = pageA.EditContext.CreateEntity("Lamp");
		let table = pageA.EditContext.CreateEntity("Table");
		// The other page's entity is minted straight on its scene with its own guid (a page's
		// CreateEntity also selects, and two fresh scenes may mint the same first guid).
		let otherSceneEntity = Guid.Generate(ref rng);
		pageB.EditContext.Scene.CreateEntity(otherSceneEntity, "Elsewhere");
		pageA.EditContext.EntitySelection.Clear();

		let server = scope McpServer();
		SceneMcpTools.Register(server, context);
		Test.Assert(server.ToolCount == SceneMcpTools.cSceneLiveToolCount);
		let onA = scope $"{{\"page\":\"{sceneA}\"}}";

		// Default addressing: the active page, a scene page, then a page that is not one.
		context.SetActivePage(pageA);
		{
			let got = Call(server, "selection_get", "{}");
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("page").Get("title").AsString() == "Bistro");
			Test.Assert(got.Payload.Get("entities").Count == 0);
			Test.Assert(got.Payload.Get("primary").IsNull);
		}
		context.SetActivePage(plain);
		{
			let got = Call(server, "selection_get", "{}");
			defer delete got;
			Test.Assert(!got.Ok);
			Test.Assert(got.Error.StartsWith("page 'a material' is not a scene or prefab page"), got.Error);
		}
		// Explicit addressing reaches a scene page whatever is active; unknown pages refuse.
		{
			let got = Call(server, "selection_get", onA);
			defer delete got;
			Test.Assert(got.Ok, got.Error);
			Test.Assert(got.Payload.Get("page").Get("title").AsString() == "Bistro");
			let unknown = Call(server, "selection_get", "{\"page\":\"00000000-0000-0000-0000-000000000000\"}");
			defer delete unknown;
			Test.Assert(!unknown.Ok);
			Test.Assert(unknown.Error.StartsWith("no open page for guid"), unknown.Error);
		}

		// The selection round trip: order kept, the first is the primary, names resolved.
		{
			let set = Call(server, "selection_set", scope $"{{\"page\":\"{sceneA}\",\"entities\":[\"{table}\",\"{lamp}\"]}}");
			defer delete set;
			Test.Assert(set.Ok, set.Error);
			let entities = set.Payload.Get("entities");
			Test.Assert(entities.Count == 2);
			Test.Assert(entities.At(0).Get("name").AsString() == "Table");
			Test.Assert(entities.At(1).Get("name").AsString() == "Lamp");
			Test.Assert(set.Payload.Get("primary").AsString() == table.ToString(.. scope .()));
			Test.Assert(pageA.EditContext.EntitySelection.Count == 2);
			Test.Assert(pageA.EditContext.EntitySelection.Primary == table);
			Test.Assert(pageB.EditContext.EntitySelection.IsEmpty); // the other page is untouched
		}
		// An entity of ANOTHER page's scene is refused for this page; nothing changes.
		{
			let wrong = Call(server, "selection_set", scope $"{{\"page\":\"{sceneA}\",\"entities\":[\"{otherSceneEntity}\"]}}");
			defer delete wrong;
			Test.Assert(!wrong.Ok);
			Test.Assert(wrong.Error.StartsWith("no entity with guid"), wrong.Error);
			Test.Assert(pageA.EditContext.EntitySelection.Count == 2);
		}
		// An empty list clears.
		{
			let set = Call(server, "selection_set", scope $"{{\"page\":\"{sceneA}\",\"entities\":[]}}");
			defer delete set;
			Test.Assert(set.Ok, set.Error);
			Test.Assert(pageA.EditContext.EntitySelection.IsEmpty);
		}

		// Simulate reflects the page's state and addresses the same way.
		{
			let sim = Call(server, "simulate_start", onA);
			defer delete sim;
			Test.Assert(sim.Ok, sim.Error);
			Test.Assert(sim.Payload.Get("simulating").AsBool());
			Test.Assert(pageA.IsSimulating);
			Test.Assert(!pageB.IsSimulating);
		}
		{
			let sim = Call(server, "simulate_stop", onA);
			defer delete sim;
			Test.Assert(sim.Ok, sim.Error);
			Test.Assert(!sim.Payload.Get("simulating").AsBool());
			Test.Assert(!pageA.IsSimulating);
		}
		context.SetActivePage(plain);
		{
			let sim = Call(server, "simulate_start", "{}");
			defer delete sim;
			Test.Assert(!sim.Ok);
		}
	}
}
