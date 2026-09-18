using Sedulous.Core;

namespace Sedulous.Materials;

/// The depth test and write preset.
[Scriptable(.AllPublic)]
enum DepthMode : uint8
{
	case Disabled;
	case ReadWrite;
	/// Tests but does not write, which is what a transparent pass wants: it must not
	/// occlude what comes after it.
	case ReadOnly;
	case WriteOnly;
}
