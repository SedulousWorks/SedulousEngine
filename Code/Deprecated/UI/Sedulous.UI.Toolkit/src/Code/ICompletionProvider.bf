using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// A completion source.
///
/// Providers are COMPOSABLE: the view queries every registered one and merges the results,
/// deduped by label and sorted by tier. `prefix` is the identifier fragment left of the cursor,
/// and may be empty for an explicit Ctrl+Space request or a trigger character.
///
/// Appends to `outCandidates`, which TAKES OWNERSHIP of every candidate added.
interface ICompletionProvider
{
	void Collect(CodeDocument document, CodePosition cursor, StringView prefix,
		List<CompletionCandidate> outCandidates);
}
