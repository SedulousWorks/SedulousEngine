using System;
using System.Collections;

namespace Sedulous.UI.Toolkit;

/// The provider every language gets for free: the identifiers already in the buffer.
///
/// It knows nothing about the language, which is the point. A file being edited is its own best
/// dictionary long before a real language service is attached.
class DocumentWordCompletionProvider : ICompletionProvider
{
	private List<StringView> mScratch = new .() ~ delete _;

	public void Collect(CodeDocument document, CodePosition cursor, StringView prefix,
		List<CompletionCandidate> outCandidates)
	{
		mScratch.Clear();
		document.GetWords(mScratch);

		for (let word in mScratch)
		{
			// The fragment being typed is itself a harvested word, and suggesting it back
			// verbatim is noise. Longer words that extend it still match.
			if (word == prefix)
				continue;

			outCandidates.Add(new CompletionCandidate(word, word, 100));
		}
	}
}
