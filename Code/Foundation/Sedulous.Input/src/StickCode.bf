using System;
namespace Sedulous.Input;

/// Which gamepad stick a binding reads.
/// Its cases are reflected so tools name them (an input map stores the numbers).
[Reflect(.StaticFields)]
enum StickCode : uint32
{
	Left = 0,
	Right = 1
}
