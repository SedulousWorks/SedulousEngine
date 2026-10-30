using System;
using Sedulous.Json;

namespace Sedulous.Input;

/// A scripted input timeline read from JSON, as the playtest tools take one (pie_run into a Game
/// tab, viewport_run into a scene view): each entry `{at, key, down}`, `{at, mouseButton, down}`,
/// `{at, mouseMove: [x, y]}`, `{at, wheel: [x, y]}`, `{at, gamepad, button, down}` or
/// `{at, gamepad, axis, value}`, the names the enums' case names in any case. One reader, so the
/// tools take the same timeline and say the same of a wrong one.
static class ScriptedInputJson
{
	/// One timeline entry; false with the error, which names it as `input[index]`, appended.
	public static bool ParseScriptedInput(JsonValue entry, int i, out ScriptedInput outInput, String outError)
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

	/// Every entry of `timeline` (a JSON array) into `source`, none after `duration` seconds; false
	/// with the first wrong entry's error appended, nothing added past it.
	public static bool AddScriptedTimeline(JsonValue timeline, double duration, ScriptedInputSource source, String outError)
	{
		if ((timeline == null) || !timeline.IsArray)
		{
			outError.Append("`input` takes an array of timeline entries");
			return false;
		}
		for (int i < timeline.Count)
		{
			if (!ParseScriptedInput(timeline.At(i), i, let entry, outError))
				return false;
			if (entry.At > duration)
			{
				outError.AppendF("input[{}]: `at` {} is after the run's end ({})", i, entry.At, duration);
				return false;
			}
			if (!source.Add(entry))
			{
				outError.AppendF("input[{}]: `gamepad` takes 0 to {}", i, ScriptedInputSource.cMaxGamepads - 1);
				return false;
			}
		}
		return true;
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
}
