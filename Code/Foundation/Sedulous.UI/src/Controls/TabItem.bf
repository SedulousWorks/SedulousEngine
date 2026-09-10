using System;

namespace Sedulous.UI;

/// One tab in a TabView: its title, its page, and whether it can be closed.
class TabItem
{
	public String Title = new .() ~ delete _;
	/// BORROWED: the page is a logical child of the TabView, so the group's own reference is
	/// the owning one.
	public View Content = null;
	public bool IsClosable = false;
}
