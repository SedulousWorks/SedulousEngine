using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Tests;

/// The flag enums, which rely on Beef's built in operators and HasFlag rather than
/// hand written ones.
class EnumFlagTests
{
	/// HasFlag is ALL BITS, which is what "may this be used as a vertex buffer" means. It
	/// is worth pinning: the any-bit reading would quietly answer true for a group.
	[Test]
	public static void HasFlagRequiresEveryBit()
	{
		let usage = BufferUsage.Vertex | BufferUsage.CopyDst;

		Test.Assert(usage.HasFlag(.Vertex));
		Test.Assert(usage.HasFlag(.CopyDst));
		Test.Assert(usage.HasFlag(.Vertex | .CopyDst), "both bits present");

		Test.Assert(!usage.HasFlag(.Index));
		Test.Assert(!usage.HasFlag(.Vertex | .Index), "one bit missing means false");

		// None is a subset of everything, which falls out of the all-bits reading.
		Test.Assert(usage.HasFlag(.None));
	}

	[Test]
	public static void FlagsCombineAndMask()
	{
		var usage = TextureUsage.Sampled;
		usage |= .RenderTarget;

		Test.Assert(usage.HasFlag(.Sampled));
		Test.Assert(usage.HasFlag(.RenderTarget));
		Test.Assert((usage & .Sampled) == .Sampled);
		Test.Assert((usage & .Storage) == .None, "masking off an absent bit leaves nothing");

		Test.Assert(TextureUsage.None == default);
	}

	/// The composite members are the exact union of their parts, which the shader stage
	/// visibility of a binding depends on.
	[Test]
	public static void CompositeShaderStagesAreTheirParts()
	{
		Test.Assert(ShaderStage.AllGraphics == (ShaderStage.Vertex | ShaderStage.Fragment));
		Test.Assert(ShaderStage.AllGraphics.HasFlag(.Vertex));
		Test.Assert(ShaderStage.AllGraphics.HasFlag(.Fragment));
		Test.Assert(!ShaderStage.AllGraphics.HasFlag(.Compute));

		// All is the eleven named stages, so every one of them is a subset of it.
		for (let stage in ShaderStage[](.Vertex, .Fragment, .Compute, .Mesh, .Task, .RayGen,
			.ClosestHit, .Miss, .AnyHit, .Intersection, .Callable))
			Test.Assert(ShaderStage.All.HasFlag(stage), scope $"All covers {stage}");

		Test.Assert((uint32)ShaderStage.All == 0x7FF, "eleven bits, not a full word");
	}

	[Test]
	public static void ColorWriteMaskAllIsEveryChannel()
	{
		Test.Assert(ColorWriteMask.All.HasFlag(.Red));
		Test.Assert(ColorWriteMask.All.HasFlag(.Green));
		Test.Assert(ColorWriteMask.All.HasFlag(.Blue));
		Test.Assert(ColorWriteMask.All.HasFlag(.Alpha));
		Test.Assert(ColorWriteMask.All == (ColorWriteMask.Red | .Green | .Blue | .Alpha));

		let colorOnly = ColorWriteMask.Red | .Green | .Blue;
		Test.Assert(!colorOnly.HasFlag(.Alpha), "writing colour without alpha");
	}

	/// ResourceState is a flag set so several READ uses can be combined into one barrier.
	[Test]
	public static void ResourceStatesCombineForReads()
	{
		let readable = ResourceState.ShaderRead | ResourceState.CopySrc;
		Test.Assert(readable.HasFlag(.ShaderRead));
		Test.Assert(readable.HasFlag(.CopySrc));
		Test.Assert(!readable.HasFlag(.ShaderWrite));

		Test.Assert(ResourceState.Undefined == default, "undefined is the zero state");
	}

	[Test]
	public static void FormatSupportSeparatesAttachmentFromBlendable()
	{
		let integerTarget = FormatSupport.Texture | FormatSupport.ColorAttachment;
		Test.Assert(integerTarget.HasFlag(.ColorAttachment));
		// An integer format can be an attachment without being blendable, which is exactly
		// why the two are separate bits.
		Test.Assert(!integerTarget.HasFlag(.BlendableColor));

		Test.Assert(FormatSupport.Unsupported == default);
	}

	[Test]
	public static void AccelStructAndGeometryFlagsCombine()
	{
		let flags = AccelStructBuildFlags.AllowUpdate | AccelStructBuildFlags.PreferFastBuild;
		Test.Assert(flags.HasFlag(.AllowUpdate));
		Test.Assert(!flags.HasFlag(.PreferFastTrace), "the two Prefer flags pull apart");

		let geometry = GeometryFlags.Opaque;
		Test.Assert(geometry.HasFlag(.Opaque));
		Test.Assert(!geometry.HasFlag(.NoDuplicateAnyHitInvocation));
	}
}
