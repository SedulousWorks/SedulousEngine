using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.UI.Pipeline;

/// A markup document.
///
/// The markup lives ONLY in the linked source file, never inline: an asset that embedded it
/// would be a second copy to keep in step with the one on disk.
[DisplayName("UI Document")]
[Category("UI")]
[Serializable]
class UIDocumentAsset : Asset
{
}
