using System;
namespace Sedulous.Input;

/// Which mouse axis a binding reads.
/// Its cases are reflected so tools name them (an input map stores the numbers).
[Reflect(.StaticFields)]
enum MouseAxisCode : uint32
{
	DeltaX = 0,
	DeltaY = 1,
	Wheel = 2
}
