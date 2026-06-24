namespace Sedulous.Editor;

using Sedulous.Editor.Core;
using System;

/// Texture setup preset applied during import.
enum TexturePreset
{
	/// 3D scene texture: mipmaps, linear filter, repeat wrap, aniso 16.
	Texture3D,
	/// Sprite: nearest filter, clamp, no mipmaps.
	Sprite,
	/// UI element: linear filter, clamp, no mipmaps.
	UI,
	/// Equirectangular skybox: linear filter, clamp, no mipmaps, Texture2D shape.
	EquirectangularSky,
	/// Cubemap skybox: linear filter, clamp, no mipmaps, Cubemap shape.
	/// Only valid when 6 face images are detected.
	CubemapSky
}

/// Import options for texture assets.
class TextureImportOptions : ImportOptions
{
	/// Preset controlling filter, wrap, mipmap, and shape settings.
	public TexturePreset Preset = .Texture3D;

	/// Whether cubemap face files were detected from the source path.
	/// When true, CubemapSky preset is available.
	public bool CubemapDetected = false;

	/// Detected face paths (valid only when CubemapDetected is true).
	/// Owned by this options object.
	public String[6] CubemapFacePaths = .(new .(), new .(), new .(), new .(), new .(), new .()) ~ { for (let p in _) delete p; };
}
