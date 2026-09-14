using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// Copying the files a .gltf points at into the project beside it.
///
/// The text form keeps its buffers and images in SIBLING files, so importing only the .gltf
/// leaves a source set that cannot be read again. Every relative reference is copied,
/// preserving the relative path, which is what the references inside the copied file still
/// spell.
static class GltfSidecars
{
	/// Copies every relative reference from beside the original file into the sources tree.
	///
	/// A failure only warns: the import itself already succeeded from the original, and losing
	/// one sidecar is not a reason to lose the model.
	public static void Copy(StringView originalPath, ImportContext context,
		List<DeferredImportWrite> deferredWrites)
	{
		let bytes = scope List<uint8>();
		if (ReadFile(originalPath, bytes) case .Err)
			return;

		let text = StringView((char8*)bytes.Ptr, bytes.Count);

		var dirEnd = 0;
		for (int i = originalPath.Length; i > 0; --i)
		{
			let c = originalPath[i - 1];
			if ((c == '/') || (c == '\\'))
			{
				dirEnd = i;
				break;
			}
		}
		let dir = originalPath.Substring(0, dirEnd);

		// A plain text scan rather than a parse: the references live in string values under a
		// known key, and the import has no reason to hold a whole JSON document in memory
		// alongside the model it already loaded.
		let key = "\"uri\"";
		for (int i = 0; (i + key.Length) < text.Length; ++i)
		{
			if (text.Substring(i, key.Length) != key)
				continue;

			var j = i + key.Length;
			while ((j < text.Length) && ((text[j] == ':') || (text[j] == ' ')
				|| (text[j] == '\t')))
			{
				j++;
			}
			if ((j >= text.Length) || (text[j] != '"'))
				continue;

			let begin = ++j;
			while ((j < text.Length) && (text[j] != '"'))
				j++;
			if (j >= text.Length)
				break;

			let uri = text.Substring(begin, j - begin);
			i = j;

			if (uri.IsEmpty)
				continue;
			// An inline payload is already inside the file that was copied.
			if ((uri.Length >= 5) && (uri.Substring(0, 5) == "data:"))
				continue;
			// A reference climbing out of the model's own directory would land outside the
			// sources tree, which is not somewhere an import may write.
			var escapes = false;
			for (int k = 0; (k + 1) < uri.Length; ++k)
			{
				if ((uri[k] == '.') && (uri[k + 1] == '.'))
				{
					escapes = true;
					break;
				}
			}
			if (escapes)
				continue;

			let from = scope String(dir);
			from.Append(uri);

			if (deferredWrites != null)
			{
				let copy = new DeferredImportWrite();
				copy.CopyFrom.Set(from);
				PathJoin(context.SourcesRoot, uri, copy.CopyTo);
				deferredWrites.Add(copy);
				continue;
			}

			let payload = scope List<uint8>();
			if (ReadFile(from, payload) case .Err)
				continue; // a missing sidecar, which the model itself already worked without

			let target = scope String();
			PathJoin(context.SourcesRoot, uri, target);
			// A NESTED reference, which "textures/x.jpg" is, needs its parents made first.
			let slash = target.LastIndexOf('/');
			if (slash > 0)
				CreateDirectory(StringView(target, 0, slash));
			WriteFile(target, payload).IgnoreError();
		}
	}
}
