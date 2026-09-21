using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Validation;

namespace Sedulous.RHI.Validation.Tests;

/// The encoder rules: recording state, pass lifetime, and what a draw needs before it runs.
class EncoderValidationTests
{
	[Test]
	public static void APassWithNoAttachmentsIsFlagged()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		fixture.Messages.Clear();

		// Nothing attached renders nowhere, which is a descriptor that was never filled in.
		encoder.BeginRenderPass(.());
		Test.Assert(fixture.Messages.HasWarning("no colour or depth attachment"));
	}

	[Test]
	public static void ANullAttachmentViewIsRefused()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		fixture.Messages.Clear();

		var desc = RenderPassDesc();
		desc.ColorAttachments.Add(.());
		Test.Assert(encoder.BeginRenderPass(desc) == null);
		Test.Assert(fixture.Messages.HasError("colour attachment 0 view is null"));
	}

	/// A draw needs a pipeline AND the pass level state the rasterizer reads. A viewport
	/// never set is whatever the last pass left, so the draw lands somewhere unrelated.
	[Test]
	public static void ADrawNeedsAPipelineAViewportAndAScissor()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);
		Test.Assert(pass != null);

		pass.Draw(3);
		Test.Assert(fixture.Messages.HasError("no pipeline is bound"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreatePipelineLayout(.() { Label = "EncoderValidationTests.ADrawNeedsAPipelineAViewportAndAScissor" }) case .Ok(var layout));
		fixture.Own(layout);
		Test.Assert(fixture.Device.CreateShaderModule(
			.() { Code = scope uint8[4](1, 2, 3, 4) }) case .Ok(var module));
			fixture.Own(module);
		var pipelineDesc = RenderPipelineDesc();
		pipelineDesc.Label = "EncoderValidationTests.ADrawNeedsAPipelineAViewportAndAScissor";
		pipelineDesc.Layout = layout;
		pipelineDesc.Vertex.Shader.Module = module;
		Test.Assert(fixture.Device.CreateRenderPipeline(pipelineDesc) case .Ok(let pipeline));
		fixture.Own(pipeline);
		fixture.Messages.Clear();

		pass.SetPipeline(pipeline);
		pass.Draw(3);
		Test.Assert(fixture.Messages.HasError("no viewport is set"));

		fixture.Messages.Clear();
		pass.SetViewport(0, 0, 64, 64);
		pass.Draw(3);
		Test.Assert(fixture.Messages.HasError("no scissor is set"));

		// With everything set, a draw is clean.
		fixture.Messages.Clear();
		pass.SetScissor(0, 0, 64, 64);
		pass.Draw(3);
		let described = scope String();
		fixture.Messages.Describe(described);
		Test.Assert(fixture.Messages.Count == 0, scope $"a complete draw reported: {described}");

		// And a draw of nothing is still worth a word.
		pass.Draw(0);
		Test.Assert(fixture.Messages.HasWarning("vertexCount is zero"));
	}

	[Test]
	public static void RecordingIntoAnEndedPassIsRefused()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);
		pass.End();
		fixture.Messages.Clear();

		pass.SetViewport(0, 0, 1, 1);
		Test.Assert(fixture.Messages.HasError("the render pass has ended"));

		fixture.Messages.Clear();
		pass.End();
		Test.Assert(fixture.Messages.HasError("already ended"));
	}

	[Test]
	public static void NullArgumentsToThePassAreRefused()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);

		pass.SetPipeline(null);
		Test.Assert(fixture.Messages.HasError("SetPipeline: pipeline is null"));

		fixture.Messages.Clear();
		pass.SetBindGroup(0, null);
		Test.Assert(fixture.Messages.HasError("SetBindGroup: group is null"));

		fixture.Messages.Clear();
		pass.SetVertexBuffer(0, null);
		Test.Assert(fixture.Messages.HasError("SetVertexBuffer: buffer is null"));

		fixture.Messages.Clear();
		pass.SetIndexBuffer(null, .UInt16);
		Test.Assert(fixture.Messages.HasError("SetIndexBuffer: buffer is null"));

		fixture.Messages.Clear();
		pass.WriteTimestamp(null, 0);
		Test.Assert(fixture.Messages.HasError("WriteTimestamp: querySet is null"));

		fixture.Messages.Clear();
		pass.BeginOcclusionQuery(null, 0);
		Test.Assert(fixture.Messages.HasError("BeginOcclusionQuery: querySet is null"));
	}

	/// Push constants are addressed in 32 bit words on every backend, so an unaligned
	/// offset or size writes somewhere other than intended.
	[Test]
	public static void PushConstantsMustBeWordAligned()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);
		let payload = scope uint8[16];

		pass.SetPushConstants(.Vertex, 1, 4, &payload[0]);
		Test.Assert(fixture.Messages.HasError("offset must be 4 byte aligned"));

		fixture.Messages.Clear();
		pass.SetPushConstants(.Vertex, 0, 3, &payload[0]);
		Test.Assert(fixture.Messages.HasError("size must be 4 byte aligned"));

		fixture.Messages.Clear();
		pass.SetPushConstants(.Vertex, 0, 4, null);
		Test.Assert(fixture.Messages.HasError("data is null but size is not zero"));

		fixture.Messages.Clear();
		pass.SetPushConstants(.Vertex, 0, 0, &payload[0]);
		Test.Assert(fixture.Messages.HasWarning("size is zero"));

		// Pushing before a pipeline is bound writes into whatever layout was last in force.
		Test.Assert(fixture.Messages.HasWarning("no pipeline is bound"));
	}

	/// Bundles inherit the pass's viewport and scissor, so executing one before they are
	/// set draws through whatever the previous pass left.
	[Test]
	public static void ExecutingBundlesWarnsAboutInheritedState()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);

		let bundles = scope IRenderBundle[1];
		pass.ExecuteBundles(bundles);
		Test.Assert(fixture.Messages.HasWarning("no viewport set"));
		Test.Assert(fixture.Messages.HasWarning("no scissor set"));
		Test.Assert(fixture.Messages.HasError("bundle 0 is null"));
	}

	[Test]
	public static void FinishingWithAnOpenPassIsRefused()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);

		Test.Assert(encoder.Finish() == null);
		Test.Assert(fixture.Messages.HasError("a render pass is still open"));

		fixture.Messages.Clear();
		pass.End();
		Test.Assert(encoder.Finish() != null, "closing the pass lets it finish");
		Test.Assert(fixture.Messages.Count == 0);

		// And finishing twice is an error.
		fixture.Messages.Clear();
		Test.Assert(encoder.Finish() == null);
		Test.Assert(fixture.Messages.HasError("already finished"));

		// As is recording after it.
		fixture.Messages.Clear();
		encoder.GenerateMipmaps(null);
		Test.Assert(fixture.Messages.HasError("already finished"));
	}

	[Test]
	public static void AnOpenComputePassAlsoBlocksFinishing()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		let compute = encoder.BeginComputePass();
		fixture.Messages.Clear();

		Test.Assert(encoder.Finish() == null);
		Test.Assert(fixture.Messages.HasError("a compute pass is still open"));

		fixture.Messages.Clear();
		compute.End();
		Test.Assert(encoder.Finish() != null);
	}

	/// Debug labels NEST, so an unmatched end pops a scope the caller did not open and
	/// every label after it lands in the wrong place in a capture.
	[Test]
	public static void DebugLabelsMustBalance()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		fixture.Messages.Clear();

		encoder.EndDebugLabel();
		Test.Assert(fixture.Messages.HasError("no matching begin"));

		fixture.Messages.Clear();
		encoder.BeginDebugLabel("outer");
		encoder.BeginDebugLabel("inner");
		encoder.EndDebugLabel();
		Test.Assert(fixture.Messages.Count == 0, "properly nested labels are fine");

		// One still open when the encoder finishes.
		encoder.Finish();
		Test.Assert(fixture.Messages.HasWarning("1 debug label(s) were not closed"));
	}

	[Test]
	public static void CopyAndBlitArgumentsAreChecked()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		let buffer = fixture.MakeBuffer();
		fixture.Messages.Clear();

		encoder.CopyBufferToBuffer(null, 0, buffer, 0, 16);
		Test.Assert(fixture.Messages.HasError("CopyBufferToBuffer: src is null"));

		fixture.Messages.Clear();
		encoder.CopyBufferToBuffer(buffer, 0, null, 0, 16);
		Test.Assert(fixture.Messages.HasError("CopyBufferToBuffer: dst is null"));

		fixture.Messages.Clear();
		encoder.CopyBufferToBuffer(buffer, 0, buffer, 0, 0);
		Test.Assert(fixture.Messages.HasWarning("size is zero"));

		fixture.Messages.Clear();
		encoder.Blit(null, null);
		Test.Assert(fixture.Messages.HasError("Blit: src or dst is null"));

		fixture.Messages.Clear();
		encoder.GenerateMipmaps(null);
		Test.Assert(fixture.Messages.HasError("GenerateMipmaps: texture is null"));

		fixture.Messages.Clear();
		encoder.ResolveTexture(null, null);
		Test.Assert(fixture.Messages.HasError("ResolveTexture: src or dst is null"));

		fixture.Messages.Clear();
		encoder.ResolveQuerySet(null, 0, 1, buffer, 0);
		Test.Assert(fixture.Messages.HasError("ResolveQuerySet: querySet is null"));
	}

	[Test]
	public static void ComputePassRulesMirrorTheRenderPassOnes()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		let compute = encoder.BeginComputePass();
		fixture.Messages.Clear();

		compute.SetPipeline(null);
		Test.Assert(fixture.Messages.HasError("SetPipeline: pipeline is null"));

		fixture.Messages.Clear();
		compute.Dispatch(1);
		Test.Assert(fixture.Messages.HasError("Dispatch: no pipeline is bound"));

		fixture.Messages.Clear();
		compute.DispatchIndirect(null, 0);
		Test.Assert(fixture.Messages.HasError("DispatchIndirect: no pipeline is bound"));

		// Bind something, then the zero dimension warning becomes reachable.
		Test.Assert(fixture.Device.CreatePipelineLayout(.() { Label = "EncoderValidationTests.ComputePassRulesMirrorTheRenderPassOnes" }) case .Ok(var layout));
		fixture.Own(layout);
		Test.Assert(fixture.Device.CreateShaderModule(
			.() { Code = scope uint8[4](1, 2, 3, 4) }) case .Ok(var module));
			fixture.Own(module);
		var desc = ComputePipelineDesc();
		desc.Label = "EncoderValidationTests.ComputePassRulesMirrorTheRenderPassOnes";
		desc.Layout = layout;
		desc.Compute.Module = module;
		Test.Assert(fixture.Device.CreateComputePipeline(desc) case .Ok(let pipeline));
		fixture.Own(pipeline);
		fixture.Messages.Clear();

		compute.SetPipeline(pipeline);
		compute.Dispatch(0, 1, 1);
		Test.Assert(fixture.Messages.HasWarning("workgroup dimension is zero"));

		fixture.Messages.Clear();
		compute.Dispatch(1, 1, 1);
		Test.Assert(fixture.Messages.Count == 0, "a real dispatch is clean");

		fixture.Messages.Clear();
		compute.End();
		compute.Dispatch(1);
		Test.Assert(fixture.Messages.HasError("the compute pass has ended"));
	}

	/// A bundle takes the same draw checks MINUS the pass level state, which it inherits.
	/// Requiring a viewport here would reject every correct bundle.
	[Test]
	public static void ABundleNeedsAPipelineButNotAViewport()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		let bundleEncoder = pool.CreateRenderBundleEncoder(.());
		Test.Assert(bundleEncoder != null);
		fixture.Messages.Clear();

		bundleEncoder.Draw(3);
		Test.Assert(fixture.Messages.HasError("no pipeline is bound"));

		Test.Assert(fixture.Device.CreatePipelineLayout(.() { Label = "EncoderValidationTests.ABundleNeedsAPipelineButNotAViewport" }) case .Ok(var layout));
		fixture.Own(layout);
		Test.Assert(fixture.Device.CreateShaderModule(
			.() { Code = scope uint8[4](1, 2, 3, 4) }) case .Ok(var module));
			fixture.Own(module);
		var desc = RenderPipelineDesc();
		desc.Label = "EncoderValidationTests.ABundleNeedsAPipelineButNotAViewport";
		desc.Layout = layout;
		desc.Vertex.Shader.Module = module;
		Test.Assert(fixture.Device.CreateRenderPipeline(desc) case .Ok(let pipeline));
		fixture.Own(pipeline);
		fixture.Messages.Clear();

		bundleEncoder.SetPipeline(pipeline);
		bundleEncoder.Draw(3);
		Test.Assert(fixture.Messages.Count == 0, "no viewport is needed: a bundle inherits it");

		bundleEncoder.Draw(0);
		Test.Assert(fixture.Messages.HasWarning("vertexCount is zero"));

		// Finishing twice, and recording after finishing.
		fixture.Messages.Clear();
		bundleEncoder.Finish();
		bundleEncoder.Finish();
		Test.Assert(fixture.Messages.HasError("Finish: already finished"));

		fixture.Messages.Clear();
		bundleEncoder.SetPipeline(pipeline);
		Test.Assert(fixture.Messages.HasError("already finished"));
	}

	/// Most of the encoder's surface is legal only while plainly RECORDING. A copy, a
	/// barrier or a second BeginRenderPass issued while a pass is open is invalid, and a
	/// backend's response runs from a validation error to undefined behaviour.
	///
	/// Gating everything on "not finished" alone catches only finishing with a pass open;
	/// this is the rest.
	[Test]
	public static void OperationsInsideAnOpenPassAreRefused()
	{
		let fixture = scope ValidationFixture();
		let pass = fixture.BeginPass(var pool, var encoder);
		Test.Assert(pass != null);
		let buffer = fixture.MakeBuffer();
		let texture = fixture.MakeTexture();
		fixture.Messages.Clear();

		// A pass cannot be nested inside a pass.
		Test.Assert(encoder.BeginRenderPass(.()) == null);
		Test.Assert(fixture.Messages.HasError("a render pass is open"),
			"a second BeginRenderPass while one is open");

		fixture.Messages.Clear();
		Test.Assert(encoder.BeginComputePass() == null);
		Test.Assert(fixture.Messages.HasError("a render pass is open"));

		// Nor can transfers or barriers be issued from inside one.
		fixture.Messages.Clear();
		encoder.CopyBufferToBuffer(buffer, 0, buffer, 0, 16);
		Test.Assert(fixture.Messages.HasError("a render pass is open"));

		fixture.Messages.Clear();
		encoder.Barrier(.());
		Test.Assert(fixture.Messages.HasError("a render pass is open"));

		fixture.Messages.Clear();
		encoder.Blit(texture, texture);
		Test.Assert(fixture.Messages.HasError("a render pass is open"));

		fixture.Messages.Clear();
		encoder.GenerateMipmaps(texture);
		Test.Assert(fixture.Messages.HasError("a render pass is open"));

		fixture.Messages.Clear();
		Test.Assert(encoder.CreateRenderBundleEncoder(.()) == null);
		Test.Assert(fixture.Messages.HasError("a render pass is open"));

		// Ending the pass puts the encoder back to recording, and the same calls are then
		// fine. Without that the state machine would be a one way trip.
		pass.End();
		fixture.Messages.Clear();
		encoder.CopyBufferToBuffer(buffer, 0, buffer, 0, 16);
		encoder.Barrier(.());
		let described = scope String();
		fixture.Messages.Describe(described);
		Test.Assert(fixture.Messages.Count == 0,
			scope $"after ending the pass these are legal again, but got: {described}");

		Test.Assert(encoder.BeginRenderPass(.()) != null || fixture.Messages.Count > 0,
			"and a pass can be begun again");
	}

	/// The same gate over a COMPUTE pass, and it names which kind is open.
	[Test]
	public static void OperationsInsideAnOpenComputePassAreRefused()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		fixture.Own(pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));
		let compute = encoder.BeginComputePass();
		let buffer = fixture.MakeBuffer();
		fixture.Messages.Clear();

		encoder.CopyBufferToBuffer(buffer, 0, buffer, 0, 16);
		Test.Assert(fixture.Messages.HasError("a compute pass is open"),
			"and it says which kind of pass is open");

		fixture.Messages.Clear();
		Test.Assert(encoder.BeginRenderPass(.()) == null);
		Test.Assert(fixture.Messages.HasError("a compute pass is open"));

		fixture.Messages.Clear();
		encoder.WriteTimestamp(null, 0);
		Test.Assert(fixture.Messages.HasError("a compute pass is open"),
			"the state is checked before the argument");

		compute.End();
		fixture.Messages.Clear();
		encoder.Barrier(.());
		Test.Assert(fixture.Messages.Count == 0, "ending it returns the encoder to recording");
	}
}
