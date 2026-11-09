using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The MCP panel over its markup (Data/Editor/Mcp.xml): the bar following the host (listening
/// with its client, stopped, a start that could not listen), Start, Stop and Copy Connect Command,
/// the preference's check box and the preferences; the calls newest first with the host's events
/// between, the filter chips with their counts, the search, Clear; the chosen call's detail and
/// Copy as JSON, an event chosen showing none; each row's time, mark and duration; and the panel
/// with no activity at all.
class McpPanelTests
{
	/// A host the panel drives: whether it listens, its port and client, what was copied.
	private class Bed
	{
		public McpActivity Activity = new .() ~ delete _;
		public bool Listening = false;
		public bool CanListen = true;
		public bool WithProject = false;
		public bool HasActivity = true;
		public String Client = new .() ~ delete _;
		public String Copied = new .() ~ delete _;
		public String CopiedWhat = new .() ~ delete _;
		public int Preferences = 0;
		public SceneRoot Root;
		public McpPanel Panel;

		public this()
		{
			let context = new GUIContext();
			Root = new SceneRoot(context);
			context.ReleaseRef(); // the root's keeps it
			Root.Size = .(1800.0f, 500.0f);
			let seams = new McpPanelSeams();
			seams.Activity = new () => HasActivity ? Activity : null;
			seams.Listening = new () => Listening;
			seams.Port = new () => Listening ? (uint16)7405 : (uint16)0;
			seams.ConfiguredPort = new () => (uint32)7405;
			seams.Client = new (outClient) => { outClient.Append(Client); };
			seams.Start = new () =>
				{
					Listening = CanListen;
					return Listening;
				};
			seams.Stop = new () => { Listening = false; };
			seams.ConnectCommand = new (outCommand) =>
				{
					if (Listening)
						outCommand.Append("claude mcp add engine-editor");
				};
			seams.StartsWithProject = new () => WithProject;
			seams.SetStartsWithProject = new (on) => { WithProject = on; };
			seams.Copy = new (text, what) =>
				{
					Copied.Set(text);
					CopiedWhat.Set(what);
				};
			seams.Preferences = new () => { Preferences++; };
			Panel = new McpPanel(seams, PagesBed.LoadMarkup(McpPanel.cMarkupPath));
			Test.Assert(Panel.Content != null);
			Panel.Content.EditLayoutStyle(scope (s) =>
				{
					s.Width = LayoutLength.Px(1800.0f);
					s.Height = LayoutLength.Px(500.0f);
				});
			Root.AddChild(Panel.Content);
			Root.UpdateLayout();
		}

		public ~this()
		{
			DeleteAndNullify!(Panel); // the list let go while the tree holds it
			Root.ReleaseRef();
		}

		public T Find<T>(StringView id) where T : Node => Panel.Content.FindElement(id) as T;

		/// Activates a button or check box, as a click does.
		public void Click(StringView id)
		{
			let node = Find<Node>(id);
			Test.Assert(node != null, scope $"no '{id}'");
			Test.Assert(node.HandleActivate(), scope $"'{id}' did not activate");
		}

		public StringView Text(StringView id) => Find<Sedulous.GUI.Label>(id).Text;

		public void Call(uint64 serial, StringView tool, StringView arguments, ToolAnnotations annotations, bool isError, StringView result,
			int64 at, double seconds = 0.002, ToolCallPhase phase = .Finished)
		{
			let args = JsonValue.Parse(arguments);
			defer delete args;
			var report = ToolCallReport();
			report.Serial = serial;
			report.Phase = phase;
			report.Tool = tool;
			report.Arguments = args;
			report.Annotations = annotations;
			report.IsError = isError;
			report.Result = result;
			report.Elapsed = TimeSpan.FromSeconds(seconds);
			Activity.Record(report, at);
		}
	}

	[Test]
	public static void TheBarFollowsTheHostStartStopAndCopyConnectCommandAStartThatCouldNotListenSaysWhy()
	{
		let bed = scope Bed();
		Test.Assert(bed.Text("mcp-state") == "Stopped");
		Test.Assert(bed.Text("mcp-client") == "Agents cannot reach the editor");
		Test.Assert(!bed.Find<UIWidget>("mcp-dot").HasClass("on"));
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-start").Displayed);
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-start").Tooltip == "Start the MCP host on 127.0.0.1:7405");
		Test.Assert(!bed.Find<Sedulous.GUI.Button>("mcp-stop").Displayed);
		Test.Assert(!bed.Find<Sedulous.GUI.Button>("mcp-copy-connect").Displayed);
		bed.Panel.CopyConnectCommand();
		Test.Assert(bed.Copied.IsEmpty, "stopped: no command to copy");

		bed.Click("mcp-start");
		Test.Assert(bed.Listening);
		Test.Assert(bed.Text("mcp-state") == "Listening on 127.0.0.1:7405");
		Test.Assert(bed.Text("mcp-client") == "no client yet");
		Test.Assert(bed.Find<UIWidget>("mcp-dot").HasClass("on"));
		Test.Assert(!bed.Find<Sedulous.GUI.Button>("mcp-start").Displayed);
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-stop").Displayed);
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-copy-connect").Displayed);
		bed.Client.Set("claude-code 2.1.0");
		bed.Panel.Update();
		Test.Assert(bed.Text("mcp-client") == "claude-code 2.1.0");
		bed.Click("mcp-copy-connect");
		Test.Assert(bed.Copied == "claude mcp add engine-editor");
		Test.Assert(bed.CopiedWhat == "the connect command");

		bed.Click("mcp-stop");
		Test.Assert(!bed.Listening);
		Test.Assert(bed.Text("mcp-state") == "Stopped");
		Test.Assert(!bed.Find<UIWidget>("mcp-dot").HasClass("on"));

		bed.CanListen = false; // another editor holds the port
		bed.Click("mcp-start");
		Test.Assert(bed.Text("mcp-state") == "Could not start");
		Test.Assert(bed.Text("mcp-client").Contains("127.0.0.1:7405 is taken"));
		// The host listening after all (the preferences moved its port) clears the failure.
		bed.Listening = true;
		bed.Panel.Update();
		Test.Assert(bed.Text("mcp-state") == "Listening on 127.0.0.1:7405");
		bed.Listening = false;
		bed.Panel.Update();
		Test.Assert(bed.Text("mcp-state") == "Stopped");

		// The check box is the preference, and follows it; the gear opens the preferences.
		let withProject = bed.Find<Sedulous.GUI.CheckBox>("mcp-with-project");
		Test.Assert(!withProject.Checked);
		bed.Click("mcp-with-project");
		Test.Assert(bed.WithProject);
		bed.WithProject = false; // changed in the preferences
		bed.Panel.Update();
		Test.Assert(!withProject.Checked);
		bed.Click("mcp-preferences");
		Test.Assert(bed.Preferences == 1);
	}

	[Test]
	public static void TheCallsNewestFirstWithTheHostsEventsTheFiltersWithTheirCountsTheSearchClear()
	{
		let bed = scope Bed();
		Test.Assert(bed.Panel.ShownCount == 0);
		Test.Assert(bed.Find<Sedulous.GUI.Label>("mcp-empty").Displayed);
		Test.Assert(bed.Text("mcp-empty") == "No calls yet. Agents' calls show here as they arrive.");
		bed.Activity.RecordEvent("Listening on 127.0.0.1:7405", 100);
		bed.Call(1, "scene_read", "{\"path\":\"Content/Scenes/Level1.scene\"}", .ReadOnly, false, "{}", 101);
		bed.Call(2, "component_set", "{\"entity\":\"Lamp 3\",\"value\":4.5}", .Overwrites, false, "{\"after\":4.5}", 102);
		bed.Call(3, "shader_validate", "{\"path\":\"Shaders/Water.hlsl\"}", .ReadOnly, true, "undeclared identifier 'speed'", 103);
		bed.Call(4, "scene_write", "{}", .Overwrites, true, "scene_write: missing required field 'source'", 104, 0.0, .Refused);
		bed.Panel.Update();

		Test.Assert(bed.Panel.ShownCount == 5);
		Test.Assert(bed.Panel.ShownEntry(0).Tool == "scene_write", "newest first");
		Test.Assert(bed.Panel.ShownEntry(1).Tool == "shader_validate");
		Test.Assert(bed.Panel.ShownEntry(4).Tool == "Listening on 127.0.0.1:7405");
		Test.Assert(bed.Panel.ShownEntry(5) == null);
		Test.Assert(!bed.Find<Sedulous.GUI.Label>("mcp-empty").Displayed);
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-all").Text == "All  4", "calls, not events");
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-edits").Text == "Edits  1", "a refused write is no edit");
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-failed").Text == "Failed  2", "a failure and a refusal");
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-all").HasClass("checked"));

		bed.Click("mcp-edits");
		Test.Assert(bed.Panel.CurrentFilter == .Edits);
		Test.Assert(bed.Panel.ShownCount == 1);
		Test.Assert(bed.Panel.ShownEntry(0).Tool == "component_set");
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-edits").HasClass("checked"));
		Test.Assert(!bed.Find<Sedulous.GUI.Button>("mcp-all").HasClass("checked"));
		bed.Click("mcp-failed");
		Test.Assert(bed.Panel.CurrentFilter == .Failed);
		Test.Assert(bed.Panel.ShownCount == 2);
		Test.Assert(bed.Panel.ShownEntry(0).Tool == "scene_write");
		Test.Assert(bed.Panel.ShownEntry(1).Tool == "shader_validate");
		bed.Panel.Select(0); // the refusal: its reason under Error, no duration
		Test.Assert(bed.Text("mcp-detail-outcome") == "Refused");
		Test.Assert(bed.Find<UIWidget>("mcp-detail-outcome").HasClass("refused"));
		Test.Assert(bed.Text("mcp-detail-when") == "00:01:44");
		Test.Assert(bed.Text("mcp-result-title") == "Error");
		Test.Assert(bed.Find<TextArea>("mcp-result").Text == "scene_write: missing required field 'source'");
		bed.Panel.CopySelectedCall();
		let copied = JsonValue.Parse(bed.Copied);
		defer delete copied;
		Test.Assert(copied.Get("outcome").AsString() == "refused");
		Test.Assert(copied.Get("error").AsString() == "scene_write: missing required field 'source'");
		Test.Assert(copied.Get("result") == null);
		bed.Click("mcp-all");
		Test.Assert(bed.Panel.ShownCount == 5);

		// The search reads a call's tool, its summary and its arguments, ignoring case.
		bed.Panel.SetSearch("level1");
		Test.Assert(bed.Panel.ShownCount == 1);
		Test.Assert(bed.Panel.ShownEntry(0).Tool == "scene_read");
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-clear-search").Visible);
		bed.Panel.SetSearch("SCENE_READ"); // the tool
		Test.Assert(bed.Panel.ShownCount == 1);
		bed.Panel.SetSearch("lamp 3, value"); // the summary's "entity: Lamp 3, value: 4.5", not the arguments' text
		Test.Assert(bed.Panel.ShownCount == 1);
		Test.Assert(bed.Panel.ShownEntry(0).Tool == "component_set");
		bed.Panel.SetSearch("nothing like it");
		Test.Assert(bed.Panel.ShownCount == 0);
		Test.Assert(bed.Find<Sedulous.GUI.Label>("mcp-empty").Displayed);
		Test.Assert(bed.Text("mcp-empty") == "No call matches.");
		// Typed into the field, then cleared by its x.
		let field = bed.Find<TextField>("mcp-search");
		Test.Assert(field != null);
		field.Text = "nothing like it";
		bed.Click("mcp-clear-search");
		Test.Assert(field.Text.IsEmpty);
		Test.Assert(bed.Panel.ShownCount == 5);
		Test.Assert(!bed.Find<Sedulous.GUI.Button>("mcp-clear-search").Visible);

		// A new call shows on the next update.
		bed.Call(5, "asset_list", "{}", .ReadOnly, false, "[]", 105);
		Test.Assert(bed.Panel.ShownCount == 5);
		bed.Panel.Update();
		Test.Assert(bed.Panel.ShownCount == 6);
		Test.Assert(bed.Panel.ShownEntry(0).Tool == "asset_list");

		bed.Click("mcp-clear");
		Test.Assert(bed.Activity.Count == 0);
		Test.Assert(bed.Panel.ShownCount == 0);
		Test.Assert(bed.Find<Sedulous.GUI.Button>("mcp-all").Text == "All");
		Test.Assert(bed.Text("mcp-empty") == "No calls yet. Agents' calls show here as they arrive.");
	}

	[Test]
	public static void TheChosenCallsArgumentsAndAnswerAnErrorUnderErrorCopyAsJsonNothingChosenShowsThePlaceholder()
	{
		let bed = scope Bed();
		bed.Call(1, "component_set", "{\"entity\":\"Lamp 3\",\"value\":4.5}", .Overwrites, false, "{\"after\":4.5}", 3600 * 12 + 4 * 60 + 27, 0.002);
		bed.Call(2, "shader_validate", "{}", .ReadOnly, true, "undeclared identifier 'speed'", 3600 * 12 + 5 * 60, 1.25);
		bed.Panel.Update();
		Test.Assert(!bed.Find<UIWidget>("mcp-detail").Displayed);
		Test.Assert(bed.Find<UIWidget>("mcp-no-detail").Displayed);
		Test.Assert(bed.Panel.Selected == null);
		Test.Assert(bed.Panel.SelectedCallJson(.. scope .()).IsEmpty);
		bed.Panel.CopySelectedCall();
		Test.Assert(bed.Copied.IsEmpty, "nothing chosen copies nothing");

		bed.Panel.Select(1); // the older: component_set
		Test.Assert(bed.Panel.Selected != null);
		Test.Assert(bed.Find<UIWidget>("mcp-detail").Displayed);
		Test.Assert(!bed.Find<UIWidget>("mcp-no-detail").Displayed);
		Test.Assert(bed.Text("mcp-detail-tool") == "component_set");
		Test.Assert(bed.Text("mcp-detail-outcome") == "Done");
		Test.Assert(bed.Find<UIWidget>("mcp-detail-outcome").HasClass("done"));
		Test.Assert(bed.Text("mcp-detail-when") == "12:04:27, 2 ms");
		Test.Assert(bed.Text("mcp-result-title") == "Result");
		let arguments = bed.Find<TextArea>("mcp-arguments");
		let expected = JsonValue.Parse("{\"entity\":\"Lamp 3\",\"value\":4.5}");
		defer delete expected;
		let pretty = scope String();
		expected.ToString(pretty, true);
		Test.Assert(arguments.Text == pretty);
		Test.Assert(arguments.Text.Contains('\n'), "laid out over lines");
		Test.Assert(arguments.IsReadOnly);
		Test.Assert(bed.Find<TextArea>("mcp-result").IsReadOnly);
		Test.Assert(bed.Find<TextArea>("mcp-result").Caret == 0, "read from the top");
		bed.Click("mcp-detail-copy");
		Test.Assert(bed.CopiedWhat == "the call");
		let copied = JsonValue.Parse(bed.Copied);
		defer delete copied;
		Test.Assert(copied.Get("tool").AsString() == "component_set");
		Test.Assert(copied.Get("arguments").Get("entity").AsString() == "Lamp 3");
		Test.Assert(copied.Get("outcome").AsString() == "done");
		Test.Assert(Math.Abs(copied.Get("result").Get("after").AsNumber() - 4.5) < 1e-9);
		Test.Assert(Math.Abs(copied.Get("milliseconds").AsNumber() - 2.0) < 1e-9);
		Test.Assert(copied.Get("error") == null);

		bed.Panel.Select(0); // the failure: its error, as text
		Test.Assert(bed.Text("mcp-detail-outcome") == "Failed");
		Test.Assert(bed.Find<UIWidget>("mcp-detail-outcome").HasClass("failed"));
		Test.Assert(!bed.Find<UIWidget>("mcp-detail-outcome").HasClass("done"));
		Test.Assert(bed.Text("mcp-detail-when") == "12:04:59, 1.3 s", "it answered at 12:05:00 after 1.25 s");
		Test.Assert(bed.Text("mcp-result-title") == "Error");
		Test.Assert(bed.Find<TextArea>("mcp-result").Text == "undeclared identifier 'speed'");
		bed.Panel.CopySelectedCall();
		let failed = JsonValue.Parse(bed.Copied);
		defer delete failed;
		Test.Assert(failed.Get("error").AsString() == "undeclared identifier 'speed'");
		Test.Assert(failed.Get("result") == null);
		Test.Assert(failed.Get("outcome").AsString() == "failed");

		// A running call says so; an event chosen shows the placeholder.
		let none = JsonValue.MakeObject();
		defer delete none;
		var started = ToolCallReport();
		started.Serial = 3;
		started.Phase = .Started;
		started.Tool = "asset_cook";
		started.Arguments = none;
		started.Annotations = .Rebuilds;
		bed.Activity.Record(started, 3600 * 12 + 6 * 60);
		bed.Activity.RecordEvent("Stopped", 3600 * 12 + 7 * 60);
		bed.Panel.Update();
		Test.Assert(bed.Panel.ShownEntry(1).Tool == "asset_cook");
		bed.Panel.Select(1);
		Test.Assert(bed.Text("mcp-detail-outcome") == "Running");
		Test.Assert(bed.Text("mcp-detail-when") == "12:06:00", "no duration while it runs");
		Test.Assert(bed.Find<TextArea>("mcp-result").Text == "(still running)");
		bed.Panel.CopySelectedCall();
		let running = JsonValue.Parse(bed.Copied);
		defer delete running;
		Test.Assert(running.Get("outcome").AsString() == "running");
		Test.Assert((running.Get("result") == null) && (running.Get("error") == null));
		bed.Panel.Select(0); // the event
		Test.Assert(bed.Panel.Selected == null);
		Test.Assert(!bed.Find<UIWidget>("mcp-detail").Displayed);
		Test.Assert(bed.Find<UIWidget>("mcp-no-detail").Displayed);
	}

	[Test]
	public static void EachRowItsTimeItsMarkItsToolItsSummaryTheEditBadgeAndHowLongItTook()
	{
		let bed = scope Bed();
		bed.Activity.RecordEvent("Listening on 127.0.0.1:7405", 3600 * 9);
		bed.Call(1, "component_set", "{\"entity\":\"Lamp 3\"}", .Overwrites, false, "{}", 3600 * 9 + 3 * 60 + 7, 0.038);
		bed.Call(2, "shader_validate", "{}", .ReadOnly, true, "undeclared identifier 'speed'\nat line 3", 3600 * 9 + 4 * 60, 2.34);
		bed.Call(3, "scene_write", "{}", .Overwrites, true, "scene_write: missing required field 'source'", 3600 * 9 + 5 * 60, 0.0, .Refused);
		bed.Panel.Update();
		let list = bed.Panel.List;
		Test.Assert(list != null);
		// The list a fixed size, so it realises its rows.
		list.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(1000.0f);
				s.Height = LayoutLength.Px(300.0f);
			});
		bed.Root.UpdateLayout();
		bed.Root.UpdateLayout();
		let rows = scope List<UIWidget>();
		for (int32 item < 4)
		{
			let row = list.RowForItem(item);
			Test.Assert(row != null, scope $"row {item} realised");
			let content = row.Content as UIWidget;
			Test.Assert((content != null) && content.HasClass("mcp-row"));
			rows.Add(content);
		}

		// The refusal, newest: its reason, no Edit badge though its tool writes, no duration.
		let refusal = rows[0];
		Test.Assert(refusal.HasClass("refused"));
		Test.Assert(!refusal.HasClass("failed"));
		Test.Assert((refusal.GetChildAt(1) as UIWidget).HasClass("refused"));
		Test.Assert(Part(refusal, 2).Text == "scene_write");
		Test.Assert(Part(refusal, 3).Text == "scene_write: missing required field 'source'");
		Test.Assert(!Part(refusal, 4).Displayed);
		Test.Assert(Part(refusal, 5).Text == "refused");
		// The failure: its first line of error.
		let failure = rows[1];
		Test.Assert(failure.HasClass("failed"));
		Test.Assert((failure.GetChildAt(1) as UIWidget).HasClass("failed"));
		Test.Assert(Part(failure, 0).Text == "09:03:58", "it answered at 09:04:00 after 2.34 s");
		Test.Assert(Part(failure, 2).Text == "shader_validate");
		Test.Assert(Part(failure, 3).Text == "undeclared identifier 'speed'");
		Test.Assert(!Part(failure, 4).Displayed, "a read: no Edit badge");
		Test.Assert(Part(failure, 5).Text == "2.3 s");
		// The edit: its badge, its arguments as the summary.
		let edit = rows[2];
		Test.Assert(edit.HasClass("done"));
		Test.Assert(!edit.HasClass("failed"));
		Test.Assert(Part(edit, 0).Text == "09:03:07");
		Test.Assert(Part(edit, 3).Text == "entity: Lamp 3");
		Test.Assert(Part(edit, 4).Displayed);
		Test.Assert(Part(edit, 4).Text == "Edit");
		Test.Assert(Part(edit, 4).HasClass("edit"));
		Test.Assert(Part(edit, 5).Text == "38 ms");
		// The event: no tool, its text, no duration.
		let listening = rows[3];
		Test.Assert(listening.HasClass("event"));
		Test.Assert((listening.GetChildAt(1) as UIWidget).HasClass("event"));
		Test.Assert(!Part(listening, 2).Displayed);
		Test.Assert(Part(listening, 3).Text == "Listening on 127.0.0.1:7405");
		Test.Assert(!Part(listening, 4).Displayed);
		Test.Assert(Part(listening, 5).Text.IsEmpty);
	}

	private static Sedulous.GUI.Label Part(UIWidget row, int at) => row.GetChildAt(at) as Sedulous.GUI.Label;

	[Test]
	public static void ARowsTimeAndDuration()
	{
		Test.Assert(McpPanel.TimeText(3600 * 9 + 60 * 3 + 7, .. scope .()) == "09:03:07");
		Test.Assert(McpPanel.TimeText(86400 * 3 + 3600 * 23 + 60 * 59 + 59, .. scope .()) == "23:59:59");
		Test.Assert(McpPanel.TookText(TimeSpan.FromMilliseconds(0.4), .. scope .()) == "0 ms");
		Test.Assert(McpPanel.TookText(TimeSpan.FromMilliseconds(38.0), .. scope .()) == "38 ms");
		Test.Assert(McpPanel.TookText(TimeSpan.FromMilliseconds(999.0), .. scope .()) == "999 ms");
		Test.Assert(McpPanel.TookText(TimeSpan.FromSeconds(2.34), .. scope .()) == "2.3 s");
		Test.Assert(McpPanel.TookText(TimeSpan.FromSeconds(1.0), .. scope .()) == "1.0 s");
	}

	/// With no service (no activity), the panel shows the bar and an empty list, and Clear and the
	/// filters do nothing that faults.
	[Test]
	public static void NoActivityAnEmptyListAndNothingFaults()
	{
		let bed = scope Bed();
		bed.HasActivity = false;
		bed.Panel.Update();
		bed.Click("mcp-clear");
		bed.Click("mcp-failed");
		Test.Assert(bed.Panel.ShownCount == 0);
		Test.Assert(bed.Panel.ShownEntry(0) == null);
		Test.Assert(bed.Text("mcp-empty") == "No calls yet. Agents' calls show here as they arrive.");
		bed.Panel.Select(0);
		Test.Assert(bed.Panel.Selected == null);
	}
}
