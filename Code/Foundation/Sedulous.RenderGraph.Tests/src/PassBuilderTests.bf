namespace Sedulous.RenderGraph.Tests;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;

class PassBuilderTests
{
	[Test]
	public static void ReadTexture_AddsAccess()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.ReadTexture(handle);

		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Handle == handle);
		Test.Assert(pass.Accesses[0].Type == .ReadTexture);
		Test.Assert(pass.Accesses[0].Subresource.IsAll);
	}

	[Test]
	public static void ReadTexture_WithSubresource()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);
		let sub = RGSubresourceRange(0, 1, 2, 1);

		builder.ReadTexture(handle, sub);

		Test.Assert(pass.Accesses[0].Subresource.BaseArrayLayer == 2);
		Test.Assert(pass.Accesses[0].Subresource.ArrayLayerCount == 1);
	}

	[Test]
	public static void SetColorTarget_AddsAccessAndAttachment()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.SetColorTarget(0, handle, .Clear, .Store);

		// Should add a WriteColorTarget access
		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .WriteColorTarget);

		// Should add a color target attachment
		Test.Assert(pass.ColorTargets.Count == 1);
		Test.Assert(pass.ColorTargets[0].Handle == handle);
		Test.Assert(pass.ColorTargets[0].LoadOp == .Clear);
	}

	[Test]
	public static void SetDepthTarget_AddsAccessAndAttachment()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.SetDepthTarget(handle, .Clear, .Store, 1.0f);

		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .WriteDepthTarget);
		Test.Assert(pass.DepthTarget.HasValue);
		Test.Assert(pass.DepthTarget.Value.Handle == handle);
		Test.Assert(pass.DepthTarget.Value.DepthClearValue == 1.0f);
	}

	[Test]
	public static void ReadDepth_SetsReadOnly()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.ReadDepth(handle);

		Test.Assert(pass.DepthTarget.HasValue);
		Test.Assert(pass.DepthTarget.Value.ReadOnly);
		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .ReadDepthStencil);
	}

	[Test]
	public static void NeverCull_SetsFlag()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);

		builder.NeverCull();

		Test.Assert(pass.NeverCull);
		Test.Assert(pass.ShouldSurviveCulling);
	}

	[Test]
	public static void HasSideEffects_SetsFlag()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);

		builder.HasSideEffects();

		Test.Assert(pass.HasSideEffects);
		Test.Assert(pass.ShouldSurviveCulling);
	}

	[Test]
	public static void EnableIf_StoresCondition()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);

		builder.EnableIf(new () => true);

		Test.Assert(pass.Condition != null);
		Test.Assert(pass.Condition());
	}

	[Test]
	public static void WriteStorage_AddsAccess()
	{
		let pass = scope RenderGraphPass("Test", .Compute);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.WriteStorage(handle);

		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .WriteStorage);
	}

	[Test]
	public static void ReadWriteStorage_AddsAccess()
	{
		let pass = scope RenderGraphPass("Test", .Compute);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.ReadWriteStorage(handle);

		Test.Assert(pass.Accesses.Count == 1);
		Test.Assert(pass.Accesses[0].Type == .ReadWriteStorage);
		Test.Assert(pass.Accesses[0].IsRead);
		Test.Assert(pass.Accesses[0].IsWrite);
	}

	[Test]
	public static void CopySrc_CopyDst()
	{
		let pass = scope RenderGraphPass("Test", .Copy);
		var builder = PassBuilder(pass);
		let src = RGHandle(0, 1);
		let dst = RGHandle(1, 1);

		builder.CopySrc(src).CopyDst(dst);

		Test.Assert(pass.Accesses.Count == 2);
		Test.Assert(pass.Accesses[0].Type == .ReadCopySrc);
		Test.Assert(pass.Accesses[1].Type == .WriteCopyDst);
	}

	[Test]
	public static void FluentChaining()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let color = RGHandle(0, 1);
		let depth = RGHandle(1, 1);
		let shadow = RGHandle(2, 1);

		builder
			.ReadTexture(shadow)
			.SetColorTarget(0, color, .Clear, .Store)
			.SetDepthTarget(depth, .Load, .Store)
			.NeverCull();

		Test.Assert(pass.Accesses.Count == 3); // ReadTexture + WriteColor + WriteDepth
		Test.Assert(pass.ColorTargets.Count == 1);
		Test.Assert(pass.DepthTarget.HasValue);
		Test.Assert(pass.NeverCull);
	}

	[Test]
	public static void GetInputs_LoadOpCreatesRead()
	{
		let pass = scope RenderGraphPass("Test", .Render);
		var builder = PassBuilder(pass);
		let handle = RGHandle(0, 1);

		builder.SetColorTarget(0, handle, .Load, .Store);

		let inputs = scope System.Collections.List<RGResourceAccess>();
		pass.GetInputs(inputs);

		// LoadOp.Load means we read the previous contents
		bool hasRead = false;
		for (let input in inputs)
		{
			if (input.Handle == handle && input.IsRead)
				hasRead = true;
		}
		Test.Assert(hasRead);
	}
}
