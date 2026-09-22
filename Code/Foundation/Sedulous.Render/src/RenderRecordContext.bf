using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Render;

/// Everything a renderer needs to record one view's draws.
///
/// The encoder is a RECORDING SURFACE rather than a live pass, so a renderer records
/// identically whether it is writing into a pass or into an off thread bundle. That is what
/// makes parallel command recording possible without a second code path.
struct RenderRecordContext
{
	public RenderView View = null;
	public IRenderCommandEncoder Pass = null;

	public Float4x4 ViewProj = .Identity();
	/// Last frame's, which is what camera motion vectors are the difference of.
	public Float4x4 PrevViewProj = .Identity();

	/// This frame's sub pixel jitter, and last frame's, which the reprojection has to undo
	/// before it compares the two.
	public Float2 Jitter = .(0, 0);
	public Float2 PrevJitter = .(0, 0);

	/// For view space depth, which the clustered shading slices by.
	public Float4x4 ViewMatrix = .Identity();
	public Float3 CameraPos = .(0, 0, 0);
	public Float3 Ambient = .(0.03f, 0.03f, 0.03f);

	public ShadowCascades Cascades = .();
	/// This view's first layer of the shared cascade array.
	public uint32 CascadeLayerBase = 0;
	/// This view's SCENE's first local shadow entry.
	public uint32 LocalShadowEntryBase = 0;

	public uint32 ProbeBase = 0;
	public uint32 ProbeCount = 0;

	/// This view's SCENE's own products.
	public IblBinding Ibl = .();
	public Span<GpuLight> Lights = default;
	/// Empty means clustering is off.
	public ClusterBinding Cluster = .();

	public uint32 FrameIndex = 0;
	/// This view's index within the frame, which selects its per view buffer slots.
	public uint32 ViewIndex = 0;

	public TextureFormat ColorFormat = .BGRA8Unorm;
	public TextureFormat DepthFormat = .Depth32Float;

	/// The sample count of the pass being recorded.
	///
	/// The OPAQUE passes take the view's count, so their pipelines and bundles match the
	/// multisampled attachments; the transparent pass and every post effect stay at one,
	/// since they run on the resolved image.
	public uint8 SampleCount = 1;

	/// The opaque scene depth as something SAMPLEABLE, on the transparent pass only. Already
	/// in the read layout from the read only depth attachment, so a renderer can sample it:
	/// what soft particles fade against.
	public ITextureView SceneDepthView = null;

	/// The camera's depth only prepass, which applies NO depth bias so it matches the forward
	/// pass exactly.
	public bool DepthPrepass = false;
	/// False while capturing a probe: the capture reflects the sky rather than the probe, or
	/// a probe would reflect itself into black.
	public bool ProbesEnabled = true;
	/// False when no temporal effect consumes velocity, which lets the resolve skip the per
	/// instance previous transform lookup entirely.
	public bool NeedsMotion = true;
	/// The camera prepass builds the FULL instance data and caches each group's range, so the
	/// forward pass reuses it rather than building it a second time.
	public bool FillInstanceCache = false;

	/// How wide, in world units, the last cascade dissolves its shadows over.
	public float ShadowFarFade = 40.0f;

	/// The editor's semantic debug mode: the forward pass outputs that term instead of the
	/// lit result.
	public uint8 DebugSemantic = 0;

	/// The sky's lighting dimmers, which scale the image based terms without touching the
	/// visible sky.
	public float IblDiffuseIntensity = 1.0f;
	public float IblSpecularIntensity = 1.0f;

	/// The frame's clock in seconds, which is the WIND sway's phase, and last frame's, which
	/// the previous position sways by so the motion vectors follow.
	public float TimeSeconds = 0.0f;
	public float PrevTimeSeconds = 0.0f;

	public this() {}
}
