using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.VFS;

namespace Sedulous.Editor.Core;

/// export_roots.xml on the project root, and the group walks the roots seed from.
static class ExportRootsFile
{
	public const String cFileName = "export_roots.xml";

	public static Result<void, ErrorCode> Load(IFileSystem root, ExportRootsSet outRoots, StringView fileName = cFileName)
		=> XmlDocumentFile.Load(root, outRoots, fileName);

	public static Result<void, ErrorCode> Save(IWritableFileSystem writable, ExportRootsSet roots, StringView fileName = cFileName)
		=> XmlDocumentFile.Save(writable, roots, fileName);

	/// A group by its slash joined path; the root for an empty path, null when a segment is
	/// missing.
	public static Group FindGroupByPath(ContentDatabase db, StringView path)
	{
		var group = db.RootGroup;
		for (let part in path.Split('/'))
		{
			if (part.IsEmpty)
				continue;
			group = group.GetGroup(part);
			if (group == null)
				return null;
		}
		return group;
	}

	/// Every instance under the group subtree, not its siblings.
	public static void CollectGroupInstances(ContentDatabase db, StringView groupPath, List<Guid> outIds)
	{
		let start = FindGroupByPath(db, groupPath);
		if (start == null)
			return;
		let stack = scope List<Group>();
		stack.Add(start);
		while (!stack.IsEmpty)
		{
			let group = stack.PopBack();
			for (let instance in group.Instances)
				outIds.Add(instance.Id);
			for (let child in group.Groups)
				stack.Add(child);
		}
	}
}
