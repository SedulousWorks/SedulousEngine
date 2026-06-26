namespace Sedulous.Editor;

using System;
using System.IO;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Fonts;
using Sedulous.Fonts.Baked;
using Sedulous.Fonts.Importer;
using Sedulous.Fonts.Resources;
using Sedulous.Fonts.TTF;
using Sedulous.VFS;
using Sedulous.Core.Logging.Abstractions;

/// Imports TrueType / OpenType font files into `.font` resources.
///
/// At edit time the importer rasterizes the source TTF/OTF into a baked
/// glyph atlas + glyph/kerning tables via `FontImporter.Bake`. The result is
/// written as a text-metadata `.font` (the `FontResource` serializer) plus
/// an atlas pixel `<name>.font.bin` sidecar - same convention as
/// `.texture`. The shipped game loads via `FontResourceManager` and never
/// re-rasterizes, so the runtime needs no stb_truetype dependency.
class FontAssetImporter : IAssetImporter
{
	private ILogger mLogger;

	public this(ILogger logger = null)
	{
		mLogger = logger;
	}

	public StringView DisplayName => "Font";

	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".ttf"));
		outExtensions.Add(new .(".otf"));
	}

	public Result<ImportPreview> CreatePreview(StringView sourcePath)
	{
		// Read the whole source file so we can parse-to-verify and tell the
		// user the font's family name without touching disk a second time
		// during Import.
		let bytes = scope List<uint8>();
		if (ReadAllBytes(sourcePath, bytes) case .Err)
		{
			mLogger?.LogError("Font import preview: read failed for {}", sourcePath);
			return .Err;
		}

		// Probe via TrueTypeFont directly. Importer-only path; doesn't
		// require FontParserFactory / FontAtlasBakerFactory to be set up.
		// TrueTypeFont.Initialize takes ownership of the buffer regardless
		// of return value (it stores the pointer before any error path), so
		// the `scope` destructor frees both the font and the buffer.
		let bytesCopy = new uint8[bytes.Count];
		bytes.CopyTo(bytesCopy);
		let probe = scope TrueTypeFont();
		if (probe.Initialize(bytesCopy, 16f) case .Err)
		{
			mLogger?.LogError("Font import preview: parse failed for {}", sourcePath);
			return .Err;
		}

		let fileName = scope String();
		Path.GetFileNameWithoutExtension(sourcePath, fileName);
		// Prefer the embedded family name over the source filename; sanitize
		// for filesystem-friendly output.
		let suggestedName = scope String();
		if (probe.FamilyName != null && !probe.FamilyName.IsEmpty)
		{
			for (let c in probe.FamilyName.RawChars)
			{
				if (c == ' ' || c == '_' || c == '-' || c.IsLetterOrDigit)
					suggestedName.Append(c);
			}
		}
		if (suggestedName.IsEmpty)
			suggestedName.Set(fileName);

		let preview = new ImportPreview();
		preview.SourcePath = new String(sourcePath);

		let item = new ImportPreviewItem();
		item.Name = new String(suggestedName);
		item.OriginalName = new String(suggestedName);
		item.Extension = new String(".font");
		// Keep TypeLabel short - the dialog's type column is 90px wide. The
		// font family name appears in the editable name field below, so
		// there's no need to duplicate it here.
		item.TypeLabel = new String("Font");
		item.InternalIndex = 0;
		preview.Items.Add(item);

		return .Ok(preview);
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
	{
		if (preview.Items.Count == 0 || !preview.Items[0].Selected)
			return .Ok;

		ctx.Logger?.LogInformation("Font import: {} -> {}{}", preview.SourcePath, ctx.UriPrefix, preview.Items[0].Name);

		// Re-read the source bytes so we can hand them to the importer.
		let bytes = scope List<uint8>();
		if (ReadAllBytes(preview.SourcePath, bytes) case .Err)
		{
			ctx.Logger?.LogError("Font import: source read failed for {}", preview.SourcePath);
			return .Err;
		}

		// Bake the TTF/OTF into glyph + atlas data using the default
		// options. TODO: surface a FontImportOptions block in ImportDialog
		// for pixel height / codepoint range / atlas size.
		let options = FontLoadOptions.Default;
		let bakeResult = FontImporter.Bake(.(bytes.Ptr, bytes.Count), options);
		if (bakeResult case .Err(let err))
		{
			ctx.Logger?.LogError("Font import: bake failed for {} ({})", preview.SourcePath, err);
			return .Err;
		}
		let bakedData = bakeResult.Value;
		defer delete bakedData;

		// Transfer ownership of the baked font + atlas to the resource. The
		// BakedFontData destructor would otherwise free them; TakeOwnership
		// nulls its fields so we get a clean handoff.
		let (bakedFont, bakedAtlas) = bakedData.TakeOwnership();
		let fontRes = new FontResource(bakedFont, bakedAtlas, options);
		defer delete fontRes;
		fontRes.Name.Set(preview.Items[0].Name);

		// Build filename, sidecar name, locator, sidecar locator, and URI.
		let fileName = scope String();
		fileName.AppendF("{}.font", preview.Items[0].Name);

		let sidecarName = scope String();
		sidecarName.AppendF("{}.bin", fileName);

		let locator = scope String();
		locator.Append(ctx.BaseLocator);
		locator.Append(fileName);

		let sidecarLocator = scope String();
		sidecarLocator.Append(ctx.BaseLocator);
		sidecarLocator.Append(sidecarName);

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);

		// Save text metadata through the mount.
		{
			let memStream = scope MemoryStream();
			if (fontRes.WriteToStream(memStream, ctx.Serializer) case .Err)
			{
				ctx.Logger?.LogError("Font import: metadata serialization failed for {}", locator);
				return .Err;
			}
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err(let saveErr))
			{
				ctx.Logger?.LogError("Font import: mount save failed for {}: {}", locator, saveErr);
				return .Err;
			}
		}

		// Save atlas pixel sidecar through the mount.
		{
			let pixelStream = scope MemoryStream();
			if (fontRes.WriteAtlasPixelsToStream(pixelStream) case .Err)
			{
				ctx.Logger?.LogError("Font import: pixel sidecar serialization failed for {}", sidecarLocator);
				return .Err;
			}
			pixelStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pixelStream) case .Err(let sidecarErr))
			{
				ctx.Logger?.LogError("Font import: pixel sidecar save failed for {}: {}", sidecarLocator, sidecarErr);
				return .Err;
			}
		}

		// Register the GUID -> URI mapping. Caller is responsible for
		// persisting the index after the import.
		ctx.Index.Register(fontRes.Id, uri);

		ctx.Logger?.LogInformation("Font import: wrote {}", uri);
		return .Ok;
	}

	private static Result<void> ReadAllBytes(StringView path, List<uint8> outBytes)
	{
		FileStream fs = scope FileStream();
		if (fs.Open(path, .Read, .Read) case .Err)
			return .Err;

		let length = (int32)fs.Length;
		outBytes.Count = length;
		if (fs.TryRead(.(outBytes.Ptr, length)) case .Err)
			return .Err;
		return .Ok;
	}
}
