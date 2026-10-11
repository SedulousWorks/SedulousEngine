using System;
using Sedulous.Content;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// What the asset browser's and the asset picker's filter field finds: a name, or a guid or
/// its start, typed or pasted. The matching is the editor's one filter (SearchFilter).
static class AssetFilter
{
	/// Whether the filter finds `instance`, by name or by guid.
	public static bool Matches(Instance instance, StringView filter) =>
		SearchFilter.NameOrGuidMatches(instance.Name, instance.Id, filter);

	/// The guid the filter spells whole (all 32 digits; braces, case and dashes aside).
	public static bool AsGuid(StringView filter, out Guid outId) => SearchFilter.FilterAsGuid(filter, out outId);
}
