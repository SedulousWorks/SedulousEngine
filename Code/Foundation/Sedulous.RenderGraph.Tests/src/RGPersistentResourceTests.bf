using System;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The persistent resource's slots.
class RGPersistentResourceTests
{
	/// A single slot resource answers the same texture for both this frame and the last: a
	/// single buffered history reads what it is about to overwrite, which is the caller's
	/// business rather than a reason to answer nothing.
	[Test]
	public static void ASingleSlotAnswersItselfForBoth()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		textureDesc.Label = "RGPersistentResourceTests.ASingleSlotAnswersItselfForBoth";
		let texture = device.CreateTexture(textureDesc).Value;
		defer { var doomed = texture; device.DestroyTexture(ref doomed); }

		let resource = scope PersistentResource(texture, null);
		Test.Assert(!resource.IsPingPong);
		Test.Assert(resource.CurrentTexture == texture);
		Test.Assert(resource.PreviousTexture == texture);

		resource.Swap();
		Test.Assert(resource.CurrentTexture == texture, "there is nothing to swap with");
	}

	[Test]
	public static void PingPongAlternatesBetweenItsSlots()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		textureDesc.Label = "RGPersistentResourceTests.PingPongAlternatesBetweenItsSlots";
		let first = device.CreateTexture(textureDesc).Value;
		var textureDesc2 = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		textureDesc2.Label = "RGPersistentResourceTests.PingPongAlternatesBetweenItsSlots";
		let second = device.CreateTexture(textureDesc2).Value;
		defer
		{
			var a = first; var b = second;
			device.DestroyTexture(ref a);
			device.DestroyTexture(ref b);
		}

		let resource = scope PersistentResource(first, second, null, null);
		Test.Assert(resource.IsPingPong);
		Test.Assert(resource.CurrentTexture == first);
		Test.Assert(resource.PreviousTexture == second, "the other slot is the history");

		resource.Swap();
		Test.Assert(resource.CurrentTexture == second);
		Test.Assert(resource.PreviousTexture == first);
	}

	/// The active slot can be RE-POINTED, which is what a resize does after the external
	/// texture is recreated.
	[Test]
	public static void TheActiveSlotCanBeRepointed()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		let device = backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 4, 4);
		textureDesc.Label = "RGPersistentResourceTests.TheActiveSlotCanBeRepointed";
		let original = device.CreateTexture(textureDesc).Value;
		var textureDesc2 = TextureDesc.RenderTarget(.RGBA8Unorm, 8, 8);
		textureDesc2.Label = "RGPersistentResourceTests.TheActiveSlotCanBeRepointed";
		let resized = device.CreateTexture(textureDesc2).Value;
		defer
		{
			var a = original; var b = resized;
			device.DestroyTexture(ref a);
			device.DestroyTexture(ref b);
		}

		let resource = scope PersistentResource(original, null);
		resource.UpdateTexture(resized, null);
		Test.Assert(resource.CurrentTexture == resized);
	}

	/// The cross frame tracking starts at the FIRST FRAME, which is what tells the solver to
	/// take the texture's own initial state rather than a state from a frame that never ran.
	[Test]
	public static void TheTrackingStartsAtTheFirstFrame()
	{
		let resource = scope PersistentResource(null, null);
		Test.Assert(resource.FirstFrame);
		Test.Assert(resource.LastKnownState == .Undefined);
		Test.Assert(resource.SubresourceStates.IsEmpty);
	}
}
