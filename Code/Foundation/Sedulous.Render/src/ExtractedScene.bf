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

		let bytes = source.Length * sizeof(T);
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
		mSky = .();
		mShadow = .();
	}
}
