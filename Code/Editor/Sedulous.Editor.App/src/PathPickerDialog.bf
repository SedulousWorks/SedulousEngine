using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Editor.App;

// The path picker (Raptor's editor-gui spec, 5.2, layer 5): the picker over the files under a
// folder whose extension is one of those asked (ignoring case; none asked: every file), so a field
// that names a file can only name one that is there (a font's source, a profiler capture), and a
// cooked reference never dangles. Each file is a row by its name, under its folder (root-relative),
// sorted by path; its key is its root-relative path, with forward slashes. With none there it says
// so, naming the extensions and the folder.

/// The path picker's request: Picker opens it.
static class PathPicker
{
	/// The picker's request over the files under `root` with one of `extensions` (".ttf");
	/// `current` the root-relative path the field names now. The caller's (Picker.Open takes it).
	public static PickerRequest Request(StringView root, Span<StringView> extensions, StringView current = default)
	{
		let files = scope List<String>();
		defer { ClearAndDeleteItems!(files); }
		Files(root, extensions, files);
		files.Sort(scope (a, b) => a.CompareTo(b));
		let request = new PickerRequest();
		request.Placeholder.Set("Search files");
		request.Current.Set(current);
		for (let file in files)
		{
			let slash = file.LastIndexOf('/');
			let nested = slash >= 0;
			let item = request.Add(file,
				nested ? StringView(file, slash + 1) : (StringView)file,
				nested ? StringView(file, 0, slash) : default);
			item.Glyph.Set("Editor/Icons/file.svg");
		}
		let kinds = scope String();
		for (let ext in extensions)
		{
			if (!kinds.IsEmpty)
				kinds.Append(" or ");
			kinds.Append(ext);
		}
		if (kinds.IsEmpty)
			request.EmptyTitle.Set("No files here");
		else
			request.EmptyTitle.AppendF("No {} files here", kinds);
		request.EmptyText.AppendF("Nothing under {}.", root);
		return request;
	}

	/// Every file under `root` with one of `extensions`, root-relative, in the walk's order, added
	/// to `outFiles` (the caller's).
	public static void Files(StringView root, Span<StringView> extensions, List<String> outFiles)
	{
		let fs = scope NativeFileSystem(root);
		let pending = scope List<String>();
		defer { ClearAndDeleteItems!(pending); }
		pending.Add(new String());
		while (!pending.IsEmpty)
		{
			let folder = pending.PopBack();
			defer delete folder;
			let entries = scope List<DirEntry>();
			defer { for (var e in entries) e.Dispose(); }
			if (fs.Enumerate(folder, entries) case .Err)
				continue;
			for (let entry in entries)
			{
				let path = new String();
				if (folder.IsEmpty)
					path.Set(entry.Name);
				else
					PathJoin(folder, entry.Name, path);
				if (entry.IsDirectory)
					pending.Add(path);
				else if (Takes(path, extensions))
					outFiles.Add(path);
				else
					delete path;
			}
		}
	}

	/// Whether `name` ends with one of `extensions`, ignoring case; none: any.
	public static bool Takes(StringView name, Span<StringView> extensions)
	{
		if (extensions.IsEmpty)
			return true;
		for (let ext in extensions)
		{
			if (name.EndsWith(ext, .OrdinalIgnoreCase))
				return true;
		}
		return false;
	}
}
