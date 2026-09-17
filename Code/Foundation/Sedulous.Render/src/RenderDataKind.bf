namespace Sedulous.Render;

/// What a RenderData IS, for the few frame level passes that must read past the base fields:
/// the shadow caster list reads a skinned caster's bones.
///
/// A one byte answer with no reflection. The subtype's constructor stamps it, so a subclass of
/// MeshRenderData inherits Mesh. This is the ONLY sanctioned way to narrow a RenderData outside
/// its own renderer, and never the renderer id, which is a registration order value an external
/// renderer can hold just as easily.
enum RenderDataKind : uint8
{
	/// The base fields alone: terrain, sprites, particles, any external renderer.
	Generic = 0,
	/// MeshRenderData, or a subclass of it such as MultiMeshRenderData.
	Mesh
}
