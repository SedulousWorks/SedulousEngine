using System;
using System.Collections;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Completion for UI MARKUP documents, fed by [[MarkupRegistry]]'s real vocabulary, which is
/// the same set of tables the loader validates against.
///
/// Element names right after an opening angle bracket or a closing one, attribute names inside
/// a tag: the element's own registered properties plus the layout vocabulary. Which layout
/// parameters actually apply depends on the PARENT container, which the line does not know, so
/// the union is offered rather than a guess.
///
/// The context is line local, and plain text between tags offers nothing.
///
/// It lives in the toolkit rather than in an editor page because MarkupRegistry is part of the
/// UI core itself, the same generic tier as [[XmlLexer]]. A script language's provider belongs
/// with that language's editor module instead.
class MarkupCompletionProvider : ICompletionProvider
{
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);

	public void Collect(CodeDocument document, CodePosition cursor, StringView prefix,
		List<CompletionCandidate> outCandidates)
	{
		let line = document.Line(cursor.Line);
		let anchorColumn = cursor.Column - Utf8Text.CharCount(prefix);
		let anchorByte = document.ColumnToByte(cursor.Line, anchorColumn);

		// The tag being written is the last UNCLOSED angle bracket before the prefix.
		int tagOpen = -1;
		for (int i = 0; (i < anchorByte) && (i < line.Length); i++)
		{
			if (line[i] == '<')
				tagOpen = i;
			else if (line[i] == '>')
				tagOpen = -1;
		}

		if (tagOpen < 0)
			return; // plain text between tags

		var nameBegin = tagOpen + 1;
		if ((nameBegin < line.Length) && (line[nameBegin] == '/'))
			nameBegin++;

		var nameEnd = nameBegin;
		while ((nameEnd < line.Length) && IsNameChar(line[nameEnd]))
			nameEnd++;

		if ((anchorByte >= nameBegin) && (anchorByte <= nameEnd))
			MarkupRegistry.CollectElementNames(mNames);
		else
			MarkupRegistry.CollectAttributeNames(line.Substring(nameBegin, nameEnd - nameBegin),
				mNames);

		for (let name in mNames)
			outCandidates.Add(new CompletionCandidate(name, name));
	}

	private static bool IsNameChar(char8 c) =>
		((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) ||
		(c == '_') || (c == ':') || (c == '-');
}
