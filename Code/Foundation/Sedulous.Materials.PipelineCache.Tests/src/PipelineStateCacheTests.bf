using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials.PipelineCache.Tests;

/// Building, caching, and rebuilding a pipeline when its shader is reloaded.
class PipelineStateCacheTests
{
	[Test]
	public static void APipelineIsBuiltOnceAndServedThereafter()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");
		let config = PipelineConfig.ForOpaqueMesh("forward");

		let first = fixture.Cache.GetPipeline(config, fixture.Layout);
		Test.Assert(first != null);
		Test.Assert(fixture.Cache.Size == 1);

		let second = fixture.Cache.GetPipeline(config, fixture.Layout);
		Test.Assert(second == first, "a cache hit, not a rebuild");
		Test.Assert(fixture.Cache.Size == 1);
		Test.Assert(fixture.Cache.RetiredCount == 0);
	}

	/// The reload path: invalidating bumps the shader's version, and the next request
	/// notices on a single integer compare.
	[Test]
	public static void AReloadedShaderRebuildsAndRetiresTheStalePipeline()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");
		let config = PipelineConfig.ForOpaqueMesh("forward");

		let original = fixture.Cache.GetPipeline(config, fixture.Layout);
		Test.Assert(original != null);

		fixture.Shaders.InvalidateShader("forward");

		let rebuilt = fixture.Cache.GetPipeline(config, fixture.Layout);
		Test.Assert(rebuilt != null);
		Test.Assert(rebuilt != original, "built against the new shader");
		Test.Assert(fixture.Cache.Size == 1, "the same key, replaced in place");
		// Retired rather than freed: frames in flight are still drawing with it.
		Test.Assert(fixture.Cache.RetiredCount == 1);

		fixture.Cache.ReleaseRetired();
		Test.Assert(fixture.Cache.RetiredCount == 0);
	}

	/// And once rebuilt it settles: a second request at the same version is a hit again,
	/// so polling does not rebuild every frame after a reload.
	[Test]
	public static void TheRebuiltPipelineIsThenCachedAgain()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");
		let config = PipelineConfig.ForOpaqueMesh("forward");

		fixture.Cache.GetPipeline(config, fixture.Layout);
		fixture.Shaders.InvalidateShader("forward");

		let rebuilt = fixture.Cache.GetPipeline(config, fixture.Layout);
		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) == rebuilt);
		Test.Assert(fixture.Cache.RetiredCount == 1, "one retirement, not two");
	}

	/// Invalidating a DIFFERENT shader leaves this one alone: the version is per shader,
	/// which is what keeps one reload from rebuilding the whole cache.
	[Test]
	public static void InvalidatingAnotherShaderDoesNotRebuildThisOne()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");
		fixture.CookBothStages("unlit");

		let config = PipelineConfig.ForOpaqueMesh("forward");
		let original = fixture.Cache.GetPipeline(config, fixture.Layout);

		fixture.Shaders.InvalidateShader("unlit");
		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) == original);
		Test.Assert(fixture.Cache.RetiredCount == 0);
	}

	/// Distinct render state is a distinct entry, which is the reason the config hashes by
	/// content.
	[Test]
	public static void DifferentRenderStateIsADifferentEntry()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");

		let opaque = fixture.Cache.GetPipeline(PipelineConfig.ForOpaqueMesh("forward"),
			fixture.Layout);
		let transparent = fixture.Cache.GetPipeline(PipelineConfig.ForTransparentMesh("forward"),
			fixture.Layout);

		Test.Assert(opaque != null);
		Test.Assert(transparent != null);
		Test.Assert(opaque != transparent);
		Test.Assert(fixture.Cache.Size == 2);
	}

	/// The target format is part of the key too: the same material drawn into an HDR target
	/// and an LDR one needs two pipelines.
	[Test]
	public static void TheColourOverrideIsPartOfTheKey()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");
		let config = PipelineConfig.ForOpaqueMesh("forward");

		let plain = fixture.Cache.GetPipeline(config, fixture.Layout);
		let hdr = fixture.Cache.GetPipeline(config, fixture.Layout, .RGBA16Float);

		Test.Assert(plain != hdr);
		Test.Assert(fixture.Cache.Size == 2);
	}

	/// A depth only config needs no fragment stage at all, so it builds against a shader
	/// that has only a vertex variant cooked.
	[Test]
	public static void ADepthOnlyConfigBuildsWithoutAFragmentShader()
	{
		let fixture = scope PipelineCacheFixture();
		// Deliberately no fragment variant.
		fixture.Cook("shadow", .Vertex);

		var config = PipelineConfig.ForOpaqueMesh("shadow");
		config.DepthOnly = true;
		config.VertexLayout = .PositionOnly;

		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) != null);
	}

	/// A shader with no vertex variant cannot produce a pipeline, and the failure is null
	/// rather than a half built one.
	[Test]
	public static void AMissingVertexVariantFailsTheBuild()
	{
		let fixture = scope PipelineCacheFixture();
		let config = PipelineConfig.ForOpaqueMesh("absent");

		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) == null);
		// The entry is still recorded, so a later request after the shader arrives finds
		// it and rebuilds rather than retrying from nothing every draw.
		Test.Assert(fixture.Cache.Size == 1);
	}

	/// And a config that DOES want a fragment stage fails when only the vertex one exists,
	/// rather than quietly building a pipeline that writes nothing.
	[Test]
	public static void AMissingFragmentVariantFailsAColourBuild()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.Cook("half", .Vertex);

		Test.Assert(fixture.Cache.GetPipeline(PipelineConfig.ForOpaqueMesh("half"),
			fixture.Layout) == null);
	}

	/// A failed entry rebuilds once its shader turns up, without needing the cache cleared.
	[Test]
	public static void AFailedEntryRecoversWhenTheShaderArrives()
	{
		let fixture = scope PipelineCacheFixture();
		let config = PipelineConfig.ForOpaqueMesh("late");

		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) == null);

		fixture.CookBothStages("late");
		// The version poll is what notices: cooking alone does not bump it, so the
		// invalidation is what a reload would do.
		fixture.Shaders.InvalidateShader("late");

		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) != null);
		Test.Assert(fixture.Cache.Size == 1);
		Test.Assert(fixture.Cache.RetiredCount == 0, "there was no pipeline to retire");
	}

	/// Clearing destroys everything live and retires nothing, which is what shutdown wants:
	/// there are no frames left to be in flight.
	[Test]
	public static void ClearingEmptiesTheCache()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("forward");

		fixture.Cache.GetPipeline(PipelineConfig.ForOpaqueMesh("forward"), fixture.Layout);
		fixture.Cache.GetPipeline(PipelineConfig.ForSkybox("forward"), fixture.Layout);
		Test.Assert(fixture.Cache.Size == 2);

		fixture.Cache.Clear();
		Test.Assert(fixture.Cache.Size == 0);
		Test.Assert(fixture.Cache.RetiredCount == 0);
	}

	/// Every vertex layout and every state preset has to reach a built pipeline, because a
	/// combination that silently fails is a draw that renders nothing.
	[Test]
	public static void EveryPresetBuilds()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("s");

		for (let config in scope PipelineConfig[](
			PipelineConfig.ForOpaqueMesh("s"),
			PipelineConfig.ForTransparentMesh("s"),
			PipelineConfig.ForSkybox("s"),
			PipelineConfig.ForSprites("s"),
			PipelineConfig.ForFullscreen("s")))
		{
			Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) != null);
		}
		Test.Assert(fixture.Cache.Size == 5);
	}

	/// A skinned draw binds three vertex buffers, and an instanced one two, so the buffer
	/// assembly has to hold for each shape.
	[Test]
	public static void TheVertexStreamShapesAllBuild()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("s");

		var skinned = PipelineConfig.ForOpaqueMesh("s");
		skinned.VertexLayout = .SkinnedMesh;
		skinned.Instanced = true;
		Test.Assert(fixture.Cache.GetPipeline(skinned, fixture.Layout) != null,
			"mesh, skinning and instance streams");

		var instanced = PipelineConfig.ForOpaqueMesh("s");
		instanced.Instanced = true;
		Test.Assert(fixture.Cache.GetPipeline(instanced, fixture.Layout) != null);

		// No vertex input at all, so no buffers to assemble.
		Test.Assert(fixture.Cache.GetPipeline(PipelineConfig.ForFullscreen("s"), fixture.Layout)
			!= null);
	}

	/// A fragment stage writing NO colour is a real configuration: a masked shadow pass
	/// discards on alpha and writes only depth. Zero targets must be honoured exactly
	/// rather than falling back to one.
	[Test]
	public static void AZeroTargetFragmentStageIsHonoured()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("masked_shadow");

		var config = PipelineConfig.ForOpaqueMesh("masked_shadow");
		config.ColorTargetCount = 0;

		Test.Assert(fixture.Cache.GetPipeline(config, fixture.Layout) != null);
	}

	/// Multiple render targets: the G buffer shape builds, and the aux write flag is part
	/// of the key so a transparent draw over it gets its own pipeline.
	[Test]
	public static void TheMultiTargetShapeBuildsAndTheAuxFlagKeysIt()
	{
		let fixture = scope PipelineCacheFixture();
		fixture.CookBothStages("gbuffer");

		var opaque = PipelineConfig.ForOpaqueMesh("gbuffer");
		opaque.ColorTargetCount = 3;
		opaque.ColorFormats[1] = .RGBA16Float;
		opaque.ColorFormats[2] = .RG16Float;

		var blended = opaque;
		blended.BlendMode = .AlphaBlend;
		blended.WriteAuxTargets = false;

		Test.Assert(fixture.Cache.GetPipeline(opaque, fixture.Layout) != null);
		Test.Assert(fixture.Cache.GetPipeline(blended, fixture.Layout) != null);
		Test.Assert(fixture.Cache.Size == 2, "the aux flag separates them");
	}
}
