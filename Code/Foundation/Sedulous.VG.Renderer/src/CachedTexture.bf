using System.Collections;
using Sedulous.Image;
using Sedulous.RHI;

namespace Sedulous.VG.Renderer;

/// One source image's GPU side.
class CachedTexture
{
	/// The identity key. NEVER dereferenced by the cache's own bookkeeping: by the time a
	/// batch names an evicted source, the object may already be gone.
	public ImageData Source;

	/// The source's instance id, which is what guards against ADDRESS REUSE: a deleted
	/// image and a new one at the same address are the same reference and different ids.
	public uint64 SourceId = 0;

	public ITexture GpuTexture;
	public ITextureView View;

	/// Per frame and per spread, indexed as frame times the spread count plus the spread.
	/// The spread picks the sampler, and the sampler lives in the bind group.
	public List<IBindGroup> BindGroups = new .() ~ delete _;

	/// The view is CALLER OWNED, such as a viewport's render target, and is never
	/// destroyed here.
	public bool External = false;
}
