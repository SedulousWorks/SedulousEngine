using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// Descriptor layouts, pipeline layouts and bind groups, on the real device.
class VulkanBindingTests
{
	private static IBackend sBackend;
	private static IDevice sDevice;

	/// A device with every optional feature ASKED FOR, so the bindless and ray tracing
	/// paths are exercised where the hardware has them.
	private static bool Ready()
	{
		if (sDevice != null)
			return true;
		if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
			return false;
		sBackend = backend;
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return false;

		let info = scope AdapterInfo();
		adapters[0].GetInfo(info);

		var desc = DeviceDesc();
		desc.RequiredFeatures = info.SupportedFeatures;
		if (!(adapters[0].CreateDevice(desc) case .Ok(let device)))
			return false;
		sDevice = device;
		return true;
	}

	[Test]
	public static void ALayoutIsBuiltFromItsEntries()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let entries = scope BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var desc = BindGroupLayoutDesc();
		desc.Entries = entries;

		Test.Assert(sDevice.CreateBindGroupLayout(desc) case .Ok(var layout));
		Test.Assert(layout.Entries.Length == 3, "the layout remembers what it was built from");
		Test.Assert(layout.Entries[0].Type == .UniformBuffer);

		let asVulkan = layout as VulkanBindGroupLayout;
		Test.Assert(!asVulkan.HasBindless, "nothing here asked for an unbounded array");

		sDevice.DestroyBindGroupLayout(ref layout);
		Test.Assert(layout == null);
	}

	/// The three HLSL register classes all bind at zero, and would collide in Vulkan's
	/// single binding space. The shifts push them apart, and the layout must apply exactly
	/// the shifts DXC applied when it compiled the shader.
	[Test]
	public static void TheBindingShiftsSeparateTheRegisterClasses()
	{
		let shifts = BindingShifts.Standard;

		Test.Assert(shifts.Apply(.UniformBuffer, 0) == 0, "b0 stays at zero");
		Test.Assert(shifts.Apply(.SampledTexture, 0) == 100, "t0 moves to the SRV space");
		Test.Assert(shifts.Apply(.StorageBufferReadWrite, 0) == 200, "u0 to the UAV space");
		Test.Assert(shifts.Apply(.Sampler, 0) == 300, "s0 to the sampler space");

		// A read only structured buffer is a `t` register in HLSL, so it takes the SRV
		// shift, unlike its read write twin. Classifying it as a UAV would point the layout
		// at a binding DXC never used.
		Test.Assert(shifts.Apply(.StorageBufferReadOnly, 0) == 100,
			"a read only structured buffer is an SRV");
		Test.Assert(shifts.Apply(.StorageBufferReadWrite, 0) == 200);

		// An acceleration structure is also read through a `t` register.
		Test.Assert(shifts.Apply(.AccelerationStructure, 0) == 100);

		// And the offset within a class is preserved.
		Test.Assert(shifts.Apply(.SampledTexture, 5) == 105);
	}

	[Test]
	public static void APipelineLayoutTakesSetLayoutsAndPushConstants()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let entries = scope BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;
		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var setLayout));

		let setLayouts = scope IBindGroupLayout[1](setLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Vertex | .Fragment;
		pushRange.Size = 64;
		let ranges = scope PushConstantRange[1](pushRange);

		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = setLayouts;
		desc.PushConstantRanges = ranges;

		Test.Assert(sDevice.CreatePipelineLayout(desc) case .Ok(var pipelineLayout));
		sDevice.DestroyPipelineLayout(ref pipelineLayout);

		// An empty layout is legitimate: a shader that binds nothing still needs one.
		Test.Assert(sDevice.CreatePipelineLayout(.()) case .Ok(var empty));
		sDevice.DestroyPipelineLayout(ref empty);

		sDevice.DestroyBindGroupLayout(ref setLayout);
	}

	/// A null entry in the layout array would leave a null handle for the driver to
	/// dereference, so it is refused here.
	[Test]
	public static void APipelineLayoutRefusesANullSetLayout()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let setLayouts = scope IBindGroupLayout[1](null);
		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = setLayouts;
		Test.Assert(sDevice.CreatePipelineLayout(desc) case .Err);
	}

	/// A bind group allocates a descriptor set and writes the resources into it.
	[Test]
	public static void ABindGroupIsFilledFromRealResources()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let entries = scope BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;
		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var layout));

		var bufferDesc = BufferDesc();
		bufferDesc.Size = 256;
		bufferDesc.Usage = .Uniform;
		bufferDesc.Memory = .CpuToGpu;
		Test.Assert(sDevice.CreateBuffer(bufferDesc) case .Ok(var buffer));

		Test.Assert(sDevice.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 32, 32))
			case .Ok(var texture));
		Test.Assert(sDevice.CreateTextureView(texture, .()) case .Ok(var view));
		Test.Assert(sDevice.CreateSampler(.()) case .Ok(var sampler));

		let groupEntries = scope BindGroupEntry[3](
			BindGroupEntry.BufferEntry(buffer, 0, 256),
			BindGroupEntry.TextureEntry(view),
			BindGroupEntry.SamplerEntry(sampler));

		var groupDesc = BindGroupDesc();
		groupDesc.Layout = layout;
		groupDesc.Entries = groupEntries;

		Test.Assert(sDevice.CreateBindGroup(groupDesc) case .Ok(var group),
			"the set allocates and the descriptors are written");
		Test.Assert(group.Layout === layout);

		sDevice.DestroyBindGroup(ref group);
		sDevice.DestroySampler(ref sampler);
		sDevice.DestroyTextureView(ref view);
		sDevice.DestroyTexture(ref texture);
		sDevice.DestroyBuffer(ref buffer);
		sDevice.DestroyBindGroupLayout(ref layout);
	}

	/// A group whose layout is null cannot allocate against anything.
	[Test]
	public static void ABindGroupRefusesANullLayout()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }
		Test.Assert(sDevice.CreateBindGroup(.()) case .Err);
	}

	/// A count of all ones asks for an UNBOUNDED array, which becomes a large partially
	/// bound one that is written after binding. This is the bindless path.
	[Test]
	public static void AnUnboundedEntryBecomesABindlessArray()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }
		if (!sDevice.Features.BindlessDescriptors)
		{
			Console.WriteLine("SKIP: this device has no descriptor indexing");
			return;
		}

		var bindless = BindGroupLayoutEntry();
		bindless.Binding = 0;
		bindless.Visibility = .Fragment;
		bindless.Type = .BindlessTextures;
		bindless.Count = uint32.MaxValue;

		let entries = scope BindGroupLayoutEntry[1](bindless);
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;

		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var layout));
		let asVulkan = layout as VulkanBindGroupLayout;
		Test.Assert(asVulkan.HasBindless, "the unbounded count was recognised");
		Test.Assert(asVulkan.BindlessCount == VulkanBindGroupLayout.BindlessCapacity,
			"and sized to the fixed capacity Vulkan needs");

		// The group takes no positional entries: a bindless slot is filled afterwards.
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = layout;
		Test.Assert(sDevice.CreateBindGroup(groupDesc) case .Ok(var group));

		// Writing one slot of the array in place, which is the point of bindless.
		Test.Assert(sDevice.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 16, 16))
			case .Ok(var texture));
		Test.Assert(sDevice.CreateTextureView(texture, .()) case .Ok(var view));

		var update = BindlessUpdateEntry();
		update.LayoutIndex = 0;
		update.ArrayIndex = 7;
		update.TextureView = view;
		let updates = scope BindlessUpdateEntry[1](update);
		group.UpdateBindless(updates);

		// And an out of range layout index is skipped rather than writing past the array.
		var bad = BindlessUpdateEntry();
		bad.LayoutIndex = 99;
		bad.TextureView = view;
		let badUpdates = scope BindlessUpdateEntry[1](bad);
		group.UpdateBindless(badUpdates);

		sDevice.DestroyTextureView(ref view);
		sDevice.DestroyTexture(ref texture);
		sDevice.DestroyBindGroup(ref group);
		sDevice.DestroyBindGroupLayout(ref layout);
	}

	/// A pool has a fixed capacity, so the manager makes another when one fills. Allocating
	/// well past a single pool's worth proves it grows rather than failing.
	[Test]
	public static void TheDescriptorPoolGrowsBeyondOnePool()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let entries = scope BindGroupLayoutEntry[1](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;
		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var layout));

		var bufferDesc = BufferDesc();
		bufferDesc.Size = 64;
		bufferDesc.Usage = .Uniform;
		bufferDesc.Memory = .CpuToGpu;
		Test.Assert(sDevice.CreateBuffer(bufferDesc) case .Ok(var buffer));

		let groupEntries = scope BindGroupEntry[1](BindGroupEntry.BufferEntry(buffer, 0, 64));
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = layout;
		groupDesc.Entries = groupEntries;

		// A pool holds 256 sets, so 300 forces a second one.
		let groups = scope IBindGroup[300];
		for (int i < 300)
		{
			Test.Assert(sDevice.CreateBindGroup(groupDesc) case .Ok(let group),
				scope $"set {i} allocated");
			groups[i] = group;
		}

		for (int i < 300)
		{
			var group = groups[i];
			sDevice.DestroyBindGroup(ref group);
		}
		sDevice.DestroyBuffer(ref buffer);
		sDevice.DestroyBindGroupLayout(ref layout);
	}

	/// An acceleration structure is sized by the DRIVER's estimate and carries a device
	/// address, which is how a top level build refers to it.
	[Test]
	public static void AnAccelerationStructureIsCreatedAndAddressable()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }
		if (!sDevice.Features.RayTracing)
		{
			Console.WriteLine("SKIP: this device has no ray tracing");
			return;
		}

		var desc = AccelStructDesc();
		desc.Type = .BottomLevel;
		Test.Assert(sDevice.CreateAccelStruct(desc) case .Ok(var bottomLevel));
		Test.Assert(bottomLevel.Type == .BottomLevel);
		Test.Assert(bottomLevel.DeviceAddress != 0,
			"a real structure has an address a build can name");

		var topDesc = AccelStructDesc();
		topDesc.Type = .TopLevel;
		Test.Assert(sDevice.CreateAccelStruct(topDesc) case .Ok(var topLevel));
		Test.Assert(topLevel.Type == .TopLevel);
		Test.Assert(topLevel.DeviceAddress != bottomLevel.DeviceAddress);

		// The shader binding table alignments come from the device once ray tracing is on.
		Test.Assert(sDevice.ShaderGroupHandleSize > 0);
		Console.WriteLine(scope $"RT: handleSize={sDevice.ShaderGroupHandleSize} align={sDevice.ShaderGroupHandleAlignment} baseAlign={sDevice.ShaderGroupBaseAlignment}");

		sDevice.DestroyAccelStruct(ref topLevel);
		sDevice.DestroyAccelStruct(ref bottomLevel);
	}

	[Test]
	public static void ZzTearDown()
	{
		if (sDevice != null)
		{
			sDevice.WaitIdle();
			sDevice.Destroy();
			sDevice = null;
		}
		if (sBackend != null)
		{
			sBackend.Destroy();
			delete sBackend;
			sBackend = null;
		}
	}
}
