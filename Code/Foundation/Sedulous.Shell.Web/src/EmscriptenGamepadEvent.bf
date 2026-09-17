using System;

namespace Sedulous.Shell.Web;

/// html5.h's EmscriptenGamepadEvent, field for field.
///
/// The browser reports pads through the W3C STANDARD MAPPING, where button and axis indices
/// mean fixed things whatever the physical pad is. Mapping says whether that holds: an empty
/// string means the browser could not map the device and the indices mean nothing in
/// particular.
///
/// The arrays are a fixed 64 and NumButtons and NumAxes say how many are real.
[CRepr]
struct EmscriptenGamepadEvent
{
	public const int MaxEntries = 64;

	public double Timestamp;
	public int32 NumAxes;
	public int32 NumButtons;
	public double[MaxEntries] Axis;
	public double[MaxEntries] AnalogButton;
	public bool[MaxEntries] DigitalButton;
	public bool Connected;
	public int32 Index;
	public char8[64] Id;
	public char8[64] Mapping;
}
