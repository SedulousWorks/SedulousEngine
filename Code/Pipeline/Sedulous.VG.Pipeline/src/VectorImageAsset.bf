using Sedulous.Core;
using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.VG.Pipeline;

/// A vector image: a LINKED `.svg` in Sources/, like a UI document or a script. A UI theme
/// names one with `@icon name "{guid}"` and draws it with `svg(name, tint=...)`.
[DisplayName("Vector Image")]
[Category("Vector Graphics")]
[Serializable]
class VectorImageAsset : Asset
{
}
