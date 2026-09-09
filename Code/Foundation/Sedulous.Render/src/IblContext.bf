using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;

namespace Sedulous.Render;

/// ONE SCENE's image based lighting products, and the sky state they were built from.
///
/// A frame can render several scenes side by side, each with its own authored sky, so the
/// products are pooled by scene identity rather than held once on the system. Every view binds
/// its own scene's.
///
/// The fields are owned by the image based lighting system, which creates, rebuilds and
/// evicts them; a consumer reads the products and the handles.
class IblContext
{
	/// The scene this belongs to, which is the pool's key. Borrowed, and compared by identity.
	public Object Scene = null;
	/// Stamped at creation and never reused, so a cache that keys on the environment view can
	/// pair the two and notice an address that came back around after an eviction.
	public uint64 Uid = 0;
	public uint64 LastUsedFrame = 0;

	/// The source radiance, whose first level is written from the scene's sky and whose
	/// remaining levels are box downsampled for the prefilter to sample.
	public ITexture EnvCube = null;
	public ITextureView EnvView = null;
	/// One single level view of each environment level, bound as the source when writing the
	/// next: the read then covers only that level, never the one being written.
	public ITextureView[IBLSystem.cEnvMips] EnvMipViews;

	/// The prefiltered specular, one level per roughness.
	public ITexture PrefilterCube = null;
	public ITextureView PrefilterView = null;
	/// The nine spherical harmonic coefficients of the diffuse irradiance.
	public IBuffer ShBuffer = null;

	public IBindGroup EnvBindGroup = null;
	public IBindGroup[IBLSystem.cEnvMips] EnvMipBindGroups;
	public IBindGroup ShBindGroup = null;

	/// Groups over the scene's OWN sky texture, which the context does not own.
	public IBindGroup ExternalEquirectBindGroup = null;
	public IBindGroup ExternalCubeBindGroup = null;
	public uint64 ExternalUid = 0;

	public ResourceState EnvState = .Undefined;
	public ResourceState PrefilterState = .Undefined;

	/// This frame's handles, valid once prepared. The forward reads them, so the graph orders
	/// any rebuild before the shading and puts the barriers in.
	public RGHandle PrefilterHandle = default;
	public RGHandle ShHandle = default;
	public RGHandle EnvHandle = default;

	public SkySnapshot Sky = .();
	public Float3 SunDir = .(0.0f, -1.0f, 0.0f);
	public bool Dirty = true;

	/// The startup rebake window. The cube is a one shot bake, but a frame's submission can be
	/// dropped during startup, and the web's swapchain texture expiring before the browser
	/// gets to it is the usual way. Rebaking for the first frames guarantees the cube lands on
	/// a frame that survives, rather than being lost forever to one bad one.
	public uint32 BakeWarmup = 20;

	/// From ONE system wide counter, so a value never collides across contexts and a
	/// downstream cache can key on it alone.
	public uint64 Generation = 0;
	/// The tick of the last programmatic source change this context saw.
	public uint64 SourceStamp = 0;

	/// The sky pass draws a crisp analytic disc for the untextured skies. A textured
	/// environment carries its own sun, so drawing one over it would double it.
	public bool HasSunDisc => (Sky.Mode != .HDREquirect) && (Sky.Mode != .Cubemap);
}
