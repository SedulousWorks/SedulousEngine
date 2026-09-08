using System;
using Sedulous.Core;

namespace Sedulous.VG.Renderer;

/// What one slice's draws read: the projection, and the distance field parameters its
/// fragment shader needs for screen space antialiasing.
///
/// The distance field fields are ignored by the default pipeline, which is cheaper than a
/// second uniform buffer for the rare case.
[CRepr]
struct VGUniforms
{
	public Float4x4 Projection = .Identity();
	public float DistanceFieldPixelRange = 4.0f;
	public float DistanceFieldAtlasWidth = 512.0f;
	public float DistanceFieldAtlasHeight = 512.0f;
	/// To a sixteen byte boundary, which every backend's constant buffer rules want.
	public float Padding = 0.0f;

	public this() {}
}
