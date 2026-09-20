using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Input.Pipeline;
using Sedulous.Physics.Pipeline;
using Sedulous.Navigation.Pipeline;
using Sedulous.Audio.Pipeline;
using Sedulous.UI.Pipeline;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Tools.Editor;

/// The New Asset creators for the types whose editor module ships none of its own: each
/// authors a default instance under the picked group, or the root.
static class EditorCreators
{
	public static void RegisterAll(EditorContext context)
	{
		context.RegisterCreator(new AssetCreator("Input Map", "", new (ctx, group) =>
			{
				let asset = scope InputMapAsset();
				asset.SeedDefaultContent();
				return CreateDefault(ctx, group, "InputMap", typeof(InputMapAsset), asset);
			}));
		context.RegisterCreator(new AssetCreator("Physical Material", "Physics", new (ctx, group) =>
			CreateDefault(ctx, group, "PhysicalMaterial", typeof(PhysicalMaterialAsset), scope PhysicalMaterialAsset())));
		context.RegisterCreator(new AssetCreator("Navigation Zone", "", new (ctx, group) =>
			{
				let target = TargetGroup(ctx, group);
				if (target == null)
					return null;
				let instance = target.CreateInstance(target.UniqueInstanceName("NavZone", .. scope .()), typeof(NavigationZoneAsset).GetFullName(.. scope .()));
				if (instance == null)
					return null;
				let asset = scope NavigationZoneAsset(); // empty; Bake fills the navmesh sidecar later
				if (NavigationZoneStorage.Write(instance, asset) case .Err)
					return null;
				return instance;
			}));
		context.RegisterCreator(new AssetCreator("Audio Bus Layout", "Audio", new (ctx, group) =>
			CreateDefault(ctx, group, "BusLayout", typeof(AudioBusLayoutAsset), scope AudioBusLayoutAsset())));
		context.RegisterCreator(new AssetCreator("Sound Cue", "Audio", new (ctx, group) =>
			CreateDefault(ctx, group, "SoundCue", typeof(SoundCueAsset), scope SoundCueAsset())));
		context.RegisterCreator(new AssetCreator("UI Document", "UI", new (ctx, group) =>
			CreateWithStarterFile(ctx, group, "UIDocument", ".sml", UIStarterContent.cDocument, typeof(UIDocumentAsset), scope UIDocumentAsset())));
		context.RegisterCreator(new AssetCreator("UI Theme", "UI", new (ctx, group) =>
			CreateWithStarterFile(ctx, group, "UITheme", ".sss", UIStarterContent.cTheme, typeof(UIThemeAsset), scope UIThemeAsset())));
		context.RegisterCreator(new AssetCreator("Collision Shape", "Physics", new (ctx, group) =>
			CreateDefault(ctx, group, "CollisionShape", typeof(CollisionShapeAsset), scope CollisionShapeAsset())));
		context.RegisterCreator(new AssetCreator("Heightfield", "Terrain", new (ctx, group) =>
			CreateDefault(ctx, group, "Heightfield", typeof(HeightfieldAsset), scope HeightfieldAsset())));
		context.RegisterCreator(new AssetCreator("Terrain", "Terrain", new (ctx, group) =>
			CreateDefault(ctx, group, "Terrain", typeof(TerrainAsset), scope TerrainAsset())));
		context.RegisterCreator(new AssetCreator("Splatmap", "Terrain", new (ctx, group) =>
			CreateDefault(ctx, group, "Splatmap", typeof(SplatmapAsset), scope SplatmapAsset()))); // 1024 square by default
	}

	private static Group TargetGroup(EditorContext ctx, Group group)
	{
		if (ctx.Project == null)
			return null;
		return (group != null) ? group : ctx.Project.SourceDb.RootGroup;
	}

	/// A uniquely named instance of `type` under the target, holding `asset` as written.
	private static Instance CreateDefault(EditorContext ctx, Group group, StringView baseName, Type type, ISerializable asset)
	{
		let target = TargetGroup(ctx, group);
		if (target == null)
			return null;
		let instance = target.CreateInstance(target.UniqueInstanceName(baseName, .. scope .()), type.GetFullName(.. scope .()));
		if (instance == null)
			return null;
		if (instance.WriteObject(asset) case .Err)
			return null;
		return instance;
	}

	/// A file backed asset: the starter text lands in the sources tree under the instance's
	/// name plus `suffix`, and the asset references it.
	private static Instance CreateWithStarterFile<T>(EditorContext ctx, Group group, StringView baseName, StringView suffix,
		StringView starter, Type type, T asset) where T : Sedulous.Pipeline.Core.Asset, ISerializable
	{
		let target = TargetGroup(ctx, group);
		if (target == null)
			return null;
		let name = target.UniqueInstanceName(baseName, .. scope .());
		let fileName = scope $"{name}{suffix}";
		let path = PathJoin(ctx.Project.SourcesRoot(.. scope .()), fileName, .. scope .());
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
