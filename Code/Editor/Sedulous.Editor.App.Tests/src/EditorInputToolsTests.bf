using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The input tools over a GUI root of their own: what a target finds, a click reaching what it names
/// (or refused: none, several, covered), a point clicked, text typed into the focus and a key
/// pressed, each answering a frame (a pump) after it acts.
class EditorInputToolsTests
{
	/// A form: "Show" and "OK" buttons, a field, and a second "OK" in a panel.
	private class Bed
	{
		public SceneRoot Root ~ _.ReleaseRef();
		public Sedulous.GUI.Button Show ~ _.ReleaseRef();
		public Sedulous.GUI.Button Ok ~ _.ReleaseRef();
		public TextField Field ~ _.ReleaseRef();
		public Panel Dialog ~ _.ReleaseRef();
		public Sedulous.GUI.Button DialogOk ~ _.ReleaseRef();
		public int Shows = 0;
		public int Oks = 0;
		public McpServer Server = new .() ~ delete _;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(400.0f, 300.0f);
			Show = Add<Sedulous.GUI.Button>(Root, "show", 10.0f, 10.0f, 80.0f, 30.0f);
			Show.Text = "Show";
			Show.SetOnClick(new () => { Shows++; });
			Ok = Add<Sedulous.GUI.Button>(Root, "ok", 10.0f, 90.0f, 80.0f, 30.0f);
			Ok.Text = "OK";
			Field = Add<TextField>(Root, "field", 10.0f, 50.0f, 150.0f, 30.0f);
			Dialog = Add<Panel>(Root, "dialog", 200.0f, 10.0f, 180.0f, 150.0f);
			DialogOk = Add<Sedulous.GUI.Button>(Dialog, "dialog-ok", 10.0f, 10.0f, 80.0f, 30.0f);
			DialogOk.Text = "OK";
			DialogOk.SetOnClick(new () => { Oks++; });
			Root.UpdateLayout();
			let seams = new InputToolSeams();
			let over = Root;
			seams.Root = new [=over] () => over;
			EditorInputTools.Register(Server, seams);
		}

		/// A new `T` with the id `id` at (`x`, `y`), `w` by `h`, under `parent`; the caller's
		/// reference.
		public static T Add<T>(Node parent, StringView id, float x, float y, float w, float h) where T : UIWidget, new
		{
			let node = new T();
			node.Id = id;
			node.Position = .(x, y);
			node.Size = .(w, h);
			parent.AddChild(node);
			return node;
		}
	}

	private class Answer
	{
		public bool Ok;
		public JsonValue Payload ~ delete _;
		public String Error = new .() ~ delete _;
		/// Entries before it answered.
		public int Pumps = 0;
	}

	/// The call, pumped as the host would until it answers. The caller deletes the answer.
	private static Answer Call(McpServer server, StringView tool, StringView argumentsJson)
	{
		let line = scope String();
		line.AppendF("{{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{{\"name\":\"{}\",\"arguments\":{}}}}}", tool, argumentsJson);
		let answer = new Answer();
		let reply = scope String();
		var state = server.HandleLine(line, reply);
		while ((state == .NotFinished) && (answer.Pumps < 5))
		{
			answer.Pumps++;
			reply.Clear();
			state = server.HandleLine(line, reply);
		}
		Test.Assert(state == .Answered);
		let response = JsonValue.Parse(reply);
		defer delete response;
		let result = response.Get("result");
		answer.Ok = !result.Get("isError").AsBool();
		let text = result.Get("content").At(0).Get("text").AsString();
		if (answer.Ok)
			answer.Payload = JsonValue.Parse(text);
		else
			answer.Error.Set(text);
		return answer;
	}

	private static bool Succeeds(McpServer server, StringView tool, StringView argumentsJson)
	{
		let answer = Call(server, tool, argumentsJson);
		defer delete answer;
		return answer.Ok;
	}

	[Test]
	public static void FindListsWhatATargetNamesWithWhereItIs()
	{
		let bed = scope Bed();
		Test.Assert(bed.Server.ToolCount == EditorInputTools.cInputToolCount);
		let found = Call(bed.Server, "editor_find", "{\"target\":\"text=OK\"}");
		defer delete found;
		Test.Assert(found.Ok);
		Test.Assert(found.Pumps == 0, "a read answers at once");
		Test.Assert(found.Payload.Get("count").AsInt() == 2);
		let within = Call(bed.Server, "editor_find", "{\"target\":\"text=OK\",\"within\":\"#dialog\"}");
		defer delete within;
		Test.Assert(within.Ok);
		Test.Assert(within.Payload.Get("count").AsInt() == 1);
		let node = within.Payload.Get("nodes").At(0);
		Test.Assert(node.Get("node").AsString().Contains("#dialog-ok"));
		Test.Assert(node.Get("text").AsString() == "OK");
		Test.Assert(Math.Abs(node.Get("x").AsNumber() - 210.0) < 1e-3);
		Test.Assert(Math.Abs(node.Get("width").AsNumber() - 80.0) < 1e-3);
	}

	[Test]
	public static void AClickReachesWhatItNamesAFrameLaterAndIsRefusedWhenItCannot()
	{
		let bed = scope Bed();
		let clicked = Call(bed.Server, "editor_click", "{\"target\":\"text=Show\"}");
		defer delete clicked;
		Test.Assert(clicked.Ok);
		Test.Assert(clicked.Pumps == 1, "answered on the frame after");
		Test.Assert(bed.Shows == 1);
		Test.Assert(clicked.Payload.Get("clicked").Get("node").AsString().Contains("#show"));
		Test.Assert(Math.Abs(clicked.Payload.Get("at").Get("x").AsNumber() - 50.0) < 1e-3);

		// Several: refused, each named; `index` or `within` picks one.
		let several = Call(bed.Server, "editor_click", "{\"target\":\"text=OK\"}");
		defer delete several;
		Test.Assert(!several.Ok);
		Test.Assert(several.Error.Contains("2 shown node(s) match"));
		Test.Assert(several.Error.Contains("#dialog-ok"));
		Test.Assert(Succeeds(bed.Server, "editor_click", "{\"target\":\"text=OK\",\"index\":1}"));
		Test.Assert(bed.Oks == 1);
		Test.Assert(!Succeeds(bed.Server, "editor_click", "{\"target\":\"#nothing\"}"));

		// Covered: refused, naming what lies over it; nothing is clicked.
		let cover = Bed.Add<Panel>(bed.Root, "cover", 0.0f, 0.0f, 120.0f, 45.0f);
		bed.Root.UpdateLayout();
		let covered = Call(bed.Server, "editor_click", "{\"target\":\"#show\"}");
		defer delete covered;
		Test.Assert(!covered.Ok);
		Test.Assert(covered.Error.Contains("covered at its middle by Panel #cover"));
		Test.Assert(bed.Shows == 1);
		bed.Root.RemoveChild(cover);
		cover.ReleaseRef();
		bed.Root.UpdateLayout();

		// A point, as the screenshot shows it.
		Test.Assert(Succeeds(bed.Server, "editor_click", "{\"x\":30,\"y\":20}"));
		Test.Assert(bed.Shows == 2);
		Test.Assert(!Succeeds(bed.Server, "editor_click", "{\"x\":30}"));
		Test.Assert(!Succeeds(bed.Server, "editor_click", "{\"target\":\"#show\",\"modifiers\":\"hyper\"}"));
	}

	[Test]
	public static void TextGoesToTheFocusAKeyActsOnItAndTheAnswerSaysWhatHasIt()
	{
		let bed = scope Bed();
		let unfocused = Call(bed.Server, "editor_type", "{\"text\":\"lost\"}");
		defer delete unfocused;
		Test.Assert(!unfocused.Ok);
		Test.Assert(unfocused.Error.Contains("nothing has the focus"));

		let clicked = Call(bed.Server, "editor_click", "{\"target\":\"#field\"}");
		defer delete clicked;
		Test.Assert(clicked.Ok);
		Test.Assert(clicked.Payload.Get("focus").Get("node").AsString().Contains("#field"));
		Test.Assert(Succeeds(bed.Server, "editor_type", "{\"text\":\"hello\"}"));
		Test.Assert(bed.Field.Text == "hello");
		Test.Assert(Succeeds(bed.Server, "editor_key", "{\"chord\":\"backspace\"}"));
		Test.Assert(bed.Field.Text == "hell");
		Test.Assert(!Succeeds(bed.Server, "editor_key", "{\"chord\":\"ctrl-nokey\"}"));

		// Hover and scroll answer with what the pointer is over.
		let hover = Call(bed.Server, "editor_hover", "{\"target\":\"text=Show\"}");
		defer delete hover;
		Test.Assert(hover.Ok);
		Test.Assert(hover.Payload.Get("over").Get("node").AsString().Contains("#show"));
		Test.Assert(Succeeds(bed.Server, "editor_scroll", "{\"target\":\"#dialog\",\"dy\":-1}"));
	}
}
