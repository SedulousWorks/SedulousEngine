using System;
using Sedulous.Core.Serialization;

namespace Sedulous.UI.Resource;

/// The cooked form of a UI theme: a validated style sheet payload.
[Serializable(1)]
class UIThemeResource
{
	public String StyleSheet = new .() ~ delete _;
}
