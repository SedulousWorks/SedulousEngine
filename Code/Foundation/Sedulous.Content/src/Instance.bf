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
	/// One qualified name rather than a namespace and a name apart: Beef gives one, and
	/// splitting it at the last dot would be inventing a boundary the language does not draw.
	private String mTypeName = new .() ~ delete _;
	/// SourceName, once known: from the scan's header, a write, or a read of the object.
	private String mSource = new .() ~ delete _;
	private bool mSourceKnown;

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

	/// The file this instance's object was made from, when it names one
	/// (ISerializable.SourceName: an asset's copy under the sources), so finding the assets made
	/// from a file reads no payload. A self-describing envelope carries it in its header from the
	/// write that put it there, and the scan reads it with the type; for an envelope written
	/// before that, or a binary one, the object is read once, here, and the name kept until a
	/// write or a read changes it.
	public StringView SourceName
	{
		get
		{
			if (!mSourceKnown)
			{
				// Records the name when it reads; an unreadable object names none.
				delete ReadObject();
				mSourceKnown = true;
			}
			return mSource;
		}
	}

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
		// Buffered: a binary envelope reads field by field, and a mount's stream need not
		// buffer at all (a native file's buffers 4 KB at a time).
		let buffered = scope BufferedStream(stream, 64 * 1024);
		let object = ReadEnvelope(buffered, false, scope .());
		// The object names its source as it stands on disk: keep that, whatever the header said.
		if (object != null)
			SetSourceName(object.SourceName());
		return object;
	}

	/// Reads an envelope an AUTHOR supplied (an agent's edit of the stored text) the way
	/// ReadObject reads the stored one, so what it accepts is exactly what a load accepts: its
	/// header must name THIS instance, its guid and its type, and its payload must read
	/// under this build's version. THE CALLER OWNS what comes back; null with the reason in
	/// outError.
	public ISerializable ReadObjectFrom(IStream stream, String outError) => ReadEnvelope(stream, true, outError);

	private ISerializable ReadEnvelope(IStream stream, bool checkIdentity, String outError)
	{
		let context = mDatabase.CreateSerializer(stream, .Read);
		if (context == null)
		{
			outError.Append("the text did not open as an envelope");
			return null;
		}
		defer delete context;

		let archive = context.Serializer;
		let storedType = scope String();
		if (!ReadHeader(archive, var id, storedType))
		{
			outError.Append("no envelope header (guid, typeName)");
			return null;
		}
		if (checkIdentity && (id != mId))
		{
			outError.AppendF("the envelope's guid {} is not this asset's ({})", id, mId);
			return null;
		}
		if (checkIdentity && (storedType != mTypeName))
		{
			outError.AppendF("the envelope's typeName '{}' is not this asset's ('{}')", storedType, mTypeName);
			return null;
		}
		// The header's source file, when it names one: the object names it again once read, so
		// it is passed over here.
		ReadSource(archive, scope .());

		let object = mDatabase.Serializables.Create(TypeIdOf(mTypeName));
		if (object == null)
		{
			outError.AppendF("the type '{}' is not registered in this build", mTypeName);
			return null;
		}

		// Read under the STORED version scope, so a migration branch inside Serialize sees
		// the version the envelope was written with rather than this build's. A refused
		// payload is not read: it is in another layout, and reading it as this one only
		// walks garbage.
		BeginVersionedPayload(archive, TypeIdOf(mTypeName), 0);
		if (archive.IsOk)
		{
			archive.Key("payload");
			archive.BeginObject();
			object.Serialize(archive);
			archive.EndObject();
		}
		EndVersionedPayload(archive);

		if (!archive.IsOk)
		{
			outError.Append("the payload did not read: a missing or misspelled key, a value of the wrong kind, or dataVersions other than this build's");
			let place = archive.DescribeFailure(.. scope String());
			if (!place.IsEmpty)
				outError.AppendF(" - {}", place);
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
		// The source file the object names, in a self-describing header only: a positional one
		// keeps its layout, and cooked data names no sources. The scan reads it with the type.
		let source = scope String(object.SourceName());
		if (archive.IsSelfDescribing)
		{
			archive.Key("source");
			archive.Text(source);
		}

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

		let saved = writable.Save(EnvelopePath(.. scope String()), buffer.Bytes);
		if (saved case .Ok)
			SetSourceName(source);
		return saved;
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

	/// What the scan or a write knows the source file to be.
	internal void SetSourceName(StringView name)
	{
		mSource.Set(name);
		mSourceKnown = true;
	}

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

	/// Reads the header's source file into `outSource` when the header names one (a
	/// self-describing envelope written since it carried one), after the type. False for one
	/// that does not, a binary envelope among them.
	internal static bool ReadSource(Serializer archive, String outSource)
	{
		if (!archive.IsSelfDescribing || !archive.HasKey("source"))
			return false;
		archive.Key("source");
		archive.Text(outSource);
		return archive.IsOk;
	}
}
