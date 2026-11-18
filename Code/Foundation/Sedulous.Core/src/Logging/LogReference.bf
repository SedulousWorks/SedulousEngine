using System;
using System.Collections;

namespace Sedulous.Core.Logging;

/// A place a log line points at, which a tool can follow (open the file at the line, select the
/// asset): its kind and its fields, in the order the kind gives them. Start and Length are the part
/// of the message that stands for it, in characters; a reference a log call attached has no part
/// (Length 0) and stands for the whole line.
class LogReference
{
	/// The kinds the engine makes; a plugin or a language may add its own.
	public const String Source = "source"; // fields: file (on disk, or a project's source path), line, column
	public const String Asset = "asset";   // fields: guid
	public const String Entity = "entity"; // fields: scene, path
	public const String Node = "node";     // fields: document, id

	public String Kind = new .() ~ delete _;
	public List<String> Fields = new .() ~ DeleteContainerAndItems!(_);
	public int Start;
	public int Length;

	public this(StringView kind)
	{
		Kind.Set(kind);
	}

	/// Field `index`, empty when it has fewer.
	public StringView Field(int index) => (index < Fields.Count) ? Fields[index] : default;

	public Self AddField(StringView value)
	{
		Fields.Add(new String(value));
		return this;
	}

	/// A copy, the caller's.
	public LogReference Clone()
	{
		let copy = new LogReference(Kind);
		for (let field in Fields)
			copy.Fields.Add(new String(field));
		copy.Start = Start;
		copy.Length = Length;
		return copy;
	}

	/// A file on disk, at a 1-based line and column (0: not given). The caller's.
	public static LogReference ForSource(StringView file, uint32 line = 0, uint32 column = 0)
	{
		let reference = new LogReference(Source);
		reference.AddField(file);
		reference.Fields.Add((line > 0) ? new String()..AppendF("{}", line) : new String());
		reference.Fields.Add((column > 0) ? new String()..AppendF("{}", column) : new String());
		return reference;
	}

	/// An asset, by its id. The caller's.
	public static LogReference ForAsset(Guid id)
	{
		let reference = new LogReference(Asset);
		reference.Fields.Add(id.ToString(.. new String(), 'D'));
		return reference;
	}
}
