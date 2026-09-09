using System;

namespace Sedulous.Render;

/// One row of the renderer's "what can I look at" table.
///
/// The PREVIOUS frame's graph inventory, since the graph is rebuilt every frame under stable
/// names. A multisampled source is listed but cannot be blitted: its resolved twin is the one
/// to pick.
class DebugResourceInfo
{
	public String Name = new .() ~ delete _;
	public uint32 Width = 0;
	public uint32 Height = 0;
	public uint8 Samples = 1;
	public bool IsDepth = false;

	public this() {}

	public this(StringView name, uint32 width, uint32 height, uint8 samples, bool isDepth)
	{
		Name.Set(name);
		Width = width;
		Height = height;
		Samples = samples;
		IsDepth = isDepth;
	}

	public bool IsBlittable => Samples <= 1;
}
