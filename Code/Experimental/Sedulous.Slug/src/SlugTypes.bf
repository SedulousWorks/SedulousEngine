using System;

namespace Sedulous.Slug;

/// Texture format for curve and band textures.
public enum TextureType : uint32
{
	/// 4-channel 16-bit floating-point (curve textures).
	Float16 = 0,
	/// 4-channel 32-bit floating-point (curve textures).
	Float32 = 1,
	/// 4-channel 16-bit unsigned integer (band textures).
	Uint16 = 2
}

/// Geometry type for glyph rendering.
public enum GeometryType : uint32
{
	/// Each glyph rendered as a quad (4 vertices, 2 triangles).
	Quads = 0,
	/// Each glyph rendered with a tight bounding polygon (3-6 vertices).
	Polygons = 1,
	/// Each glyph rendered as a single triangle (rectangle primitive extension).
	Rectangles = 2
}

/// Text alignment for multi-line text.
public enum AlignmentType : uint32
{
	Left = 0,
	Right = 1,
	Center = 2
}

/// Effect type applied to glyphs.
public enum EffectType : uint32
{
	None = 0,
	Shadow = 1,
	Outline = 2,
	OutlineShadow = 3
}

/// Vertex color component type.
public enum VertexType : uint32
{
	/// 4x 8-bit unsigned integer color (68-byte vertex).
	Vertex4U = 0,
	/// 4x 32-bit floating-point color (80-byte vertex).
	VertexRGBA = 1
}

/// Triangle index type.
public enum IndexType : uint32
{
	Index16 = 0,
	Index32 = 1
}

/// Layout flags controlling typesetting behavior.
//[Flags]
public enum LayoutFlags : uint32
{
	None                  = 0,
	FormatDirectives      = 1 << 0,
	ClippingPlanes        = 1 << 1,
	VerticalClip          = 1 << 2,
	KernDisable           = 1 << 3,
	MarkDisable           = 1 << 4,
	DecomposeDisable      = 1 << 5,
	SequenceDisable       = 1 << 6,
	AlternateDisable      = 1 << 7,
	LayerDisable          = 1 << 8,
	FullJustification     = 1 << 10,
	RightToLeft           = 1 << 11,
	Bidirectional         = 1 << 12,
	GridPositioning       = 1 << 14,
	ParagraphAttributes   = 1 << 15,
	TabSpacing            = 1 << 16,
	WrapDisable           = 1 << 18
}

/// Render flags controlling shader options.
//[Flags]
public enum RenderFlags : uint32
{
	None                         = 0,
	OpticalWeight                = 1 << 0,
	EvenOdd                      = 1 << 1
}

/// Constants
public static class SlugConstants
{
	public const int32 kLogBandTextureWidth = 12;
	public const int32 kBandTextureWidth = 1 << kLogBandTextureWidth; // 4096
	public const int32 kMaxBandCount = 32;
}
