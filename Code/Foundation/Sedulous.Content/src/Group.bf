using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Content;

/// A folder in the tree: child groups and instances.
///
/// Children stay NAME SORTED, case insensitively. A mount scan hands entries back in
/// whatever order the filesystem felt like, and imports append, so without an invariant
/// every browser and picker showed a different order each session.
///
/// Owned by the database, along with everything under it.
class Group
{
	private ContentDatabase mDatabase;
	private Group mParent;
	private String mName = new .() ~ delete _;
	/// Both lists hold borrowed pointers: the database owns every node.
	private List<Group> mGroups = new .() ~ delete _;
	private List<Instance> mInstances = new .() ~ delete _;

	public this(ContentDatabase database, Group parent, StringView name)
	{
		mDatabase = database;
		mParent = parent;
		mName.Set(name);
	}

	public StringView Name => mName;
	public Group Parent => mParent;
	public List<Group> Groups => mGroups;
	public List<Instance> Instances => mInstances;

	/// The mount-relative folder path: empty at the root, "materials/metal" deeper.
	///
	/// Derived by walking up rather than stored, so renaming a group needs no fixup in
	/// anything beneath it.
	public void GetPath(String outPath)
	{
		outPath.Clear();
		if (mParent == null)
			return; // the root is the mount itself

		mParent.GetPath(outPath);
		if (outPath.IsEmpty)
			outPath.Set(mName);
		else
			PathJoin(scope String(outPath), mName, outPath);
	}

	public Group GetGroup(StringView name)
	{
		for (let group in mGroups)
		{
			if (group.Name == name)
				return group;
		}
		return null;
	}

	public Instance GetInstance(StringView name)
	{
		for (let instance in mInstances)
		{
			if (instance.Name == name)
				return instance;
		}
		return null;
	}

	// ---- tooling ----

	/// The child group of this name, creating it if there is none. Nothing reaches disk
	/// until an instance under it is written.
	public Group CreateGroup(StringView name)
	{
		if (let existing = GetGroup(name))
			return existing;
		return AddChildGroup(name);
	}

	/// A new instance with a fresh identity. The file appears once WriteObject is called.
	///
	/// A NAME ALREADY TAKEN RETURNS THE EXISTING INSTANCE, which is what makes a reimport
	/// or a re-cook idempotent. A creator making a brand new asset must therefore ask for
	/// UniqueInstanceName first, or it will write its starter object over whatever was
	/// already there.
	public Instance CreateInstance(StringView name, StringView typeName)
	{
		return CreateInstanceWithId(Guid.Create(), name, typeName);
	}

	/// The same, with a caller-chosen identity: a cook keeps the product's guid equal to
	/// the source's so the two stay linked across databases.
	public Instance CreateInstanceWithId(Guid id, StringView name, StringView typeName)
	{
		if (let existing = GetInstance(name))
			return existing;
		return mDatabase.[Friend]RegisterInstance(this, id, name, typeName);
	}

	/// The first free name from a base: the base itself, then "base.2", "base.3". The one
	/// general answer for a creator that must not overwrite.
	public void UniqueInstanceName(StringView @base, String outName)
	{
		outName.Set(@base);
		if (GetInstance(outName) == null)
			return;

		for (int suffix = 2; ; suffix++)
		{
			outName.Clear();
			outName.AppendF("{}.{}", @base, suffix);
			if (GetInstance(outName) == null)
				return;
		}
	}

	/// The same convention for a child group.
	public void UniqueGroupName(StringView @base, String outName)
	{
		outName.Set(@base);
		if (GetGroup(outName) == null)
			return;

		for (int suffix = 2; ; suffix++)
		{
			outName.Clear();
			outName.AppendF("{}.{}", @base, suffix);
			if (GetGroup(outName) == null)
				return;
		}
	}

	// ---- used by the scanner and the database ----

	internal Group AddChildGroup(StringView name)
	{
		if (let existing = GetGroup(name))
			return existing;

		let group = mDatabase.[Friend]RegisterGroup(this, name);
		InsertSorted(mGroups, group, scope (a, b) => NameLess(a.Name, b.Name));
		return group;
	}

	internal void AddInstanceNode(Instance instance)
	{
		InsertSorted(mInstances, instance, scope (a, b) => NameLess(a.Name, b.Name));
	}

	/// Unlinks without destroying: the database owns every node and frees them together.
	internal void RemoveInstance(Instance instance)
	{
		mInstances.Remove(instance);
	}

	internal void RemoveGroup(Group group)
	{
		mGroups.Remove(group);
	}

	/// Re-establishes the order after a child was renamed under it.
	internal void ResortChildren()
	{
		mGroups.Sort(scope (a, b) => NameLess(a.Name, b.Name) ? -1 : (NameLess(b.Name, a.Name) ? 1 : 0));
		mInstances.Sort(scope (a, b) => NameLess(a.Name, b.Name) ? -1 : (NameLess(b.Name, a.Name) ? 1 : 0));
	}

	internal void SetName(StringView name) => mName.Set(name);

	private static void InsertSorted<T>(List<T> list, T item, delegate bool(T, T) less)
	{
		for (int i < list.Count)
		{
			if (less(item, list[i]))
			{
				list.Insert(i, item);
				return;
			}
		}
		list.Add(item);
	}

	/// Case insensitive, so a browser's order does not depend on how a file was typed.
	private static bool NameLess(StringView a, StringView b)
	{
		let shorter = (a.Length < b.Length) ? a.Length : b.Length;
		for (int i < shorter)
		{
			let ca = ToLowerAscii(a[i]);
			let cb = ToLowerAscii(b[i]);
			if (ca != cb)
				return ca < cb;
		}
		return a.Length < b.Length;
	}

	private static char8 ToLowerAscii(char8 c) => ((c >= 'A') && (c <= 'Z')) ? (char8)(c - 'A' + 'a') : c;
}
