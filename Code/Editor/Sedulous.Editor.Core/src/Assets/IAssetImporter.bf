namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Converts source files (.fbx, .png, .hlsl) into engine asset formats.
interface IAssetImporter
{
	void GetSupportedExtensions(List<String> outExtensions);
	Result<void> Import(StringView sourcePath, StringView outputPath);
}
