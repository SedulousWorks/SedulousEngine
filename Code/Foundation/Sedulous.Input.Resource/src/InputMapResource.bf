using Sedulous.Core.Serialization;
using Sedulous.Input;

namespace Sedulous.Input.Resource;

/// The cooked form of an input map, and the runtime product built from it.
///
/// The SAME type both sides of the cook, because there is nothing to transform: a map is
/// data all the way down, with no GPU form and no build step beyond the validation the
/// cook already ran. A factory that decoded one shape into another would only be moving
/// bytes around.
[Serializable]
class InputMapResource
{
	public InputMap Map = new .() ~ delete _;
}
