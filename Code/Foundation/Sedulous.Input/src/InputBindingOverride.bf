using System;
using System.Collections;

namespace Sedulous.Input;

/// One action's REPLACEMENT bindings, as a user chose them.
///
/// A replacement rather than a patch: rebinding is "these are the keys now", and a merge
/// would leave a player wondering which of the old ones still worked.
class InputBindingOverride
{
	public String SetName = new .() ~ delete _;
	public String ActionName = new .() ~ delete _;
	public List<Binding> Bindings = new .() ~ delete _;
}
