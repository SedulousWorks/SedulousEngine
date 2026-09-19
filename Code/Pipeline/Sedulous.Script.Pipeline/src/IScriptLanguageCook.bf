using System;
using System.Collections;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Pipeline;

/// The per language cook: compile checks the source and harvests the class record from
/// it. A language's library provides one and registers it by language id, mirroring the
/// backends; the builder resolves it and never names a language.
interface IScriptLanguageCook
{
	/// Folded into the builder's version: bump when the cook's output changes.
	int32 CookVersion => 1;

	/// The source a new asset of this language starts with.
	void NewAssetTemplate(String outSource);

	/// Compiles `source`, harvests `className` (or the first class when empty) into the record,
	/// reporting anything wrong into `problems`. False when the source does not compile or
	/// the class is not in it.
	bool Cook(StringView source, StringView sourceName, StringView className, ScriptClassSource outRecord, List<String> problems);
}
