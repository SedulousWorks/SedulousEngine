using System;

namespace Sedulous.Editor.Fonts;

/// What a preview bake needs, captured on the UI thread so the worker touches no page
/// state: the source path and the bake parameters, tagged with the generation that asked.
class FontBakeRequest
{
	public bool Valid = false;
	public String Path = new .() ~ delete _;
	public bool DistanceField = false;
	public float Size = 0.0f;
	public int32 FirstCodepoint = 0;
	public int32 LastCodepoint = 0;
	public uint32 AtlasWidth = 0;
	public uint32 AtlasHeight = 0;
	public uint64 Generation = 0;
}
