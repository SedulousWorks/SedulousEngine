using System;
using Sedulous.Model;

namespace Sedulous.Model.IO;

// `Model` alone resolves to the enclosing NAMESPACE here, not the class, so the model type
// gets a name of its own.
typealias ModelData = Sedulous.Model.Model;

/// A loader for one model file format.
///
/// Format specific loaders register themselves and the registry dispatches by extension,
/// so a caller loads a model without naming a format and adding a format touches nothing
/// that already exists.
interface IModelLoader
{
	/// Whether this loader handles an extension, WITH its dot, such as ".gltf".
	///
	/// @extension because `extension` is a Beef keyword.
	bool SupportsExtension(StringView @extension);

	/// Loads into the model, replacing what it holds.
	ModelLoadResult Load(StringView path, ModelData model);
}
