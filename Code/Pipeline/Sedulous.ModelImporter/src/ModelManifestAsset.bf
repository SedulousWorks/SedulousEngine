using Sedulous.Core.Serialization;
using Sedulous.Model.Resource;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// The source asset an import writes for the model as a whole: the manifest it produced, plus
/// the decisions that produced it.
///
/// The identities inside are SOURCE identities, and the cook writes the manifest through
/// unchanged, so a source identity and its product's are the same one. That is what lets a
/// material written at import already name the textures written beside it.
[Serializable]
class ModelManifestAsset : Asset
{
	/// The manifest the cook writes out verbatim. The file name beside it is the model file
	/// the import read, which is also the seed a re-import starts from.
	public ModelManifestSource Manifest = new .() ~ delete _;

	/// Re-import memory: the review dialog's decisions from the import that wrote this, which
	/// a re-import merges onto the fresh plan instead of asking again.
	public ImportPlan ImportSelection = new .() ~ delete _;
}
