using System;
using Sedulous.Core.Serialization;

namespace Sedulous.UI.Resource;

/// The cooked form of a UI document: a validated markup payload.
///
/// Only the markup is stored. A document is a TEMPLATE, and the tree it describes is built
/// fresh per canvas, so there is nothing else about it worth cooking.
[Serializable(1)]
class UIDocumentResource
{
	public String Markup = new .() ~ delete _;
}
