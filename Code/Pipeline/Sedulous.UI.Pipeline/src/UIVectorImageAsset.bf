using Sedulous.Core;
using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.UI.Pipeline;

/// A vector image: a LINKED `.svg` in Sources/, like the documents and themes. A theme names it
/// with `@icon name "{guid}"` and draws it with `svg(name, tint=...)`.
[DisplayName("Vector Image")]
[Category("UI")]
[Serializable]
class UIVectorImageAsset : Asset
{
}
