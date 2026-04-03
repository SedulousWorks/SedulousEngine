using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A sprite representing a region of a texture atlas
public struct Sprite
{
	/// The texture containing this sprite
	public IImageData Texture;
	/// Source rectangle in texture coordinates (pixels)
	public RectangleF SourceRect;
	/// Origin/pivot point relative to sprite size (0-1, default is top-left)
	public Vector2 Origin;

	/// Width of the sprite in pixels
	public float Width => SourceRect.Width;

	/// Height of the sprite in pixels
	public float Height => SourceRect.Height;

	/// The texture width in pixels (for UV calculation)
	public uint32 TextureWidth => Texture?.Width ?? 0;

	/// The texture height in pixels (for UV calculation)
	public uint32 TextureHeight => Texture?.Height ?? 0;

	/// Create a sprite from a texture region
	public this(IImageData texture, RectangleF sourceRect)
	{
		Texture = texture;
		SourceRect = sourceRect;
		Origin = .(0, 0);
	}

	/// Create a sprite from a texture region with custom origin
	public this(IImageData texture, RectangleF sourceRect, Vector2 origin)
	{
		Texture = texture;
		SourceRect = sourceRect;
		Origin = origin;
	}

	/// Create a sprite from an entire texture
	public static Sprite FromTexture(IImageData texture)
	{
		return .(texture, .(0, 0, texture.Width, texture.Height));
	}

	/// Create a sprite with centered origin
	public Sprite WithCenteredOrigin() mut
	{
		Origin = .(0.5f, 0.5f);
		return this;
	}

	/// Create a sprite with custom origin
	public Sprite WithOrigin(Vector2 origin) mut
	{
		Origin = origin;
		return this;
	}

	/// Get the offset from origin in pixels
	public Vector2 GetOriginOffset()
	{
		return .(Origin.X * SourceRect.Width, Origin.Y * SourceRect.Height);
	}
}
