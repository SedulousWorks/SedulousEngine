using System;
using System.IO;
using System.Threading;
using System.Diagnostics;
using System.Reflection;
using System.Collections;
using Sedulous.Serialization;

namespace Sedulous.Resources;

/// Abstract base class for all resources.
/// Provides reference counting and serialization support.
abstract class Resource : IResource, ISerializable
{
	private int32 mRefCount = 0;
	private Guid mId;
	private String mName = new .() ~ delete _;
	private String mSourcePath = new .() ~ delete _;
	private uint32 mGeneration = 0;

	/// Gets or sets the unique identifier.
	public Guid Id
	{
		get => mId;
		set => mId = value;
	}

	/// Gets or sets the resource name.
	public String Name
	{
		get => mName;
		set { mName.Set(value); }
	}

	/// Content generation counter. Incremented on successful hot-reload.
	/// Used by resolvers to detect content changes without pointer comparison.
	public uint32 Generation => mGeneration;

	/// Increments the generation counter. Called by ResourceSystem after a successful reload.
	public void IncrementGeneration() { mGeneration++; }

	/// Original source path used for import deduplication.
	/// External textures: resolved file path. Embedded: modelPath#textureN.
	/// Persisted across sessions so dedup context can be rebuilt from baked resources.
	public String SourcePath
	{
		get => mSourcePath;
		set { mSourcePath.Set(value); }
	}

	/// Gets the resource file type identifier (fully qualified class name).
	public abstract ResourceType ResourceType { get; }

	/// Gets the current reference count.
	public int RefCount => mRefCount;

	public this()
	{
		mId = Guid.Create();
	}

	public ~this()
	{
		Debug.Assert(mRefCount == 0, "Resource deleted with non-zero ref count");
	}

	/// Increments the reference count.
	public void AddRef()
	{
		Interlocked.Increment(ref mRefCount);
	}

	/// Decrements the reference count. Deletes when count reaches zero.
	public void ReleaseRef()
	{
		let refCount = Interlocked.Decrement(ref mRefCount);
		Debug.Assert(refCount >= 0);
		if (refCount == 0)
			delete this;
	}
	
	public void ReleaseLastRef()
	{
		int refCount = Interlocked.Decrement(ref mRefCount);
		Debug.Assert(refCount == 0);
		if (refCount == 0)
		{
			delete this;
		}
	}

	/// Decrements the reference count without deleting.
	public int ReleaseRefNoDelete()
	{
		let refCount = Interlocked.Decrement(ref mRefCount);
		Debug.Assert(refCount >= 0);
		return refCount;
	}

	// ---- ISerializable ----

	/// Gets the serialization version for this resource type.
	public virtual int32 SerializationVersion => 1;

	/// Serializes the resource.
	public virtual SerializationResult Serialize(Serializer s)
	{
		// Serialize resource type hash for validation
		var typeHash = ResourceType.Value;
		s.UInt64("_type", ref typeHash);
		if (s.IsReading && typeHash != ResourceType.Value)
			return .InvalidData;

		var version = SerializationVersion;
		s.Version(ref version);

		// Serialize GUID as string
		let guidStr = scope String();
		if (s.IsWriting)
			mId.ToString(guidStr);
		s.String("_id", guidStr);
		if (s.IsReading)
			mId = Guid.Parse(guidStr).GetValueOrDefault();

		s.String("_name", mName);
		s.String("_sourcePath", mSourcePath);

		return OnSerialize(s);
	}

	/// Override to serialize resource-specific data.
	protected virtual SerializationResult OnSerialize(Serializer s)
	{
		return .Ok;
	}

	/// Reloads the resource in place from a serializer.
	/// Override to clear internal state and re-read data without destroying the object.
	/// Resources that can't reload should return .Err(.NotSupported).
	/// Default: .Err(.NotSupported).
	public virtual Result<void, ResourceLoadError> Reload(Serializer s)
	{
		return .Err(.NotSupported);
	}

	/// Rewrites internal cross-resource references using the given GUID -> new
	/// Path map. Default no-op; resource types that hold ResourceRefs to other
	/// resources (materials -> textures, skinned meshes -> skeletons, sound
	/// cues -> audio clips, animation graphs -> animation clips, particle
	/// effects -> meshes/textures/materials, etc.) override this to walk
	/// their refs and substitute Path when the ref's Guid matches an entry
	/// in the map. Called during asset import after the user renames items
	/// in the import dialog, so the saved resources point at the user-chosen
	/// filenames instead of the source's authored names.
	public virtual void RemapReferences(Dictionary<Guid, String> finalPaths) { }

	/// Writes this resource into `stream` using the given serializer provider.
	/// Caller owns the stream and routes it to wherever it needs to go (a mount
	/// `Save`, an in-memory buffer, etc.) - the resource has no opinion about
	/// destinations.
	public virtual Result<void> WriteToStream(Stream stream, Sedulous.Serialization.ISerializerProvider provider)
	{
		let writer = provider.CreateWriter();
		if (writer == null)
			return .Err;
		defer delete writer;

		Serialize(writer);

		let output = scope String();
		provider.GetOutput(writer, output);

		if (stream.TryWrite(.((uint8*)output.Ptr, output.Length)) case .Err)
			return .Err;
		return .Ok;
	}
}
