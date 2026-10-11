using System;
using System.Collections;
using Sedulous.Input;

namespace Sedulous.Editor.Input;

/// The input map page's headless edits: the guarded lookups the editors mutate through, fresh
/// bindings, the names the page shows, the source cycle, and the capture filter a listen uses.
static class InputMapEdit
{
	public static ActionSet SetAt(InputMap map, int set) => ((set >= 0) && (set < map.Sets.Count)) ? map.Sets[set] : null;

	public static InputAction ActionAt(InputMap map, int set, int action)
	{
		let s = SetAt(map, set);
		return ((s != null) && (action >= 0) && (action < s.Actions.Count)) ? s.Actions[action] : null;
	}

	public static bool HasBinding(InputMap map, int set, int action, int binding)
	{
		let a = ActionAt(map, set, action);
		return (a != null) && (binding >= 0) && (binding < a.Bindings.Count);
	}

	/// A fresh binding for an action: a stick for a 2D axis, a key otherwise.
	public static Binding FreshBinding(ActionKind kind)
	{
		var fresh = Binding();
		if (kind == .Axis2D)
			fresh.Source = .GamepadStick;
		return fresh;
	}

	/// A fresh binding of `source`, for the Add Binding menu.
	public static Binding FreshBinding(BindingSource source)
	{
		var fresh = Binding();
		fresh.Source = source;
		return fresh;
	}

	/// Whether an action of `kind` takes a `source` binding.
	public static bool SourceFitsKind(ActionKind kind, BindingSource source)
	{
		let valid = scope List<BindingSource>();
		BindingNames.ValidSources(kind, valid);
		return valid.Contains(source);
	}

	/// A source as the page names it: what the user plugs in or touches.
	public static StringView SourceTitle(BindingSource source)
	{
		switch (source)
		{
		case .Key: return "Key";
		case .MouseButton: return "Mouse button";
		case .MouseAxis: return "Mouse axis";
		case .MouseDelta: return "Mouse movement";
		case .GamepadButton: return "Gamepad button";
		case .GamepadAxis: return "Gamepad axis";
		case .GamepadStick: return "Gamepad stick";
		case .Composite2D: return "Four keys";
		case .TouchButton: return "Touch button";
		case .TouchStick: return "Touch stick";
		}
	}

	/// An action kind as the page names it.
	public static StringView KindTitle(ActionKind kind)
	{
		switch (kind)
		{
		case .Button: return "Button";
		case .Axis1D: return "1D axis";
		case .Axis2D: return "2D axis";
		}
	}

	/// The next source valid for the action, on a fresh binding since the source specifics
	/// mean nothing across sources.
	public static Binding CycleSource(ActionKind kind, Binding current)
	{
		let valid = scope List<BindingSource>();
		BindingNames.ValidSources(kind, valid);
		if (valid.IsEmpty)
			return current;
		int index = 0;
		for (int i < valid.Count)
		{
			if (valid[i] == current.Source)
			{
				index = i;
				break;
			}
		}
		var fresh = Binding();
		fresh.Source = valid[(index + 1) % valid.Count];
		return fresh;
	}

	/// What a listen on `kind` accepts; a composite direction takes keys only.
	public static CaptureFilter FilterFor(ActionKind kind, bool compositeDirection)
	{
		var filter = CaptureFilter();
		if (compositeDirection)
		{
			filter.MouseButtons = false;
			filter.GamepadButtons = false;
			return filter;
		}
		switch (kind)
		{
		case .Button: // keys, mouse and pad buttons
		case .Axis1D:
			filter.GamepadAxes = true;
		case .Axis2D:
			filter.Keys = false;
			filter.MouseButtons = false;
			filter.GamepadButtons = false;
			filter.GamepadSticks = true;
		}
		return filter;
	}

	/// Writes a captured binding into its slot: the whole binding, or one composite
	/// direction's key code.
	public static void ApplyCapture(InputMap map, int set, int action, int binding, int direction, Binding captured)
	{
		let a = ActionAt(map, set, action);
		if ((a == null) || (binding < 0) || (binding >= a.Bindings.Count))
			return;
		if (direction < 0)
		{
			a.Bindings[binding] = captured;
			return;
		}
		var slot = a.Bindings[binding];
		switch (direction)
		{
		case 0: slot.NegX = captured.Code;
		case 1: slot.PosX = captured.Code;
		case 2: slot.NegY = captured.Code;
		default: slot.PosY = captured.Code;
		}
		a.Bindings[binding] = slot;
	}
}
