using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook.Tests;

/// A stand in asset: a setting, and optionally a source file.
///
/// Deliberately trivial. What the cases measure is the DRIVER, so an asset that cooked
/// anything real would only add ways for a case to fail for the wrong reason.
[Serializable]
class CookWidgetAsset : Asset
{
	public int32 Quality = 1;
}
