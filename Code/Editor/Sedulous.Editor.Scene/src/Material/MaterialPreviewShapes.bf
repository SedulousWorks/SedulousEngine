using System;
using Sedulous.Geometry;

namespace Sedulous.Editor.Scene;

/// The primitive shapes a material previews on, in the order the page's Shape row lists
/// them. Index zero, the sphere, is the default and what an out of range index builds.
static class MaterialPreviewShapes
{
	public static readonly StringView[6] Names = .("Sphere", "Cube", "Plane", "Cylinder", "Torus", "Cone");

	/// Sized so each fills the preview framing comparably. The caller owns the result.
	public static StaticMesh Build(uint32 shape)
	{
		switch (shape)
		{
		case 1: return Primitives.Cube(1.4f);
		case 2: return Primitives.Plane(2.0f, 2.0f);
		case 3: return Primitives.Cylinder(0.7f, 1.6f, 48);
		case 4: return Primitives.Torus(0.8f, 0.35f, 48, 24);
		case 5: return Primitives.Cone(0.8f, 1.6f, 48);
		default: return Primitives.Sphere(1.0f, 48, 24);
		}
	}
}
