using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// One WebGPU adapter: what it is, what it can do, and the device made from it.
///
/// BORROWS its backend, which outlives every adapter on it.
sealed class WebGpuAdapter : IAdapter
{
	private WebGpuBackend mBackend;
	private WGPUAdapter mHandle;
	/// OWNED. Torn down FIRST in the destructor, so a device releases its wgpu handle
	/// while the adapter that made it is still alive.
	private List<WebGpuDevice> mDevices = new .() ~ delete _;

	public WGPUAdapter Handle => mHandle;
	public WebGpuBackend Backend => mBackend;

	/// TAKES the handle. Releasing it is this object's job.
	public this(WebGpuBackend backend, WGPUAdapter handle)
	{
		mBackend = backend;
		mHandle = handle;
	}

	public ~this()
	{
		ClearAndDeleteItems!(mDevices);

		if (mHandle != null)
		{
			wgpuAdapterRelease(mHandle);
			mHandle = null;
		}
	}

	/// Which wgpu backend this adapter belongs to.
	///
	/// ONE physical GPU appears once per backend, so this is what tells two entries for
	/// the same card apart. The backend orders on it; see WebGpuBackend.EnumerateNow.
	public WGPUBackendType WgpuBackendType()
	{
		WGPUAdapterInfo info = .();
		wgpuAdapterGetInfo(mHandle, &info);
		let type = info.backendType;
		wgpuAdapterInfoFreeMembers(info);
		return type;
	}

	public void GetInfo(AdapterInfo outInfo)
	{
		WGPUAdapterInfo info = .();
		wgpuAdapterGetInfo(mHandle, &info);

		// The strings belong to wgpu until FreeMembers, so the name is COPIED out
		// before that runs rather than referenced.
		outInfo.Name.Set(StringView((char8*)info.device.data, (int)info.device.length));
		outInfo.VendorId = info.vendorID;
		outInfo.DeviceId = info.deviceID;

		switch (info.adapterType)
		{
		case .WGPUAdapterType_DiscreteGPU: outInfo.Type = .DiscreteGpu;
		case .WGPUAdapterType_IntegratedGPU: outInfo.Type = .IntegratedGpu;
		case .WGPUAdapterType_CPU: outInfo.Type = .Cpu;
		default: outInfo.Type = .Unknown;
		}

		wgpuAdapterInfoFreeMembers(info);

		WGPULimits limits = .();
		if (wgpuAdapterGetLimits(mHandle, &limits) == .WGPUStatus_Success)
		{
			outInfo.SupportedFeatures.MaxBindGroups = limits.maxBindGroups;
			// WebGPU has no single "bindings per group" limit; the sampled texture
			// count is the one that actually binds first in practice.
			outInfo.SupportedFeatures.MaxBindingsPerGroup = limits.maxSampledTexturesPerShaderStage;
			outInfo.SupportedFeatures.MaxTextureDimension2D = limits.maxTextureDimension2D;
			outInfo.SupportedFeatures.MaxTextureArrayLayers = limits.maxTextureArrayLayers;
			outInfo.SupportedFeatures.MaxComputeWorkgroupSizeX = limits.maxComputeWorkgroupSizeX;
			outInfo.SupportedFeatures.MaxComputeWorkgroupSizeY = limits.maxComputeWorkgroupSizeY;
			outInfo.SupportedFeatures.MaxComputeWorkgroupSizeZ = limits.maxComputeWorkgroupSizeZ;
			outInfo.SupportedFeatures.MaxComputeWorkgroupsPerDimension =
				limits.maxComputeWorkgroupsPerDimension;
			outInfo.SupportedFeatures.MinUniformBufferOffsetAlignment =
				limits.minUniformBufferOffsetAlignment;
			outInfo.SupportedFeatures.MinStorageBufferOffsetAlignment =
				limits.minStorageBufferOffsetAlignment;
			outInfo.SupportedFeatures.MaxBufferSize = limits.maxBufferSize;
		}

		WGPUSupportedFeatures features = .();
		wgpuAdapterGetFeatures(mHandle, &features);
		for (uint i = 0; i < features.featureCount; i++)
		{
			switch (features.features[i])
			{
			case .WGPUFeatureName_TimestampQuery:
				outInfo.SupportedFeatures.TimestampQueries = true;
			case .WGPUFeatureName_TextureCompressionBC:
				outInfo.SupportedFeatures.TextureCompressionBC = true;
			case .WGPUFeatureName_TextureCompressionASTC:
				outInfo.SupportedFeatures.TextureCompressionASTC = true;
			case .WGPUFeatureName_DepthClipControl:
				outInfo.SupportedFeatures.DepthClamp = true;
			default:
			}
		}
		wgpuSupportedFeaturesFreeMembers(features);

		// Not probed, because WebGPU guarantees them. Per attachment blend state is in
		// the spec, and occlusion works through the pass begin declaration rather than
		// through a feature. Push constants are decided at device creation, which is
		// where MaxPushConstantSize gets stamped.
		outInfo.SupportedFeatures.IndependentBlend = true;
		outInfo.SupportedFeatures.OcclusionQueries = true;
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		// The wrapper does not exist until the request completes, so loss routes through a
		// record the callback fills lazily. The device adopts it and frees it at Destroy.
		let lostRoute = new WebGpuDeviceLostRoute();

		let required = scope List<WGPUFeatureName>();
		let info = scope AdapterInfo();
		GetInfo(info);

		// Enable what the adapter HAS, the way the Vulkan backend does. Callers gate on the
		// device's features, not on what was asked for.
		if (info.SupportedFeatures.TimestampQueries)
			required.Add(.WGPUFeatureName_TimestampQuery);

		if (info.SupportedFeatures.TextureCompressionBC)
			required.Add(.WGPUFeatureName_TextureCompressionBC);

		// ASTC is the mobile web compressed family. A desktop browser usually exposes only
		// BC, a mobile one only ASTC, so whichever the adapter has is what gets asked for.
		if (info.SupportedFeatures.TextureCompressionASTC)
			required.Add(.WGPUFeatureName_TextureCompressionASTC);

		if (info.SupportedFeatures.DepthClamp)
			required.Add(.WGPUFeatureName_DepthClipControl);

		// Push constants are WebGPU IMMEDIATES - a wgpu-native feature today, though the
		// field is in the STANDARD pipeline layout descriptor, so browsers will follow. The
		// feature ENUM is native only; Dawn has no immediates path, so web routes
		// SetPushConstants through the uniform buffer emulation. Fully functional, just not
		// immediates.
#if BF_PLATFORM_WASM
		let immediatesSupported = false;
#else
		let immediates = (WGPUFeatureName)WGPUNativeFeature.WGPUNativeFeature_Immediates;
		let immediatesSupported = wgpuAdapterHasFeature(mHandle, immediates) != 0;
		if (immediatesSupported)
			required.Add(immediates);
#endif

		// 32 bit float textures are non filterable in core WebGPU, and the renderer linear
		// samples HDR sky and IBL sources, so filtering goes on where it is available.
		let f32Filter = wgpuAdapterHasFeature(mHandle, .WGPUFeatureName_Float32Filterable) != 0;
		if (f32Filter)
			required.Add(.WGPUFeatureName_Float32Filterable);

		GlobalLog(.Information, "[webgpu] float32-filterable {}",
			f32Filter ? "ENABLED" : "MISSING (rgba32f linear-sample will fail)");

		// Encoder level WriteTimestamp - the RHI's ICommandEncoder.WriteTimestamp, which the
		// GPU graph profiler uses - is a SEPARATE wgpu feature from pass boundary timestamps.
		// The enum is wgpu-native only, so a browser never has it.
#if !BF_PLATFORM_WASM
		let encoderTimestamps =
			(WGPUFeatureName)WGPUNativeFeature.WGPUNativeFeature_TimestampQueryInsideEncoders;
		if (info.SupportedFeatures.TimestampQueries
			&& (wgpuAdapterHasFeature(mHandle, encoderTimestamps) != 0))
			required.Add(encoderTimestamps);
#endif

		// The adapter's OWN limits are requested wholesale, which is always legal and
		// unlocks the real texture size and buffer ceilings. The immediates budget is the
		// RHI's 128 byte push constant contract.
		WGPULimits adapterLimits = .();
		WGPULimits requiredLimits = .();
		let haveLimits = wgpuAdapterGetLimits(mHandle, &adapterLimits) == .WGPUStatus_Success;
		if (haveLimits)
		{
			requiredLimits = adapterLimits; // adapter supported values are always legal
			if (immediatesSupported && (requiredLimits.maxImmediateSize < 128)
				&& (adapterLimits.maxImmediateSize >= 128))
				requiredLimits.maxImmediateSize = 128;
		}

		WGPUDeviceDescriptor deviceDesc = .();
		deviceDesc.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		deviceDesc.requiredFeatureCount = (uint)required.Count;
		deviceDesc.requiredFeatures = required.Ptr;
		if (haveLimits)
			deviceDesc.requiredLimits = &requiredLimits;

		deviceDesc.deviceLostCallbackInfo.mode = WebGpuApi.cCallbackMode;
		deviceDesc.deviceLostCallbackInfo.callback =
			(device, reason, message, userdata1, userdata2) =>
			{
				if (reason == .WGPUDeviceLostReason_Destroyed)
					return; // an orderly teardown is not a loss

				let route = (WebGpuDeviceLostRoute)Internal.UnsafeCastToObject(userdata1);
				if (route.Device != null)
					route.Device.MarkLost();

				// Console, not GlobalLog, and for the same reason the Vulkan backend writes
				// its validation messages there: a device error nobody sees is the worst
				// case. GlobalLog has no console sink in a sample, so an uncaptured error
				// vanished and a bind group that failed to build only showed up much later,
				// as an "invalid BindGroup" abort inside an unrelated call.
				Console.Error.WriteLine("[webgpu] device LOST (reason {}): {}", reason,
					StringView((char8*)message.data, (int)message.length));
			};
		deviceDesc.deviceLostCallbackInfo.userdata1 = Internal.UnsafeCastToPtr(lostRoute);

		deviceDesc.uncapturedErrorCallbackInfo.callback =
			(device, errorType, message, userdata1, userdata2) =>
			{
				Console.Error.WriteLine("[webgpu] uncaptured error (type {}): {}", errorType,
					StringView((char8*)message.data, (int)message.length));
			};

		// A HEAP record that orphans on timeout, which is the same pattern the fence uses: a
		// stack one would leave the still registered callback writing through a dead frame
		// if the pump gives up before the request resolves.
		let request = new WebGpuPendingDeviceRequest();

		WGPURequestDeviceCallbackInfo callback = .();
		callback.mode = WebGpuApi.cCallbackMode;
		callback.callback = (status, created, message, userdata1, userdata2) =>
			{
				let r = (WebGpuPendingDeviceRequest)Internal.UnsafeCastToObject(userdata1);
				if (r.Orphaned)
				{
					if ((status == .WGPURequestDeviceStatus_Success) && (created != null))
						wgpuDeviceRelease(created); // nobody else will

					delete r;
					return;
				}

				if (status == .WGPURequestDeviceStatus_Success)
				{
					r.Device = created;
				}
				else
				{
					GlobalLog(.Error, "[webgpu] RequestDevice failed: {}",
						StringView((char8*)message.data, (int)message.length));
				}

				r.Done = true;
			};
		callback.userdata1 = Internal.UnsafeCastToPtr(request);

		wgpuAdapterRequestDevice(mHandle, &deviceDesc, callback);
		WebGpuApi.PumpUntil(mBackend.Instance, ref request.Done);

		WGPUDevice device = null;
		if (!request.Done)
		{
			GlobalLog(.Error, "[webgpu] RequestDevice callback did not fire (pump timed out)");
			request.Orphaned = true; // the callback owns the record now
		}
		else
		{
			device = request.Device;
			delete request;
		}

		if (device == null)
		{
			delete lostRoute;
			return .Err;
		}

		let wrapper = new WebGpuDevice(mBackend.Instance, mHandle, device);
		var features = info.SupportedFeatures;
		// SetPushConstants works EITHER way, native immediates or the uniform buffer
		// emulation, so the budget is always advertised. Reporting zero under emulation
		// would make a capability checking caller disable the very paths the emulator
		// exists to serve.
		features.MaxPushConstantSize = 128;
		wrapper.SetFeatures(features);
		wrapper.SetImmediatesSupported(immediatesSupported);

		lostRoute.Device = wrapper;
		wrapper.AdoptLostRoute(lostRoute);

		mDevices.Add(wrapper);
		return .Ok(wrapper);
	}
}
