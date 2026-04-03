using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.Models;

/// Alpha mode for materials
public enum AlphaMode
{
	Opaque,
	Mask,
	Blend
}

/// Material properties for a model
public class ModelMaterial
{
	private String mName ~ delete _;

	// Base color
	public Vector4 BaseColorFactor = .(1, 1, 1, 1);
	public int32 BaseColorTextureIndex = -1;

	// Metallic-Roughness
	public float MetallicFactor = 1.0f;
	public float RoughnessFactor = 1.0f;
	public int32 MetallicRoughnessTextureIndex = -1;

	// Normal map
	public float NormalScale = 1.0f;
	public int32 NormalTextureIndex = -1;

	// Occlusion
	public float OcclusionStrength = 1.0f;
	public int32 OcclusionTextureIndex = -1;

	// Emissive
	public Vector3 EmissiveFactor = .Zero;
	public int32 EmissiveTextureIndex = -1;

	// Alpha
	public AlphaMode AlphaMode = .Opaque;
	public float AlphaCutoff = 0.5f;

	// Double-sided
	public bool DoubleSided = false;

	public StringView Name => mName;

	public this()
	{
		mName = new String();
	}

	public void SetName(StringView name)
	{
		mName.Set(name);
	}
}
