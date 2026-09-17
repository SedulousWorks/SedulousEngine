using System;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// An external renderer's Opaque data: the base fields, and a payload that is NOT mesh data.
///
/// Every byte past the base is 0xFF, so a blind narrowing to MeshRenderData reads a non null
/// BoneMatrices with an enormous BoneCount and files it as an animated caster.
class JunkRenderData : RenderData
{
	public uint8[512] Junk;

	public this()
	{
		Internal.MemSet(&Junk[0], 0xFF, Junk.Count);
	}
}
