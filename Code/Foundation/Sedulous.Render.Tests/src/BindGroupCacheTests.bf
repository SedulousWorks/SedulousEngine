using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The passes' bind group cache keeps a group only while every view it binds is the same view
/// of the same texture. TAA once checked only its jittered colour: on the player's first frame
/// the motion texture differed from every later frame's while the colour did not, so the group
/// built for one of its two history textures kept frame 0's motion vectors, and every other
/// frame's edges flickered. These replay that sequence on stand-ins; no device.
class BindGroupCacheTests
{
	private class StubView : ITextureView
	{
		public uint64 Id = TextureViewIds.Next();
		public TextureViewDesc Desc => .();
		public ITexture Texture => null;
		public uint64 UniqueId => Id;
	}

	private class StubGroup : IBindGroup
	{
		public IBindGroupLayout Layout => null;
		public void UpdateBindless(Span<BindlessUpdateEntry> entries) {}
	}

	/// TAA's inputs: jittered colour, motion, depth.
	private static BindGroupInputs<3> Inputs(ITextureView colour, uint64 colourGeneration,
		ITextureView motion, uint64 motionGeneration, ITextureView depth, uint64 depthGeneration)
	{
		var inputs = BindGroupInputs<3>();
		inputs.Set(0, colour, colourGeneration);
		inputs.Set(1, motion, motionGeneration);
		inputs.Set(2, depth, depthGeneration);
		return inputs;
	}

	[Test]
	public static void AGroupIsRebuiltWhenAnyInputChangedNotOnlyTheFirst()
	{
		let colour = scope StubView();
		let motionFirst = scope StubView();
		let motion = scope StubView();
		let depth = scope StubView();
		let historyA = scope StubView();
		let historyB = scope StubView();
		let group0 = scope StubGroup();
		let group1 = scope StubGroup();
		let group2 = scope StubGroup();
		let cache = scope BindGroupCache<3>();

		// Frame 0 reads history A: the colour, the first frame's motion, the depth.
		let frame0 = Inputs(colour, 9, motionFirst, 3, depth, 1);
		Test.Assert(cache.Find(historyA, frame0, var stale) == null);
		Test.Assert(stale == null);
		cache.Store(historyA, frame0, group0);
		// Frame 1 reads history B with this frame's motion texture: a group of its own.
		let steady = Inputs(colour, 9, motion, 2, depth, 1);
		Test.Assert(cache.Find(historyB, steady, out stale) == null);
		cache.Store(historyB, steady, group1);

		// Frame 2 reads history A again: the same colour and depth, but this frame's motion. The
		// frame 0 group binds the wrong motion vectors, so it is handed back, not returned.
		Test.Assert(cache.Find(historyA, steady, out stale) == null);
		Test.Assert(stale == group0);
		Test.Assert(cache.Count == 1);
		cache.Store(historyA, steady, group2);

		// Steady state: both history textures hit with this frame's inputs.
		Test.Assert(cache.Find(historyA, steady, out stale) == group2);
		Test.Assert(stale == null);
		Test.Assert(cache.Find(historyB, steady, out stale) == group1);

		// The same view back over another texture (a new generation) is a different input.
		Test.Assert(cache.Find(historyB, Inputs(colour, 9, motion, 2, depth, 2), out stale) == null);
		Test.Assert(stale == group1);
		// History A is untouched by B's miss.
		Test.Assert(cache.Find(historyA, steady, out stale) == group2);

		// An input missing: no group can be built.
		var missing = steady;
		missing.Set(1, null, 0);
		Test.Assert(!missing.Complete);
		Test.Assert(steady.Complete);

		// Teardown hands every held group to the owner: A's (B's was handed back as stale).
		int released = 0;
		cache.Release(scope [&] (group) => { released++; });
		Test.Assert(released == 1);
		Test.Assert(cache.Count == 0);
	}

	/// A view's address can be handed to the next view after it is destroyed; the unique id is
	/// what tells them apart. A key or an input with a new id is a miss, though its address is
	/// the same.
	[Test]
	public static void AViewWithANewIdIsANewViewThoughItsAddressIsTheSame()
	{
		let colour = scope StubView();
		let history = scope StubView();
		let group = scope StubGroup();
		let cache = scope BindGroupCache<3>();
		let inputs = Inputs(colour, 1, colour, 1, colour, 1);
		cache.Store(history, inputs, group);
		Test.Assert(cache.Find(history, inputs, var stale) == group);

		// The history key reborn at the same address.
		history.Id = TextureViewIds.Next();
		Test.Assert(cache.Find(history, inputs, out stale) == null);
		Test.Assert(stale == group);

		// An input reborn at the same address.
		cache.Store(history, inputs, group);
		colour.Id = TextureViewIds.Next();
		Test.Assert(cache.Find(history, Inputs(colour, 1, colour, 1, colour, 1), out stale) == null);
		Test.Assert(stale == group);
	}
}
