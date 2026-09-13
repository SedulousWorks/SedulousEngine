using Sedulous.RHI;
using Sedulous.VG.Renderer;

namespace Sedulous.Engine.UI;

/// A vector renderer built for ONE target configuration.
///
/// A pipeline has to match the pass it is used in, so the format, whether the pass carries a
/// stencil attachment, and the sample count are all part of the key rather than something one
/// renderer can vary at draw time.
class UIFormatRenderer
{
	public TextureFormat Format = .RGBA8Unorm;
	public bool Stencil = false;
	public uint32 SampleCount = 1;
	public VGRenderer Renderer = null ~ delete _;

	/// The last UI frame this renderer's rings were rewound for.
	public uint64 BegunSerial = 0;
}
