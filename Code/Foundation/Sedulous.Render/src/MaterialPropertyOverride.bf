using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One material property set for one mesh alone, borrowed into its draw from the owner: the
/// draw's material in `Slot` gets an instance of its own carrying `Value`, as the material
/// authors it (a colour sRGB rgba, an HDR colour sRGB rgb with its intensity in w).
///
/// The owner keeps `Name` and frees it.
struct MaterialPropertyOverride
{
	public uint32 Slot = 0;
	/// The bytes written: 4 for a float, 16 for a Float4.
	public uint32 Size = sizeof(float);
	public Float4 Value = .(0, 0, 0, 0);
	public String Name = null;

	public this() {}
}
