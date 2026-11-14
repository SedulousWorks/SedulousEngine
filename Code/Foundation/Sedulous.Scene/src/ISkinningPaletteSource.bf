using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// A skinned mesh's bone matrices this frame: BORROWED from whatever poses it, valid until that
/// system's next update. `Previous` is the frame before's (null: reuse `Current`).
struct SkinningPalette
{
	public Float4x4* Current = null;
	public Float4x4* Previous = null;
	public uint32 BoneCount = 0;

	public this() {}
}

/// A system that poses skinned meshes (the animators), asked for a mesh's palette when it is
/// drawn rather than writing the palette into the mesh: a mesh whose animator goes, or stops
/// naming it, then draws static instead of reading the animator's freed matrices.
/// Scene.FindSkinningPalette asks every one.
interface ISkinningPaletteSource
{
	/// The palette `mesh` is posed with now; false when this system does not pose it.
	bool SkinningPaletteOf(EntityHandle mesh, out SkinningPalette outPalette);
}
