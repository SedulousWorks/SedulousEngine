using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Fonts.Resources;

/// Resource manager for `.font` resources.
///
/// On-disk format is metadata-only text (serialized through
/// `FontResource.OnSerialize`) plus an atlas pixel sidecar at `<locator>.bin`
/// - same convention used by `.texture`. There is no longer a path through
/// `FontParserFactory` / `FontAtlasBakerFactory` or stb_truetype: the
/// editor's importer pre-bakes the glyph atlas at edit time and the shipped
/// game only deserializes.
public class FontResourceManager : ResourceManager<FontResource>
{
	protected override Result<FontResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		if (SerializerProvider == null)
			return .Err(.NotSupported);

		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		let resource = new FontResource();
		if (resource.Serialize(reader) != .Ok)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		// Load the atlas pixel buffer from the binary sidecar
		// "<mainLocator>.bin" - same convention as TextureResource.
		if (ctx.Mount == null)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		let sidecarLocator = scope String()..AppendF("{}.bin", ctx.Locator);

		let sidecarResult = ctx.Mount.Open(sidecarLocator);
		if (sidecarResult case .Err)
		{
			delete resource;
			return .Err(.NotFound);
		}
		let binStream = sidecarResult.Value;
		defer delete binStream;

		let binBytes = scope List<uint8>();
		if (ReadAllBytes(binStream, binBytes) case .Err)
		{
			delete resource;
			return .Err(.ReadError);
		}

		// Validate the sidecar matches the recorded atlas dimensions, then
		// hand the pixel bytes to BakedFontAtlas. `SetPixels` takes ownership
		// of the array - we allocate one sized to the recorded atlas dims and
		// copy whatever the sidecar provided (truncated or padded with zeros
		// if the sidecar is misaligned, rather than crashing downstream).
		let opts = resource.Options;
		let expected = (int)opts.AtlasWidth * (int)opts.AtlasHeight;
		let pixels = new uint8[expected];
		let copyCount = Math.Min(expected, binBytes.Count);
		for (int i = 0; i < copyCount; i++)
			pixels[i] = binBytes[i];
		resource.BakedAtlas.SetPixels(opts.AtlasWidth, opts.AtlasHeight, pixels);

		resource.AddRef();
		return .Ok(resource);
	}

	public override void Unload(FontResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}
}
