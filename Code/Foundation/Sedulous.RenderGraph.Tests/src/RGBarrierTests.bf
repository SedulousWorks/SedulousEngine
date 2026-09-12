using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;

namespace Sedulous.RenderGraph.Tests;

/// The barrier solver, driven directly: what it emits, and what it does not.
class RGBarrierTests
{
	/// A device, some textures, and the resources over them, torn down together.
	private class Fixture
	{
		public IBackend Backend ~ delete _;
		public IDevice Device;
		public RecordingEncoder Encoder = new .() ~ delete _;
		public BarrierSolver Solver = new .() ~ delete _;

		private List<ITexture> mTextures = new .() ~ delete _;
		private List<RenderGraphResource> mResources = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			Backend = NullRhi.CreateBackend();
			Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		}

		public ~this()
		{
			for (var texture in ref mTextures)
				Device.DestroyTexture(ref texture);
		}

		public ITexture MakeTexture(uint32 mips = 1, uint32 layers = 1,
			ResourceState initialState = .Undefined)
		{
			var desc = TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64);
			desc.Label = "RGBarrierTests.Fixture.this";
			desc.MipLevelCount = mips;
			desc.ArrayLayerCount = layers;

			let texture = Device.CreateTexture(desc).Value;
			texture.InitialState = initialState;
			mTextures.Add(texture);
			return texture;
		}

		/// A resource over a texture. The FIXTURE owns it.
		public RenderGraphResource AddResource(StringView name, ITexture texture,
			RGResourceLifetime lifetime = .Imported)
		{
			let resource = new RenderGraphResource(name, .Texture, lifetime);
			resource.Texture = texture;
			mResources.Add(resource);
			return resource;
		}

		public Span<RenderGraphResource> Resources => .(mResources.Ptr, mResources.Count);
	}

	private static RGResourceAccess Access(uint32 index, RGAccessType type,
		RGSubresourceRange subresource = .()) => .(RGHandle(index, 0), type, subresource);

	/// A pass carrying one access. THE CALLER OWNS it.
	private static RenderGraphPass PassWith(StringView name, RGResourceAccess access)
	{
		let pass = new RenderGraphPass(name, .Render);
		pass.Accesses.Add(access);
		return pass;
	}

	/// Two handles onto the SAME texture agree about its state, so the second one transitions
	/// from what the first left rather than from nothing.
	[Test]
	public static void TwoHandlesOntoOneTextureShareItsState()
	{
		let fixture = scope Fixture();
		let shadow = fixture.MakeTexture();
		fixture.AddResource("ShadowWrite", shadow);
		fixture.AddResource("ShadowRead", shadow);

		fixture.Solver.Reset(fixture.Resources);

		let writer = PassWith("ShadowPass", Access(0, .WriteDepthTarget));
		defer delete writer;
		fixture.Solver.EmitBarriers(writer, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let reader = PassWith("ForwardPass", Access(1, .ReadTexture));
		defer delete reader;
		fixture.Solver.EmitBarriers(reader, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .DepthStencilWrite);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .ShaderRead);
		Test.Assert(fixture.Encoder.TextureBarriers[0].Texture == shadow);
	}

	[Test]
	public static void AReadAfterAWriteTransitions()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Color", fixture.MakeTexture());
		fixture.Solver.Reset(fixture.Resources);

		let writer = PassWith("Write", Access(0, .WriteColorTarget));
		defer delete writer;
		fixture.Solver.EmitBarriers(writer, fixture.Resources, fixture.Encoder);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .RenderTarget);
		fixture.Encoder.Clear();

		let reader = PassWith("Read", Access(0, .ReadTexture));
		defer delete reader;
		fixture.Solver.EmitBarriers(reader, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .RenderTarget);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .ShaderRead);
	}

	[Test]
	public static void AComputeWriteThenARenderReadTransitions()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Storage", fixture.MakeTexture());
		fixture.Solver.Reset(fixture.Resources);

		let compute = PassWith("Compute", Access(0, .WriteStorage));
		defer delete compute;
		fixture.Solver.EmitBarriers(compute, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let render = PassWith("Render", Access(0, .ReadTexture));
		defer delete render;
		fixture.Solver.EmitBarriers(render, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .ShaderWrite);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .ShaderRead);
	}

	/// NOTHING is emitted when the resource is already where it needs to be: a barrier is a
	/// pipeline stall, and one that changes nothing is pure cost.
	[Test]
	public static void NothingIsEmittedWhenTheStateAlreadyMatches()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Color", fixture.MakeTexture());
		fixture.Solver.Reset(fixture.Resources);

		let first = PassWith("First", Access(0, .WriteColorTarget));
		defer delete first;
		fixture.Solver.EmitBarriers(first, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let second = PassWith("Second", Access(0, .WriteColorTarget));
		defer delete second;
		fixture.Solver.EmitBarriers(second, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.IsEmpty);
		Test.Assert(fixture.Encoder.GroupCount == 0, "and no empty group either");
	}

	/// A READ WRITE access barriers even when the state already matches: the hazard is
	/// between the two uses of it, not between two states.
	[Test]
	public static void AReadWriteAccessBarriersAgainstItself()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Storage", fixture.MakeTexture());
		fixture.Solver.Reset(fixture.Resources);

		let first = PassWith("First", Access(0, .ReadWriteStorage));
		defer delete first;
		fixture.Solver.EmitBarriers(first, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let second = PassWith("Second", Access(0, .ReadWriteStorage));
		defer delete second;
		fixture.Solver.EmitBarriers(second, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
	}

	/// Writing individual layers emits ONE BARRIER PER LAYER, because the layers no longer
	/// agree and a whole resource barrier would claim they do.
	[Test]
	public static void PerLayerWritesEmitPerLayerBarriers()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Cascades", fixture.MakeTexture(1, 4));
		fixture.Solver.Reset(fixture.Resources);

		let first = PassWith("Cascade0", Access(0, .WriteDepthTarget, .(0, 1, 0, 1)));
		defer delete first;
		fixture.Solver.EmitBarriers(first, fixture.Resources, fixture.Encoder);
		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].BaseArrayLayer == 0);
		fixture.Encoder.Clear();

		let second = PassWith("Cascade1", Access(0, .WriteDepthTarget, .(0, 1, 1, 1)));
		defer delete second;
		fixture.Solver.EmitBarriers(second, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].BaseArrayLayer == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].ArrayLayerCount == 1);
	}

	/// Reading the WHOLE of a resource whose layers disagree emits one barrier per layer that
	/// needs it, since each is coming from somewhere different.
	[Test]
	public static void AWholeResourceReadOverDivergedLayersSplits()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Cascades", fixture.MakeTexture(1, 4));
		fixture.Solver.Reset(fixture.Resources);

		let write = PassWith("WriteOne", Access(0, .WriteDepthTarget, .(0, 1, 1, 1)));
		defer delete write;
		fixture.Solver.EmitBarriers(write, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let read = PassWith("ReadAll", Access(0, .SampleDepthStencil));
		defer delete read;
		fixture.Solver.EmitBarriers(read, fixture.Resources, fixture.Encoder);

		// Every layer moves to the depth read layout: three from undefined, one from written.
		Test.Assert(fixture.Encoder.TextureBarriers.Count == 4);
		for (let barrier in fixture.Encoder.TextureBarriers)
		{
			Test.Assert(barrier.NewState == .DepthStencilRead);
			Test.Assert(barrier.ArrayLayerCount == 1, "one layer each");
		}
	}

	/// Once every layer has been written the same way, the tracker COLLAPSES back to uniform
	/// and the next transition is a single barrier again.
	[Test]
	public static void WritingEveryLayerCollapsesBackToUniform()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Cascades", fixture.MakeTexture(1, 2));
		fixture.Solver.Reset(fixture.Resources);

		for (uint32 layer = 0; layer < 2; layer++)
		{
			let pass = PassWith("Cascade", Access(0, .WriteDepthTarget, .(0, 1, layer, 1)));
			defer delete pass;
			fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);
		}
		fixture.Encoder.Clear();

		let read = PassWith("Read", Access(0, .SampleDepthStencil));
		defer delete read;
		fixture.Solver.EmitBarriers(read, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1, "one barrier, not one per layer");
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .DepthStencilWrite);
	}

	[Test]
	public static void PerMipStatesAreTrackedSeparately()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Chain", fixture.MakeTexture(4, 1));
		fixture.Solver.Reset(fixture.Resources);

		let write = PassWith("WriteMip1", Access(0, .WriteColorTarget, .(1, 1, 0, 1)));
		defer delete write;
		fixture.Solver.EmitBarriers(write, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let read = PassWith("ReadMip1", Access(0, .ReadTexture, .(1, 1, 0, 1)));
		defer delete read;
		fixture.Solver.EmitBarriers(read, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].BaseMipLevel == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .RenderTarget);
	}

	/// Accesses that do not OVERLAP emit no barrier against each other: two passes writing
	/// different cascades are not a hazard.
	[Test]
	public static void NonOverlappingAccessesDoNotBarrierEachOther()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Cascades", fixture.MakeTexture(1, 4));
		fixture.Solver.Reset(fixture.Resources);

		let write = PassWith("Cascade0", Access(0, .WriteDepthTarget, .(0, 1, 0, 1)));
		defer delete write;
		fixture.Solver.EmitBarriers(write, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		let read = PassWith("ReadCascade2", Access(0, .SampleDepthStencil, .(0, 1, 2, 1)));
		defer delete read;
		fixture.Solver.EmitBarriers(read, fixture.Resources, fixture.Encoder);

		// One barrier, for the layer being read, and it comes from UNDEFINED rather than
		// from the write to a different layer.
		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].BaseArrayLayer == 2);
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .Undefined);
	}

	/// Readable after write moves only what the PASS ACTUALLY WROTE, and only the part of it.
	[Test]
	public static void ReadableAfterWriteIsSubresourceAware()
	{
		let fixture = scope Fixture();
		let resource = fixture.AddResource("Cascades", fixture.MakeTexture(1, 4));
		resource.ReadableAfterWrite = true;
		fixture.Solver.Reset(fixture.Resources);

		let pass = PassWith("Cascade1", Access(0, .WriteDepthTarget, .(0, 1, 1, 1)));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		fixture.Solver.EmitReadableAfterWriteBarriers(pass, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].BaseArrayLayer == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .ShaderRead);
	}

	/// A resource that did NOT ask to be readable is left where the pass put it.
	[Test]
	public static void WithoutTheRequestNothingIsMovedAfterAWrite()
	{
		let fixture = scope Fixture();
		fixture.AddResource("Color", fixture.MakeTexture());
		fixture.Solver.Reset(fixture.Resources);

		let pass = PassWith("Write", Access(0, .WriteColorTarget));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		fixture.Solver.EmitReadableAfterWriteBarriers(pass, fixture.Resources, fixture.Encoder);
		Test.Assert(fixture.Encoder.TextureBarriers.IsEmpty);
	}

	/// The final transition uses the state tracked against the TEXTURE, so it is right even
	/// when the resource was reached through another handle.
	[Test]
	public static void TheFinalTransitionComesFromTheTrackedState()
	{
		let fixture = scope Fixture();
		let backbuffer = fixture.MakeTexture();
		let resource = fixture.AddResource("Backbuffer", backbuffer);
		resource.FinalState = ResourceState.Present;
		fixture.Solver.Reset(fixture.Resources);

		let pass = PassWith("Draw", Access(0, .WriteColorTarget));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		fixture.Solver.EmitFinalTransitions(fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .RenderTarget);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .Present);
	}

	/// A final transition over a resource whose subresources DISAGREE emits one barrier each,
	/// because each is coming from somewhere different.
	[Test]
	public static void ANonUniformFinalTransitionSplits()
	{
		let fixture = scope Fixture();
		let resource = fixture.AddResource("Cascades", fixture.MakeTexture(1, 2));
		resource.FinalState = ResourceState.ShaderRead;
		fixture.Solver.Reset(fixture.Resources);

		let pass = PassWith("Cascade0", Access(0, .WriteDepthTarget, .(0, 1, 0, 1)));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);
		fixture.Encoder.Clear();

		fixture.Solver.EmitFinalTransitions(fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 2);
		for (let barrier in fixture.Encoder.TextureBarriers)
			Test.Assert(barrier.NewState == .ShaderRead);
	}

	/// A TRANSIENT starts from undefined every frame, even when the pooled texture it was
	/// handed was left in some other state by whoever had it last.
	[Test]
	public static void ATransientAlwaysStartsUndefined()
	{
		let fixture = scope Fixture();
		let texture = fixture.MakeTexture(1, 1, .ShaderRead);
		fixture.AddResource("Scratch", texture, .Transient);
		fixture.Solver.Reset(fixture.Resources);

		let pass = PassWith("Write", Access(0, .WriteColorTarget));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 1);
		Test.Assert(fixture.Encoder.TextureBarriers[0].OldState == .Undefined);
		Test.Assert(fixture.Encoder.TextureBarriers[0].NewState == .RenderTarget);
	}

	/// A PERSISTENT resource resumes from what it ended the last frame in, including when its
	/// subresources disagreed.
	[Test]
	public static void APersistentResourceResumesItsSubresourceStates()
	{
		let fixture = scope Fixture();
		let texture = fixture.MakeTexture(1, 2);
		let resource = fixture.AddResource("History", texture, .Persistent);
		// The resource owns it once attached, so there is nothing to free here.
		resource.PersistentData = new PersistentResource(texture, null);

		// The first frame writes one layer, so the two diverge.
		fixture.Solver.Reset(fixture.Resources);
		let pass = PassWith("Write", Access(0, .WriteColorTarget, .(0, 1, 0, 1)));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);
		fixture.Solver.UpdatePersistentStates(fixture.Resources);

		Test.Assert(!resource.PersistentData.FirstFrame);
		Test.Assert(resource.PersistentData.SubresourceStates.Count == 2, "they disagree");

		// The next frame resumes exactly that, so the written layer is not transitioned again.
		fixture.Encoder.Clear();
		fixture.Solver.Reset(fixture.Resources);
		let again = PassWith("WriteAgain", Access(0, .WriteColorTarget, .(0, 1, 0, 1)));
		defer delete again;
		fixture.Solver.EmitBarriers(again, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.IsEmpty, "that layer was already there");
	}

	/// A buffer is tracked per handle rather than per subresource, and its barrier carries the
	/// buffer.
	[Test]
	public static void ABufferTransitionsAsAWhole()
	{
		let fixture = scope Fixture();
		let buffer = fixture.Device.CreateBuffer(.() { Label = "RGBarrierTests.ABufferTransitionsAsAWhole", Size = 256, Usage = .Storage }).Value;
		defer { var doomed = buffer; fixture.Device.DestroyBuffer(ref doomed); }

		let resource = new RenderGraphResource("Counts", .Buffer, .Imported);
		defer delete resource;
		resource.Buffer = buffer;

		let resources = scope RenderGraphResource[1](resource);
		let span = Span<RenderGraphResource>(&resources[0], 1);
		fixture.Solver.Reset(span);

		let pass = PassWith("Compute", Access(0, .WriteStorage));
		defer delete pass;
		fixture.Solver.EmitBarriers(pass, span, fixture.Encoder);

		Test.Assert(fixture.Encoder.BufferBarriers.Count == 1);
		Test.Assert(fixture.Encoder.BufferBarriers[0].Buffer == buffer);
		Test.Assert(fixture.Encoder.BufferBarriers[0].NewState == .ShaderWrite);
	}

	/// Several barriers from one emit point go out as ONE group: a barrier is a stall, and
	/// several groups where one would do stalls several times.
	[Test]
	public static void EverythingFromOneEmitPointIsOneGroup()
	{
		let fixture = scope Fixture();
		fixture.AddResource("A", fixture.MakeTexture());
		fixture.AddResource("B", fixture.MakeTexture());
		fixture.Solver.Reset(fixture.Resources);

		let pass = new RenderGraphPass("Both", .Render);
		defer delete pass;
		pass.Accesses.Add(Access(0, .WriteColorTarget));
		pass.Accesses.Add(Access(1, .ReadTexture));

		fixture.Solver.EmitBarriers(pass, fixture.Resources, fixture.Encoder);

		Test.Assert(fixture.Encoder.TextureBarriers.Count == 2);
		Test.Assert(fixture.Encoder.GroupCount == 1);
	}
}
