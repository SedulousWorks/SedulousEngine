using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Render;

/// The per scene, once per frame, IMMUTABLE snapshot pushed to the renderer.
///
/// Every view of a scene shares it read only, so a scene seen through four cameras is
/// extracted once rather than four times. It carries the renderables, the lights and the
/// environment, all in world space.
class ExtractedScene
{
	private FrameArena mArena = new .() ~ delete _;
	private List<RenderData> mItems = new .() ~ delete _;
	private List<GpuLight> mLights = new .() ~ delete _;
	private List<LocalShadowCaster> mLocalCasters = new .() ~ delete _;
	private List<DecalInstance> mDecals = new .() ~ delete _;
	private List<ReflectionProbe> mProbes = new .() ~ delete _;

	private Float3 mAmbient = .(0.03f, 0.03f, 0.03f);
	/// The world position of the FIRST view that renders this snapshot, set by the render
	/// subsystem before the scene's providers extract: a producer that thins by distance, the
	/// vegetation fade prefix, reads it. One snapshot serves every view of the scene, so a
	/// second view sees the first view's thinning; a per view prefix is a follow on.
	private Float3 mViewOrigin = .(0, 0, 0);
	/// False for a headless extraction, where nothing is thinned.
	private bool mHasViewOrigin = false;
	private float mTimeSeconds = 0.0f;
	private float mPrevTimeSeconds = 0.0f;
	private bool mHasTime = false;
	private SkySnapshot mSky = .();
	private DirectionalShadow mShadow = .();

	/// Allocates a render data type from the arena and registers it in the snapshot.
	///
	/// The arena owns it, so it is never deleted individually: it lives until the reset.
	public T Add<T>() where T : RenderData, new
	{
		let item = new:mArena T();
		if (item != null)
			mItems.Add(item);
		return item;
	}

	/// Copies an array INTO the arena and hands back the frame owned view of it.
	///
	/// For render data that has to be SELF CONTAINED. The snapshot is read at record time,
	/// after arbitrary scene mutations have had their chance, so a pointer into a producer's
	/// own storage is a use after free waiting for the next rebuild. An empty or failed copy
	/// answers an empty span, which a producer treats as an item to skip.
	public Span<T> AddArray<T>(Span<T> source) where T : struct
	{
		if (source.IsEmpty)
			return .();

		// STRIDE, not size: sizeof leaves a struct's tail padding out, and a copy measured by
		// it drops the last element's final bytes, which then read as whatever the arena held.
		let bytes = source.Length * strideof(T);
		let memory = mArena.Allocate(bytes, alignof(T));
		if (memory == null)
			return .();

		Internal.MemCpy(memory, source.Ptr, bytes);
		return .((T*)memory, source.Length);
	}

	/// Adopts render data allocated ELSEWHERE, which must outlive this snapshot's use.
	///
	/// What parallel extraction merges with: each worker fills its own arena, and the merge
	/// adopts the pointers here on one thread.
	public void AddExternal(RenderData data)
	{
		if (data != null)
			mItems.Add(data);
	}

	public void AddLight(GpuLight light) => mLights.Add(light);

	/// Registers a spot or point light as a shadow caster. The shadow system builds its
	/// atlas tile and matrix at frame time and patches the light's own shadow index once the
	/// slot is known.
	public void AddLocalShadowCaster(LocalShadowCaster caster) => mLocalCasters.Add(caster);

	public void AddDecal(DecalInstance decal) => mDecals.Add(decal);
	public void AddReflectionProbe(ReflectionProbe probe) => mProbes.Add(probe);

	/// The flat indirect term, premultiplied by its intensity, applied as a multiple of the
	/// albedo in the forward shading.
	public void SetAmbient(Float3 ambient) => mAmbient = ambient;

	public void SetViewOrigin(Float3 origin)
	{
		mViewOrigin = origin;
		mHasViewOrigin = true;
	}
	public Float3 ViewOrigin => mViewOrigin;
	public bool HasViewOrigin => mHasViewOrigin;

	/// The SCENE's clock, this frame's seconds and last frame's, stamped by the environment
	/// extraction from a clock that accumulates the scene's OWN delta, so the context, group
	/// and scene time scales, and a pause, all reach it: a paused world's grass stands still,
	/// and the editor's Simulate ticks the editing scene, so it sways there.
	///
	/// This is the WIND sway's phase. A snapshot no scene stamped, a probe, has none, and the
	/// frame's own clock stands in.
	public void SetTime(float seconds, float prevSeconds)
	{
		mTimeSeconds = seconds;
		mPrevTimeSeconds = prevSeconds;
		mHasTime = true;
	}
	public float TimeSeconds => mTimeSeconds;
	public float PrevTimeSeconds => mPrevTimeSeconds;
	public bool HasTime => mHasTime;
	public Float3 Ambient => mAmbient;

	public void SetSky(SkySnapshot sky) => mSky = sky;
	public SkySnapshot Sky => mSky;

	public void SetDirectionalShadow(DirectionalShadow shadow) => mShadow = shadow;
	public DirectionalShadow DirectionalShadowData => mShadow;

	public Span<RenderData> Items => .(mItems.Ptr, mItems.Count);
	public Span<GpuLight> Lights => .(mLights.Ptr, mLights.Count);
	public Span<LocalShadowCaster> LocalShadowCasters => .(mLocalCasters.Ptr, mLocalCasters.Count);
	public Span<DecalInstance> Decals => .(mDecals.Ptr, mDecals.Count);
	public Span<ReflectionProbe> ReflectionProbes => .(mProbes.Ptr, mProbes.Count);

	public int Size => mItems.Count;
	public bool IsEmpty => mItems.IsEmpty;

	/// Drops the lists and REWINDS the arena, which keeps its chunks for the next frame.
	public void Reset()
	{
		mItems.Clear();
		mLights.Clear();
		mLocalCasters.Clear();
		mDecals.Clear();
		mProbes.Clear();
		mArena.Reset();

		mAmbient = .(0.03f, 0.03f, 0.03f);
		mViewOrigin = .(0, 0, 0);
		mHasViewOrigin = false;
		mTimeSeconds = 0.0f;
		mPrevTimeSeconds = 0.0f;
		mHasTime = false;
		mSky = .();
		mShadow = .();
	}
}
