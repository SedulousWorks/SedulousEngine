using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.IO;

/// Whole-file helpers and the directory queries, on one surface.
///
/// The whole-file helpers go through FileStream rather than corlib's File, so they
/// exercise the same stack everything else in Core does.
static
{
	/// Reads an entire file, replacing whatever outData held. On failure it is left empty
	/// rather than partly filled.
	public static Result<void, ErrorCode> ReadFile(StringView path, List<uint8> outData)
	{
		outData.Clear();

		let file = scope FileStream(path, .Read);
		if (!file.IsValid)
			return .Err(.NotFound);

		let size = file.Size();
		if (size < 0)
			return .Err(.Internal);
		if (size == 0)
			return .Ok;

		let buffer = outData.GrowUninitialized((int)size);
		if (file.Read(.(buffer, (int)size)) != (int)size)
		{
			outData.Clear();
			return .Err(.Internal);
		}
		return .Ok;
	}

	/// Writes a buffer to a file, replacing any existing contents.
	public static Result<void, ErrorCode> WriteFile(StringView path, Span<uint8> data)
	{
		let file = scope FileStream(path, .Write);
		if (!file.IsValid)
			return .Err(.Internal);
		if (data.Length == 0)
			return .Ok;
		if (file.Write(data) != data.Length)
			return .Err(.Internal);
		return .Ok;
	}

	public static bool FileExists(StringView path) => System.IO.File.Exists(path);

	public static bool DeleteFile(StringView path) => System.IO.File.Delete(path) case .Ok;

	public static bool DirectoryExists(StringView path) => System.IO.Directory.Exists(path);

	public static bool CreateDirectory(StringView path) => System.IO.Directory.CreateDirectory(path) case .Ok;

	/// Empty directories only, which is all the platform primitive does. A populated one
	/// fails quietly, which is how stale test scratch directories accumulate.
	public static bool RemoveDirectory(StringView path) => System.IO.Directory.Delete(path) case .Ok;

	/// A directory and everything under it. A directory that is already absent counts as
	/// gone, so this is idempotent.
	public static bool RemoveDirectoryRecursive(StringView path)
	{
		if (!System.IO.Directory.Exists(path))
			return true;
		return System.IO.Directory.DelTree(path) case .Ok;
	}
}
