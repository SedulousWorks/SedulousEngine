using System;
using System.Collections;

namespace Sedulous.Core.Serialization;

/// The concrete base backends extend, holding the mode, the data-version scopes and a
/// sticky error.
///
/// Naming and object scopes carry no information in an unkeyed format, so they default to
/// nothing here and a keyed backend overrides what it needs. BeginArray, Scalar, Text and
/// Blob stay abstract: every backend has to move data.
abstract class Serializer : ISerializer
{
	private SerializeMode mMode;
	/// A flat stack of every open scope's entries, with the start index of each scope.
	/// The concrete type is always entry zero of its scope.
	private List<SerializedDataVersion> mVersions = new .() ~ delete _;
	private List<int> mScopeStarts = new .() ~ delete _;
	private bool mFailed;
	private ErrorCode mError;

	public this(SerializeMode mode)
	{
		mMode = mode;
	}

	public SerializeMode Mode => mMode;
	public bool IsReading => mMode == .Read;
	public bool IsWriting => mMode == .Write;

	public bool IsOk => !mFailed;
	public bool IsPayloadOk => IsOk;
	public Result<void, ErrorCode> Status => mFailed ? .Err(mError) : .Ok;

	/// True for a backend whose structure is discoverable from the data, meaning keyed or
	/// text. False for a positional one, which needs explicit framing and versioning. A
	/// store uses this to add a format-version field only where the layout is not already
	/// self describing.
	public virtual bool IsSelfDescribing => false;

	public uint32 Version
	{
		get
		{
			if (mScopeStarts.IsEmpty)
				return 0;
			let start = mScopeStarts.Back;
			return (start < mVersions.Count) ? mVersions[start].Version : 0;
		}
	}

	public uint32 VersionOf(uint64 typeId)
	{
		if (mScopeStarts.IsEmpty)
			return 0;
		for (int i = mScopeStarts.Back; i < mVersions.Count; i++)
		{
			if (mVersions[i].TypeId == typeId)
				return mVersions[i].Version;
		}
		return 0;
	}

	public void PushVersionScope(Span<SerializedDataVersion> chain)
	{
		mScopeStarts.Add(mVersions.Count);
		for (let entry in chain)
			mVersions.Add(entry);
	}

	public void PopVersionScope()
	{
		if (mScopeStarts.IsEmpty)
			return;
		let start = mScopeStarts.PopBack();
		while (mVersions.Count > start)
			mVersions.PopBack();
	}

	/// Routed into the serializer's status, so a failed payload surfaces exactly as a
	/// short read does. The first failure wins, since later ones are its consequences.
	public void FailPayload(ErrorCode code) => Fail(code);

	protected void Fail(ErrorCode code)
	{
		if (!mFailed)
		{
			mFailed = true;
			mError = code;
		}
	}

	public virtual void Key(StringView name) {}
	public virtual void BeginObject() {}
	public virtual void EndObject() {}
	public virtual void EndArray() {}

	public abstract void BeginArray(ref uint32 count);
	public abstract void Scalar(void* value, ScalarKind kind);
	public abstract void Text(String value);
	public abstract void Blob(void* data, int size);

	/// The canonical string, which is what a text backend wants. BinarySerializer
	/// overrides this with the compact raw form.
	///
	/// A guid that does not parse leaves the value alone rather than zeroing it, and fails
	/// the payload: a malformed guid is corrupt data, not an empty one.
	public virtual void GuidValue(ref Guid value)
	{
		let text = scope String();
		if (mMode == .Write)
			value.ToString(text, 'D');

		Text(text);

		if (mMode == .Read)
		{
			if (Guid.Parse(text) case .Ok(let parsed))
				value = parsed;
			else
				Fail(.InvalidArgument);
		}
	}

	/// Brackets a self-delimiting sub-region, so a payload whose type this build cannot
	/// instantiate can be captured or skipped uniformly. Binary length-prefixes the
	/// enclosed bytes; a self-describing format leans on its own element boundaries and
	/// does nothing. Regions may nest.
	public virtual void BeginFramedRegion() {}
	public virtual void EndFramedRegion() {}

	public virtual bool RawRemainder(List<uint8> blob) => false;
}
