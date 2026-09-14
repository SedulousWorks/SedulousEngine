using System;
using Sedulous.Input;

namespace Samples.InputActions;

/// Short names for the binding sources, for the panel.
static class BindingLabels
{
	public static StringView SourceLabel(BindingSource source)
	{
		switch (source)
		{
		case .Key: return "Key";
		case .MouseButton: return "MouseBtn";
		case .MouseAxis: return "MouseAxis";
		case .MouseDelta: return "MouseDelta";
		case .GamepadButton: return "PadBtn";
		case .GamepadAxis: return "PadAxis";
		case .GamepadStick: return "PadStick";
		case .Composite2D: return "Keys4";
		case .TouchButton: return "TouchBtn";
		case .TouchStick: return "TouchStick";
		default: return "?";
		}
	}
}
