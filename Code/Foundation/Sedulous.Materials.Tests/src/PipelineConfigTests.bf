using System;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials.Tests;

/// The pipeline key: what it distinguishes, and what the predefined layouts describe.
class PipelineConfigTests
{
	[Test]
	public static void TheSameStateHashesAndComparesTheSame()
	{
		let a = PipelineConfig.ForOpaqueMesh("forward");
		let b = PipelineConfig.ForOpaqueMesh("forward");
		Test.Assert(a == b);
		Test.Assert(a.HashCode == b.HashCode);
	}

	[Test]
	public static void DifferentRenderStateIsADifferentPipeline()
	{
		let opaque = PipelineConfig.ForOpaqueMesh("forward");
		let transparent = PipelineConfig.ForTransparentMesh("forward");
		Test.Assert(!(opaque == transparent), "blend and depth both differ");
		Test.Assert(opaque.HashCode != transparent.HashCode);
	}

	/// The shader name is part of the key: the same state on a different shader is a
	/// different pipeline.
	[Test]
	public static void TheShaderNameIsPartOfTheKey()
	{
		let forward = PipelineConfig.ForOpaqueMesh("forward");
		let unlit = PipelineConfig.ForOpaqueMesh("unlit");
		Test.Assert(!(forward == unlit));
		Test.Assert(forward.HashCode != unlit.HashCode);
	}

	/// And so are the shader FLAGS, which pick the permutation. This is the axis that is
	/// orthogonal to the fixed function state: same state, different code.
	[Test]
	public static void TheShaderFlagsAreOrthogonalToTheState()
	{
		let plain = PipelineConfig.ForOpaqueMesh("forward");
		let skinned = PipelineConfig.ForOpaqueMesh("forward", .Skinned);
		Test.Assert(!(plain == skinned));
		Test.Assert(plain.HashCode != skinned.HashCode);

		// The state itself is identical: only the permutation differs.
		Test.Assert(plain.BlendMode == skinned.BlendMode);
		Test.Assert(plain.DepthMode == skinned.DepthMode);
	}

	/// Every field that changes the pipeline has to change the key, or a cache serves the
	/// wrong one.
	[Test]
	public static void EveryStateFieldMovesTheKey()
	{
		let baseline = PipelineConfig.ForOpaqueMesh("forward");

		void Differs(PipelineConfig changed, StringView what)
		{
			Test.Assert(!(baseline == changed), scope $"{what} compared equal");
			Test.Assert(baseline.HashCode != changed.HashCode, scope $"{what} hashed the same");
		}

		var changed = baseline;
		changed.VertexLayout = .PositionOnly;
		Differs(changed, "vertex layout");

		changed = baseline;
		changed.Instanced = true;
		Differs(changed, "instancing");

		changed = baseline;
		changed.Topology = .LineList;
		Differs(changed, "topology");

		changed = baseline;
		changed.CullMode = .Front;
		Differs(changed, "cull mode");

		changed = baseline;
		changed.FrontFace = .CW;
		Differs(changed, "front face");

		changed = baseline;
		changed.FillMode = .Wireframe;
		Differs(changed, "fill mode");

		changed = baseline;
		changed.ColorWriteMask = .Red;
		Differs(changed, "colour write mask");

		changed = baseline;
		changed.DepthCompare = .Greater;
		Differs(changed, "depth compare");

		changed = baseline;
		changed.DepthFormat = .Depth16Unorm;
		Differs(changed, "depth format");

		changed = baseline;
		changed.DepthBias = 4;
		Differs(changed, "depth bias");

		changed = baseline;
		changed.SampleCount = 4;
		Differs(changed, "sample count");

		changed = baseline;
		changed.DepthOnly = true;
		Differs(changed, "depth only");

		changed = baseline;
		changed.WriteAuxTargets = false;
		Differs(changed, "aux target writes");

		changed = baseline;
		changed.CustomVertexStride = 24;
		Differs(changed, "custom stride");

		changed = baseline;
		changed.CustomAttributeCount = 3;
		Differs(changed, "custom attribute count");

		changed = baseline;
		changed.BlendMode = .Additive;
		Differs(changed, "blend mode");

		changed = baseline;
		changed.DepthMode = .Disabled;
		Differs(changed, "depth mode");
	}

	/// The slope scale is compared but NOT hashed, so two configs differing only there
	/// collide in the cache and are then told apart by the comparison. That is the correct
	/// shape for a hash, and this pins it so nobody reads the omission as a bug.
	[Test]
	public static void TheSlopeScaleIsComparedThoughItDoesNotHash()
	{
		var biased = PipelineConfig.ForOpaqueMesh("forward");
		biased.DepthBiasSlopeScale = 2.0f;
		let plain = PipelineConfig.ForOpaqueMesh("forward");

		Test.Assert(!(plain == biased), "the comparison separates them");
		Test.Assert(plain.HashCode == biased.HashCode, "a collision the comparison resolves");
	}

	/// Only the ACTIVE colour formats matter: the slots past the target count are never
	/// read, and two configs differing only there describe the same pipeline.
	[Test]
	public static void OnlyTheActiveColourFormatsCount()
	{
		var a = PipelineConfig.ForOpaqueMesh("forward");
		var b = PipelineConfig.ForOpaqueMesh("forward");
		b.ColorFormats[3] = .RGBA16Float;

		Test.Assert(a == b, "slot three is past the one active target");
		Test.Assert(a.HashCode == b.HashCode);

		// Once it IS active, it separates them.
		a.ColorTargetCount = 4;
		b.ColorTargetCount = 4;
		Test.Assert(!(a == b));
	}

	[Test]
	public static void ThePresetsDescribeWhatTheyAreFor()
	{
		let skybox = PipelineConfig.ForSkybox("sky");
		Test.Assert(skybox.VertexLayout == .PositionOnly);
		Test.Assert(skybox.DepthCompare == .LessEqual, "drawn AT the far plane");
		Test.Assert(skybox.CullMode == .Front, "seen from the inside");
		Test.Assert(skybox.DepthMode == .ReadOnly);

		let sprites = PipelineConfig.ForSprites("sprite");
		Test.Assert(sprites.VertexLayout == .PositionUVColor);
		Test.Assert(sprites.BlendMode == .AlphaBlend);
		Test.Assert(sprites.CullMode == .None, "a quad has no meaningful facing");

		let fullscreen = PipelineConfig.ForFullscreen("post");
		Test.Assert(fullscreen.VertexLayout == .None, "the vertex stage makes its own triangle");
		Test.Assert(fullscreen.DepthMode == .Disabled);
		Test.Assert(fullscreen.CullMode == .None);
	}
}
