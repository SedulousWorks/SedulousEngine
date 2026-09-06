using System;
using System.Collections;
using Sedulous.Core.IO;

namespace Sedulous.Core.Serialization;

/// A positional binary backend: values as stored, in the order they are described.
///
/// Names and object scopes carry nothing here and are inherited as no-ops, so a Serialize
/// body keys every field uniformly and only a text backend pays attention. Arrays are
/// length prefixed.
class BinarySerializer : Serializer
{
	/// One open framed region: where to put the bytes back, and the buffer holding them.
	private struct Frame
	{
		public IStream Previous;
		public MemoryStream Buffer;
	}

	private RedirectStream mRedirect = new .() ~ delete _;
	private BinaryReader mReader ~ delete _;
	private BinaryWriter mWriter ~ delete _;
	private List<Frame> mFrames = new .() ~ delete _;

	public this(IStream stream, SerializeMode mode) : base(mode)
	{
		mRedirect.Target = stream;
		mReader = new BinaryReader(mRedirect);
		mWriter = new BinaryWriter(mRedirect);
	}

	public ~this()
	{
		// A region left open is a bug in the caller, but its buffer is still ours.
		for (let frame in mFrames)
			delete frame.Buffer;
	}

	public override void BeginArray(ref uint32 count) => Scalar(&count, .UInt32);

	public override void Scalar(void* value, ScalarKind kind) => RawBytes(value, kind.Size);

	public override void Blob(void* data, int size) => RawBytes(data, size);

	public override void Text(String value)
	{
		if (IsWriting)
		{
			if (!mWriter.WriteString(value))
				Fail(.Internal);
		}
		else if (!mReader.ReadString(value))
		{
			Fail(.Internal);
		}
	}

	/// Writing redirects everything enclosed into a fresh buffer, which End emits as a
	/// uint32 length followed by the bytes. Reading takes that length, pulls exactly that
	/// many bytes into a bounded buffer and reads from it, so End can discard whatever the
	/// caller did not consume and land on the next region either way.
	public override void BeginFramedRegion()
	{
		let buffer = new MemoryStream();
		if (IsReading)
		{
			uint32 length = 0;
			if (!mReader.Read(out length))
			{
				Fail(.Internal);
				length = 0;
			}
			if (length > 0)
			{
				let bytes = scope List<uint8>();
				let raw = bytes.GrowUninitialized((int)length);
				if (!mReader.ReadBytes(.(raw, (int)length)))
					Fail(.Internal);
				buffer.Write(.(raw, (int)length));
				buffer.Seek(0, .Begin);
			}
		}

		mFrames.Add(Frame() { Previous = mRedirect.Target, Buffer = buffer });
		mRedirect.Target = buffer;
	}

	public override void EndFramedRegion()
	{
		if (mFrames.IsEmpty)
			return;

		let frame = mFrames.PopBack();
		// Restored BEFORE emitting, so the length and bytes reach the outer stream.
		mRedirect.Target = frame.Previous;

		if (IsWriting)
		{
			let bytes = frame.Buffer.Bytes;
			let length = (uint32)bytes.Length;
			if (!mWriter.Write(length) || ((length > 0) && !mWriter.WriteBytes(bytes)))
				Fail(.Internal);
		}

		delete frame.Buffer;
	}

	/// Binary needs an active frame to know where the unknown region ends, so this is
	/// false outside one and the caller drops the section with a warning.
	public override bool RawRemainder(List<uint8> blob)
	{
		if (mFrames.IsEmpty)
			return false;

		if (IsWriting)
		{
			if (!blob.IsEmpty && !mWriter.WriteBytes(.(blob.Ptr, blob.Count)))
			{
				Fail(.Internal);
				return false;
			}
			return true;
		}

		let buffer = mFrames.Back.Buffer;
		let size = buffer.Size();
		let position = buffer.Tell();
		let remaining = (size > position) ? (int)(size - position) : 0;

		blob.Clear();
		if (remaining > 0)
		{
			let raw = blob.GrowUninitialized(remaining);
			if (!mReader.ReadBytes(.(raw, remaining)))
			{
				Fail(.Internal);
				return false;
			}
		}
		return true;
	}

	private void RawBytes(void* data, int size)
	{
		if (size == 0)
			return;

		if (IsWriting)
		{
			if (!mWriter.WriteBytes(.((uint8*)data, size)))
				Fail(.Internal);
		}
		else if (!mReader.ReadBytes(.((uint8*)data, size)))
		{
			Fail(.Internal);
		}
	}
}
