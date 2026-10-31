using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Materials;

/// A per use copy of a material's properties, with overrides and dirty tracking.
///
/// A setter writes into the override buffer and flips a dirty flag. On the false to true
/// TRANSITION it notifies its sink, so the system's per frame work is proportional to what
/// actually changed rather than to how many instances exist.
///
/// THE MATERIAL IS BORROWED, and that has a consequence a renderer has to answer for.
///
/// An instance holding a reference counted material would get two things for free: an
/// instance cache keyed by material uid could prune an entry once the material's count
/// drops to one, meaning only the cache still holds it; and the same strong reference
/// would keep a RELOADED-AWAY material alive until that prune runs, so bind groups
/// pointing at the old texture views retire on schedule instead of dangling.
///
/// Here the material is a resource the manager owns and the handle is what survives a
/// reload, so neither of those falls out for free. A renderer built on this owes two
/// things:
///
/// - A different STALE signal. Comparing the cached uid against the handle's current
///   product is the direct replacement: a reload mints a new uid, so a mismatch is the
///   cue to rebuild rather than a reference count reaching one.
/// - An ORDERING guarantee. The manager must not free the old product until the frame's
///   prune has run DetachBindGroup and DetachUniformBuffer and handed both to deferred
///   retirement. Detaching only the bind group is not enough: the buffer's memory is still
///   bound, which is what a validating backend reports on every material hot reload.
///
/// Nothing consumes this yet, so nothing is wrong today. It is written down here because
/// the alternative is finding it out when the renderer lands.
class MaterialInstance
{
	private Material mMaterial;
	private IMaterialInstanceSink mSink;

	private List<uint8> mUniformData = new .() ~ delete _;
	private Dictionary<int, ITextureView> mTextures = new .() ~ delete _;
	private Dictionary<int, ISampler> mSamplers = new .() ~ delete _;
	private PropertyOverrideMask mOverrides = .();
	/// The values per effect group this instance draws with (its overrides over the material's).
	private List<List<uint8>> mEffectData = new .() ~ DeleteContainerAndItems!(_);

	private IBindGroupLayout mBindGroupLayout;

	// Both start dirty: an instance that has never been prepared has nothing on the GPU,
	// which is exactly what dirty means.
	private bool mUniformDirty = true;
	private bool mBindGroupDirty = true;
	private bool mInDirtyList = false;

	public this(Material material)
	{
		mMaterial = material;
		if (material == null)
			return;
		// Each effect group's values, which this instance may override apart from the shader's
		// buffer (`Wind.Strength`).
		for (let group in material.EffectGroups)
			mEffectData.Add(new List<uint8>()..AddRange(group.Defaults));
		if (material.UniformDataSize == 0)
			return;

		// Seeded from the material's defaults, so an instance that overrides nothing still
		// draws what the material says it should.
		mUniformData.Resize((int)material.UniformDataSize);
		let defaults = material.DefaultUniformData;
		for (int i = 0; (i < defaults.Length) && (i < mUniformData.Count); i++)
			mUniformData[i] = defaults[i];
	}

	public ~this()
	{
		if (mSink != null)
			mSink.ReleaseInstance(this);
	}

	public Material Material => mMaterial;

	// ---- setters ----

	public void SetFloat(StringView name, float value) => WriteUniform(name, value);
	public void SetFloat2(StringView name, Float2 value) => WriteUniform(name, value);
	public void SetFloat3(StringView name, Float3 value) => WriteUniform(name, value);
	public void SetFloat4(StringView name, Float4 value) => WriteUniform(name, value);
	public void SetColor(StringView name, Float4 color) => SetFloat4(name, color);

	public void SetTexture(StringView name, ITextureView texture)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if ((index < 0) || !mMaterial.GetProperty(index).IsTexture)
			return;

		mTextures[index] = texture;
		mOverrides.Set(index);
		SetBindGroupDirty();
	}

	public void SetSampler(StringView name, ISampler sampler)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if ((index < 0) || !mMaterial.GetProperty(index).IsSampler)
			return;

		mSamplers[index] = sampler;
		mOverrides.Set(index);
		SetBindGroupDirty();
	}

	// ---- effective values: the override, else the material's default ----

	public ITextureView GetTexture(int propertyIndex)
	{
		if (mOverrides.IsSet(propertyIndex) && mTextures.TryGetValue(propertyIndex, let texture))
			return texture;
		return mMaterial.GetDefaultTexture(propertyIndex);
	}

	public ISampler GetSampler(int propertyIndex)
	{
		if (mOverrides.IsSet(propertyIndex) && mSamplers.TryGetValue(propertyIndex, let sampler))
			return sampler;
		return mMaterial.GetDefaultSampler(propertyIndex);
	}

	/// The instance's own buffer, or the material's defaults when it has none: a material
	/// with no uniforms gives every instance an empty one, and there is nothing to copy.
	public Span<uint8> UniformData
		=> !mUniformData.IsEmpty ? mUniformData : mMaterial.DefaultUniformData;

	public bool IsOverridden(int propertyIndex) => mOverrides.IsSet(propertyIndex);

	/// The values of the material's effect group `groupIndex` this instance draws with (its
	/// overrides over the material's).
	public Span<uint8> EffectData(int groupIndex)
	{
		if (groupIndex < mEffectData.Count)
			return mEffectData[groupIndex];
		if (groupIndex < mMaterial.EffectGroupCount)
			return mMaterial.GetEffectGroup(groupIndex).Defaults;
		return default;
	}

	/// Every effect group back to the material's values.
	public void ResetEffects()
	{
		var changed = false;
		for (int g = 0; (g < mEffectData.Count) && (g < mMaterial.EffectGroupCount); g++)
		{
			let defaults = mMaterial.GetEffectGroup(g).Defaults;
			if ((mEffectData[g].Count == defaults.Count) && (defaults.Count > 0))
			{
				Internal.MemCpy(mEffectData[g].Ptr, defaults.Ptr, defaults.Count);
				changed = true;
			}
		}
		if (changed)
			SetUniformDirty();
	}

	/// Drops one override, so the property reads the material's default again.
	public void ResetProperty(StringView name)
	{
		if (mMaterial.FindEffectProperty(name, let effect, let group))
		{
			let defaults = mMaterial.GetEffectGroup(group).Defaults;
			if ((group < mEffectData.Count) && ((int)(effect.Offset + effect.Size) <= mEffectData[group].Count)
				&& ((int)(effect.Offset + effect.Size) <= defaults.Count))
			{
				Internal.MemCpy(mEffectData[group].Ptr + effect.Offset, defaults.Ptr + effect.Offset, (int)effect.Size);
				SetUniformDirty();
			}
			return;
		}
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0)
			return;

		let def = mMaterial.GetProperty(index);
		if (def.IsUniform && (mUniformData.Count >= (int)(def.Offset + def.Size)))
		{
			let defaults = mMaterial.DefaultUniformData;
			if (defaults.Length >= (int)(def.Offset + def.Size))
			{
				Internal.MemCpy(mUniformData.Ptr + def.Offset, defaults.Ptr + def.Offset,
					(int)def.Size);
			}
			SetUniformDirty();
		}
		else if (def.IsTexture)
		{
			mTextures.Remove(index);
			SetBindGroupDirty();
		}
		else if (def.IsSampler)
		{
			mSamplers.Remove(index);
			SetBindGroupDirty();
		}

		mOverrides.Clear(index);
	}

	// ---- dirty state, driven by the material system ----

	public bool IsUniformDirty => mUniformDirty;
	public bool IsBindGroupDirty => mBindGroupDirty;
	public void ClearUniformDirty() => mUniformDirty = false;
	public void ClearBindGroupDirty() => mBindGroupDirty = false;
	public void MarkUniformDirty() => SetUniformDirty();
	public void MarkBindGroupDirty() => SetBindGroupDirty();

	// ---- wiring, used only by the material system ----

	public void SetSink(IMaterialInstanceSink sink) => mSink = sink;
	public bool IsInDirtyList => mInDirtyList;
	public void SetInDirtyList(bool value) => mInDirtyList = value;

	/// The layout the system inferred, which pipeline creation needs.
	public IBindGroupLayout BindGroupLayout => mBindGroupLayout;
	public void SetBindGroupLayout(IBindGroupLayout layout) => mBindGroupLayout = layout;

	private void WriteUniform<T>(StringView name, T value) where T : struct
	{
		// `Effect.Property`: a value of an effect group, in its own buffer.
		if (mMaterial.FindEffectProperty(name, let effect, let group))
		{
			if ((group < mEffectData.Count) && ((uint32)sizeof(T) <= effect.Size)
				&& ((int)effect.Offset + sizeof(T) <= mEffectData[group].Count))
			{
				var local = value;
				Internal.MemCpy(mEffectData[group].Ptr + effect.Offset, &local, sizeof(T));
				SetUniformDirty();
			}
			return;
		}
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0)
			return;

		let def = mMaterial.GetProperty(index);
		// Never wider than the property: a Float4 written to a float would spill into the next.
		if (!def.IsUniform || ((uint32)sizeof(T) > def.Size)
			|| (mUniformData.Count < (int)def.Offset + sizeof(T)))
			return;

		var local = value;
		Internal.MemCpy(mUniformData.Ptr + def.Offset, &local, sizeof(T));
		mOverrides.Set(index);
		SetUniformDirty();
	}

	/// The notification is on the TRANSITION, and only while the instance is not already
	/// queued: a setter called a hundred times in a frame must not enqueue it a hundred
	/// times.
	private void SetUniformDirty()
	{
		if (mUniformDirty)
			return;
		mUniformDirty = true;
		if (!mInDirtyList && (mSink != null))
			mSink.MarkInstanceDirty(this);
	}

	private void SetBindGroupDirty()
	{
		if (mBindGroupDirty)
			return;
		mBindGroupDirty = true;
		if (!mInDirtyList && (mSink != null))
			mSink.MarkInstanceDirty(this);
	}
}
