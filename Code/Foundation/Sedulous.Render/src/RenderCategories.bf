using System;
using Sedulous.Materials;

namespace Sedulous.Render;

/// The BUILT IN render categories, and the limits the registry works within.
///
/// A category is a plain number rather than an enum so a subsystem outside this module can
/// claim one without editing anything here: particles and world space UI are extensions, and
/// an enum would make every extension a change to the core.
static class RenderCategories
{
	/// Depth sorted front to back, which is what makes early depth rejection work.
	public const uint16 Opaque = 0;
	/// Alpha tested, and sorted like the opaque ones.
	public const uint16 Masked = 1;
	/// Depth sorted BACK TO FRONT, because blending is order dependent.
	public const uint16 Transparent = 2;
	public const uint16 Sky = 3;
	public const uint16 Decal = 4;
	public const uint16 Light = 5;
	public const uint16 ReflectionProbe = 6;
	public const uint16 GUI = 7;
	public const uint16 Particle = 8;
	/// After tone mapping and depth tested, which is what a world space panel needs to keep
	/// its authored colours and still be occluded.
	public const uint16 WorldUI = 9;

	public const uint16 BuiltinCount = 10;
	/// The registry's table size, with room for extensions.
	public const uint16 MaxCategories = 64;

	/// The category a material draws in, the dispatch and sort key: Masked for an alpha tested
	/// cut-out, or for an opaque material whose shader moves its vertices (it draws its depth
	/// with a program of its own, Material.DepthShaderName, compiled apart from its forward one:
	/// the forward pass's equal test against the camera depth prepass would flicker where they
	/// differ, so it stays out of the prepass, as a fading mesh does); Transparent for a blend;
	/// else Opaque.
	public static uint16 CategoryForMaterial(Material material)
	{
		if (material == null)
			return Opaque;
		switch (material.Pipeline.BlendMode)
		{
		case .Opaque: return material.DepthShaderName.IsEmpty ? Opaque : Masked;
		case .Masked: return Masked;
		default: return Transparent;
		}
	}

	/// The category a mesh's slot draws in: its material's, an opaque one Masked while the mesh
	/// fades (the screen door dither keeps it out of the depth prepass, whose depth would hide
	/// what shows through it).
	public static uint16 MeshSlotCategory(Material material, float fade)
	{
		let category = CategoryForMaterial(material);
		return ((fade > 0.0f) && (category == Opaque)) ? Masked : category;
	}
}
