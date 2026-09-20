using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Generic.Tests;

/// A synthetic asset exercising scalars, strings, guids, blobs, arrays, and a version-gated
/// plus a value-conditional field. Hand-written, since the conditionals are the point.
class FormProbeAsset : ISerializable
{
	public const uint64 TypeId = 0x7A3F19C2D4B8E601UL;
	public const uint32 DataVersion = 2;

	public float Friction = 0.5f;
	public int32 Group = 3;
	public bool Enabled = true;
	public String Note = new .("hello") ~ delete _;
	public Guid Mesh = .(0xAB, 0x12, 0x34, 0, 0, 0, 0, 0, 0, 0, 0);
	/// An unkeyed scalar array.
	public List<float> Weights = new .() ~ delete _;
	public uint8[4] Blob = .(1, 2, 3, 4);
	/// Gates Extra below, the value-conditional shape.
	public bool HasExtra = false;
	public float Extra = 9.0f;
	/// Behind Version >= 2, the type's data version.
	public float Gated = 7.0f;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, DataVersion);
		SerializeValue(ar, "friction", ref Friction);
		SerializeValue(ar, "group", ref Group);
		SerializeValue(ar, "enabled", ref Enabled);
		Sedulous.Core.Serialization.Serialize(ar, "note", Note);
		SerializeValue(ar, "mesh", ref Mesh);
		ar.Key("weights");
		SerializeList(ar, Weights);
		ar.Key("blob");
		ar.Blob(&Blob[0], 4);
		SerializeValue(ar, "hasExtra", ref HasExtra);
		if (HasExtra)
			SerializeValue(ar, "extra", ref Extra);
		if (ar.Version >= 2)
			SerializeValue(ar, "gated", ref Gated);
		EndVersionedPayload(ar);
	}
}
