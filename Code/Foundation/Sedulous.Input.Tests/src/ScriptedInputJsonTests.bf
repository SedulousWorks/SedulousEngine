using System;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Input;

namespace Sedulous.Input.Tests;

/// A scripted timeline read from JSON, as the playtest tools take it (pie_run, viewport_run), each
/// wrong entry named.
class ScriptedInputJsonTests
{
	/// What reading `json` says when it fails; empty when it reads.
	private static void ErrorOf(StringView json, double duration, String outError)
	{
		let source = scope ScriptedInputSource();
		let timeline = JsonValue.Parse(json);
		defer delete timeline;
		ScriptedInputJson.AddScriptedTimeline(timeline, duration, source, outError);
	}

	[Test]
	public static void ATimelineReadFromJsonAsThePlaytestToolsTakeItEachWrongEntryNamed()
	{
		let source = scope ScriptedInputSource();
		let timeline = JsonValue.Parse("""
			[{"at": 0.5, "key": "leftshift"}, {"at": 0.1, "mouseMove": [320, 200]}, {"at": 0.2, "wheel": [0, 2]},
			 {"at": 0.3, "mouseButton": "Left", "down": false}, {"at": 0.4, "gamepad": 1, "axis": "LeftX", "value": -0.5}]
			""");
		defer delete timeline;
		let error = scope String();
		Test.Assert(ScriptedInputJson.AddScriptedTimeline(timeline, 1.0, source, error), error);
		Test.Assert(source.Count == 5);
		source.Advance(0.25);
		Test.Assert(Math.Abs(source.Mouse.X - 320.0f) < 0.001f);
		Test.Assert(Math.Abs(source.Mouse.ScrollY - 2.0f) < 0.001f); // this frame's
		source.Advance(0.6);
		Test.Assert(source.Keyboard.IsKeyDown(.LeftShift)); // the name in any case
		Test.Assert(source.GamepadCount == 2);

		Test.Assert(ErrorOf(@"[{""at"": 0.1, ""key"": ""Nope""}]", 1.0, .. scope .()).StartsWith("input[0]: no key 'Nope'"));
		Test.Assert(ErrorOf(@"[{""at"": 0.1}, {""at"": 2.0, ""key"": ""A""}]", 5.0, .. scope .()).StartsWith("input[0]: name one of"));
		Test.Assert(ErrorOf(@"[{""at"": 2.0, ""key"": ""A""}]", 1.0, .. scope .()).Contains("after the run's end"));
		Test.Assert(ErrorOf(@"[{""at"": 0.1, ""wheel"": [1]}]", 1.0, .. scope .()) == "input[0]: `wheel` takes [x, y]");
		Test.Assert(ErrorOf(@"{""at"": 0}", 1.0, .. scope .()) == "`input` takes an array of timeline entries");
	}
}
