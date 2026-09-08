using System;
using Sedulous.Core;
using Sedulous.Shell;

namespace Sedulous.Input;

/// Listening for the next physical input, for a rebind screen.
///
/// Polled once a frame while the screen is listening: the first ACTIVATED input matching
/// the filter comes back as a ready made Binding, and false means keep listening. Cancelling
/// is the screen's business, not this one's.
static class BindingCapture
{
	/// Deliberately high, and deliberately not the press point: an axis at rest is rarely
	/// at exactly zero, and a rebind that captured drift would bind a stick the player
	/// never touched.
	public const float cActivate = 0.6f;

	public static bool Capture(IInputSourceProvider devices, CaptureFilter filter, out Binding binding)
	{
		binding = .();

		if (filter.Keys)
		{
			if (let keyboard = devices.Keyboard)
			{
				// From one: Unknown is not a key anybody can press.
				for (uint32 code = 1; code < (uint32)KeyCode.Count; code++)
				{
					if (!keyboard.IsKeyPressed((KeyCode)code))
						continue;
					binding.Source = .Key;
					binding.Code = code;
					return true;
				}
			}
		}

		if (filter.MouseButtons)
		{
			if (let mouse = devices.Mouse)
			{
				for (uint32 code = 0; code < (uint32)MouseButton.Count; code++)
				{
					if (!mouse.IsButtonPressed((MouseButton)code))
						continue;
					binding.Source = .MouseButton;
					binding.Code = code;
					return true;
				}
			}
		}

		let pads = devices.GamepadCount;
		for (int32 p = 0; p < pads; p++)
		{
			let pad = devices.GetGamepad(p);
			if ((pad == null) || !pad.Connected)
				continue;

			if (filter.GamepadButtons)
			{
				for (uint32 code = 0; code < (uint32)GamepadButton.Count; code++)
				{
					if (!pad.IsButtonPressed((GamepadButton)code))
						continue;
					binding.Source = .GamepadButton;
					binding.Code = code;
					return true;
				}
			}

			// Sticks BEFORE axes: a deflected stick is two axes over the threshold, and
			// binding it as one of them would give a rebind screen half a stick.
			if (filter.GamepadSticks)
			{
				let lx = pad.Axis(.LeftX);
				let ly = pad.Axis(.LeftY);
				let rx = pad.Axis(.RightX);
				let ry = pad.Axis(.RightY);

				if (((lx * lx) + (ly * ly)) > (cActivate * cActivate))
				{
					binding.Source = .GamepadStick;
					binding.Code = (uint32)StickCode.Left;
					return true;
				}
				if (((rx * rx) + (ry * ry)) > (cActivate * cActivate))
				{
					binding.Source = .GamepadStick;
					binding.Code = (uint32)StickCode.Right;
					return true;
				}
			}

			if (filter.GamepadAxes)
			{
				for (uint32 code = 0; code < (uint32)GamepadAxis.Count; code++)
				{
					if (Math.Abs(pad.Axis((GamepadAxis)code)) <= cActivate)
						continue;
					binding.Source = .GamepadAxis;
					binding.Code = code;
					return true;
				}
			}
		}

		return false;
	}
}
