namespace Sedulous.Renderer;

using System;
using Sedulous.Core.Mathematics;

/// Identifies a render data category.
/// Categories determine which render pass processes the data and how it's sorted.
struct RenderDataCategory : IEquatable<RenderDataCategory>, IHashable
{
	public uint16 Value;

	public this(uint16 value)
	{
		Value = value;
	}

	public bool IsValid => Value != uint16.MaxValue;

	public static readonly RenderDataCategory Invalid = .(uint16.MaxValue);

	public bool Equals(RenderDataCategory other) => Value == other.Value;
	public int GetHashCode() => (int)Value;
	public static bool operator ==(RenderDataCategory a, RenderDataCategory b) => a.Value == b.Value;
	public static bool operator !=(RenderDataCategory a, RenderDataCategory b) => a.Value != b.Value;
}

/// Function that generates a 64-bit sorting key for render data.
/// Lower values are rendered first.
typealias RenderDataSortFunc = function uint64(RenderData data, Matrix viewMatrix);

/// Built-in render data categories.
static class RenderCategories
{
	/// Opaque lit geometry. Sorted front-to-back by depth, then by material.
	public static readonly RenderDataCategory Opaque = .(0);

	/// Alpha-tested geometry. Sorted front-to-back.
	public static readonly RenderDataCategory Masked = .(1);

	/// Transparent geometry. Sorted back-to-front.
	public static readonly RenderDataCategory Transparent = .(2);

	/// Sky rendering. No sort (typically one item).
	public static readonly RenderDataCategory Sky = .(3);

	/// Screen-space projected decals. Sorted by sort order.
	public static readonly RenderDataCategory Decal = .(4);

	/// Light data (not drawn — consumed by lighting system).
	public static readonly RenderDataCategory Light = .(5);

	/// Reflection probe data (not drawn — consumed by probe system).
	public static readonly RenderDataCategory ReflectionProbe = .(6);

	/// Screen-space GUI. Rendered last.
	public static readonly RenderDataCategory GUI = .(7);

	/// Particle systems. Rendered in a dedicated pass with depth sampling for soft particles.
	public static readonly RenderDataCategory Particle = .(8);

	/// Total number of built-in categories.
	public const int32 Count = 9;

	/// Gets the sort function for a category.
	public static RenderDataSortFunc GetSortFunc(RenderDataCategory category)
	{
		switch (category.Value)
		{
		case 0, 1: return => SortFrontToBack;   // Opaque, Masked
		case 2:    return => SortBackToFront;    // Transparent
		case 4:    return => SortBySortOrder;    // Decal
		case 8:    return => SortBackToFront;    // Particle
		default:   return => SortNone;
		}
	}

	/// Front-to-back: minimize overdraw for opaque geometry.
	private static uint64 SortFrontToBack(RenderData data, Matrix viewMatrix)
	{
		// View-space Z (smaller = closer = renders first)
		let viewPos = Vector3.Transform(data.Position, viewMatrix);
		let depth = Math.Max(viewPos.Z, 0);
		uint32 depthBits = (uint32)(depth * 1000.0f);

		// Material sort key in upper bits (minimize state changes)
		return ((uint64)data.MaterialSortKey << 32) | (uint64)depthBits;
	}

	/// Back-to-front: correct blending for transparent geometry.
	private static uint64 SortBackToFront(RenderData data, Matrix viewMatrix)
	{
		let viewPos = Vector3.Transform(data.Position, viewMatrix);
		let depth = Math.Max(viewPos.Z, 0);
		uint32 depthBits = (uint32)(depth * 1000.0f);

		// Invert depth so further objects sort first
		return (uint64)(uint32.MaxValue - depthBits);
	}

	/// Sort by explicit sort order (for decals, overlays).
	private static uint64 SortBySortOrder(RenderData data, Matrix viewMatrix)
	{
		return (uint64)(uint32)data.SortOrder;
	}

	/// No sorting.
	private static uint64 SortNone(RenderData data, Matrix viewMatrix)
	{
		return 0;
	}
}
