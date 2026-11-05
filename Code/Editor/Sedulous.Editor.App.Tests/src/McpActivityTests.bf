using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The MCP activity: each tools/call the host reports becomes one entry (added at once, or when it
/// starts running and closed when it answers or is abandoned), the host's own events sit between
/// them, a stopped host abandons what was still running, and the entries are capped. A row's
/// summary is a failure's first line, else the arguments as name: value pairs.
static class McpActivityTests
{
	private static ToolCallReport Report(uint64 serial, ToolCallPhase phase, StringView tool, JsonValue arguments,
		ToolAnnotations annotations, bool isError = false, StringView result = default, double seconds = 0.0)
	{
		var report = ToolCallReport();
		report.Serial = serial;
		report.Phase = phase;
		report.Tool = tool;
		report.Arguments = arguments;
		report.Annotations = annotations;
		report.IsError = isError;
		report.Result = result;
		report.Elapsed = TimeSpan.FromSeconds(seconds);
		return report;
	}

	[Test]
	public static void AnAtOnceCallIsOneFinishedEntryARunningOneIsClosedByItsOwnSerial()
	{
		let activity = scope McpActivity();
		let args = JsonValue.MakeObject();
		defer delete args;
		args.Set("entity", JsonValue.MakeString("Lamp 3"));
		args.Set("value", JsonValue.MakeNumber(4.5));

		let before = activity.Revision;
		activity.Record(Report(1, .Finished, "component_set", args, .Overwrites, false, "{\"after\":4.5}"), 1000);
		Test.Assert(activity.Revision != before);
		Test.Assert(activity.Count == 1);
		let component = activity[0];
		Test.Assert(component.IsCall);
		Test.Assert(component.Outcome == .Done);
		Test.Assert(component.Tool == "component_set");
		Test.Assert(component.Arguments == "{\"entity\":\"Lamp 3\",\"value\":4.5}", component.Arguments);
		Test.Assert(component.Result == "{\"after\":4.5}");
		Test.Assert(component.Changes);
		Test.Assert(component.At == 1000);
		Test.Assert(activity.RunningCall == null);

		// A cook runs across pumps: Started adds it running, a read lands meanwhile, then it answers.
		let none = JsonValue.MakeObject();
		defer delete none;
		activity.Record(Report(2, .Started, "asset_cook", none, .Rebuilds), 1010);
		Test.Assert(activity.RunningCall != null);
		Test.Assert(activity.RunningCall.Tool == "asset_cook");
		Test.Assert(activity.RunningCall.Outcome == .Running);
		Test.Assert(!activity.RunningCall.Changes, "a rebuild of derived output");
		activity.Record(Report(3, .Finished, "asset_list", none, .ReadOnly), 1011);
		activity.Record(Report(2, .Finished, "asset_cook", none, .Rebuilds, true, "cook failed\nat step 2", 4.0), 1014);
		Test.Assert(activity.Count == 3);
		Test.Assert(activity[1].Tool == "asset_cook");
		Test.Assert(activity[1].Outcome == .Failed);
		Test.Assert(activity[1].Elapsed == TimeSpan.FromSeconds(4.0));
		Test.Assert(activity[1].At == 1010, "when it started, not when it answered");
		Test.Assert(activity[2].Tool == "asset_list");
		Test.Assert(activity.RunningCall == null);
		Test.Assert(activity.LastCall === activity[2]);

		// Its caller left: abandoned. An Abandoned for a call never heard Started adds nothing.
		activity.Record(Report(4, .Started, "pie_run", none, .Adjusts), 1020);
		activity.Record(Report(4, .Abandoned, "pie_run", none, .Adjusts), 1030);
		Test.Assert(activity[3].Outcome == .Abandoned);
		activity.Record(Report(9, .Abandoned, "pie_run", none, .Adjusts), 1031);
		Test.Assert(activity.Count == 4);

		// Refused before any tool ran: an entry of its own with the refusal, never an edit.
		let revision = activity.Revision;
		activity.Record(Report(10, .Refused, "scene_write", none, .Overwrites, true, "scene_write: missing required field 'source'"), 1040);
		Test.Assert(activity.Revision != revision);
		Test.Assert(activity.Count == 5);
		Test.Assert(activity[4].IsCall);
		Test.Assert(activity[4].Outcome == .Refused);
		Test.Assert(!activity[4].Changes);
		Test.Assert(activity[4].Result == "scene_write: missing required field 'source'");
		Test.Assert(activity[4].At == 1040);
		Test.Assert(McpActivity.Summary(activity[4], .. scope .()) == "scene_write: missing required field 'source'");
		Test.Assert(activity.RunningCall == null);
		Test.Assert(activity.LastCall == activity[4]);
	}

	[Test]
	public static void TheHostsEventsSitBetweenTheCallsAndAStopAbandonsWhatStillRuns()
	{
		let activity = scope McpActivity();
		let none = JsonValue.MakeObject();
		defer delete none;
		activity.RecordEvent("Listening on 127.0.0.1:7405", 100);
		activity.Record(Report(1, .Started, "asset_cook", none, .Rebuilds), 101);
		activity.HostStopped(102);
		Test.Assert(activity.Count == 3);
		Test.Assert(!activity[0].IsCall);
		Test.Assert(activity[0].Tool == "Listening on 127.0.0.1:7405");
		Test.Assert(activity[1].Outcome == .Abandoned);
		Test.Assert(activity[2].Tool == "Stopped");
		Test.Assert(activity.RunningCall == null);
		// The next host numbers its calls from 1 again: a new call, not the old one finishing.
		activity.Record(Report(1, .Finished, "host_info", none, .ReadOnly), 103);
		Test.Assert(activity.Count == 4);
		Test.Assert(activity[1].Outcome == .Abandoned);
		activity.Clear();
		Test.Assert(activity.Count == 0);
		Test.Assert(activity.LastCall == null);
	}

	[Test]
	public static void TheEntriesAreCappedTheOldestTrimmed()
	{
		let activity = scope McpActivity();
		let none = JsonValue.MakeObject();
		defer delete none;
		for (uint64 i = 1; i <= McpActivity.cMaxEntries + 5; i++)
			activity.Record(Report(i, .Finished, "host_info", none, .ReadOnly), (int64)i);
		Test.Assert(activity.Count == McpActivity.cMaxEntries);
		Test.Assert(activity[0].At == 6);
		Test.Assert(activity.FindById(activity[0].Id) === activity[0]);
	}

	[Test]
	public static void ARowsSummaryIsAFailuresFirstLineElseTheArgumentsByNameCutShort()
	{
		let call = scope McpActivity.Entry();
		call.Arguments.Set("{\"path\":\"Content/Scenes/Level1.scene\",\"force\":true,\"ids\":[1,2]}");
		Test.Assert(McpActivity.Summary(call, .. scope .()) == "path: Content/Scenes/Level1.scene, force: true, ids: [1,2]");
		Test.Assert(McpActivity.Summary(call, 10, .. scope .()) == "path: Cont...");
		call.Arguments.Set("{}");
		Test.Assert(McpActivity.Summary(call, .. scope .()).IsEmpty);
		call.Outcome = .Failed;
		call.Result.Set("Scripts/Player.as: 'speed' is not a member\nline 4");
		Test.Assert(McpActivity.Summary(call, .. scope .()) == "Scripts/Player.as: 'speed' is not a member");
		let event = scope McpActivity.Entry();
		event.Kind = .Event;
		event.Tool.Set("claude-code 2.1.0 connected");
		Test.Assert(McpActivity.Summary(event, .. scope .()) == "claude-code 2.1.0 connected");
	}
}
