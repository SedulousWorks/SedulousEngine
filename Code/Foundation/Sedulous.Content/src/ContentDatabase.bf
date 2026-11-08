using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;

namespace Sedulous.Content;

/// A hierarchical store of serializable objects, addressed by identity or by path.
///
/// A group is a directory, an instance is a file, and a data stream is a sidecar beside
/// it. Identity is decoupled from bytes: the database owns the guid to location mapping
/// and the VFS owns the bytes, so neither has to know how the other works.
///
/// The FORMAT is decided by the caller, through the serializer factory it is handed. The
/// database never names a backend, which is what lets the same store be binary in a
/// shipped build and text in an editor.
///
/// It owns every group and instance. The mount and the factory are borrowed and must
/// outlive it.
class ContentDatabase : IContentDatabase
{
	private IFileSystem mMount;
	private SerializerFactory mFactory;
	private String mExtension = new .() ~ delete _;
	/// BORROWED, like the mount and the factory.
	private SerializableRegistry mSerializables;

	private Group mRoot;
	private List<Group> mAllGroups = new .() ~ DeleteContainerAndItems!(_);
	private List<Instance> mAllInstances = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<Guid, Instance> mByGuid = new .() ~ delete _;
	private ScanStats mScanStats;
	private uint64 mRevision;

	/// Scans the mount on construction. The extension is given without a dot.
	///
	/// The registry is INJECTED rather than reached for, defaulting to the global one.
	/// Two databases in one process can then carry different registrations: a tool
	/// inspecting content built by another build, or a test that wants a table holding
	/// exactly the types it declared.
	public this(IFileSystem mount, SerializerFactory factory, StringView fileExtension,
		SerializableRegistry serializables = null)
	{
		mMount = mount;
		mFactory = factory;
		mExtension.Set(fileExtension);
		mSerializables = (serializables != null) ? serializables : GlobalSerializableRegistry;

		mRoot = RegisterGroup(null, "");
		Scan(mRoot, "");
	}

	public IFileSystem Mount => mMount;
	/// What this database resolves stored type names through.
	public SerializableRegistry Serializables => mSerializables;
	public StringView Extension => mExtension;
	public ScanStats LastScanStats => mScanStats;

	public Group RootGroup => mRoot;

	/// Counts the changes to the tree's shape: a group or an instance added, removed, renamed
	/// or moved. A view of the tree (the asset browser) builds again when it moves, however
	/// the change came (a page, an import, an agent's write). An instance's content being
	/// written does not move it.
	public uint64 Revision => mRevision;

	/// The shape changed: what the groups' own edits call.
	private void Touch() => mRevision++;

	public Instance GetInstance(Guid id)
	{
		if (mByGuid.TryGetValue(id, let instance))
			return instance;
		return null;
	}

	/// Walks "group/sub/name". An empty segment is skipped, so a leading or doubled slash
	/// is tolerated rather than being a different path.
	public Instance GetInstanceByPath(StringView path)
	{
		var group = mRoot;
		var start = 0;

		for (int i = 0; i <= path.Length; i++)
		{
			let atEnd = i == path.Length;
			if (!atEnd && (path[i] != '/'))
				continue;

			let part = StringView(path, start, i - start);
			start = i + 1;
			if (part.IsEmpty)
				continue;

			if (atEnd)
				return group.GetInstance(part);

			group = group.GetGroup(part);
			if (group == null)
				return null;
		}
		return null;
	}

	public ISerializable ReadObject(Guid id)
	{
		let instance = GetInstance(id);
		return (instance != null) ? instance.ReadObject() : null;
	}

	/// Makes a serializer for a stream. THE CALLER OWNS the context.
	public SerializerContext CreateSerializer(IStream stream, SerializeMode mode) => mFactory(stream, mode);

	/// The factory itself, for a caller that has to hand it on rather than use it: a cook
	/// passes it to every builder, since Beef has no copy constructor and a faithful clone of
	/// a polymorphic graph goes out through a serializer and back.
	public SerializerFactory Serializers => mFactory;

	// ---- tooling ----

	/// Removes an instance: its envelope and every data-stream sidecar, then its place in
	/// the tree and the identity index.
	public Result<void, ErrorCode> DeleteInstance(Guid id)
	{
		let instance = GetInstance(id);
		if (instance == null)
			return .Err(.NotFound);

		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		writable.Delete(instance.EnvelopePath(.. scope String())).IgnoreError();
		DeleteSidecars(instance);

		instance.OwningGroup.[Friend]RemoveInstance(instance);
		mByGuid.Remove(id);
		mAllInstances.Remove(instance);
		delete instance;
		return .Ok;
	}

	/// Renames an instance in place: same group, same identity, and the files move,
	/// because the NAME IS THE FILENAME and the envelope does not store it.
	///
	/// References by identity are untouched by design: renaming an asset should not break
	/// anything pointing at it.
	public Result<void, ErrorCode> RenameInstance(Guid id, StringView newName)
	{
		let instance = GetInstance(id);
		if (instance == null)
			return .Err(.NotFound);
		if (instance.Name == newName)
			return .Ok;

		let group = instance.OwningGroup;
		if (group.GetInstance(newName) != null)
			return .Err(.AlreadyExists);

		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		// Every path is derived from the name, so the old ones have to be taken before it
		// changes and the new ones after.
		let oldName = scope String(instance.Name);
		let oldEnvelope = instance.EnvelopePath(.. scope String());
		let oldSidecars = scope List<String>();
		defer { ClearAndDeleteItems!(oldSidecars); }
		CollectSidecars(instance, oldSidecars);

		instance.[Friend]SetName(newName);

		if (mMount.Exists(oldEnvelope))
		{
			if (writable.Move(oldEnvelope, instance.EnvelopePath(.. scope String())) case .Err(let error))
			{
				// The move failed, so the files still carry the old name and the node has
				// to go back to matching them.
				instance.[Friend]SetName(oldName);
				return .Err(error);
			}
		}

		for (let oldPath in oldSidecars)
		{
			let suffix = SidecarSuffix(oldPath, oldEnvelope);
			let newPath = scope String();
			instance.GetPath(newPath);
			newPath.Append(suffix);
			writable.Move(oldPath, newPath).IgnoreError();
		}

		group.[Friend]ResortChildren();
		return .Ok;
	}

	/// Moves an instance to another group, keeping its name and identity: its envelope and
	/// every data-stream sidecar move to that group's folder, which is made when it has none
	/// yet. It is re-filed in the group's name order.
	///
	/// References by identity are untouched, as with a rename. InvalidArgument when it is
	/// in that group already, AlreadyExists when the group has an instance of its name.
	public Result<void, ErrorCode> MoveInstance(Guid id, Group to)
	{
		let instance = GetInstance(id);
		if (instance == null)
			return .Err(.NotFound);

		let from = instance.OwningGroup;
		if (from == to)
			return .Err(.InvalidArgument);
		if (to.GetInstance(instance.Name) != null)
			return .Err(.AlreadyExists);

		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		// Every path is derived from the group, so the old ones have to be taken before it
		// changes and the new ones after.
		let oldEnvelope = instance.EnvelopePath(.. scope String());
		let oldSidecars = scope List<String>();
		defer { ClearAndDeleteItems!(oldSidecars); }
		CollectSidecars(instance, oldSidecars);

		let toFolder = to.GetPath(.. scope String());
		if (!toFolder.IsEmpty && !mMount.Exists(toFolder))
			writable.CreateDirectory(toFolder).IgnoreError();

		from.[Friend]RemoveInstance(instance);
		instance.[Friend]SetGroup(to);
		to.[Friend]AddInstanceNode(instance);

		// The envelope may not exist yet: an instance created and never written.
		if (mMount.Exists(oldEnvelope))
		{
			if (writable.Move(oldEnvelope, instance.EnvelopePath(.. scope String())) case .Err(let error))
			{
				// The move failed, so the files are still in the old folder and the node has
				// to go back to matching them.
				to.[Friend]RemoveInstance(instance);
				instance.[Friend]SetGroup(from);
				from.[Friend]AddInstanceNode(instance);
				return .Err(error);
			}
		}

		for (let oldPath in oldSidecars)
		{
			let suffix = SidecarSuffix(oldPath, oldEnvelope);
			let newPath = scope String();
			instance.GetPath(newPath);
			newPath.Append(suffix);
			writable.Move(oldPath, newPath).IgnoreError();
		}
		return .Ok;
	}

	/// Renames a group, which is a directory move. Descendant paths are derived, so
	/// nothing beneath it needs fixing up.
	public Result<void, ErrorCode> RenameGroup(Group group, StringView newName)
	{
		if (group == mRoot)
			return .Err(.NotSupported);
		if (group.Name == newName)
			return .Ok;

		let parent = group.Parent;
		if (parent.GetGroup(newName) != null)
			return .Err(.AlreadyExists);

		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		let oldPath = group.GetPath(.. scope String());
		group.[Friend]SetName(newName);
		let newPath = group.GetPath(.. scope String());

		if (mMount.Exists(oldPath))
			writable.Move(oldPath, newPath).IgnoreError();

		parent.[Friend]ResortChildren();
		return .Ok;
	}

	/// Removes a group and everything under it, bottom up, then the directories
	/// themselves. A rescan must not resurrect a ghost.
	///
	/// The group object is destroyed, so the caller's reference is dangling afterwards.
	public Result<void, ErrorCode> DeleteGroup(Group group)
	{
		if (group == mRoot)
			return .Err(.NotSupported);

		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		// A copy, because deleting mutates the lists being walked.
		let children = scope List<Group>();
		for (let child in group.Groups)
			children.Add(child);
		for (let child in children)
			DeleteGroup(child).IgnoreError();

		let instances = scope List<Instance>();
		for (let instance in group.Instances)
			instances.Add(instance);
		for (let instance in instances)
			DeleteInstance(instance.Id).IgnoreError();

		let path = group.GetPath(.. scope String());
		writable.DeleteDirectory(path).IgnoreError();

		Touch();
		let parent = group.Parent;
		if (parent != null)
			parent.[Friend]RemoveGroup(group);
		mAllGroups.Remove(group);
		delete group;
		return .Ok;
	}

	/// Copies an instance under a new name in the same group, with a fresh identity: the
	/// object round trips through its registered type so the copy is deep and re-keyed,
	/// and every sidecar is copied byte for byte.
	public Instance CloneInstance(Guid id, StringView newName)
	{
		let source = GetInstance(id);
		if (source == null)
			return null;

		let group = source.OwningGroup;
		if (group.GetInstance(newName) != null)
			return null;

		let object = source.ReadObject();
		if (object == null)
			return null;
		defer delete object;

		let copy = group.CreateInstance(newName, source.TypeName);
		if (copy.WriteObject(object) case .Err)
			return null;

		CopySidecars(source, copy);
		return copy;
	}

	/// Fills an existing instance with another's object and sidecars, byte for byte. The
	/// two are expected to share an identity, which is how a cook carries a product that
	/// does not vary by platform into a per-target database without redoing the work.
	public Result<void, ErrorCode> CopyContentForward(Instance destination, ContentDatabase source, Guid sourceId)
	{
		let sourceInstance = source.GetInstance(sourceId);
		if (sourceInstance == null)
			return .Err(.NotFound);

		let object = sourceInstance.ReadObject();
		if (object == null)
			return .Err(.NotFound);
		defer delete object;

		let wrote = destination.WriteObject(object);
		if (wrote case .Err)
			return wrote;

		CopySidecarsAcross(sourceInstance, source, destination);
		return .Ok;
	}

	// ---- node ownership ----

	private Group RegisterGroup(Group parent, StringView name)
	{
		let group = new Group(this, parent, name);
		Touch();
		mAllGroups.Add(group);
		return group;
	}

	private Instance RegisterInstance(Group group, Guid id, StringView name, StringView typeName)
	{
		let instance = new Instance(this, group, id, name, typeName);
		Touch();
		mAllInstances.Add(instance);
		group.[Friend]AddInstanceNode(instance);
		// A duplicate identity means two envelopes claim the same guid; the first one
		// scanned keeps the index, since silently rebinding would make loads depend on
		// directory order.
		if (!mByGuid.ContainsKey(id))
			mByGuid[id] = instance;
		return instance;
	}

	// ---- the scan ----

	private void Scan(Group group, StringView folder)
	{
		let enumerable = mMount as IEnumerableFileSystem;
		if (enumerable == null)
			return;

		let entries = scope List<DirEntry>();
		defer { for (var entry in ref entries) entry.Dispose(); }

		if (enumerable.Enumerate(folder, entries) case .Err)
			return;

		let suffix = scope String("."); suffix.Append(mExtension);
		for (let entry in entries)
		{
			if (entry.IsDirectory)
			{
				let child = group.[Friend]AddChildGroup(entry.Name);
				Scan(child, PathJoin(folder, entry.Name, .. scope:: String()));
			}
			else if (entry.Name.EndsWith(suffix))
			{
				ScanInstance(group, folder, entry.Name, suffix.Length);
			}
		}
	}

	/// Reads only the header of an envelope: identity, type, and the source file when the
	/// header names one. The object itself is left on disk until someone asks for it.
	private void ScanInstance(Group group, StringView folder, StringView fileName, int suffixLength)
	{
		let instanceName = StringView(fileName, 0, fileName.Length - suffixLength);

		let stream = mMount.Open(PathJoin(folder, fileName, .. scope String()), .Read);
		if (stream == null)
			return;
		defer delete stream;

		mScanStats.Envelopes++;
		let size = stream.Size();
		if (size > 0)
			mScanStats.BytesOpened += size;

		let context = mFactory(stream, .Read);
		if (context == null)
			return;
		defer delete context;

		let typeName = scope String();
		if (!Instance.[Friend]ReadHeader(context.Serializer, var id, typeName))
			return;
		// An envelope written before its header named the source does not: its record learns
		// it on first asking (Instance.SourceName).
		let source = scope String();
		let named = Instance.[Friend]ReadSource(context.Serializer, source);

		let instance = RegisterInstance(group, id, instanceName, typeName);
		if (named)
			instance.[Friend]SetSourceName(source);
	}

	// ---- refresh ----

	/// Brings the index in line with files that changed on disk after the scan, as a watcher
	/// reports them: mount relative paths of envelopes and of their data streams. Nothing on
	/// disk is touched.
	///
	/// - An envelope that appeared is registered, the groups of its folder made as needed.
	/// - One that changed is read again. The same identity and type keep their record, its
	///   source name refreshed, so code holding the record keeps a live one; another identity or
	///   type replaces it.
	/// - One that went is dropped from the index and freed; whoever was told of it by id finds
	///   nothing.
	/// - A data stream that changed reports its record changed; the index holds nothing of it.
	/// - An envelope present but unreadable (still being written, or broken) keeps its old
	///   record and is reported, for a later refresh of the path to try again.
	public void Refresh(Span<StringView> paths, ContentChanges outChanges)
	{
		let suffix = scope String(".");
		suffix.Append(mExtension);
		for (let path in paths)
		{
			if (path.EndsWith(suffix))
				RefreshEnvelope(path, StringView(path, 0, path.Length - suffix.Length), outChanges);
			else
				RefreshDataStream(path, outChanges);
		}
	}

	private void RefreshEnvelope(StringView path, StringView recordPath, ContentChanges outChanges)
	{
		let existing = GetInstanceByPath(recordPath);
		let stream = mMount.Open(path, .Read);
		if (stream == null)
		{
			if (existing != null)
			{
				let gone = existing.Id;
				ForgetInstance(existing);
				Note(outChanges.Removed, gone);
			}
			return;
		}
		defer delete stream;

		Guid id = default;
		let typeName = scope String();
		let source = scope String();
		bool named = false;
		bool readable = false;
		let context = mFactory(stream, .Read);
		if (context != null)
		{
			defer delete context;
			if (Instance.[Friend]ReadHeader(context.Serializer, out id, typeName) && (id != Guid.Empty))
			{
				readable = true;
				named = Instance.[Friend]ReadSource(context.Serializer, source);
			}
		}
		if (!readable)
		{
			outChanges.Unreadable.Add(new String(path));
			return;
		}

		if ((existing != null) && (existing.Id == id) && (existing.TypeName == typeName))
		{
			if (named)
				existing.[Friend]SetSourceName(source);
			else
				existing.[Friend]ForgetSourceName();
			Touch();
			Note(outChanges.Changed, id);
			return;
		}

		// A new record, or one whose identity or type changed under the same path.
		bool sameId = false;
		if (existing != null)
		{
			let previous = existing.Id;
			sameId = previous == id;
			ForgetInstance(existing);
			if (!sameId)
				Note(outChanges.Removed, previous);
		}
		var group = mRoot;
		var name = recordPath;
		let slash = recordPath.LastIndexOf('/');
		if (slash >= 0)
		{
			for (let part in StringView(recordPath, 0, slash).Split('/'))
			{
				if (!part.IsEmpty)
					group = group.[Friend]AddChildGroup(part);
			}
			name = StringView(recordPath, slash + 1);
		}
		let instance = RegisterInstance(group, id, name, typeName);
		if (named)
			instance.[Friend]SetSourceName(source);
		Note(sameId ? outChanges.Changed : outChanges.Added, id);
	}

	/// A data stream's sidecar is "<record path>.<stream>.data" (text) or ".bin" (binary).
	private void RefreshDataStream(StringView path, ContentChanges outChanges)
	{
		StringView rest;
		if (path.EndsWith(".data"))
			rest = StringView(path, 0, path.Length - 5);
		else if (path.EndsWith(".bin"))
			rest = StringView(path, 0, path.Length - 4);
		else
			return;
		let dot = rest.LastIndexOf('.');
		if (dot <= 0)
			return;
		if (let instance = GetInstanceByPath(StringView(rest, 0, dot)))
		{
			if (!outChanges.Added.Contains(instance.Id))
				Note(outChanges.Changed, instance.Id);
		}
	}

	/// Drops a record from the index and frees it, without touching its files. Another record
	/// claiming the same identity (two envelopes with one guid) takes the index over.
	private void ForgetInstance(Instance instance)
	{
		let id = instance.Id;
		instance.OwningGroup.[Friend]RemoveInstance(instance);
		mAllInstances.Remove(instance);
		if (mByGuid.TryGetValue(id, let indexed) && (indexed == instance))
		{
			mByGuid.Remove(id);
			for (let other in mAllInstances)
			{
				if (other.Id == id)
				{
					mByGuid[id] = other;
					break;
				}
			}
		}
		delete instance;
	}

	private static void Note(List<Guid> list, Guid id)
	{
		if (!list.Contains(id))
			list.Add(id);
	}

	// ---- sidecars ----

	/// Every sidecar belonging to an instance, found by enumerating its folder rather than
	/// by guessing stream names: the envelope does not list them.
	private void CollectSidecars(Instance instance, List<String> outPaths)
	{
		let enumerable = mMount as IEnumerableFileSystem;
		if (enumerable == null)
			return;

		let folder = instance.OwningGroup.GetPath(.. scope String());
		let entries = scope List<DirEntry>();
		defer { for (var entry in ref entries) entry.Dispose(); }
		if (enumerable.Enumerate(folder, entries) case .Err)
			return;

		let prefix = scope String(instance.Name); prefix.Append('.');
		let envelope = scope String(instance.Name); envelope.Append('.'); envelope.Append(mExtension);

		for (let entry in entries)
		{
			if (entry.IsDirectory || !entry.Name.StartsWith(prefix) || (entry.Name == envelope))
				continue;
			outPaths.Add(PathJoin(folder, entry.Name, .. new String()));
		}
	}

	private void DeleteSidecars(Instance instance)
	{
		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return;

		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		CollectSidecars(instance, paths);
		for (let path in paths)
			writable.Delete(path).IgnoreError();
	}

	private void CopySidecars(Instance source, Instance destination) => CopySidecarsAcross(source, this, destination);

	private void CopySidecarsAcross(Instance source, ContentDatabase sourceDatabase, Instance destination)
	{
		let writable = mMount as IWritableFileSystem;
		if (writable == null)
			return;

		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		sourceDatabase.CollectSidecars(source, paths);

		let sourceEnvelope = source.EnvelopePath(.. scope String());
		for (let path in paths)
		{
			let stream = sourceDatabase.Mount.Open(path, .Read);
			if (stream == null)
				continue;
			defer delete stream;

			let size = (int)stream.Size();
			let bytes = scope List<uint8>();
			if (size > 0)
			{
				let raw = bytes.GrowUninitialized(size);
				if (stream.Read(.(raw, size)) != size)
					continue;
			}

			let suffix = SidecarSuffix(path, sourceEnvelope);
			let target = scope String();
			destination.GetPath(target);
			target.Append(suffix);
			writable.Save(target, .(bytes.Ptr, bytes.Count)).IgnoreError();
		}
	}

	/// The part of a sidecar's path after the instance name: ".stream.bin" and the like.
	private static StringView SidecarSuffix(StringView sidecarPath, StringView envelopePath)
	{
		// The envelope is "<path>.<ext>", so the instance path is everything before its
		// last dot, and the sidecar shares that prefix.
		let lastDot = envelopePath.LastIndexOf('.');
		let prefixLength = (lastDot >= 0) ? lastDot : envelopePath.Length;
		if (sidecarPath.Length <= prefixLength)
			return "";
		return StringView(sidecarPath, prefixLength);
	}
}
