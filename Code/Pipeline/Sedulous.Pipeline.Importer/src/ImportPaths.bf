using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Importer;

/// The path and plan work every importer repeats.
///
/// Hand written rather than reached for from the core path helpers: these take and give
/// STRING VIEWS into the caller's own path, so the common cases cost no allocation, and the
/// lowercase rule for extensions is the routing key rather than a formatting choice.
static class ImportPaths
{
	/// The lowercased extension of a path, without the dot, appended to `outExtension`.
	public static void ExtensionLower(StringView path, String outExtension)
	{
		var dot = path.Length;
		for (int i = path.Length; i > 0; --i)
		{
			let c = path[i - 1];
			if (c == '.')
			{
				dot = i;
				break;
			}
			if ((c == '/') || (c == '\\'))
				break;
		}
		for (int i = dot; i < path.Length; ++i)
		{
			let c = path[i];
			outExtension.Append(((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c);
		}
	}

	/// The final path component: "/a/b/foo.png" gives "foo.png".
	public static StringView FileNameOf(StringView path)
	{
		for (int i = path.Length; i > 0; --i)
		{
			let c = path[i - 1];
			if ((c == '/') || (c == '\\'))
				return path.Substring(i);
		}
		return path;
	}

	/// The stem, which is what an instance gets named: "foo.png" gives "foo".
	public static StringView StemOf(StringView fileName)
	{
		for (int i = fileName.Length; i > 0; --i)
		{
			if (fileName[i - 1] == '.')
				return fileName.Substring(0, i - 1);
		}
		return fileName;
	}

	/// The plan of a SINGLE asset importer: one entry named after the file's stem. The shared
	/// DescribeImport for a texture, an image, audio, a font, a heightfield or a splat map.
	public static void SingleAssetPlan(StringView sourcePath, ImportPlan outPlan)
	{
		let stem = StemOf(FileNameOf(sourcePath));
		outPlan.Add(new ImportPlanEntry(.Asset, stem, stem));
	}

	/// The instance name a single asset importer should CLAIM: the user's rename when the
	/// selection carries one, and the stem otherwise.
	public static StringView SingleAssetName(ImportOptions options, StringView stem)
		=> (options != null) ? options.SelectionName(.Asset, stem) : stem;

	/// Re-import memory for a single asset importer: the asset a PREVIOUS import of this source
	/// created in the group, with its CURRENT name as the stored rename.
	///
	/// Matched by the typed file name back reference rather than by name, so an asset the user
	/// renamed is still found. The type name filters candidates before the envelope read,
	/// which is the expensive part.
	public static void SingleAssetStoredSelection(Group group, StringView sourcePath,
		StringView typeName, ImportPlan outPlan)
	{
		let fileName = FileNameOf(sourcePath);
		if (fileName.IsEmpty)
			return;

		for (let instance in group.Instances)
		{
			if (instance.TypeName != typeName)
				continue;

			// THE CALLER OWNS what the read returns.
			let object = instance.ReadObject();
			if (object == null)
				continue;
			defer delete object;

			// An interface handle reaches its class through the object it is part of.
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset;
			if ((asset == null) || (asset.FileName.Value != fileName))
				continue;

			outPlan.Add(new ImportPlanEntry(.Asset, StemOf(fileName), instance.Name));
			return;
		}
	}

	/// Copies an OS file into the project's sources tree, appending the sources relative name
	/// the asset should reference.
	///
	/// An existing file with the SAME bytes is left untouched, so nothing downstream re-cooks.
	/// CHANGED bytes overwrite it: a re-import has to see the edited file, and the older skip
	/// if present behaviour silently kept a stale source forever.
	public static Result<void, ErrorCode> CopyIntoSources(ImportContext context,
		StringView sourcePath, String outFileName)
	{
		let fileName = FileNameOf(sourcePath);
		if (fileName.IsEmpty)
			return .Err(.InvalidArgument);

		let target = scope String();
		PathJoin(context.SourcesRoot, fileName, target);

		let bytes = scope List<uint8>();
		if (ReadFile(sourcePath, bytes) case .Err(let error))
			return .Err(error);

		if (FileExists(target))
		{
			let existing = scope List<uint8>();
			if ((ReadFile(target, existing) case .Ok) && (existing.Count == bytes.Count))
			{
				var same = true;
				for (int i < bytes.Count)
				{
					if (existing[i] != bytes[i])
					{
						same = false;
						break;
					}
				}
				if (same)
				{
					outFileName.Append(fileName);
					return .Ok; // identical, so no touch and no re-cook churn
				}
			}
		}

		if (WriteFile(target, bytes) case .Err(let writeError))
			return .Err(writeError);

		outFileName.Append(fileName);
		return .Ok;
	}
}
