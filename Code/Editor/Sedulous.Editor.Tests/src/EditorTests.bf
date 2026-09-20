using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Tests;

/// The asset pipeline base the editor stands on: an asset round trips its source path and
/// settings, source files read through the VFS mount, and the builder registry routes by
/// asset type with the dependency hooks surfacing.
class EditorTests
{
	[Test]
	public static void AnAssetCarriesASourceFilePathAndSettingsThatRoundTrip()
	{
		let a = scope WidgetAsset();
		a.FileName.Set("art/widget.png");
		a.Quality = 7;
		let buffer = scope MemoryStream();
		{
			let w = scope BinarySerializer(buffer, .Write);
			ISerializable serializable = a;
			serializable.Serialize(w);
			Test.Assert(w.IsOk);
		}
		buffer.Seek(0, .Begin);
		let b = scope WidgetAsset();
		{
			let r = scope BinarySerializer(buffer, .Read);
			ISerializable serializable = b;
			serializable.Serialize(r);
			Test.Assert(r.IsOk);
		}
		Test.Assert(b.FileName.Value == "art/widget.png");
		Test.Assert(b.Quality == 7);
	}

	[Test]
	public static void SourceFilesReadThroughTheVfsMount()
	{
		let mount = scope NativeFileSystem(".");
		uint8[3] payload = .((uint8)'a', (uint8)'b', (uint8)'c');
		Test.Assert(mount.Save("editor_vfs_src.txt", payload) case .Ok);
		defer { mount.Delete("editor_vfs_src.txt").IgnoreError(); }

		let ctx = scope AssetBuildContext();
		ctx.Sources = mount;
		let bytes = scope List<uint8>();
		Test.Assert(AssetSource.ReadBytes(ctx, "editor_vfs_src.txt", bytes) case .Ok);
		Test.Assert(bytes.Count == 3);
		let text = scope String();
		Test.Assert(AssetSource.ReadText(ctx, "editor_vfs_src.txt", text) case .Ok);
		Test.Assert(text == "abc");

		// A missing file and a missing mount are clean failures.
		Test.Assert(AssetSource.ReadBytes(ctx, "editor_vfs_missing.txt", scope List<uint8>()) case .Err);
		let empty = scope AssetBuildContext();
		Test.Assert(AssetSource.ReadBytes(empty, "editor_vfs_src.txt", scope List<uint8>()) case .Err);
	}

	[Test]
	public static void TheBuilderRegistryRoutesByAssetTypeAndTheHooksSurface()
	{
		let registry = scope BuilderRegistry();
		Test.Assert(registry.Find(typeof(WidgetAsset)) == null);
		registry.Register(new WidgetBuilder());
		Test.Assert(registry.Count == 1);
		let builder = registry.Find(typeof(WidgetAsset));
		Test.Assert(builder != null);
		Test.Assert(builder.Version == 3);
		Test.Assert(registry.FindByTypeName(typeof(WidgetAsset).GetFullName(.. scope .())) === builder);
		Test.Assert(registry.Find(typeof(float)) == null);

		// ScanDependencies collects the declared extras and nothing else.
		let asset = scope WidgetAsset();
		let ctx = scope AssetBuildContext();
		let deps = scope AssetDependencies();
		builder.ScanDependencies(asset, ctx, deps);
		Test.Assert(deps.Files.Count == 1);
		Test.Assert(deps.Files[0].Value == "extra.bin");
		Test.Assert(deps.Reads.IsEmpty);
		Test.Assert(deps.References.IsEmpty);
	}
}
