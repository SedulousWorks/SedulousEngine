namespace Sedulous.Engine.Render;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;

/// Per-probe GPU resources for cubemap capture and IBL processing.
class ProbeGPUData
{
	/// Captured scene cubemap (6 faces, RGBA16Float)
	public ITexture CaptureCubemap;
	public ITextureView CaptureCubemapView; // TextureCube view for sampling
	public ITextureView[6] CaptureFaceViews; // Texture2D views for rendering

	/// Probe needs recapture
	public bool Dirty = true;

	/// The entity this probe belongs to (for world position lookup)
	public EntityHandle Owner = .Invalid;

	/// Cached probe settings
	public uint16 Resolution;
	public float InfluenceRadius;
	public float Intensity;
	public float NearClip;
	public float FarClip;

	public void Release(IDevice device)
	{
		for (int i = 0; i < 6; i++)
			if (CaptureFaceViews[i] != null) device.DestroyTextureView(ref CaptureFaceViews[i]);
		if (CaptureCubemapView != null) device.DestroyTextureView(ref CaptureCubemapView);
		if (CaptureCubemap != null) device.DestroyTexture(ref CaptureCubemap);
	}
}

/// Manages reflection probe components and their GPU resources.
/// Injected into scenes by RenderSubsystem via ISceneAware.
class ReflectionProbeComponentManager : ComponentManager<ReflectionProbeComponent>
{
	public override StringView SerializationTypeId => "Sedulous.ReflectionProbeComponent";

	private IDevice mDevice;
	private List<ProbeGPUData> mProbeData = new .() ~ { for (let d in _) { d.Release(mDevice); delete d; } delete _; };

	/// Set by RenderSubsystem after creation.
	public IDevice Device { get => mDevice; set => mDevice = value; }

	/// Active probe GPU data for capture and rendering.
	public List<ProbeGPUData> ProbeData => mProbeData;

	/// Depth texture shared by all probe captures (sized to max probe resolution).
	private ITexture mProbeDepth ~ { if (_ != null) mDevice?.DestroyTexture(ref _); };
	private ITextureView mProbeDepthView ~ { if (_ != null) mDevice?.DestroyTextureView(ref _); };
	private uint32 mProbeDepthSize = 0;

	public ITextureView ProbeDepthView => mProbeDepthView;

	protected override void OnComponentInitialized(ReflectionProbeComponent comp)
	{
		base.OnComponentInitialized(comp);
		if (mDevice == null) return;

		let gpuData = new ProbeGPUData();
		gpuData.Owner = comp.Owner;
		gpuData.Resolution = comp.CaptureResolution;
		gpuData.InfluenceRadius = comp.InfluenceRadius;
		gpuData.Intensity = comp.Intensity;
		gpuData.NearClip = comp.NearClip;
		gpuData.FarClip = comp.FarClip;
		gpuData.Dirty = true;

		if (CreateProbeTextures(gpuData) case .Err)
		{
			delete gpuData;
			return;
		}

		EnsureProbeDepth(gpuData.Resolution);
		mProbeData.Add(gpuData);
	}

	protected override void OnComponentDestroyed(ReflectionProbeComponent comp)
	{
		// Find and remove the probe data for this entity
		for (int i = 0; i < mProbeData.Count; i++)
		{
			if (mProbeData[i].Owner == comp.Owner)
			{
				let data = mProbeData[i];
				data.Release(mDevice);
				delete data;
				mProbeData.RemoveAt(i);
				break;
			}
		}
		base.OnComponentDestroyed(comp);
	}

	/// Cubemap face view/projection matrices for probe capture.
	/// View matrices are constructed manually (not via CreateLookAt) to match
	/// the cubemap face UV convention used by CubeUVToDirection in our shaders.
	/// This produces left-handed view matrices — the caller must flip cull mode
	/// (use Front instead of Back) to compensate.
	public static void GetCubeFaceCamera(Vector3 position, int faceIndex, float nearClip, float farClip,
		out Matrix viewMatrix, out Matrix projMatrix)
	{
		// Each face's basis vectors are derived from the CubeUVToDirection mapping:
		//   viewDir = ndc_x * right + ndc_y * up + forward
		// must equal the cubemap convention direction for that face.
		Vector3 right = .Zero;
		Vector3 up = .Zero;
		Vector3 forward = .Zero;
		switch (faceIndex)
		{
		case 0: right = .(0, 0,-1); up = .(0, 1, 0); forward = .( 1, 0, 0); // +X
		case 1: right = .(0, 0, 1); up = .(0, 1, 0); forward = .(-1, 0, 0); // -X
		case 2: right = .(1, 0, 0); up = .(0, 0,-1); forward = .( 0, 1, 0); // +Y
		case 3: right = .(1, 0, 0); up = .(0, 0, 1); forward = .( 0,-1, 0); // -Y
		case 4: right = .(1, 0, 0); up = .(0, 1, 0); forward = .( 0, 0, 1); // +Z
		case 5: right = .(-1,0, 0); up = .(0, 1, 0); forward = .( 0, 0,-1); // -Z
		}

		viewMatrix = BuildCubeViewMatrix(right, up, forward, position);

		// 90° FOV, 1:1 aspect ratio — no projection flip needed
		projMatrix = Matrix.CreatePerspectiveFieldOfView(Math.PI_f * 0.5f, 1.0f, nearClip, farClip);
	}

	/// Builds an XNA-style view matrix from explicit basis vectors.
	/// zAxis = -forward (XNA convention: camera looks down -Z in view space).
	private static Matrix BuildCubeViewMatrix(Vector3 right, Vector3 up, Vector3 forward, Vector3 pos)
	{
		let zAxis = -forward;
		Matrix m = .Identity;
		m.M11 = right.X;  m.M12 = up.X;  m.M13 = zAxis.X;
		m.M21 = right.Y;  m.M22 = up.Y;  m.M23 = zAxis.Y;
		m.M31 = right.Z;  m.M32 = up.Z;  m.M33 = zAxis.Z;
		m.M41 = -Vector3.Dot(right, pos);
		m.M42 = -Vector3.Dot(up, pos);
		m.M43 = -Vector3.Dot(zAxis, pos);
		return m;
	}

	// ==================== Internal ====================

	private Result<void> CreateProbeTextures(ProbeGPUData data)
	{
		let size = (uint32)data.Resolution;

		let desc = TextureDesc.Cube(.RGBA16Float, size, .Sampled | .RenderTarget,
			label: "Reflection Probe Cubemap");

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
			data.CaptureCubemap = tex;
		else
			return .Err;

		// Cubemap view for sampling
		if (mDevice.CreateTextureView(data.CaptureCubemap, .()
		{
			Format = .RGBA16Float, Dimension = .TextureCube,
			BaseArrayLayer = 0, ArrayLayerCount = 6,
			Label = "Probe Cubemap View"
		}) case .Ok(let cubeView))
			data.CaptureCubemapView = cubeView;
		else
			return .Err;

		// Per-face views for rendering as color attachments
		for (uint32 face = 0; face < 6; face++)
		{
			if (mDevice.CreateTextureView(data.CaptureCubemap, .()
			{
				Format = .RGBA16Float, Dimension = .Texture2D,
				BaseArrayLayer = face, ArrayLayerCount = 1,
				Label = "Probe Face"
			}) case .Ok(let faceView))
				data.CaptureFaceViews[face] = faceView;
			else
				return .Err;
		}

		return .Ok;
	}

	/// Ensure the shared probe depth texture is at least `size` pixels.
	private void EnsureProbeDepth(uint16 size)
	{
		let s = (uint32)size;
		if (s <= mProbeDepthSize) return;

		// Destroy old
		if (mProbeDepthView != null) mDevice.DestroyTextureView(ref mProbeDepthView);
		if (mProbeDepth != null) mDevice.DestroyTexture(ref mProbeDepth);

		let desc = TextureDesc.DepthBuffer(Pipeline.DepthFormat, s, s, label: "Probe Depth");

		if (mDevice.CreateTexture(desc) case .Ok(let tex))
		{
			mProbeDepth = tex;
			if (mDevice.CreateTextureView(tex, .() { Format = Pipeline.DepthFormat, Dimension = .Texture2D }) case .Ok(let view))
			{
				mProbeDepthView = view;
				mProbeDepthSize = s;
			}
		}
	}

}
