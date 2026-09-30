using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Core.IO;

namespace Sedulous.UI.Pipeline;

/// The UI domain's New Asset creators: a document and a theme, each a starter file in the
/// sources folder that the asset references.
static class UICreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("UI Document", "UI", typeof(UIDocumentAsset), new (context) =>
			CreateWithStarterFile(context, "UIDocument", ".sml", UIStarterContent.cDocument, typeof(UIDocumentAsset), scope UIDocumentAsset())));
		registry.Register(new AssetCreator("UI Theme", "UI", typeof(UIThemeAsset), new (context) =>
			CreateWithStarterFile(context, "UITheme", ".sss", UIStarterContent.cTheme, typeof(UIThemeAsset), scope UIThemeAsset())));
	}

	/// The starter text under the sources folder as the instance's name plus `suffix`, and the
	/// asset pointing at it. Refused without a sources folder.
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
