using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Generic;

/// Records every value a Serialize produces, in write mode, as an ordinal field list.
class FormScanSerializer : Serializer
{
	/// Borrowed; the list owns the fields.
	private List<AssetFormField> mFields;
	private String mLastKey = new .() ~ delete _;
	private List<String> mArrayKeys = new .() ~ DeleteContainerAndItems!(_);
	private List<uint32> mArrayIndices = new .() ~ delete _;

	public this(List<AssetFormField> fields) : base(.Write)
	{
		mFields = fields;
	}

	public override void Key(StringView name) => mLastKey.Set(name);

	public override void BeginArray(ref uint32 count)
	{
		let field = NewField(.ArrayCount);
		field.ScalarKind = .UInt32;
		field.IntValue = count;
		mArrayKeys.Add(new String(CurrentLabel(.. scope .())));
		mArrayIndices.Add(0);
	}

	public override void EndArray()
	{
		if (!mArrayKeys.IsEmpty)
		{
			delete mArrayKeys.PopBack();
			mArrayIndices.PopBack();
		}
	}

	public override void Scalar(void* value, ScalarKind kind)
	{
		let field = NewField(.Scalar);
		field.ReadScalar(value, kind);
		BumpArrayIndex();
	}

	public override void Text(String value)
	{
		let field = NewField(.Text);
		field.TextValue.Set(value);
		BumpArrayIndex();
	}

	public override void GuidValue(ref Guid value)
	{
		let field = NewField(.Guid);
		field.GuidValue = value;
		BumpArrayIndex();
	}

	public override void Blob(void* data, int size)
	{
		let field = NewField(.Blob);
		if (size > 0)
			field.BlobValue.AddRange(Span<uint8>((uint8*)data, size));
		BumpArrayIndex();
	}

	/// A field labelled and stamped with the outermost array's key as its category.
	private AssetFormField NewField(AssetFormFieldKind kind)
	{
		let field = new AssetFormField();
		field.Kind = kind;
		CurrentLabel(field.Label);
		if (!mArrayKeys.IsEmpty)
			field.Category.Set(mArrayKeys[0]);
		mFields.Add(field);
		return field;
	}

	/// Inside an unkeyed array, where elements serialize without Key calls, elements label as
	/// "arrayKey[i]"; a keyed field inside an array keeps its own key.
	private void CurrentLabel(String outLabel)
	{
		if (!mArrayKeys.IsEmpty && (mLastKey.IsEmpty || (mArrayKeys.Back == mLastKey)))
		{
			outLabel.AppendF("{}[{}]", mArrayKeys.Back, mArrayIndices.Back);
			return;
		}
		outLabel.Set(mLastKey);
	}

	private void BumpArrayIndex()
	{
		if (!mArrayIndices.IsEmpty)
			mArrayIndices[mArrayIndices.Count - 1]++;
	}
}
