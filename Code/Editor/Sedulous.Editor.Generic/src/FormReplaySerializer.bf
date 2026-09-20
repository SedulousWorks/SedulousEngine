using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Generic;

/// Feeds recorded fields back through a Serialize, in read mode, with one field patched. A
/// shape mismatch flips the replay inert: the object keeps its live values from there.
class FormReplaySerializer : Serializer
{
	/// Borrowed.
	private List<AssetFormField> mFields;
	private int mPatchIndex;
	/// Borrowed.
	private AssetFormField mPatch;
	private int mCursor = 0;
	private bool mDesynced = false;

	public this(List<AssetFormField> fields, int patchIndex, AssetFormField patch) : base(.Read)
	{
		mFields = fields;
		mPatchIndex = patchIndex;
		mPatch = patch;
	}

	public override void BeginArray(ref uint32 count)
	{
		if (let field = Next(.ArrayCount))
			count = (uint32)field.IntValue;
	}

	public override void Scalar(void* value, ScalarKind kind)
	{
		let field = Next(.Scalar);
		if (field == null)
			return;
		if (field.ScalarKind == kind)
			field.WriteScalar(value, kind);
		else
			mDesynced = true;
	}

	public override void Text(String value)
	{
		if (let field = Next(.Text))
			value.Set(field.TextValue);
	}

	public override void GuidValue(ref Guid value)
	{
		if (let field = Next(.Guid))
			value = field.GuidValue;
	}

	public override void Blob(void* data, int size)
	{
		let field = Next(.Blob);
		if (field == null)
			return;
		if (field.BlobValue.Count == size)
		{
			if (size > 0)
				Internal.MemCpy(data, field.BlobValue.Ptr, size);
		}
		else
		{
			mDesynced = true;
		}
	}

	private AssetFormField Next(AssetFormFieldKind expected)
	{
		if (mDesynced || (mCursor >= mFields.Count))
		{
			mDesynced = true;
			return null;
		}
		let index = mCursor++;
		let stored = mFields[index];
		if (stored.Kind != expected)
		{
			mDesynced = true;
			return null;
		}
		return (index == mPatchIndex) ? mPatch : stored;
	}
}
