using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.Drawing;

/// A sprite sheet (texture atlas) containing multiple named sprites
public class SpriteSheet
{
	private IImageData mTexture;
	private Dictionary<String, Sprite> mSprites = new .() ~ DeleteDictionaryAndKeys!(_);

	/// The texture for this sprite sheet
	public IImageData Texture => mTexture;

	/// Width of the texture in pixels
	public uint32 Width => mTexture?.Width ?? 0;

	/// Height of the texture in pixels
	public uint32 Height => mTexture?.Height ?? 0;

	/// Number of sprites in this sheet
	public int SpriteCount => mSprites.Count;

	public this(IImageData texture)
	{
		mTexture = texture;
	}

	/// Add a named sprite region
	public void AddSprite(StringView name, RectangleF sourceRect)
	{
		mSprites[new String(name)] = .(mTexture, sourceRect);
	}

	/// Add a named sprite region with custom origin
	public void AddSprite(StringView name, RectangleF sourceRect, Vector2 origin)
	{
		mSprites[new String(name)] = .(mTexture, sourceRect, origin);
	}

	/// Add a grid of sprites with automatic naming (name_0, name_1, etc.)
	public void AddGrid(StringView baseName, int32 columns, int32 rows, int32 cellWidth, int32 cellHeight, int32 startX = 0, int32 startY = 0)
	{
		int32 index = 0;
		for (int32 row = 0; row < rows; row++)
		{
			for (int32 col = 0; col < columns; col++)
			{
				let x = startX + col * cellWidth;
				let y = startY + row * cellHeight;
				let name = scope String();
				name.AppendF("{}_{}", baseName, index);
				AddSprite(name, .(x, y, cellWidth, cellHeight));
				index++;
			}
		}
	}

	/// Get a sprite by name
	public Sprite? GetSprite(StringView name)
	{
		if (mSprites.TryGetValueAlt(name, let sprite))
			return sprite;
		return null;
	}

	/// Get a sprite by name, returns default sprite if not found
	public Sprite GetSpriteOrDefault(StringView name)
	{
		if (mSprites.TryGetValueAlt(name, let sprite))
			return sprite;
		return .(mTexture, .(0, 0, Width, Height));
	}

	/// Check if a sprite exists
	public bool HasSprite(StringView name)
	{
		return mSprites.ContainsKeyAlt(name);
	}

	/// Remove a sprite by name
	public bool RemoveSprite(StringView name)
	{
		if (mSprites.GetAndRemoveAlt(name) case .Ok(let pair))
		{
			delete pair.key;
			return true;
		}
		return false;
	}

	/// Clear all sprites
	public void Clear()
	{
		for (let key in mSprites.Keys)
			delete key;
		mSprites.Clear();
	}

	/// Get all sprite names
	public Dictionary<String, Sprite>.KeyEnumerator GetSpriteNames()
	{
		return mSprites.Keys;
	}
}
