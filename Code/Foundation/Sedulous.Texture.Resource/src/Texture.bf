using System.Threading;
using Sedulous.RHI;

namespace Sedulous.Texture.Resource;

/// The runtime product: a live GPU texture, its default view, and its sampler.
///
/// What a material or a renderer binds. It owns the three handles and destroys them
/// through the device it was built on.
class Texture
{
	private static int64 sNextUid;

	private IDevice mDevice;
	private ITexture mTexture;
	private ITextureView mView;
	private ISampler mSampler;

	private uint32 mWidth;
	private uint32 mHeight;
	private TextureFormat mFormat = .RGBA8Unorm;
	private bool mIsCube;
	private uint64 mUid;

	public ~this()
	{
		if (mDevice == null)
			return;

		// The view first: it refers to the texture, and a backend that validates would
		// object to outliving it.
		if (mView != null)
			mDevice.DestroyTextureView(ref mView);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mTexture != null)
			mDevice.DestroyTexture(ref mTexture);
	}

	/// Takes ownership of the three handles. The DEVICE is borrowed and must outlive this.
	public void Adopt(IDevice device, ITexture texture, ITextureView view, ISampler sampler,
		uint32 width, uint32 height, TextureFormat format, bool isCube = false)
	{
		mDevice = device;
		mTexture = texture;
		mView = view;
		mSampler = sampler;
		mWidth = width;
		mHeight = height;
		mFormat = format;
		mIsCube = isCube;
		mUid = (uint64)Interlocked.Increment(ref sNextUid);
	}

	/// A monotonic identity, minted per adoption.
	///
	/// A cache or a dirty check keys on THIS, never on the reference: a reload frees the
	/// old product and the allocator can hand the new one the same address, at which point
	/// a pointer keyed cache quietly serves the dead texture.
	public uint64 Uid => mUid;

	/// True when the default view is a cube, so a consumer knows it can sample it as one.
	public bool IsCube => mIsCube;

	public ITexture GpuTexture => mTexture;
	/// The default sampled view, spanning every mip and layer.
	public ITextureView View => mView;
	public ISampler Sampler => mSampler;

	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public TextureFormat Format => mFormat;
}
