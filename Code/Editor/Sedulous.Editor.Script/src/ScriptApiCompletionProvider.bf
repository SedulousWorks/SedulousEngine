using System;
using System.Collections;
using Sedulous.UI.Toolkit;
using Sedulous.Script;

namespace Sedulous.Editor.Script;

/// Completion from the bound API: after "Type." the type's members, else every type, an
/// editor-only one marked. An unknown receiver offers nothing, leaving the word provider
/// to contribute. The surface is BORROWED from the page.
class ScriptApiCompletionProvider : ICompletionProvider
{
	private ScriptApiSurface mSurface = null;

	public void SetSurface(ScriptApiSurface surface) => mSurface = surface;

	public void Collect(CodeDocument document, CodePosition cursor, StringView prefix, List<CompletionCandidate> outCandidates)
	{
		if (mSurface == null)
			return;
		let types = mSurface.Types;
		if (types.IsEmpty)
			return;
		let anchorColumn = cursor.Column - (int32)Utf8Length(prefix);
		if ((anchorColumn >= 1) && (document.CodepointAt(.(cursor.Line, anchorColumn - 1)) == (uint32)'.'))
		{
			if (anchorColumn < 2)
				return;
			let owner = document.WordAt(.(cursor.Line, anchorColumn - 2));
			if (owner.IsEmpty)
				return;
			let ownerName = document.GetTextInSpan(owner, .. scope .());
			for (let type in types)
			{
				if (type.ScriptName != ownerName)
					continue;
				for (let member in type.Members)
					outCandidates.Add(new CompletionCandidate(member.Name, member.Name));
				return;
			}
			return;
		}
		for (let type in types)
		{
			let label = scope String(type.ScriptName);
			if (mSurface.IsEditorOnly(type))
				label.Append(" [editor]");
			outCandidates.Add(new CompletionCandidate(label, type.ScriptName));
		}
	}

	private static int Utf8Length(StringView text)
	{
		int count = 0;
		for (let c in text.RawChars)
		{
			if (((uint8)c & 0xC0) != 0x80)
				count++;
		}
		return count;
	}
}
