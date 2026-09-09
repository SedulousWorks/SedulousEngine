using Sedulous.RHI;

namespace Sedulous.Render;

/// Finding a depth stencil format the device actually has.
static class StencilFormatProbe
{
	/// Probes for a single sampled, stencil capable format, in the SAME candidate order the
	/// vector graphics renderer probes in: the overlay passes attach whatever this answers,
	/// and the UI only records stencil work when its own probe agrees, so the two orders have
	/// to stay in step.
	///
	/// Undefined means no stencil support at all, which the overlay UI falls back from to
	/// tessellated fills.
	public static TextureFormat PickStencilFormat(IDevice device)
	{
		let candidates = TextureFormat[3](.Depth24PlusStencil8, .Depth32FloatStencil8, .Stencil8);

		for (let format in candidates)
		{
			var desc = TextureDesc();
			desc.Dimension = .Texture2D;
			desc.Format = format;
			desc.Width = 4;
			desc.Height = 4;
			desc.Depth = 1;
			desc.Usage = .DepthStencil;
			desc.SampleCount = 1;

			if (device.CreateTexture(desc) case .Ok(var probe))
			{
				device.DestroyTexture(ref probe);
				return format;
			}
		}
		return .Undefined;
	}
}
