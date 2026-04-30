namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.Resources;

/// Converts source files (.fbx, .gltf, .png, etc.) into baked engine resources.
///
/// Import flow:
///   1. GetSupportedExtensions() - discover which files this importer handles
///   2. CreatePreview(sourcePath) - analyze source, return list of importable items
///   3. User reviews/configures items in the import dialog
///   4. Import(preview, outputDir, registry) - save selected items, register GUIDs
interface IAssetImporter
{
	/// File extensions this importer handles (e.g. ".gltf", ".glb", ".fbx").
	void GetSupportedExtensions(List<String> outExtensions);

	/// Analyze a source file and return a preview of what will be imported.
	/// Called before showing the import dialog so the user can review and configure.
	Result<ImportPreview> CreatePreview(StringView sourcePath);

	/// Import selected items from the preview into the output directory.
	/// Registers each resource's GUID in the given registry.
	Result<void> Import(ImportPreview preview, StringView outputDir,
		ResourceRegistry registry, Sedulous.Serialization.ISerializerProvider serializer);
}

/// One importable item discovered in a source file.
class ImportPreviewItem
{
	/// Suggested filename (user-editable in import dialog).
	public String Name ~ delete _;

	/// File extension for the output (e.g. ".mesh", ".texture").
	public String Extension ~ delete _;

	/// Human-readable type label (e.g. "Static Mesh", "Texture").
	public String TypeLabel ~ delete _;

	/// Whether this item is selected for import.
	public bool Selected = true;

	/// Opaque index used by the importer to identify this item in its internal data.
	public int32 InternalIndex;
}

/// Preview of what an import will produce. Created by IAssetImporter.CreatePreview().
/// Owns all items and import options. Passed back to Import() after user configuration.
class ImportPreview : IDisposable
{
	/// Absolute path to the source file.
	public String SourcePath ~ delete _;

	/// Items that will be produced by the import.
	public List<ImportPreviewItem> Items = new .() ~ DeleteContainerAndItems!(_);

	/// Import options (importer-specific, may be null for simple importers).
	public ImportOptions Options ~ delete _;

	public void Dispose() { }
}

/// Base class for importer-specific options shown in the import dialog.
/// Subclassed by each importer (e.g. ModelImportDialogOptions).
abstract class ImportOptions
{
}
