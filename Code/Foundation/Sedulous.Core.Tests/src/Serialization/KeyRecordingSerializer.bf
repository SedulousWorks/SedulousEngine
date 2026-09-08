using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A backend that records the KEYS a body emits, and delegates everything else.
///
/// The keys are the text format. Binary ignores them, so without something that watches
/// them the name a field is stored under is unverifiable, and it is exactly the thing that
/// has to match across engines reading the same project.
class KeyRecordingSerializer : Serializer
{
	private BinarySerializer mInner ~ delete _;

	public List<String> Keys = new .() ~ DeleteContainerAndItems!(_);

	public this(IStream stream, SerializeMode mode) : base(mode)
	{
		mInner = new BinarySerializer(stream, mode);
	}

	public override void Key(StringView name)
	{
		Keys.Add(new String(name));
		mInner.Key(name);
	}

	public override void BeginObject() => mInner.BeginObject();
	public override void EndObject() => mInner.EndObject();
	public override void BeginArray(ref uint32 count) => mInner.BeginArray(ref count);
	public override void EndArray() => mInner.EndArray();
	public override void Scalar(void* value, ScalarKind kind) => mInner.Scalar(value, kind);
	public override void Text(String value) => mInner.Text(value);
	public override void Blob(void* data, int size) => mInner.Blob(data, size);
	public override void GuidValue(ref Guid value) => mInner.GuidValue(ref value);
}
