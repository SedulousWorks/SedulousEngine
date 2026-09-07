using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;

namespace Sedulous.Content;

/// One stored unit: an identity, a primary object, and any number of named data streams.
///
/// The envelope holds the identity and the object. Heavy blobs live in sidecar files
/// beside it, so loading an instance's metadata does not drag its payload in with it.
///
/// Owned by the database. The name IS the filename, which is why renaming moves files and
/// why the envelope does not store it.
class Instance
{
	private ContentDatabase mDatabase;
	private Group mGroup;
	private Guid mId;
	private String mName = new .() ~ delete _;
	/// The qualified name of the primary object's type, as stored.
	///
	/// Raptor keeps a namespace and a name separately, because its own RTTI has them
	/// apart. Beef gives one qualified name, and splitting it at the last dot would be
	/// inventing a boundary the language does not draw.
	private String mTypeName = new .() ~ delete _;

	public this(ContentDatabase database, Group group, Guid id, StringView name, StringView typeName)
	{
		mDatabase = database;
		mGroup = group;
		mId = id;
		mName.Set(name);
		mTypeName.Set(typeName);
	}

	public Guid Id => mId;
	public StringView Name => mName;
	public StringView TypeName => mTypeName;
	public Group OwningGroup => mGroup;

	/// "group/path/name", mount relative and without the extension.
	public void GetPath(String outPath)
	{
		mGroup.GetPath(outPath);
		if (outPath.IsEmpty)
			outPath.Set(mName);
		else
			PathJoin(scope String(outPath), mName, outPath);
	}

	// ---- reading ----

	/// Reads the primary object, constructing its type from the stored name. Null when the
	/// type is not registered in this build, or on any read failure.
	///
	/// THE CALLER OWNS what comes back.
	public ISerializable ReadObject()
	{
		let stream = mDatabase.Mount.Open(EnvelopePath(.. scope String()), .Read);
		if (stream == null)
			return null;
		defer delete stream;

		let context = mDatabase.CreateSerializer(stream, .Read);
		if (context == null)
			return null;
		defer delete context;

		let archive = context.Serializer;
		if (!ReadHeader(archive, var id, scope String()))
			return null;

		let object = mDatabase.Serializables.Create(TypeIdOf(mTypeName));
		if (object == null)
			return null;

		// Read under the STORED version scope, so a migration branch inside Serialize sees
		// the version the envelope was written with rather than this build's.
		BeginVersionedPayload(archive, TypeIdOf(mTypeName), 0);
		archive.Key("payload");
		archive.BeginObject();
		object.Serialize(archive);
		archive.EndObject();
		EndVersionedPayload(archive);

		if (!archive.IsOk)
		{
			delete object;
			return null;
		}
		return object;
	}

	/// Opens a named data stream, or null if there is none. THE CALLER OWNS the stream.
	///
	/// The text suffix is probed first and the binary one second, so a stream reads
	/// whichever way it was written.
	public IStream ReadData(StringView streamName)
	{
		if (let text = mDatabase.Mount.Open(DataPath(streamName, .Text, .. scope String()), .Read))
			return text;
		return mDatabase.Mount.Open(DataPath(streamName, .Binary, .. scope String()), .Read);
	}

	/// The raw envelope, for a caller that wants to fingerprint the stored bytes rather
	/// than the object they decode to. THE CALLER OWNS the stream.
	public IStream OpenEnvelope() => mDatabase.Mount.Open(EnvelopePath(.. scope String()), .Read);

	// ---- writing ----

	/// Writes the primary object into the envelope, replacing whatever was there.
	public Result<void, ErrorCode> WriteObject(ISerializable object)
	{
		let writable = mDatabase.Mount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		let buffer = scope MemoryStream();
		let context = mDatabase.CreateSerializer(buffer, .Write);
		if (context == null)
			return .Err(.Internal);
		defer delete context;

		let archive = context.Serializer;
		archive.Key("guid");
		archive.GuidValue(ref mId);
		archive.Key("typeName");
		archive.Text(mTypeName);

		BeginVersionedPayload(archive, TypeIdOf(mTypeName), 0);
		archive.Key("payload");
		archive.BeginObject();
		object.Serialize(archive);
		archive.EndObject();
		EndVersionedPayload(archive);

		if (!archive.IsOk)
			return .Err(.Internal);

		// A text backend has built a document and only now has bytes.
		context.Flush(buffer);

		return writable.Save(EnvelopePath(.. scope String()), buffer.Bytes);
	}

	/// Writes a named data stream, and removes the sibling under the other suffix so a
	/// stream never exists as both at once. That is also how a stream migrates when its
	/// encoding changes.
	public Result<void, ErrorCode> WriteData(StringView streamName, Span<uint8> data, StreamEncoding encoding = .Binary)
	{
		let writable = mDatabase.Mount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		let saved = writable.Save(DataPath(streamName, encoding, .. scope String()), data);
		if (saved case .Err)
			return saved;

		let other = DataPath(streamName, (encoding == .Text) ? .Binary : .Text, .. scope String());
		if (mDatabase.Mount.Exists(other))
			writable.Delete(other).IgnoreError();
		return .Ok;
	}

	/// Removes a named data stream. Idempotent: an absent stream is not an error, since a
	/// re-cook that no longer produces one has to be able to clear a stale sidecar.
	public Result<void, ErrorCode> DeleteData(StringView streamName)
	{
		let writable = mDatabase.Mount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		// Both suffixes, since a stream written one way may be being cleared by a build
		// that would have written it the other.
		for (let encoding in StreamEncoding[?](.Binary, .Text))
		{
			let path = DataPath(streamName, encoding, .. scope:: String());
			if (mDatabase.Mount.Exists(path))
				writable.Delete(path).IgnoreError();
		}
		return .Ok;
	}

	// ---- storage layout ----

	/// "<path>.<extension>"
	public void EnvelopePath(String outPath)
	{
		GetPath(outPath);
		outPath.Append('.');
		outPath.Append(mDatabase.Extension);
	}

	/// "<path>.<stream>.bin" or "<path>.<stream>.data"
	public void DataPath(StringView streamName, StreamEncoding encoding, String outPath)
	{
		GetPath(outPath);
		outPath.Append('.');
		outPath.Append(streamName);
		outPath.Append((encoding == .Text) ? ".data" : ".bin");
	}

	/// Renaming moves files, so the database sets this only after the move succeeded.
	internal void SetName(StringView name) => mName.Set(name);
	internal void SetGroup(Group group) => mGroup = group;

	/// Reads the three header fields every envelope starts with.
	internal static bool ReadHeader(Serializer archive, out Guid id, String outTypeName)
	{
		id = default;
		archive.Key("guid");
		archive.GuidValue(ref id);
		archive.Key("typeName");
		archive.Text(outTypeName);
		return archive.IsOk;
	}
}
