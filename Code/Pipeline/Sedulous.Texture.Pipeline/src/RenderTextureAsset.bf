using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Pipeline;

/// What a render texture holds: Ldr is what a tonemapped view writes and what UI shows; Hdr
/// keeps the linear values, for a material that wants them.
[Scriptable(.AllPublic), TypeDomain(ScriptDomains.Pipeline)]
enum RenderTextureFormat : uint32
{
	case Ldr = 0;
	case Hdr = 1;
}

/// An authored render texture: a size and a format, and no source file. A camera's target
/// draws into it; a sprite, a material or a UI image shows it.
[Category("Textures")]
[DisplayName("Render Texture")]
[Serializable]
class RenderTextureAsset : Asset
{
	[Range(1.0f, 4096.0f, 1.0f)]
	public uint32 Width = 256;
	[Range(1.0f, 4096.0f, 1.0f)]
	public uint32 Height = 256;
	[Description("Ldr for what a camera shows on screen or in UI; Hdr keeps linear values for a material")]
	public RenderTextureFormat Format = .Ldr;

	/// Fills the cooked record this asset makes.
	public void Cook(RenderTextureResource cooked)
	{
		cooked.Width = Width;
		cooked.Height = Height;
		cooked.Format = (Format == .Hdr) ? .RGBA16Float : .RGBA8UnormSrgb;
	}
}

/// Cooks a render texture's record, refusing a size past the limit at the cook rather than
/// at the first frame.
class RenderTextureAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(RenderTextureAsset);
	public Type ProductType => typeof(RenderTextureResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let cooked = scope RenderTextureResource();
		((RenderTextureAsset)asset).Cook(cooked);
		if (!cooked.IsValid)
		{
			Sedulous.Core.Logging.GlobalLog(.Error, "Cook: render texture {}x{}: each side must be 1 to {}",
				cooked.Width, cooked.Height, RenderTextureResource.cMaxSize);
			return .Err(.InvalidArgument);
		}
		return context.Output.WriteObject(cooked);
	}
}

/// The texture domain's New Asset creators: a texture from a file is an import, but a render
/// texture has no file, so it is made here.
static class TextureCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		// A 256 x 256 LDR render texture: a minimap's or a monitor's size.
		registry.Register(new AssetCreator("Render Texture", "Textures", typeof(RenderTextureAsset), new (context) =>
			AssetCreator.CreateWritten(context.Target, context.NameOr("RenderTexture"), typeof(RenderTextureAsset), scope RenderTextureAsset())));
	}
}
