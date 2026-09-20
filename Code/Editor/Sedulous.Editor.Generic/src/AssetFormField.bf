using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Generic;

/// One recorded value of an asset's Serialize: the label is the last Key before it (or
/// "key[i]" inside an unkeyed array), the category the outermost enclosing array's key,
/// empty for top-level fields. The grid groups each array's rows under a default-collapsed
/// expander, so a bulk section costs no layout until opened.
class AssetFormField
{
	/// The array key of the version envelope every versioned type writes first; structural,
	/// never shown or edited.
	public const String cVersionsKey = "dataVersions";

	public String Label = new .() ~ delete _;
	public String Category = new .() ~ delete _;
	public AssetFormFieldKind Kind = .Scalar;
	/// When Kind is Scalar or ArrayCount.
	public ScalarKind ScalarKind = .Float32;
	/// Bool and integer scalars, array counts.
	public int64 IntValue = 0;
	/// Float scalars.
	public double FloatValue = 0.0;
	public String TextValue = new .() ~ delete _;
	public Guid GuidValue = .Empty;
	public List<uint8> BlobValue = new .() ~ delete _;

	public bool Editable => (Kind != .Blob) && (Kind != .ArrayCount) && (Category != cVersionsKey);

	public void CopyTo(AssetFormField other)
	{
		other.Label.Set(Label);
		other.Category.Set(Category);
		other.Kind = Kind;
		other.ScalarKind = ScalarKind;
		other.IntValue = IntValue;
		other.FloatValue = FloatValue;
		other.TextValue.Set(TextValue);
		other.GuidValue = GuidValue;
		other.BlobValue.Clear();
		other.BlobValue.AddRange(BlobValue);
	}

	/// Widens a raw scalar into the field's storage.
	public void ReadScalar(void* value, Sedulous.Core.Serialization.ScalarKind kind)
	{
		ScalarKind = kind;
		switch (kind)
		{
		case .Bool: IntValue = *(bool*)value ? 1 : 0;
		case .Int8: IntValue = *(int8*)value;
		case .UInt8: IntValue = *(uint8*)value;
		case .Int16: IntValue = *(int16*)value;
		case .UInt16: IntValue = *(uint16*)value;
		case .Int32: IntValue = *(int32*)value;
		case .UInt32: IntValue = *(uint32*)value;
		case .Int64: IntValue = *(int64*)value;
		case .UInt64: IntValue = (int64)*(uint64*)value;
		case .Float32: FloatValue = *(float*)value;
		case .Float64: FloatValue = *(double*)value;
		}
	}

	/// Narrows the field's storage back out into a raw scalar.
	public void WriteScalar(void* value, Sedulous.Core.Serialization.ScalarKind kind)
	{
		switch (kind)
		{
		case .Bool: *(bool*)value = IntValue != 0;
		case .Int8: *(int8*)value = (int8)IntValue;
		case .UInt8: *(uint8*)value = (uint8)IntValue;
		case .Int16: *(int16*)value = (int16)IntValue;
		case .UInt16: *(uint16*)value = (uint16)IntValue;
		case .Int32: *(int32*)value = (int32)IntValue;
		case .UInt32: *(uint32*)value = (uint32)IntValue;
		case .Int64: *(int64*)value = IntValue;
		case .UInt64: *(uint64*)value = (uint64)IntValue;
		case .Float32: *(float*)value = (float)FloatValue;
		case .Float64: *(double*)value = FloatValue;
		}
	}
}
