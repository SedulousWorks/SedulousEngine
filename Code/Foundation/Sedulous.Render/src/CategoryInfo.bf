using System;

namespace Sedulous.Render;

/// What the registry knows about one category.
struct CategoryInfo
{
	/// BORROWED: the name is a literal the registrant keeps alive.
	public StringView Name = default;
	public SortMode Sort = .FrontToBack;
	public PassAffinity Affinity = .None;

	public this() {}

	public this(StringView name, SortMode sort, PassAffinity affinity)
	{
		Name = name;
		Sort = sort;
		Affinity = affinity;
	}
}
