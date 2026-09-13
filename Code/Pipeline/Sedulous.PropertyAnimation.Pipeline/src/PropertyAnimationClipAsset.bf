using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.PropertyAnimation.Resource;

namespace Sedulous.PropertyAnimation.Pipeline;

/// The authored clip.
///
/// The source IS the cooked wire, edited in place by the clip page, so the builder writes it
/// through unchanged. Clips are authored in the editor and have no OS file importer, which is
/// why the file name a plain asset carries goes unused here.
[Serializable]
class PropertyAnimationClipAsset : Asset
{
	public PropertyAnimationClipSource Source = new .() ~ delete _;
}
