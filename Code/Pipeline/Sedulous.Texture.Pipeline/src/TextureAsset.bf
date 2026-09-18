using Sedulous.Core;
using System;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Pipeline.Core;
using Sedulous.Texture;
using Sedulous.Texture.Compression;

namespace Sedulous.Texture.Pipeline;

/// An image file and how it should become a GPU texture.
///
/// The compression fields are AUTHORING data: the builder feeds them to the policy table to
/// pick the cooked format, and the runtime never sees them.
[Category("Textures")]
[DisplayName("Texture")]
[Serializable]
class TextureAsset : Asset
{
	[DisplayName("Color Space")]
	public ImageColorSpace ColorSpace = .Srgb;

	/// Embedded mode, which a model import produces: no file name, these two set, and the
	/// pixels in the source instance's own stream rather than an external file.
	[DisplayName("Embedded Width")]
	public uint32 EmbeddedWidth = 0;
	[DisplayName("Embedded Height")]
	public uint32 EmbeddedHeight = 0;

	[DisplayName("Shape")]
	public TextureShape Shape = .Texture2D;
	[DisplayName("Min Filter")]
	public TextureFilter MinFilter = .Linear;
	[DisplayName("Mag Filter")]
	public TextureFilter MagFilter = .Linear;
	[DisplayName("Wrap U")]
	public TextureWrap WrapU = .Repeat;
	[DisplayName("Wrap V")]
	public TextureWrap WrapV = .Repeat;
	[DisplayName("Wrap W")]
	public TextureWrap WrapW = .Repeat;
	[DisplayName("Generate Mipmaps")]
	public bool GenerateMipmaps = true;
	[DisplayName("Anisotropy")]
	public float Anisotropy = 1.0f;

	[DisplayName("Usage")]
	public SourceUsage Usage = .Color;
	[DisplayName("Compression")]
	public CompressionChoice Compression = .Default;

	/// DISPLAY ONLY provenance: where an embedded texture came from, being the model's own
	/// image reference. It never drives loading, which keys on the file name and the embedded
	/// size, and it must stay out of that decision.
	public String SourceHint = new .() ~ delete _;

	// ==================== profiles ====================
	// Each configures the WHOLE story coherently: sampler, shape, usage, and the colour space
	// the usage implies. The editor's profile buttons and the importer share these definitions
	// rather than each setting a subset of the fields.

	public void SetupForUI()
	{
		Usage = .Color;
		ColorSpace = .Srgb;
		Shape = .Texture2D;
		MinFilter = .Linear;
		MagFilter = .Linear;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	public void SetupForSprite()
	{
		SetupForUI();
		MinFilter = .Nearest;
		MagFilter = .Nearest;
	}

	public void SetupFor3D()
	{
		Usage = .Color;
		ColorSpace = .Srgb;
		Shape = .Texture2D;
		MinFilter = .MipmapLinear;
		MagFilter = .Linear;
		WrapU = .Repeat;
		WrapV = .Repeat;
		GenerateMipmaps = true;
		Anisotropy = 16.0f;
	}

	/// A tangent space normal map: the surface sampler with linear data semantics.
	public void SetupForNormalMap()
	{
		SetupFor3D();
		Usage = .Normal;
		ColorSpace = .Linear;
	}

	/// A data mask, being roughness, occlusion, height or coverage.
	public void SetupForDataMask()
	{
		SetupFor3D();
		Usage = .Mask;
		ColorSpace = .Linear;
	}

	public void SetupForEquirectangularSkybox()
	{
		Usage = .HDR;
		ColorSpace = .Linear;
		Shape = .Texture2D;
		MinFilter = .Linear;
		MagFilter = .Linear;
		WrapU = .ClampToEdge;
		WrapV = .ClampToEdge;
		WrapW = .ClampToEdge;
		GenerateMipmaps = false;
		Anisotropy = 1.0f;
	}

	public void SetupForCubemapSkybox()
	{
		SetupForEquirectangularSkybox();
		Shape = .Cubemap;
	}
}
