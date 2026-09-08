using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Input;

/// Human readable names for bindings and the enums around them.
///
/// Formatting over shell codes and a Binding, and nothing else: no UI and no editor. It
/// lives here rather than in the editor's input map page so a HUD button prompt and a
/// rebind screen render a binding exactly the way the editor does, instead of each
/// growing its own table that drifts.
static class BindingNames
{
	/// A key code to a short label: "A".."Z", "0".."9", "F1".."F24", the named keys, else
	/// "Key#<code>" so an unnamed key still shows something a person can report.
	public static void KeyName(uint32 code, String outName)
	{
		const uint32 cA = (.)KeyCode.A;
		const uint32 cZ = (.)KeyCode.Z;
		const uint32 cNum0 = (.)KeyCode.Num0;
		const uint32 cNum9 = (.)KeyCode.Num9;
		const uint32 cF1 = (.)KeyCode.F1;
		const uint32 cF24 = (.)KeyCode.F24;

		if ((code >= cA) && (code <= cZ))
		{
			outName.Append((char8)('A' + (code - cA)));
			return;
		}
		if ((code >= cNum0) && (code <= cNum9))
		{
			outName.Append((char8)('0' + (code - cNum0)));
			return;
		}
		if ((code >= cF1) && (code <= cF24))
		{
			outName.AppendF("F{}", code - cF1 + 1);
			return;
		}

		switch ((KeyCode)code)
		{
		case .Return: outName.Append("Return");
		case .Escape: outName.Append("Escape");
		case .Backspace: outName.Append("Backspace");
		case .Tab: outName.Append("Tab");
		case .Space: outName.Append("Space");
		case .Left: outName.Append("Left");
		case .Right: outName.Append("Right");
		case .Up: outName.Append("Up");
		case .Down: outName.Append("Down");
		case .LeftShift: outName.Append("LShift");
		case .RightShift: outName.Append("RShift");
		case .LeftCtrl: outName.Append("LCtrl");
		case .RightCtrl: outName.Append("RCtrl");
		case .LeftAlt: outName.Append("LAlt");
		case .RightAlt: outName.Append("RAlt");
		default: outName.AppendF("Key#{}", code);
		}
	}

	/// A gamepad button by POSITION, which is how it is bound: "Pad South" whatever the pad
	/// prints on that button.
	public static StringView PadButtonName(uint32 code)
	{
		switch ((GamepadButton)code)
		{
		case .South: return "Pad South";
		case .East: return "Pad East";
		case .West: return "Pad West";
		case .North: return "Pad North";
		case .LeftShoulder: return "Pad LB";
		case .RightShoulder: return "Pad RB";
		case .DPadUp: return "DPad Up";
		case .DPadDown: return "DPad Down";
		case .DPadLeft: return "DPad Left";
		case .DPadRight: return "DPad Right";
		case .Start: return "Pad Start";
		case .Back: return "Pad Back";
		default: return "Pad Button";
		}
	}

	/// A whole binding, dispatching on the physical control its source names.
	public static void DescribeBinding(Binding binding, String outName)
	{
		switch (binding.Source)
		{
		case .Key:
			KeyName(binding.Code, outName);

		case .MouseButton:
			switch ((Sedulous.Shell.MouseButton)binding.Code)
			{
			case .Left: outName.Append("Mouse Left");
			case .Right: outName.Append("Mouse Right");
			case .Middle: outName.Append("Mouse Middle");
			default: outName.Append("Mouse Button");
			}

		case .MouseAxis:
			switch ((MouseAxisCode)binding.Code)
			{
			case .DeltaX: outName.Append("Mouse dX");
			case .DeltaY: outName.Append("Mouse dY");
			case .Wheel: outName.Append("Mouse Wheel");
			default: outName.Append("Mouse Axis");
			}

		case .MouseDelta:
			outName.Append("Mouse Delta (2D)");

		case .GamepadButton:
			outName.Append(PadButtonName(binding.Code));

		case .GamepadAxis:
			switch ((GamepadAxis)binding.Code)
			{
			case .LeftX: outName.Append("Pad Left X");
			case .LeftY: outName.Append("Pad Left Y");
			case .RightX: outName.Append("Pad Right X");
			case .RightY: outName.Append("Pad Right Y");
			case .LeftTrigger: outName.Append("Pad LT");
			case .RightTrigger: outName.Append("Pad RT");
			default: outName.Append("Pad Axis");
			}

		case .GamepadStick:
			outName.Append(((StickCode)binding.Code == .Left) ? "Left Stick" : "Right Stick");

		case .TouchButton:
			outName.Append("Touch Region");

		case .TouchStick:
			outName.Append("Touch Stick");

		case .Composite2D:
			outName.Append("Keys ");
			KeyName(binding.NegX, outName);
			outName.Append('/');
			KeyName(binding.PosX, outName);
			outName.Append('/');
			KeyName(binding.NegY, outName);
			outName.Append('/');
			KeyName(binding.PosY, outName);
		}
	}

	/// The short name of a binding source, for a grid column rather than a prompt.
	public static StringView SourceName(BindingSource source)
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
		}
	}

	/// The sources an action of `kind` accepts, in CYCLE order: an editor stepping a
	/// binding through its choices walks this list, so it has to agree with what
	/// InputMap validation allows or the editor offers a source that then fails.
	public static void ValidSources(ActionKind kind, List<BindingSource> outSources)
	{
		switch (kind)
		{
		case .Button:
			outSources.Add(.Key);
			outSources.Add(.MouseButton);
			outSources.Add(.GamepadButton);
			outSources.Add(.TouchButton);

		case .Axis1D:
			outSources.Add(.Key);
			outSources.Add(.MouseButton);
			outSources.Add(.GamepadButton);
			outSources.Add(.MouseAxis);
			outSources.Add(.GamepadAxis);

		case .Axis2D:
			outSources.Add(.GamepadStick);
			outSources.Add(.Composite2D);
			outSources.Add(.MouseDelta);
			outSources.Add(.TouchStick);
		}
	}

	public static StringView KindName(ActionKind kind)
	{
		switch (kind)
		{
		case .Button: return "Button";
		case .Axis1D: return "Axis1D";
		case .Axis2D: return "Axis2D";
		}
	}

	public static StringView InteractionName(InteractionKind kind)
	{
		switch (kind)
		{
		case .None: return "On Press";
		case .Hold: return "Hold";
		case .Tap: return "Tap";
		case .DoubleTap: return "Double Tap";
		}
	}
}
