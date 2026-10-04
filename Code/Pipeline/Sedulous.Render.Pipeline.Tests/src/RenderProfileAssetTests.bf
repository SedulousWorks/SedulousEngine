using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;
using Sedulous.Render;
using Sedulous.Render.Pipeline;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Render.Pipeline.Tests;

/// The render profile assets: a profile asset round trips its values through its source
/// envelope, cooks to its record by a copy, loads through the runtime factory, and declares its
/// texture reference so the cook knows the profile needs it.
class RenderProfileAssetTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-5f;

	/// A scratch mount and a database holding both the authored and the cooked types.
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Serializers ~ delete _;
		public SerializableRegistry Serializables = new .() ~ delete _;
		public ContentDatabase Database ~ delete _;
		private String mRoot = new .() ~ delete _;

		public this(StringView root)
		{
			mRoot.Set(root);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);
			RenderPipeline.RegisterAll(Serializables);
			RenderProfileResources.RegisterAll(Serializables);
			Mount = new NativeFileSystem(mRoot);
			Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}
	}

	[Test]
	public static void AnEnvironmentProfileCooksAndLoadsWithItsValues()
	{
		let fixture = scope Fixture("scratch_render_pipeline_db");
		let database = fixture.Database;
		let skyId = Guid.Create();

		// The source asset round trips its values, through the block's own serializer.
		let asset = scope EnvironmentProfileAsset();
		asset.Values.AmbientIntensity = 0.08f;
		asset.Values.SkyMode = .Analytic;
		asset.Values.ShadowDistance = 60.0f;
		asset.Values.SkyTexture.Id = skyId;
		let source = database.RootGroup.CreateInstance("dusk", "Sedulous.Render.Pipeline.EnvironmentProfileAsset");
		Test.Assert(source.WriteObject(asset) case .Ok);
		let back = source.ReadObject() as EnvironmentProfileAsset;
		Test.Assert(back != null);
		defer delete back;
		Test.Assert(Near(back.Values.ShadowDistance, 60.0f));
		Test.Assert(back.Values.SkyTexture.Id == skyId);

		// The cook copies the values; the sky texture is a reference the product needs.
		let builder = scope EnvironmentProfileAssetBuilder();
		let dependencies = scope AssetDependencies();
		let context = scope AssetBuildContext();
		builder.ScanDependencies(asset, context, dependencies);
		Test.Assert((dependencies.References.Count == 1) && (dependencies.References[0] == skyId));
		asset.Values.SkyTexture.Id = Guid.Empty; // no texture product in this database
		let cooked = database.RootGroup.CreateInstance("dusk.cooked", "Sedulous.Engine.Render.EnvironmentProfileSource");
		context.Output = cooked;
		Test.Assert(builder.Build(asset, context) case .Ok);

		let factory = scope EnvironmentProfileFactory();
		let manager = scope ResourceManager(database, null);
		manager.AddFactory(factory);
		let profile = manager.Bind<EnvironmentProfile>(cooked.Id).Get;
		Test.Assert(profile != null);
		Test.Assert(Near(profile.Values.AmbientIntensity, 0.08f));
		Test.Assert(profile.Values.SkyMode == .Analytic);
		Test.Assert(Near(profile.Values.ShadowDistance, 60.0f));
	}

	[Test]
	public static void APostProcessProfileCooksAndLoadsWithItsValues()
	{
		let fixture = scope Fixture("scratch_render_pipeline_post_db");
		let database = fixture.Database;
		let asset = scope PostProcessProfileAsset();
		asset.Values.ExposureEV = 1.0f;
		asset.Values.AaMode = .FXAA;
		asset.Values.AoMode = .GTAO;
		let cooked = database.RootGroup.CreateInstance("look", "Sedulous.Engine.Render.PostProcessProfileSource");
		let builder = scope PostProcessProfileAssetBuilder();
		let context = scope AssetBuildContext();
		context.Output = cooked;
		Test.Assert(builder.Build(asset, context) case .Ok);

		let factory = scope PostProcessProfileFactory();
		let manager = scope ResourceManager(database, null);
		manager.AddFactory(factory);
		let profile = manager.Bind<PostProcessProfile>(cooked.Id).Get;
		Test.Assert(profile != null);
		Test.Assert(Near(profile.Values.ExposureEV, 1.0f));
		Test.Assert(profile.Values.AaMode == .FXAA);
		Test.Assert(profile.Values.AoMode == .GTAO);
	}
}
