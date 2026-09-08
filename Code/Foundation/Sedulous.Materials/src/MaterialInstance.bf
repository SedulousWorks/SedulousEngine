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
/// The material is BORROWED. Raptor's instance holds a reference counted pointer, which
/// keeps a reloaded-away material alive underneath it; here the material is a resource the
/// manager owns, and its handle is what survives a reload. So an instance must not outlive
/// the material it was made from.
class MaterialInstance
{
	private Material mMaterial;
	private IMaterialInstanceSink mSink;

	private List<uint8> mUniformData = new .() ~ delete _;
	private Dictionary<int, ITextureView> mTextures = new .() ~ delete _;
	private Dictionary<int, ISampler> mSamplers = new .() ~ delete _;
	private PropertyOverrideMask mOverrides = .();

	private IBindGroupLayout mBindGroupLayout;

	// Both start dirty: an instance that has never been prepared has nothing on the GPU,
	// which is exactly what dirty means.
	private bool mUniformDirty = true;
	private bool mBindGroupDirty = true;
	private bool mInDirtyList = false;

	public this(Material material)
	{
		mMaterial = material;
		if ((material == null) || (material.UniformDataSize == 0))
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

	/// Drops one override, so the property reads the material's default again.
	public void ResetProperty(StringView name)
	{
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
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0)
			return;

		let def = mMaterial.GetProperty(index);
		if (!def.IsUniform || (mUniformData.Count < (int)def.Offset + sizeof(T)))
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
