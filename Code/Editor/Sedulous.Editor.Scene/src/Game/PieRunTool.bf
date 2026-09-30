using System;
using System.Collections;
using System.Diagnostics;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene;
using Sedulous.Input;
using Sedulous.Script;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// pie_run, the playtest primitive: one call plays a device-level input timeline into one
/// running PIE instance for a stretch of run time, and answers what happened: probe samples
/// (entity fields and game script properties) at the asked times, screenshots at the asked
/// times, and whether an `until` condition ended it early.
///
/// The call is re-entered every pump until the run ends. One run per instance at a time: the
/// run is found again by its instance, so instances run side by side, a host and a client
/// scripted over the same seconds.
static class PieRunTool
{
	/// The longest run one call takes, in run seconds.
	public const double cMaxDuration = 600;
	/// The sampling period when probes are given without `every` or `sampleAt`.
	public const double cDefaultEvery = 0.5;
	/// The most samples one run takes.
	public const int cMaxSamples = 5000;

	/// One value a run reads: a field of an entity, or a property of the game script.
	private class Probe
	{
		/// A guid, a name or a slash path; empty for a script probe.
		public String Entity = new .() ~ delete _;
		public String Field = new .() ~ delete _;
		/// The game script property; empty for an entity probe.
		public String Script = new .() ~ delete _;
		public String Label = new .() ~ delete _;
	}

	private class Run
	{
		/// BORROWED; the run is dropped when the page is no longer open.
		public EditorPage Page;
		public double Start;
		public uint64 StartFrames;
		public double Duration;
		public List<double> SampleTimes = new .() ~ delete _;
		public int NextSample = 0;
		public double LastSampleTime = -1;
		public List<Probe> Probes = new .() ~ DeleteContainerAndItems!(_);
		public Probe Until ~ delete _;
		public String UntilOp = new .() ~ delete _;
		public JsonValue UntilValue ~ delete _;
		public List<double> ShotTimes = new .() ~ delete _;
		public int NextShot = 0;
		public bool ShotInFlight = false;
		public double ShotAt = 0;
		public String ShotDirectory = new .() ~ delete _;
		public int Serial;
		public JsonValue Samples = JsonValue.MakeArray() ~ delete _;
		public JsonValue Shots = JsonValue.MakeArray() ~ delete _;
		public JsonValue UntilHit ~ delete _;
		public int InputCount;
		public Stopwatch Clock = new .() ~ delete _;
	}

	private class Runs
	{
		public List<Run> Active = new .() ~ DeleteContainerAndItems!(_);
		public int Serial = 0;
	}

	public static void Register(McpServer server, EditorContext context)
	{
		let schema = scope SchemaBuilder();
		schema.Str("pie", "the PIE instance's id, as pie_list reports it (default: the primary, `game-page`)");
		schema.Number("duration", "run seconds to run, up to 600", true);
		schema.Arr("input", "object", "the timeline: entries {at, key, down} | {at, mouseButton, down} | {at, mouseMove: [x, y]} | {at, wheel: [x, y]} | {at, gamepad, button, down} | {at, gamepad, axis, value}; `at` is run seconds since the run starts, `down` defaults to true, `gamepad` to 0");
		schema.Arr("probes", "object", "what to read: {entity, fields} (entity by guid, name or slash path; fields default [\"worldPosition\"]) or {script: \"<game script property>\"}");
		schema.Number("every", "sample the probes every N run seconds (default 0.5)");
		schema.Arr("sampleAt", "number", "or sample at these run times instead");
		schema.Arr("screenshots", "number", "run times at which to write a PNG of the tab");
		schema.Str("screenshotDir", "an existing directory for the screenshots (default: <user-data>/screenshots)");
		let untilSchema = scope SchemaBuilder();
		untilSchema.Str("entity", "the entity, by guid, name or slash path");
		untilSchema.Str("field", "its field path, as in probes (default worldPosition; worldPosition.y for the height)");
		untilSchema.Str("script", "or a game script property");
		untilSchema.Str("op", "<, <=, >, >=, == or !=");
		let untilProperty = untilSchema.Build();
		untilProperty.Set("description", JsonValue.MakeString("end the run early when one value crosses: {entity, field, op, value} or {script, op, value}; `value` is a number, or with == and != a boolean or a string"));
		schema.Property("until", untilProperty);
		let runs = new Runs();
		server.RegisterTool("pie_run",
			"""
			Playtest one running PIE instance (pie_start first): play a device-level input timeline into it for `duration` run seconds and answer what happened. The timeline replaces that tab's real input for the run (the user's mouse and keys do not reach it; other instances keep theirs) and goes through the project's input map as a player's would: keys by KeyCode name ("D", "Space", "LeftShift"), mouse buttons ("Left"), gamepad buttons ("South", "DPadUp") and axes ("LeftX", -1 to 1). Held keys are let go when the run ends. `probes` read entity fields (the paths are `worldPosition`, `position`, `rotation`, `scale`, `active`, or `<component>.<property>` as entity_inspect names them, then `.x`/`.y`/`.z` or a key or index to go inside) and game script properties, sampled `every` N seconds or at `sampleAt` times, one row per sample {t, frame, values} with a final row at the end; an entity missing at a sample reads null. `screenshots` writes the tab at those run times. `until` ends the run when its value crosses ("player worldPosition.y < -10", "script score >= 3"). Returns {pie, endedBy: duration | until | stopped | timeout, gameTime, frames, samples, screenshots, until, state}. Runs are real frames: a time lands within a frame of where it was asked, so compare with tolerances. Start from pie_start for a reproducible run. One run per instance at a time.
			""",
			schema.Build(), .Creates,
			new (arguments, outResult, outError) => Handle(context, runs, arguments, outResult, outError),
			runs);
	}

	private static ToolOutcome Handle(EditorContext context, Runs runs, JsonValue arguments, JsonValue outResult, String outError)
	{
		// A run whose tab closed is over; its page pointer is never used again.
		for (int i = runs.Active.Count - 1; i >= 0; i--)
		{
			if (!context.OpenPages.Contains(runs.Active[i].Page))
			{
				delete runs.Active[i];
				runs.Active.RemoveAt(i);
			}
		}
		let page = PieMcpTools.ResolvePie(context, arguments, outError);
		if (page == null)
			return .Failed;
		for (let run in runs.Active)
		{
			if (run.Page == page)
				return Step(context, runs, run, outResult, outError);
		}
		return Begin(context, runs, page, arguments, outError);
	}

	private static ToolOutcome Begin(EditorContext context, Runs runs, EditorPage page, JsonValue arguments, String outError)
	{
		let pie = page as IPieInstancePage;
		if (!pie.IsRunning)
		{
			outError.AppendF("PIE instance '{}' is not running (pie_start runs it)", pie.PieId);
			return .Failed;
		}
		var run = new Run();
		defer { if (run != null) delete run; }
		let durationArg = arguments.Get("duration");
		if ((durationArg == null) || !durationArg.IsNumber || (durationArg.AsNumber() <= 0) || (durationArg.AsNumber() > cMaxDuration))
		{
			outError.AppendF("`duration` takes run seconds, above 0 and at most {}", cMaxDuration);
			return .Failed;
		}
		run.Duration = durationArg.AsNumber();

		var source = new ScriptedInputSource();
		defer { if (source != null) delete source; }
		if (let input = arguments.Get("input"))
		{
			if (!input.IsArray)
			{
				outError.Append("`input` takes an array of timeline entries");
				return .Failed;
			}
			for (int i < input.Count)
			{
				ScriptedInput entry;
				if (!ParseInput(input.At(i), i, out entry, outError))
					return .Failed;
				if (entry.At > run.Duration)
				{
					outError.AppendF("input[{}]: `at` {} is after the run's end ({})", i, entry.At, run.Duration);
					return .Failed;
				}
				if (!source.Add(entry))
				{
					outError.AppendF("input[{}]: `gamepad` takes 0 to {}", i, ScriptedInputSource.cMaxGamepads - 1);
					return .Failed;
				}
			}
		}
		run.InputCount = source.Count;

		// Probes, checked against the scene the game is in now: a typo fails here, not as a
		// column of nulls.
		if (let probes = arguments.Get("probes"))
		{
			if (!probes.IsArray)
			{
				outError.Append("`probes` takes an array");
				return .Failed;
			}
			for (int i < probes.Count)
			{
				if (!ParseProbes(probes.At(i), i, run.Probes, outError))
					return .Failed;
			}
			for (let probe in run.Probes)
			{
				let value = ProbeValue(pie, probe, outError);
				if (value == null)
					return .Failed;
				delete value;
			}
		}
		if (!run.Probes.IsEmpty && !SampleTimes(arguments, run, outError))
			return .Failed;

		if (let shots = arguments.Get("screenshots"))
		{
			if (!shots.IsArray)
			{
				outError.Append("`screenshots` takes an array of run times");
				return .Failed;
			}
			for (int i < shots.Count)
			{
				let at = shots.At(i);
				if (!at.IsNumber || (at.AsNumber() < 0) || (at.AsNumber() > run.Duration))
				{
					outError.AppendF("screenshots[{}]: a run time from 0 to the duration ({})", i, run.Duration);
					return .Failed;
				}
				run.ShotTimes.Add(at.AsNumber());
			}
			run.ShotTimes.Sort();
			if (!run.ShotTimes.IsEmpty)
			{
				let dirArg = arguments.Get("screenshotDir");
				if ((dirArg != null) && dirArg.IsString && !dirArg.AsString().IsEmpty)
				{
					run.ShotDirectory.Set(dirArg.AsString());
				}
				else
				{
					PathJoin(GetUserDataDirectory(.. scope .()), "screenshots", run.ShotDirectory);
					if (!CreateDirectory(run.ShotDirectory))
					{
						outError.AppendF("could not create '{}'", run.ShotDirectory);
						return .Failed;
					}
				}
			}
		}

		if (let until = arguments.Get("until"))
		{
			if (!ParseUntil(until, run, outError))
				return .Failed;
			let value = ProbeValue(pie, run.Until, outError);
			if (value == null)
				return .Failed;
			delete value;
		}

		run.Page = page;
		run.Start = pie.RunTime;
		run.StartFrames = pie.FrameCount;
		run.Serial = ++runs.Serial;
		run.Clock.Start();
		pie.BeginScriptedInput(source);
		source = null; // the page owns it now
		runs.Active.Add(run);
		run = null;
		return .NotFinished;
	}

	private static ToolOutcome Step(EditorContext context, Runs runs, Run run, JsonValue outResult, String outError)
	{
		let pie = run.Page as IPieInstancePage;
		let t = pie.RunTime - run.Start;
		if (!pie.IsRunning)
			return Finish(runs, run, "stopped", t, outResult);

		if (run.ShotInFlight)
		{
			let capture = pie.LastViewportCapture;
			if ((capture.State == .Written) || (capture.State == .Failed))
			{
				let shot = JsonValue.MakeObject();
				shot.Set("at", JsonValue.MakeNumber(run.ShotAt));
				if (capture.State == .Written)
				{
					shot.Set("path", JsonValue.MakeString(capture.Path));
					shot.Set("width", JsonValue.MakeNumber(capture.Width));
					shot.Set("height", JsonValue.MakeNumber(capture.Height));
				}
				else
				{
					shot.Set("error", JsonValue.MakeString("the capture failed (log_read, category Screenshot, says why)"));
				}
				run.Shots.Add(shot);
				run.ShotInFlight = false;
			}
		}

		// Every sample time passed since the last pump is one row, read now.
		if ((run.NextSample < run.SampleTimes.Count) && (run.SampleTimes[run.NextSample] <= t))
		{
			while ((run.NextSample < run.SampleTimes.Count) && (run.SampleTimes[run.NextSample] <= t))
				run.NextSample++;
			TakeSample(pie, run, t);
		}

		if (run.Until != null)
		{
			let value = ProbeValue(pie, run.Until, scope .());
			if ((value != null) && Crosses(value, run.UntilOp, run.UntilValue))
			{
				let hit = JsonValue.MakeObject();
				hit.Set("probe", JsonValue.MakeString(run.Until.Label));
				hit.Set("op", JsonValue.MakeString(run.UntilOp));
				hit.Set("value", value);
				hit.Set("t", JsonValue.MakeNumber(t));
				run.UntilHit = hit;
				return Finish(runs, run, "until", t, outResult);
			}
			delete value;
		}

		if (!run.ShotInFlight && (run.NextShot < run.ShotTimes.Count) && (run.ShotTimes[run.NextShot] <= t))
		{
			run.ShotAt = run.ShotTimes[run.NextShot++];
			let path = scope String();
			PathJoin(run.ShotDirectory, scope $"{pie.PieId}-{System.Diagnostics.Process.CurrentId}-run{run.Serial}-{run.ShotAt:F2}.png", path);
			context.RevealPage(run.Page); // a hidden tab never renders
			pie.RequestViewportCapture(path);
			run.ShotInFlight = true;
		}

		if ((t >= run.Duration) && !run.ShotInFlight && (run.NextShot >= run.ShotTimes.Count))
			return Finish(runs, run, "duration", t, outResult);
		// The game clock stood still: the debugger holds the run, or the editor is not ticking.
		if (run.Clock.Elapsed.TotalSeconds > (run.Duration * 4) + 30)
			return Finish(runs, run, "timeout", t, outResult);
		return .NotFinished;
	}

	private static ToolOutcome Finish(Runs runs, Run run, StringView endedBy, double t, JsonValue outResult)
	{
		let pie = run.Page as IPieInstancePage;
		if (pie.IsRunning && !run.Probes.IsEmpty && (run.LastSampleTime < t))
			TakeSample(pie, run, t);
		pie.EndScriptedInput();
		outResult.Set("pie", JsonValue.MakeString(pie.PieId));
		outResult.Set("endedBy", JsonValue.MakeString(endedBy));
		outResult.Set("runTime", JsonValue.MakeNumber(t));
		outResult.Set("frames", JsonValue.MakeNumber((double)(pie.FrameCount - run.StartFrames)));
		outResult.Set("inputs", JsonValue.MakeNumber(run.InputCount));
		outResult.Set("samples", run.Samples);
		run.Samples = null;
		outResult.Set("screenshots", run.Shots);
		run.Shots = null;
		outResult.Set("until", (run.UntilHit != null) ? run.UntilHit : JsonValue.MakeNull());
		run.UntilHit = null;
		let state = JsonValue.MakeObject();
		PieMcpTools.WriteState(pie, state);
		outResult.Set("state", state);
		runs.Active.Remove(run);
		delete run;
		return .Answered;
	}

	private static void TakeSample(IPieInstancePage pie, Run run, double t)
	{
		let row = JsonValue.MakeObject();
		row.Set("t", JsonValue.MakeNumber(t));
		row.Set("frame", JsonValue.MakeNumber((double)(pie.FrameCount - run.StartFrames)));
		let values = JsonValue.MakeObject();
		for (let probe in run.Probes)
		{
			let value = ProbeValue(pie, probe, scope .());
			values.Set(probe.Label, (value != null) ? value : JsonValue.MakeNull());
		}
		row.Set("values", values);
		run.Samples.Add(row);
		run.LastSampleTime = t;
	}

	private static bool SampleTimes(JsonValue arguments, Run run, String outError)
	{
		if (let at = arguments.Get("sampleAt"))
		{
			if (!at.IsArray || (at.Count == 0))
			{
				outError.Append("`sampleAt` takes a non-empty array of run times");
				return false;
			}
			for (int i < at.Count)
			{
				let time = at.At(i);
				if (!time.IsNumber || (time.AsNumber() < 0) || (time.AsNumber() > run.Duration))
				{
					outError.AppendF("sampleAt[{}]: a run time from 0 to the duration ({})", i, run.Duration);
					return false;
				}
				run.SampleTimes.Add(time.AsNumber());
			}
			run.SampleTimes.Sort();
			return true;
		}
		var every = cDefaultEvery;
		if (let everyArg = arguments.Get("every"))
		{
			if (!everyArg.IsNumber || (everyArg.AsNumber() <= 0))
			{
				outError.Append("`every` takes run seconds above 0");
				return false;
			}
			every = everyArg.AsNumber();
		}
		if ((run.Duration / every) > cMaxSamples)
		{
			outError.AppendF("`every` {} over {} seconds is more than {} samples", every, run.Duration, cMaxSamples);
			return false;
		}
		for (int i = 0; (i * every) <= run.Duration; i++)
			run.SampleTimes.Add(i * every);
		return true;
	}

	// ---- The timeline ----

	private static bool ParseInput(JsonValue entry, int i, out ScriptedInput outInput, String outError)
	{
		outInput = .();
		if ((entry == null) || !entry.IsObject)
		{
			outError.AppendF("input[{}]: an object", i);
			return false;
		}
		let at = entry.Get("at");
		if ((at == null) || !at.IsNumber || (at.AsNumber() < 0))
		{
			outError.AppendF("input[{}]: `at` takes run seconds from 0", i);
			return false;
		}
		outInput.At = at.AsNumber();
		let downArg = entry.Get("down");
		outInput.Down = (downArg == null) || downArg.AsBool(true);
		let gamepadArg = entry.Get("gamepad");
		outInput.Gamepad = ((gamepadArg != null) && gamepadArg.IsNumber) ? (int32)gamepadArg.AsInt() : 0;

		if (let key = entry.Get("key"))
		{
			outInput.Kind = .Key;
			if (!ScriptedInputSource.ParseKey(key.AsString(), out outInput.Key))
			{
				outError.AppendF("input[{}]: no key '{}' (KeyCode names: A to Z, Num0 to Num9, F1 to F24, Space, Return, Escape, Tab, Left, Right, Up, Down, LeftShift, LeftCtrl, LeftAlt, ...)", i, key.AsString());
				return false;
			}
			return true;
		}
		if (let button = entry.Get("mouseButton"))
		{
			outInput.Kind = .MouseButton;
			if (!ScriptedInputSource.ParseMouseButton(button.AsString(), out outInput.Button))
			{
				outError.AppendF("input[{}]: no mouse button '{}' (Left, Middle, Right, X1, X2)", i, button.AsString());
				return false;
			}
			return true;
		}
		if (let move = entry.Get("mouseMove"))
		{
			outInput.Kind = .MouseMove;
			return ReadPair(move, i, "mouseMove", out outInput.X, out outInput.Y, outError);
		}
		if (let wheel = entry.Get("wheel"))
		{
			outInput.Kind = .MouseWheel;
			return ReadPair(wheel, i, "wheel", out outInput.X, out outInput.Y, outError);
		}
		if (let button = entry.Get("button"))
		{
			outInput.Kind = .PadButton;
			if (!ScriptedInputSource.ParsePadButton(button.AsString(), out outInput.PadButton))
			{
				outError.AppendF("input[{}]: no gamepad button '{}' (South, East, West, North, LeftShoulder, RightShoulder, DPadUp, DPadDown, DPadLeft, DPadRight, Start, Back, ...)", i, button.AsString());
				return false;
			}
			return true;
		}
		if (let axis = entry.Get("axis"))
		{
			outInput.Kind = .PadAxis;
			if (!ScriptedInputSource.ParsePadAxis(axis.AsString(), out outInput.PadAxis))
			{
				outError.AppendF("input[{}]: no gamepad axis '{}' (LeftX, LeftY, RightX, RightY, LeftTrigger, RightTrigger)", i, axis.AsString());
				return false;
			}
			let value = entry.Get("value");
			if ((value == null) || !value.IsNumber || (value.AsNumber() < -1) || (value.AsNumber() > 1))
			{
				outError.AppendF("input[{}]: an axis takes `value` from -1 to 1", i);
				return false;
			}
			outInput.Value = (float)value.AsNumber();
			return true;
		}
		outError.AppendF("input[{}]: name one of `key`, `mouseButton`, `mouseMove`, `wheel`, `button` or `axis`", i);
		return false;
	}

	private static bool ReadPair(JsonValue value, int i, StringView name, out float outX, out float outY, String outError)
	{
		outX = 0;
		outY = 0;
		if (!value.IsArray || (value.Count != 2) || !value.At(0).IsNumber || !value.At(1).IsNumber)
		{
			outError.AppendF("input[{}]: `{}` takes [x, y]", i, name);
			return false;
		}
		outX = (float)value.At(0).AsNumber();
		outY = (float)value.At(1).AsNumber();
		return true;
	}

	// ---- Probes ----

	private static bool ParseProbes(JsonValue entry, int i, List<Probe> outProbes, String outError)
	{
		if ((entry == null) || !entry.IsObject)
		{
			outError.AppendF("probes[{}]: an object", i);
			return false;
		}
		if (let script = entry.Get("script"))
		{
			let probe = new Probe();
			probe.Script.Set(script.AsString());
			probe.Label.AppendF("script.{}", probe.Script);
			outProbes.Add(probe);
			return true;
		}
		let entity = entry.Get("entity");
		if ((entity == null) || !entity.IsString || entity.AsString().IsEmpty)
		{
			outError.AppendF("probes[{}]: name an `entity` (guid, name or slash path) or a `script` property", i);
			return false;
		}
		let fields = entry.Get("fields");
		if ((fields != null) && (!fields.IsArray || (fields.Count == 0)))
		{
			outError.AppendF("probes[{}]: `fields` takes a non-empty array of paths", i);
			return false;
		}
		let count = (fields != null) ? fields.Count : 1;
		for (int f < count)
		{
			let probe = new Probe();
			probe.Entity.Set(entity.AsString());
			probe.Field.Set((fields != null) ? fields.At(f).AsString() : "worldPosition");
			probe.Label.AppendF("{}.{}", probe.Entity, probe.Field);
			outProbes.Add(probe);
		}
		return true;
	}

	private static bool ParseUntil(JsonValue until, Run run, String outError)
	{
		if (!until.IsObject)
		{
			outError.Append("`until` takes {entity, field, op, value} or {script, op, value}");
			return false;
		}
		let probe = new Probe();
		run.Until = probe;
		if (let script = until.Get("script"))
		{
			probe.Script.Set(script.AsString());
			probe.Label.AppendF("script.{}", probe.Script);
		}
		else
		{
			let entity = until.Get("entity");
			if ((entity == null) || !entity.IsString || entity.AsString().IsEmpty)
			{
				outError.Append("`until` names an `entity` (with a `field`) or a `script` property");
				return false;
			}
			probe.Entity.Set(entity.AsString());
			let field = until.Get("field");
			probe.Field.Set(((field != null) && field.IsString) ? field.AsString() : "worldPosition");
			probe.Label.AppendF("{}.{}", probe.Entity, probe.Field);
		}
		let op = until.Get("op");
		let opText = ((op != null) && op.IsString) ? op.AsString() : "";
		if ((opText != "<") && (opText != "<=") && (opText != ">") && (opText != ">=") && (opText != "==") && (opText != "!="))
		{
			outError.Append("`until.op` takes <, <=, >, >=, == or !=");
			return false;
		}
		run.UntilOp.Set(opText);
		let value = until.Get("value");
		if ((value == null) || !(value.IsNumber || value.IsBool || value.IsString))
		{
			outError.Append("`until.value` takes a number (or, with == and !=, a boolean or a string)");
			return false;
		}
		if (!value.IsNumber && (opText != "==") && (opText != "!="))
		{
			outError.Append("`until` compares a boolean or a string with == or != only");
			return false;
		}
		run.UntilValue = value.Clone();
		return true;
	}

	/// Whether `value` stands in `op` to `target`: numbers compare, anything else is equal
	/// or not by its text.
	private static bool Crosses(JsonValue value, StringView op, JsonValue target)
	{
		if (value.IsNumber && target.IsNumber)
		{
			let a = value.AsNumber();
			let b = target.AsNumber();
			switch (op)
			{
			case "<": return a < b;
			case "<=": return a <= b;
			case ">": return a > b;
			case ">=": return a >= b;
			case "==": return a == b;
			case "!=": return a != b;
			}
			return false;
		}
		let a = value.ToString(.. scope .());
		let b = target.ToString(.. scope .());
		if (op == "==")
			return a == b;
		if (op == "!=")
			return a != b;
		return false;
	}

	/// The probe's value now, OWNED; null with the reason when it cannot be read.
	private static JsonValue ProbeValue(IPieInstancePage pie, Probe probe, String outError)
	{
		if (!probe.Script.IsEmpty)
		{
			var value = ScriptValue.Nil;
			if (!pie.GetScriptProperty(probe.Script, ref value))
			{
				outError.AppendF("the game script of PIE instance '{}' has no property '{}' (or no script runs)", pie.PieId, probe.Script);
				return null;
			}
			return ScriptJson(value, pie.RunningScene);
		}
		let scene = pie.RunningScene;
		if (scene == null)
		{
			outError.AppendF("PIE instance '{}' has no scene", pie.PieId);
			return null;
		}
		let handle = FindEntity(scene, probe.Entity);
		if (!scene.IsValid(handle))
		{
			outError.AppendF("no entity '{}' in PIE instance '{}''s scene '{}'", probe.Entity, pie.PieId, scene.Name);
			return null;
		}
		return FieldValue(scene, handle, probe.Entity, probe.Field, outError);
	}

	/// An entity by guid, slash path or name; invalid when none.
	public static EntityHandle FindEntity(Sedulous.Scene.Scene scene, StringView text)
	{
		Guid id;
		if (Guid.Parse(text) case .Ok(out id))
			return scene.FindEntity(id);
		if (text.Contains('/'))
			return scene.FindEntityByPath(text);
		return scene.FindEntityByName(text);
	}

	/// A field path's value, OWNED: the transform names, then `<component>.<property>` (the
	/// component by type id or type name, which may hold dots), then keys and indices inside.
	public static JsonValue FieldValue(Sedulous.Scene.Scene scene, EntityHandle handle, StringView entityText, StringView path, String outError)
	{
		let segments = scope List<StringView>();
		for (let part in path.Split('.'))
			segments.Add(part);
		JsonValue root = null;
		int rest = 1;
		switch (segments[0])
		{
		case "worldPosition":
			var world = scene.GetWorldPosition(handle);
			root = ComponentJson.ValueJson(typeof(Float3), &world);
		case "position":
			var position = scene.GetLocalTransform(handle).Position;
			root = ComponentJson.ValueJson(typeof(Float3), &position);
		case "rotation":
			var rotation = scene.GetLocalTransform(handle).Rotation;
			root = ComponentJson.ValueJson(typeof(Quaternion), &rotation);
		case "scale":
			var scale = scene.GetLocalTransform(handle).Scale;
			root = ComponentJson.ValueJson(typeof(Float3), &scale);
		case "active":
			root = JsonValue.MakeBool(scene.IsActive(handle));
		default:
			let component = scope String();
			for (int k = 1; k < segments.Count; k++)
			{
				component.Clear();
				for (int s < k)
				{
					if (s > 0)
						component.Append('.');
					component.Append(segments[s]);
				}
				let manager = SceneMcpTools.FindComponentManager(scene, handle, component);
				if ((manager == null) || (manager.ComponentType == null))
					continue;
				FieldInfo field = default;
				if (!(manager.ComponentType.GetField(scope String(segments[k])) case .Ok(out field)) || !ComponentJson.IsShown(field))
					continue;
				root = ComponentJson.ValueJson(field.FieldType, (uint8*)manager.GetComponentAddress(handle) + field.MemberOffset);
				rest = k + 1;
				break;
			}
		}
		if (root == null)
		{
			outError.AppendF("entity '{}' has no field '{}' (worldPosition, position, rotation, scale, active, or <component>.<property> as entity_inspect names them)", entityText, path);
			return null;
		}
		var node = root;
		for (int s = rest; s < segments.Count; s++)
		{
			let segment = segments[s];
			JsonValue next = null;
			if (node.IsObject)
			{
				next = node.Get(segment);
			}
			else if (node.IsArray)
			{
				int index = -1;
				switch (segment)
				{
				case "x": index = 0;
				case "y": index = 1;
				case "z": index = 2;
				case "w": index = 3;
				default:
					if (int.Parse(segment) case .Ok(let parsed))
						index = parsed;
				}
				if ((index >= 0) && (index < node.Count))
					next = node.At(index);
			}
			if (next == null)
			{
				outError.AppendF("'{}' of entity '{}': nothing at '{}'", path, entityText, segment);
				delete root;
				return null;
			}
			node = next;
		}
		if (node == root)
			return root;
		let value = node.Clone();
		delete root;
		return value;
	}

	/// A game script value as JSON, OWNED.
	private static JsonValue ScriptJson(ScriptValue value, Sedulous.Scene.Scene scene)
	{
		switch (value.Kind)
		{
		case .Bool: return JsonValue.MakeBool(value.AsBool);
		case .Int: return JsonValue.MakeNumber((double)value.AsInt);
		case .Float: return JsonValue.MakeNumber(value.AsFloat);
		case .String: return JsonValue.MakeString(value.AsString);
		case .Guid: return ComponentJson.GuidJson(value.AsGuid);
		case .Float2: var v2 = value.AsFloat2; return ComponentJson.ValueJson(typeof(Float2), &v2);
		case .Float3: var v3 = value.AsFloat3; return ComponentJson.ValueJson(typeof(Float3), &v3);
		case .Float4: var v4 = value.AsFloat4; return ComponentJson.ValueJson(typeof(Float4), &v4);
		case .Quaternion: var q = value.AsQuaternion; return ComponentJson.ValueJson(typeof(Quaternion), &q);
		case .Color: var c = value.AsColor; return ComponentJson.ValueJson(typeof(Color), &c);
		case .Entity:
			let owner = (value.AsEntityScene != null) ? value.AsEntityScene : scene;
			if ((owner == null) || !owner.IsValid(value.AsEntity))
				return JsonValue.MakeNull();
			return ComponentJson.GuidJson(owner.GetEntityId(value.AsEntity));
		case .Nil: return JsonValue.MakeNull();
		default:
			return JsonValue.MakeString(scope $"<{value.Kind}>");
		}
	}
}
