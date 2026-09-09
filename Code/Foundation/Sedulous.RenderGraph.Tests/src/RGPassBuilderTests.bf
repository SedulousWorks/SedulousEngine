using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// What the builder records onto a pass.
class RGPassBuilderTests
{
	private static RGHandle Handle(uint32 index) => .(index, 0);

	/// A pass and a builder over it, which is what a setup callback is handed.
	private static RenderGraphPass Build(RGPassType type, delegate void(PassBuilder) setup)
	{
		let pass = new RenderGraphPass("Test", type);
		let builder = scope PassBuilder(pass);
		setup(builder);
		return pass;
	}

	[Test]
	public static void ReadingATextureAddsAnAccess()
	{
		let pass = Build(.Render, scope (builder) => { builder.ReadTexture(Handle(1)); });
		defer delete pass;

		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .ReadTexture);
		Test.Assert(pass.Accesses[0].Handle == Handle(1));
		Test.Assert(pass.Accesses[0].Subresource.IsAll, "the whole thing unless told otherwise");
	}

	[Test]
	public static void AReadCanNameASubresource()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.ReadTexture(Handle(1), .(0, 1, 2, 1));
			});
		defer delete pass;

		Test.Assert(pass.Accesses[0].Subresource == RGSubresourceRange(0, 1, 2, 1));
	}

	[Test]
	public static void AColorTargetIsBothAnAttachmentAndAnAccess()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetColorTarget(0, Handle(3), .Clear, .Store);
			});
		defer delete pass;

		Test.Assert(pass.ColorTargets.Count == 1);
		Test.Assert(pass.ColorTargets[0].Handle == Handle(3));
		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .WriteColorTarget);
	}

	/// Loading AND storing is a READ WRITE, which is what makes it a hazard with itself
	/// rather than a state that happens to already match.
	[Test]
	public static void LoadingAndStoringAColorTargetIsAReadWrite()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetColorTarget(0, Handle(3), .Load, .Store);
			});
		defer delete pass;

		Test.Assert(pass.Accesses[0].Type == .ReadWriteColorTarget);
	}

	/// A slot beyond the end grows the list, so a pass can attach to slot two without
	/// attaching to nought and one first.
	[Test]
	public static void ALaterSlotGrowsTheAttachmentList()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetColorTarget(2, Handle(5), .Clear, .Store);
			});
		defer delete pass;

		Test.Assert(pass.ColorTargets.Count == 3);
		Test.Assert(pass.ColorTargets[2].Handle == Handle(5));
		Test.Assert(!pass.ColorTargets[0].Handle.IsValid, "the empty slots stay empty");
	}

	[Test]
	public static void ADepthTargetIsBothAnAttachmentAndAnAccess()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetDepthTarget(Handle(4), .Clear, .Store, 0.0f);
			});
		defer delete pass;

		Test.Assert(pass.DepthTarget != null);
		Test.Assert(pass.DepthTarget.Value.Handle == Handle(4));
		Test.Assert(pass.DepthTarget.Value.DepthClearValue == 0.0f);
		Test.Assert(pass.Accesses[0].Type == .WriteDepthTarget);
	}

	[Test]
	public static void TheStencilOpsDefaultToLeavingItAlone()
	{
		let pass = Build(.Render, scope (builder) => { builder.SetDepthTarget(Handle(4)); });
		defer delete pass;

		Test.Assert(pass.DepthTarget.Value.StencilLoadOp == .DontCare);
		Test.Assert(pass.DepthTarget.Value.StencilStoreOp == .DontCare);
		Test.Assert(pass.DepthTarget.Value.StencilClearValue == 0);
	}

	[Test]
	public static void TheStencilOpsCanBeStated()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetDepthTarget(Handle(4), .Clear, .Store, 1.0f, .(), .Clear, .Store, 7);
			});
		defer delete pass;

		let depth = pass.DepthTarget.Value;
		Test.Assert(depth.StencilLoadOp == .Clear);
		Test.Assert(depth.StencilStoreOp == .Store);
		Test.Assert(depth.StencilClearValue == 7);
	}

	/// A depth attachment that DISCARDS is still a write.
	///
	/// The access is what keeps the transient referenced and therefore allocated; without it
	/// the resource counts down to nothing, is never allocated, and the whole pass is dropped
	/// at the null attachment guard. A scratch stencil used only inside the pass is exactly
	/// this case.
	[Test]
	public static void ADiscardedDepthTargetIsStillAWrite()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetDepthTarget(Handle(4), .Clear, .DontCare);
			});
		defer delete pass;

		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .WriteDepthTarget);
	}

	[Test]
	public static void ReadingDepthAttachesItReadOnly()
	{
		let pass = Build(.Render, scope (builder) => { builder.ReadDepth(Handle(4)); });
		defer delete pass;

		Test.Assert(pass.DepthTarget.Value.ReadOnly);
		Test.Assert(pass.DepthTarget.Value.DepthLoadOp == .Load);
		Test.Assert(pass.Accesses[0].Type == .ReadDepthStencil);
	}

	/// Sampling depth is a read with NO attachment, which is how a shadow map is read by a
	/// pass that is drawing somewhere else entirely.
	[Test]
	public static void SamplingDepthAttachesNothing()
	{
		let pass = Build(.Render, scope (builder) => { builder.SampleDepth(Handle(7)); });
		defer delete pass;

		Test.Assert(pass.DepthTarget == null);
		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .SampleDepthStencil);
		Test.Assert(pass.Accesses[0].IsRead && !pass.Accesses[0].IsWrite);
	}

	[Test]
	public static void SamplingDepthCanNameACascade()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SampleDepth(Handle(7), .(0, 1, 2, 1));
			});
		defer delete pass;

		Test.Assert(pass.Accesses[0].Subresource == RGSubresourceRange(0, 1, 2, 1));
	}

	[Test]
	public static void TheCullingFlagsAreRecorded()
	{
		let neverCull = Build(.Render, scope (builder) => { builder.NeverCull(); });
		defer delete neverCull;
		Test.Assert(neverCull.NeverCull && neverCull.ShouldSurviveCulling);

		let sideEffects = Build(.Render, scope (builder) => { builder.HasSideEffects(); });
		defer delete sideEffects;
		Test.Assert(sideEffects.HasSideEffects && sideEffects.ShouldSurviveCulling);

		let plain = Build(.Render, scope (builder) => {});
		defer delete plain;
		Test.Assert(!plain.ShouldSurviveCulling);
	}

	/// The condition is checked at EXECUTION time, so a pass can skip a frame without being
	/// rebuilt out of the graph.
	[Test]
	public static void AConditionIsStoredAndOwned()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.EnableIf(new () => false);
			});
		defer delete pass;

		Test.Assert(pass.Condition != null);
		Test.Assert(!pass.Condition());
	}

	[Test]
	public static void StorageAndCopyAccessesAreRecorded()
	{
		let pass = Build(.Compute, scope (builder) =>
			{
				builder.WriteStorage(Handle(1));
				builder.ReadWriteStorage(Handle(2));
				builder.CopySrc(Handle(3));
				builder.CopyDst(Handle(4));
			});
		defer delete pass;

		Test.Assert(pass.Accesses.Count == 4);
		Test.Assert(pass.Accesses[0].Type == .WriteStorage);
		Test.Assert(pass.Accesses[1].Type == .ReadWriteStorage);
		Test.Assert(pass.Accesses[2].Type == .ReadCopySrc);
		Test.Assert(pass.Accesses[3].Type == .WriteCopyDst);
	}

	/// A resolve target rewrites the multisampled slot's store to a DISCARD, since its
	/// samples are not wanted once resolved, and registers the resolve as a write so the
	/// graph allocates it.
	[Test]
	public static void AResolveTargetDiscardsTheMultisampledSamples()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetColorTarget(0, Handle(1), .Clear, .Store);
				builder.SetResolveTarget(0, Handle(2));
			});
		defer delete pass;

		Test.Assert(pass.ColorTargets[0].StoreOp == .DontCare);
		Test.Assert(pass.ColorTargets[0].ResolveHandle == Handle(2));
		Test.Assert(pass.Accesses.Count == 2);
		Test.Assert(pass.Accesses[1].Handle == Handle(2));
		Test.Assert(pass.Accesses[1].Type == .WriteColorTarget);
	}

	/// Every method answers the builder, so a setup reads as one statement.
	[Test]
	public static void TheBuilderChains()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder
					.ReadTexture(Handle(1))
					.SetColorTarget(0, Handle(2), .Clear, .Store)
					.SetDepthTarget(Handle(3))
					.NeverCull()
					.DependsOn(PassHandle(5));
			});
		defer delete pass;

		Test.Assert(pass.Accesses.Count == 3);
		Test.Assert(pass.ColorTargets.Count == 1);
		Test.Assert(pass.DepthTarget != null);
		Test.Assert(pass.NeverCull);
		Test.Assert(pass.Dependencies[0] == PassHandle(5));
	}

	/// An attachment that LOADS is a read whether the pass declared one or not, which is what
	/// the compiler reasons about.
	[Test]
	public static void LoadingAnAttachmentFoldsIntoTheInputs()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetColorTarget(0, Handle(1), .Load, .Store);
			});
		defer delete pass;

		let inputs = scope List<RGResourceAccess>();
		pass.GetInputs(inputs);

		// Once as the declared read write, once folded in from the attachment.
		var readsOfOne = 0;
		for (let input in inputs)
		{
			if (input.Handle == Handle(1))
				readsOfOne++;
		}
		Test.Assert(readsOfOne >= 1);

		let outputs = scope List<RGResourceAccess>();
		pass.GetOutputs(outputs);
		var writesOfOne = 0;
		for (let output in outputs)
		{
			if (output.Handle == Handle(1))
				writesOfOne++;
		}
		Test.Assert(writesOfOne >= 1, "and storing it is a write");
	}

	/// A CLEARED attachment is not a read: nothing that was in it survives.
	[Test]
	public static void AClearedAttachmentIsNotARead()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetColorTarget(0, Handle(1), .Clear, .Store);
			});
		defer delete pass;

		let inputs = scope List<RGResourceAccess>();
		pass.GetInputs(inputs);
		Test.Assert(inputs.IsEmpty);
	}

	/// A read only depth attachment is an input even though it does not load, because it is
	/// bound and tested against.
	[Test]
	public static void AReadOnlyDepthAttachmentIsAnInput()
	{
		let pass = Build(.Render, scope (builder) =>
			{
				builder.SetReadOnlyDepthTarget(Handle(4));
			});
		defer delete pass;

		let inputs = scope List<RGResourceAccess>();
		pass.GetInputs(inputs);
		Test.Assert(!inputs.IsEmpty);

		let outputs = scope List<RGResourceAccess>();
		pass.GetOutputs(outputs);
		Test.Assert(outputs.IsEmpty, "and it writes nothing");
	}
}
