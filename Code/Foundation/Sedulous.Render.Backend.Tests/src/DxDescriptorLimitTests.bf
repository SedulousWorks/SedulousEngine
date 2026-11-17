#if BF_PLATFORM_WINDOWS
using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.TestSupport;
using Sedulous.RHI.DX12;

namespace Sedulous.Render.Backend.Tests;

/// DX12's descriptor limits, on a real device. The CPU descriptor heaps page, so more views than
/// one page holds all get their descriptors; and bind groups of the same samplers share one shader
/// visible sampler table, so more groups than that heap's 2048 slots still bind.
class DxDescriptorLimitTests
{
	/// 4097 views, each written into a group: one more SRV than the first CPU page holds (a full
	/// heap handed out a zero handle, and the view was written through it). And 4097 groups on one
	/// sampler: more than the shader visible sampler heap has slots (each group took its own table),
	/// and more than the CPU sampler heap has (a sharing group still took slots there).
	[Test]
	public static void ViewsPastAPageAndGroupsPastTheSamplerHeapAllGetTheirDescriptors()
	{
		if (!(DxRhi.CreateBackend() case .Ok(let backend)))
		{
			Console.WriteLine("SKIP: no DX12");
			return;
		}
		defer { backend.Destroy(); delete backend; }
		let device = RhiTestSupport.MakeTestDevice(backend);
		if (device == null)
		{
			Console.WriteLine("SKIP: no DX12 device");
			return;
		}
		defer device.Destroy();

		var textureDesc = TextureDesc();
		textureDesc.Label = "DxDescriptorLimitTests.texture";
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = 4;
		textureDesc.Height = 4;
		textureDesc.Usage = .Sampled;
		Test.Assert(device.CreateTexture(textureDesc) case .Ok(var texture));
		Test.Assert(device.CreateSampler(.() { Label = "DxDescriptorLimitTests.sampler" }) case .Ok(var sampler));
		let layoutEntries = scope BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Label = "DxDescriptorLimitTests.layout";
		layoutDesc.Entries = layoutEntries;
		Test.Assert(device.CreateBindGroupLayout(layoutDesc) case .Ok(var layout));

		const int cGroups = 4097;
		let views = scope List<ITextureView>();
		let groups = scope List<IBindGroup>();
		bool allMade = true;
		for (int i < cGroups)
		{
			if (!(device.CreateTextureView(texture, .() { Label = "DxDescriptorLimitTests.view" }) case .Ok(let view)))
			{
				allMade = false;
				break;
			}
			views.Add(view);
			let groupEntries = scope BindGroupEntry[2](BindGroupEntry.TextureEntry(view), BindGroupEntry.SamplerEntry(sampler));
			var groupDesc = BindGroupDesc();
			groupDesc.Label = "DxDescriptorLimitTests.group";
			groupDesc.Layout = layout;
			groupDesc.Entries = groupEntries;
			if (!(device.CreateBindGroup(groupDesc) case .Ok(let group)))
			{
				allMade = false;
				break;
			}
			groups.Add(group);
		}
		Test.Assert(allMade, scope $"{groups.Count} of {cGroups} groups made");

		for (var group in groups)
			device.DestroyBindGroup(ref group);
		for (var view in views)
			device.DestroyTextureView(ref view);
		device.DestroyBindGroupLayout(ref layout);
		device.DestroySampler(ref sampler);
		device.DestroyTexture(ref texture);
	}
}
#endif
