using System;
using System.Collections;

namespace Sedulous.Editor.ViewportTools;

/// One palette group: the tools sharing a Category, in registration order, or a lone
/// uncategorised tool.
///
/// Groups come in first-appearance order, so a domain's registration order still decides
/// where its dropdown sits on the bar.
class ViewportToolGroup
{
	/// Empty for a lone tool.
	public String Category = new .() ~ delete _;
	/// Never empty.
	public List<String> ToolIds = new .() ~ DeleteContainerAndItems!(_);

	public this() {}
}

static class ViewportToolGrouping
{
	/// Groups every tool but the default, which is index 0 and is driven by the gizmo
	/// toggles rather than the palette. The list is filled with OWNED groups.
	public static void Group(ViewportToolManager manager, List<ViewportToolGroup> outGroups)
	{
		if (manager == null)
			return;
		for (int i = 1; i < manager.Count; i++)
		{
			let tool = manager.ToolAt(i);
			if (tool == null)
				continue;
			let category = tool.Category;
			ViewportToolGroup group = null;
			if (!category.IsEmpty)
			{
				for (let existing in outGroups)
				{
					if (existing.Category == category)
					{
						group = existing;
						break;
					}
				}
			}
			if (group == null)
			{
				group = new ViewportToolGroup();
				group.Category.Set(category);
				outGroups.Add(group);
			}
			group.ToolIds.Add(new String(tool.Id));
		}
	}
}
