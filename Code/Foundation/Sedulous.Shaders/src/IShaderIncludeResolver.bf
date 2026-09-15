using System;

namespace Sedulous.Shaders;

/// Serves `#include` requests during a compile from wherever the caller's sources live.
///
/// With one of these set the compiler never touches the native filesystem for an include, so a
/// shader corpus behind a VFS mount, a pak or memory resolves the same way a directory does.
///
/// `path` arrives as the preprocessor formed it, normalised to forward slashes with any leading
/// "./" stripped: relative to the INCLUDING file's directory. The main source has no directory,
/// so a first level include arrives bare ("common.hlsli") and a nested one carries the
/// includer's prefix. False means not found, and the preprocessor reports the miss itself.
interface IShaderIncludeResolver
{
	bool LoadInclude(StringView path, String outSource);
}
