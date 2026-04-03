namespace Sedulous.Physics;

/// Interface for filtering physics queries.
/// Implement to customize which bodies are tested during queries.
interface IQueryFilter
{
	/// Returns true if the given body should be included in query results.
	bool ShouldInclude(BodyHandle body);
}
