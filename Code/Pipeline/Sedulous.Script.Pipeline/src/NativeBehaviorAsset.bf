using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Script.Pipeline;

/// A behavior written in native code: it names the class by its full name ("NativeSample.Orb"),
/// which a plugin of the project builds in. It cooks into an ordinary BehaviorClass of language
/// `native`, so an entity, a scene or the project refers to it as it refers to a script's class.
/// No file: the class is the plugin's.
[Category("Scripting")]
[DisplayName("Native Behavior")]
[Serializable]
class NativeBehaviorAsset : Asset
{
	/// The class's full name, which a plugin of the project builds in.
	[DisplayName("Class"), Description("The native class's full name (NativeSample.Orb), which a plugin of the project builds in")]
	public String ClassName = new .() ~ delete _;
}
