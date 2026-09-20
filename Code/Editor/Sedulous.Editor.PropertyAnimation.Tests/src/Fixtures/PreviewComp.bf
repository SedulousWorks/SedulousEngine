using System;
using Sedulous.Core;

namespace Sedulous.Editor.PropertyAnimation.Tests;

/// A plain reflected value component: its fields are visible through the manager's component
/// type, so the binding resolver finds them.
[Reflect(.Type | .NonStaticFields)]
struct PreviewComp
{
	public Float3 Position = .(0.0f, 0.0f, 0.0f);

	public this() {}
}
