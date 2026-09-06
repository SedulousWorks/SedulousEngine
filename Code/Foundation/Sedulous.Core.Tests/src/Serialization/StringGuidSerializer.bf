using System;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A backend that takes Serializer's DEFAULT guid handling, which is the canonical string.
///
/// BinarySerializer overrides GuidValue with the compact raw form, so the default is
/// otherwise unreachable until a text backend exists. Everything else is delegated, since
/// only the guid path is under test.
class StringGuidSerializer : Serializer
{
	private BinarySerializer mInner ~ delete _;

	public this(IStream stream, SerializeMode mode) : base(mode)
	{
		mInner = new BinarySerializer(stream, mode);
	}

	public override void BeginArray(ref uint32 count) => mInner.BeginArray(ref count);
	public override void Scalar(void* value, ScalarKind kind) => mInner.Scalar(value, kind);
	public override void Text(String value) => mInner.Text(value);
	public override void Blob(void* data, int size) => mInner.Blob(data, size);
}
