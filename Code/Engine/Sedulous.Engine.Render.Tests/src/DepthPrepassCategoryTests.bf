using System;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Engine.Render;

namespace Sedulous.Engine.Render.Tests;

/// The camera depth prepass holds only what its forward draw will place on exactly the same
/// depth: an opaque material whose shader moves its vertices with a depth program of its own (a
/// surface shader's Vertex()) is drawn without it, as a fading mesh is; masked and blended keep
/// theirs.
class DepthPrepassCategoryTests
{
	[Test]
	public static void AMaterialWithItsOwnDepthProgramStaysOutOfTheDepthPrepass()
	{
		let plain = MaterialPresets.CreatePbr("plain");
		defer delete plain;
		Test.Assert(RenderExtract.CategoryForMaterial(plain) == RenderCategories.Opaque);
		let waves = MaterialPresets.CreatePbr("waves");
		defer delete waves;
		waves.DepthShaderName.Set("waves.depth");
		Test.Assert(RenderExtract.CategoryForMaterial(waves) == RenderCategories.Masked);
		waves.Pipeline.BlendMode = .AlphaBlend;
		Test.Assert(RenderExtract.CategoryForMaterial(waves) == RenderCategories.Transparent);
		Test.Assert(RenderExtract.CategoryForMaterial(null) == RenderCategories.Opaque);
	}
}
