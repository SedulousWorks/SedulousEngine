using System;
using Sedulous.Materials;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The transparent pass reads depth and never writes it.
class TransparentPassTests
{
	/// A blended material authored as data (blend mode set, depth left at ReadWrite) drew in
	/// the transparent pass with a depth writing pipeline, which WebGPU refuses there: the
	/// pass's bundle is depth read only.
	[Test]
	public static void APipelineForTheTransparentPassNeverWritesDepth()
	{
		Test.Assert(MeshRenderer.TransparentPassDepth(.ReadWrite) == .ReadOnly);
		Test.Assert(MeshRenderer.TransparentPassDepth(.WriteOnly) == .ReadOnly);
		Test.Assert(MeshRenderer.TransparentPassDepth(.ReadOnly) == .ReadOnly);
		Test.Assert(MeshRenderer.TransparentPassDepth(.Disabled) == .Disabled);
	}
}
