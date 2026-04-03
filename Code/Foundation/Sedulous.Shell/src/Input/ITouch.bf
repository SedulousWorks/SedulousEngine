using System;
using Sedulous.Core;

namespace Sedulous.Shell.Input;

/// Touch input interface for multi-touch support.
public interface ITouch
{
	/// Gets the number of active touch points.
	int TouchCount { get; }

	/// Gets a touch point by index.
	/// Returns false if the index is out of range.
	bool GetTouchPoint(int index, out TouchPoint point);

	/// Gets whether touch input is available on this device.
	bool HasTouch { get; }

	/// Called when a finger touches down.
	EventAccessor<TouchEventDelegate> OnTouchDown { get; }

	/// Called when a finger lifts up.
	EventAccessor<TouchEventDelegate> OnTouchUp { get; }

	/// Called when a finger moves.
	EventAccessor<TouchEventDelegate> OnTouchMove { get; }
}
