namespace Sedulous.Materials;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// Tracks which properties have been overridden in a material instance.
struct PropertyOverrideMask
{
	private uint64 mMask0;
	private uint64 mMask1;

	public void Set(int index) mut
	{
		if (index < 64)
			mMask0 |= (1UL << index);
		else if (index < 128)
			mMask1 |= (1UL << (index - 64));
	}

	public void Clear(int index) mut
	{
		if (index < 64)
			mMask0 &= ~(1UL << index);
		else if (index < 128)
			mMask1 &= ~(1UL << (index - 64));
	}

	public bool IsSet(int index)
	{
		if (index < 64)
			return (mMask0 & (1UL << index)) != 0;
		else if (index < 128)
			return (mMask1 & (1UL << (index - 64))) != 0;
		return false;
	}

	public void Reset() mut
	{
		mMask0 = 0;
		mMask1 = 0;
	}

	public bool HasAnyOverrides => mMask0 != 0 || mMask1 != 0;
}

/// Instance of a material with overridable properties.
/// Tracks dirty state for efficient GPU buffer updates.
class MaterialInstance : RefCounted, IDisposable
{
	/// The base material (not owned).
	private Material mMaterial;

	/// Material system that manages this instance's GPU resources (bind group, uniform buffer).
	/// Set by MaterialSystem.PrepareInstance. Used in destructor for cleanup.
	private MaterialSystem mMaterialSystem;

	/// Override uniform data (null = use material defaults).
	private uint8[] mUniformData ~ delete _;

	/// Override textures by property index.
	private Dictionary<int, ITextureView> mTextures = new .() ~ delete _;

	/// Override samplers by property index.
	private Dictionary<int, ISampler> mSamplers = new .() ~ delete _;

	/// Which properties are overridden.
	private PropertyOverrideMask mOverrideMask;

	/// Whether uniform data needs GPU upload.
	private bool mUniformDirty = true;

	/// Whether bind group needs recreation.
	private bool mBindGroupDirty = true;

	/// True while this instance is in MaterialSystem.mDirtyInstances. Gates
	/// the notify-on-dirty path so we enqueue at most once per dirty cycle.
	/// Cleared by MaterialSystem.PrepareDirtyInstances after the drain.
	private bool mInDirtyList;

	/// GPU bind group for this material instance.
	private IBindGroup mBindGroup;

	/// GPU bind group layout (set when bind group is created by MaterialSystem).
	private IBindGroupLayout mBindGroupLayout;

	/// Blend mode for rendering.
	private BlendMode mBlendMode = .Opaque;

	/// The base material.
	public Material Material => mMaterial;

	/// Gets the vertex layout type from the material's pipeline config.
	public VertexLayoutType VertexLayout => mMaterial?.PipelineConfig.VertexLayout ?? .Mesh;

	/// Gets or sets the GPU bind group layout.
	public IBindGroupLayout BindGroupLayout
	{
		get => mBindGroupLayout;
		set => mBindGroupLayout = value;
	}

	/// Gets or sets the GPU bind group.
	public IBindGroup BindGroup
	{
		get => mBindGroup;
		set
		{
			//if (mBindGroup != null)
			//	delete mBindGroup;
			mBindGroup = value;
		}
	}

	/// Gets or sets the blend mode for transparent rendering.
	public BlendMode BlendMode
	{
		get => mBlendMode;
		set => mBlendMode = value;
	}

	/// Whether uniform data is dirty.
	public bool IsUniformDirty => mUniformDirty;

	/// Whether bind group is dirty.
	public bool IsBindGroupDirty => mBindGroupDirty;

	/// Whether this instance is currently queued in MaterialSystem's
	/// dirty list. Used by MaterialSystem to dedupe enqueues.
	public bool IsInDirtyList => mInDirtyList;

	/// Sets the in-dirty-list flag. Called only by MaterialSystem.
	public void SetInDirtyList(bool value)
	{
		mInDirtyList = value;
	}

	/// Sets the material system reference. Called by MaterialSystem.PrepareInstance.
	public void SetMaterialSystem(MaterialSystem system)
	{
		mMaterialSystem = system;
	}

	/// Marks uniform data dirty and notifies the material system. Internal
	/// helper - all uniform-mutating paths route through here so the
	/// notify happens exactly once per (false -> true) transition.
	private void SetUniformDirty()
	{
		if (mUniformDirty) return;
		mUniformDirty = true;
		if (!mInDirtyList && mMaterialSystem != null)
			mMaterialSystem.MarkInstanceDirty(this);
	}

	/// Marks bind group dirty and notifies the material system. Internal
	/// helper - all bind-group-mutating paths route through here.
	private void SetBindGroupDirty()
	{
		if (mBindGroupDirty) return;
		mBindGroupDirty = true;
		if (!mInDirtyList && mMaterialSystem != null)
			mMaterialSystem.MarkInstanceDirty(this);
	}

	public ~this()
	{
		// Clean up GPU resources (bind group, uniform buffer) via the material system
		if (mMaterialSystem != null)
			mMaterialSystem.ReleaseInstance(this);
	}

	/// Creates a material instance from a material.
	public this(Material material)
	{
		mMaterial = material;
		mBlendMode = material.PipelineConfig.BlendMode;

		// Allocate override buffer if material has uniforms
		if (material.UniformDataSize > 0)
		{
			mUniformData = new uint8[material.UniformDataSize];
			// Copy defaults
			let defaults = material.DefaultUniformData;
			if (defaults.Length > 0)
				Internal.MemCpy(mUniformData.Ptr, defaults.Ptr, defaults.Length);
		}
	}

	/// Sets a float property.
	public void SetFloat(StringView name, float value)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);
		if (prop.IsUniform && mUniformData != null)
		{
			*(float*)(&mUniformData[prop.Offset]) = value;
			mOverrideMask.Set(index);
			SetUniformDirty();
		}
	}

	/// Sets a float2 property.
	public void SetFloat2(StringView name, Vector2 value)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);
		if (prop.IsUniform && mUniformData != null)
		{
			*(Vector2*)(&mUniformData[prop.Offset]) = value;
			mOverrideMask.Set(index);
			SetUniformDirty();
		}
	}

	/// Sets a float3 property.
	public void SetFloat3(StringView name, Vector3 value)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);
		if (prop.IsUniform && mUniformData != null)
		{
			*(Vector3*)(&mUniformData[prop.Offset]) = value;
			mOverrideMask.Set(index);
			SetUniformDirty();
		}
	}

	/// Sets a float4 property.
	public void SetFloat4(StringView name, Vector4 value)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);
		if (prop.IsUniform && mUniformData != null)
		{
			*(Vector4*)(&mUniformData[prop.Offset]) = value;
			mOverrideMask.Set(index);
			SetUniformDirty();
		}
	}

	/// Sets a color property (alias for float4).
	public void SetColor(StringView name, Vector4 color)
	{
		SetFloat4(name, color);
	}

	/// Sets a texture property.
	public void SetTexture(StringView name, ITextureView texture)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);
		if (prop.IsTexture)
		{
			mTextures[index] = texture;
			mOverrideMask.Set(index);
			SetBindGroupDirty();
		}
	}

	/// Sets a sampler property.
	public void SetSampler(StringView name, ISampler sampler)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);
		if (prop.IsSampler)
		{
			mSamplers[index] = sampler;
			mOverrideMask.Set(index);
			SetBindGroupDirty();
		}
	}

	/// Gets the effective texture for a property (override or default).
	public ITextureView GetTexture(int propertyIndex)
	{
		if (mOverrideMask.IsSet(propertyIndex))
		{
			if (mTextures.TryGetValue(propertyIndex, let texture))
				return texture;
		}
		return mMaterial.GetDefaultTexture(propertyIndex);
	}

	/// Gets the effective sampler for a property (override or default).
	public ISampler GetSampler(int propertyIndex)
	{
		if (mOverrideMask.IsSet(propertyIndex))
		{
			if (mSamplers.TryGetValue(propertyIndex, let sampler))
				return sampler;
		}
		return mMaterial.GetDefaultSampler(propertyIndex);
	}

	/// Gets the uniform data span.
	public Span<uint8> UniformData => mUniformData != null ? Span<uint8>(mUniformData) : mMaterial.DefaultUniformData;

	/// Resets a property to the material default.
	public void ResetProperty(StringView name)
	{
		let index = mMaterial.GetPropertyIndex(name);
		if (index < 0) return;

		let prop = mMaterial.GetProperty(index);

		if (prop.IsUniform && mUniformData != null)
		{
			// Copy default value back
			let defaults = mMaterial.DefaultUniformData;
			if (defaults.Length >= prop.Offset + prop.Size)
				Internal.MemCpy(&mUniformData[prop.Offset], &defaults[prop.Offset], prop.Size);
			SetUniformDirty();
		}
		else if (prop.IsTexture)
		{
			mTextures.Remove(index);
			SetBindGroupDirty();
		}
		else if (prop.IsSampler)
		{
			mSamplers.Remove(index);
			SetBindGroupDirty();
		}

		mOverrideMask.Clear(index);
	}

	/// Resets all properties to material defaults.
	public void ResetAllProperties()
	{
		// Reset uniform data
		if (mUniformData != null)
		{
			let defaults = mMaterial.DefaultUniformData;
			if (defaults.Length > 0)
				Internal.MemCpy(mUniformData.Ptr, defaults.Ptr, defaults.Length);
		}

		mTextures.Clear();
		mSamplers.Clear();
		mOverrideMask.Reset();
		SetUniformDirty();
		SetBindGroupDirty();
	}

	/// Clears dirty flags after GPU upload.
	public void ClearUniformDirty()
	{
		mUniformDirty = false;
	}

	/// Clears bind group dirty flag.
	public void ClearBindGroupDirty()
	{
		mBindGroupDirty = false;
	}

	/// Marks uniform data as dirty (e.g., after external modification).
	public void MarkUniformDirty()
	{
		SetUniformDirty();
	}

	/// Marks bind group as dirty.
	public void MarkBindGroupDirty()
	{
		SetBindGroupDirty();
	}

	public void Dispose()
	{
		// Note: BindGroup is managed by the pool, not deleted here
	}
}
