using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Images;

namespace Sedulous.Drawing.Tests;

// Mock texture for testing
class MockTexture : IImageData
{
	private uint32 mWidth;
	private uint32 mHeight;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public PixelFormat Format => .RGBA8;
	public ImageColorSpace ColorSpace => .Srgb;
	public Span<uint8> PixelData => .();

	public this(uint32 width, uint32 height)
	{
		mWidth = width;
		mHeight = height;
	}
}

class SpriteTests
{
	[Test]
	public static void Constructor_SetsProperties()
	{
		let texture = scope MockTexture(256, 256);
		let sprite = Sprite(texture, .(10, 20, 32, 64));

		Test.Assert(sprite.Texture == texture);
		Test.Assert(sprite.SourceRect.X == 10);
		Test.Assert(sprite.SourceRect.Y == 20);
		Test.Assert(sprite.SourceRect.Width == 32);
		Test.Assert(sprite.SourceRect.Height == 64);
		Test.Assert(sprite.Origin == Vector2.Zero);
	}

	[Test]
	public static void Constructor_WithOrigin_SetsOrigin()
	{
		let texture = scope MockTexture(256, 256);
		let sprite = Sprite(texture, .(0, 0, 32, 32), .(0.5f, 0.5f));

		Test.Assert(sprite.Origin == Vector2(0.5f, 0.5f));
	}

	[Test]
	public static void Width_ReturnsSourceRectWidth()
	{
		let texture = scope MockTexture(256, 256);
		let sprite = Sprite(texture, .(0, 0, 48, 32));

		Test.Assert(sprite.Width == 48);
	}

	[Test]
	public static void Height_ReturnsSourceRectHeight()
	{
		let texture = scope MockTexture(256, 256);
		let sprite = Sprite(texture, .(0, 0, 48, 32));

		Test.Assert(sprite.Height == 32);
	}

	[Test]
	public static void TextureWidth_ReturnsTextureWidth()
	{
		let texture = scope MockTexture(512, 256);
		let sprite = Sprite(texture, .(0, 0, 32, 32));

		Test.Assert(sprite.TextureWidth == 512);
	}

	[Test]
	public static void TextureHeight_ReturnsTextureHeight()
	{
		let texture = scope MockTexture(512, 256);
		let sprite = Sprite(texture, .(0, 0, 32, 32));

		Test.Assert(sprite.TextureHeight == 256);
	}

	[Test]
	public static void FromTexture_CreatesFullTextureSprite()
	{
		let texture = scope MockTexture(128, 64);
		let sprite = Sprite.FromTexture(texture);

		Test.Assert(sprite.SourceRect.X == 0);
		Test.Assert(sprite.SourceRect.Y == 0);
		Test.Assert(sprite.SourceRect.Width == 128);
		Test.Assert(sprite.SourceRect.Height == 64);
	}

	[Test]
	public static void WithCenteredOrigin_SetsOriginToCenter()
	{
		let texture = scope MockTexture(256, 256);
		var sprite = Sprite(texture, .(0, 0, 32, 32));
		sprite = sprite.WithCenteredOrigin();

		Test.Assert(sprite.Origin == Vector2(0.5f, 0.5f));
	}

	[Test]
	public static void WithOrigin_SetsCustomOrigin()
	{
		let texture = scope MockTexture(256, 256);
		var sprite = Sprite(texture, .(0, 0, 32, 32));
		sprite = sprite.WithOrigin(.(0.25f, 0.75f));

		Test.Assert(sprite.Origin == Vector2(0.25f, 0.75f));
	}

	[Test]
	public static void GetOriginOffset_ReturnsCorrectPixelOffset()
	{
		let texture = scope MockTexture(256, 256);
		var sprite = Sprite(texture, .(0, 0, 100, 50));
		sprite.Origin = .(0.5f, 0.5f);

		let offset = sprite.GetOriginOffset();

		Test.Assert(offset.X == 50);
		Test.Assert(offset.Y == 25);
	}

	[Test]
	public static void GetOriginOffset_ZeroOrigin_ReturnsZero()
	{
		let texture = scope MockTexture(256, 256);
		let sprite = Sprite(texture, .(0, 0, 100, 50));

		let offset = sprite.GetOriginOffset();

		Test.Assert(offset == Vector2.Zero);
	}
}

class SpriteSheetTests
{
	[Test]
	public static void Constructor_SetsTexture()
	{
		let texture = scope MockTexture(512, 512);
		let sheet = scope SpriteSheet(texture);

		Test.Assert(sheet.Texture == texture);
		Test.Assert(sheet.Width == 512);
		Test.Assert(sheet.Height == 512);
	}

	[Test]
	public static void AddSprite_IncreasesSpriteCount()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);

		sheet.AddSprite("player", .(0, 0, 32, 32));

		Test.Assert(sheet.SpriteCount == 1);
	}

	[Test]
	public static void GetSprite_ReturnsAddedSprite()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);
		sheet.AddSprite("enemy", .(64, 64, 32, 48));

		let sprite = sheet.GetSprite("enemy");

		Test.Assert(sprite.HasValue);
		Test.Assert(sprite.Value.SourceRect.X == 64);
		Test.Assert(sprite.Value.SourceRect.Y == 64);
		Test.Assert(sprite.Value.SourceRect.Width == 32);
		Test.Assert(sprite.Value.SourceRect.Height == 48);
	}

	[Test]
	public static void GetSprite_NonExistent_ReturnsNull()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);

		let sprite = sheet.GetSprite("nonexistent");

		Test.Assert(!sprite.HasValue);
	}

	[Test]
	public static void GetSpriteOrDefault_NonExistent_ReturnsFullTexture()
	{
		let texture = scope MockTexture(128, 64);
		let sheet = scope SpriteSheet(texture);

		let sprite = sheet.GetSpriteOrDefault("nonexistent");

		Test.Assert(sprite.SourceRect.Width == 128);
		Test.Assert(sprite.SourceRect.Height == 64);
	}

	[Test]
	public static void HasSprite_ReturnsCorrectValue()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);
		sheet.AddSprite("item", .(0, 0, 16, 16));

		Test.Assert(sheet.HasSprite("item"));
		Test.Assert(!sheet.HasSprite("missing"));
	}

	[Test]
	public static void RemoveSprite_RemovesSprite()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);
		sheet.AddSprite("temp", .(0, 0, 16, 16));

		let removed = sheet.RemoveSprite("temp");

		Test.Assert(removed);
		Test.Assert(!sheet.HasSprite("temp"));
		Test.Assert(sheet.SpriteCount == 0);
	}

	[Test]
	public static void RemoveSprite_NonExistent_ReturnsFalse()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);

		let removed = sheet.RemoveSprite("nonexistent");

		Test.Assert(!removed);
	}

	[Test]
	public static void AddGrid_CreatesMultipleSprites()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);

		sheet.AddGrid("tile", 4, 2, 32, 32);

		Test.Assert(sheet.SpriteCount == 8);
		Test.Assert(sheet.HasSprite("tile_0"));
		Test.Assert(sheet.HasSprite("tile_7"));
	}

	[Test]
	public static void AddGrid_SpritesAtCorrectPositions()
	{
		let texture = scope MockTexture(128, 64);
		let sheet = scope SpriteSheet(texture);

		sheet.AddGrid("cell", 2, 2, 32, 32);

		let sprite0 = sheet.GetSprite("cell_0");
		let sprite1 = sheet.GetSprite("cell_1");
		let sprite2 = sheet.GetSprite("cell_2");
		let sprite3 = sheet.GetSprite("cell_3");

		Test.Assert(sprite0.Value.SourceRect.X == 0 && sprite0.Value.SourceRect.Y == 0);
		Test.Assert(sprite1.Value.SourceRect.X == 32 && sprite1.Value.SourceRect.Y == 0);
		Test.Assert(sprite2.Value.SourceRect.X == 0 && sprite2.Value.SourceRect.Y == 32);
		Test.Assert(sprite3.Value.SourceRect.X == 32 && sprite3.Value.SourceRect.Y == 32);
	}

	[Test]
	public static void Clear_RemovesAllSprites()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);
		sheet.AddSprite("a", .(0, 0, 16, 16));
		sheet.AddSprite("b", .(16, 0, 16, 16));

		sheet.Clear();

		Test.Assert(sheet.SpriteCount == 0);
	}

	[Test]
	public static void AddSprite_WithOrigin_SetsOrigin()
	{
		let texture = scope MockTexture(256, 256);
		let sheet = scope SpriteSheet(texture);

		sheet.AddSprite("centered", .(0, 0, 32, 32), .(0.5f, 0.5f));

		let sprite = sheet.GetSprite("centered");
		Test.Assert(sprite.Value.Origin == Vector2(0.5f, 0.5f));
	}
}
