namespace Sedulous.Render;

/// What one view's shadow composition came to, for the tests and the tools to read back.
struct ViewShadowDebug
{
	/// Whether this view's own scene had a directional caster and fitted cascades.
	public bool Directional = false;
	/// Whether the cascade map existed at all this frame, which every view must declare a
	/// read of even when its own scene casts nothing.
	public bool MapBound = false;
	/// This view's scene's first entry in the frame's concatenated local shadow buffer.
	public uint32 LocalEntryBase = 0;

	public this() {}
}
