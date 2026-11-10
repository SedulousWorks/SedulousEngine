using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Core;

namespace Sedulous.GUI.Pipeline;

/// The GUI's New Asset creators: a document and a style sheet, each a linked source file written
/// from starter text, as a shader's is.
static class GuiCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("GUI Document", "GUI", typeof(GuiDocumentAsset), new (context) =>
			CreateWithStarterFile(context, "GuiDocument", ".xml", GuiPipeline.cDocumentStarter, typeof(GuiDocumentAsset), scope GuiDocumentAsset())));
		registry.Register(new AssetCreator("GUI Style Sheet", "GUI", typeof(GuiStyleSheetAsset), new (context) =>
			CreateWithStarterFile(context, "GuiStyleSheet", ".css", GuiPipeline.cStyleSheetStarter, typeof(GuiStyleSheetAsset), scope GuiStyleSheetAsset())));
	}

	/// The starter text under the sources folder as the instance's name plus `suffix`, and the asset
	/// pointing at it. Refused without a sources folder.
	private static Instance CreateWithStarterFile<T>(AssetCreationContext context, StringView baseName, StringView suffix,
		StringView starter, Type type, T asset) where T : Asset, Sedulous.Core.Serialization.ISerializable
	{
		let target = context.Target;
		if ((target == null) || context.SourcesRoot.IsEmpty)
			return null;
		let name = target.UniqueInstanceName(context.NameOr(baseName), .. scope .());
		let fileName = scope $"{name}{suffix}";
		let path = PathJoin(context.SourcesRoot, fileName, .. scope .());
		if (WriteFile(path, Span<uint8>((uint8*)starter.Ptr, starter.Length)) case .Err)
			return null;
		let instance = target.CreateInstance(name, type.GetFullName(.. scope .()));
		if (instance == null)
			return null;
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err)
			return null;
		return instance;
	}
}
