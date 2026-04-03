namespace Sedulous.Models;

using System;

/// Unified result enum for model loading operations.
public enum ModelLoadResult
{
	Ok,
	FileNotFound,
	ParseError,
	InvalidFormat,
	UnsupportedVersion,
	BufferLoadError,
	UnsupportedFormat
}

/// Interface for model file loaders (format-specific backends).
public interface IModelLoader
{
	/// File extensions this loader supports (e.g., ".gltf", ".glb", ".fbx").
	Span<StringView> SupportedExtensions { get; }

	/// Check if this loader supports the given file extension.
	bool SupportsExtension(StringView fileExtension);

	/// Load a model from a file path into the given Model.
	ModelLoadResult Load(StringView path, Model model);
}
