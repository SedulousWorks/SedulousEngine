using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;

namespace Sedulous.RHI.WebGPU.Tests;

/// The register space shift, end to end.
///
/// The shift is the one piece of this backend that silently binds the WRONG resource
/// when it is wrong: DXC bakes the numbers into the SPIR-V, so a layout that declares
/// different ones does not fail, it feeds the shader whatever sits at the number it did
/// declare. So these go through real WebGPU validation rather than asserting the
/// arithmetic against itself.
class WebGpuBindingShiftTests
{
	private static WGPUDevice RequestDevice(WebGpuBackend backend)
	{
		if (backend.Initialize() case .Err)
			return null;

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return null;

		WGPUDevice device = null;
		var done = false;

		WGPURequestDeviceCallbackInfo callback = .();
		callback.mode = WebGpuApi.cCallbackMode;
		callback.callback = (status, got, message, userdata1, userdata2) =>
			{
				*(WGPUDevice*)userdata1 = (status == .WGPURequestDeviceStatus_Success) ? got : null;
				*(bool*)userdata2 = true;
			};
		callback.userdata1 = &device;
		callback.userdata2 = &done;

		WGPUDeviceDescriptor desc = .();
		wgpuAdapterRequestDevice(((WebGpuAdapter)adapters[0]).Handle, &desc, callback);
		WebGpuApi.PumpUntil(backend.Instance, ref done);
		return device;
	}

	/// Each register class lands where the table says. Read off the conversion rather
	/// than off a copy of the numbers, so the table itself is what is under test.
	[Test]
	public static void EachRegisterClassShiftsToItsOwnSpace()
	{
		// A constant buffer does not move; everything else does, and the classes must
		// not collide at the same source binding.
		Test.Assert(WebGpuConversions.ShiftedBinding(.UniformBuffer, 0) == 0);
		Test.Assert(WebGpuConversions.ShiftedBinding(.SampledTexture, 0) == 100);
		Test.Assert(WebGpuConversions.ShiftedBinding(.StorageBufferReadWrite, 0) == 200);
		Test.Assert(WebGpuConversions.ShiftedBinding(.Sampler, 0) == 300);

		// A StructuredBuffer is an SRV in HLSL terms, so a READ ONLY storage buffer
		// shifts with the sampled textures rather than with the writable ones. Getting
		// this one backwards is the subtle failure.
		Test.Assert(WebGpuConversions.ShiftedBinding(.StorageBufferReadOnly, 0) == 100);
		Test.Assert(WebGpuConversions.ShiftedBinding(.StorageTextureReadOnly, 0) == 200);
		Test.Assert(WebGpuConversions.ShiftedBinding(.ComparisonSampler, 0) == 300);

		// The shift is an offset, not a replacement.
		Test.Assert(WebGpuConversions.ShiftedBinding(.SampledTexture, 7) == 107);

		// Bindless never reaches a WebGPU layout, so it is left where it is.
		Test.Assert(WebGpuConversions.ShiftedBinding(.BindlessTextures, 5) == 5);
	}

	/// The layout ACCEPTS the shifted numbers. WebGPU validates binding indices against
	/// maxBindingsPerBindGroup, which a browser caps at a thousand, and this is what says
	/// the compact profile fits inside that.
	[Test]
	public static void AShiftedLayoutIsAcceptedByWebGpu()
	{
		let backend = scope WebGpuBackend();
		let device = RequestDevice(backend);
		if (device == null)
			return;
		defer { wgpuDeviceRelease(device); backend.Destroy(); }

		let entries = scope List<BindGroupLayoutEntry>();
		entries.Add(.() { Binding = 0, Type = .UniformBuffer, Visibility = .Vertex });
		entries.Add(.() { Binding = 0, Type = .SampledTexture, Visibility = .Fragment,
			TextureDimension = .Texture2D, TextureSampleType = .Float });
		entries.Add(.() { Binding = 0, Type = .Sampler, Visibility = .Fragment });

		let layout = scope WebGpuBindGroupLayout();
		let desc = BindGroupLayoutDesc() { Entries = entries, Label = "shifted" };
		Test.Assert(layout.Initialize(device, desc) case .Ok,
			"three classes at source binding zero coexist once shifted");

		// And the layout kept the UNSHIFTED entries, which is what the bind group
		// replays to reach the same numbers.
		Test.Assert(layout.Entries.Length == 3);
		for (let entry in layout.Entries)
			Test.Assert(entry.Binding == 0, "the entries are kept as declared, not shifted");
	}

	/// A binding ARRAY has no core WebGPU shape, so the layout refuses it rather than
	/// creating something that silently binds one element.
	[Test]
	public static void ABindingArrayIsRefused()
	{
		let backend = scope WebGpuBackend();
		let device = RequestDevice(backend);
		if (device == null)
			return;
		defer { wgpuDeviceRelease(device); backend.Destroy(); }

		let entries = scope List<BindGroupLayoutEntry>();
		entries.Add(.() { Binding = 0, Type = .SampledTexture, Visibility = .Fragment,
			TextureDimension = .Texture2D, TextureSampleType = .Float, Count = 8 });

		let layout = scope WebGpuBindGroupLayout();
		let desc = BindGroupLayoutDesc() { Entries = entries };
		Test.Assert(layout.Initialize(device, desc) case .Err, "a count above one is refused");
	}

	/// Bindless has no WebGPU shape either, and its refusal is what makes the bind
	/// group's UpdateBindless a safe no-op.
	[Test]
	public static void ABindlessEntryIsRefused()
	{
		let backend = scope WebGpuBackend();
		let device = RequestDevice(backend);
		if (device == null)
			return;
		defer { wgpuDeviceRelease(device); backend.Destroy(); }

		let entries = scope List<BindGroupLayoutEntry>();
		entries.Add(.() { Binding = 0, Type = .BindlessTextures, Visibility = .Fragment });

		let layout = scope WebGpuBindGroupLayout();
		let desc = BindGroupLayoutDesc() { Entries = entries };
		Test.Assert(layout.Initialize(device, desc) case .Err);
	}
}
