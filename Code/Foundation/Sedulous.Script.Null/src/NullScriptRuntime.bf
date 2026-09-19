using System;
using System.Collections;
using Sedulous.Script;

namespace Sedulous.Script.Null;

/// The backend with no VM: it binds a surface and writes it out as text.
///
/// What it is for is looking at the surface, before and after a real backend exists: a
/// test dumps the whole engine's and a person reads what a script would see. The listing
/// is grouped by domain, then by namespace, one type per block, with type names shortened
/// to their last segment because the namespace is already in the heading.
class NullScriptRuntime : ScriptRuntime
{
	public override StringView Name => "Null";

	/// The bound surface as a listing.
	public void Describe(String outText)
	{
		if (mSurface == null)
		{
			outText.Append("(no surface bound)\n");
			return;
		}

		let domains = scope List<String>();
		defer { ClearAndDeleteItems(domains); }
		mSurface.CollectDomains(domains);

		int callable = 0, blocked = 0;
		for (let t in mSurface.Types)
		{
			for (let m in t.Methods)
			{
				if (m.IsCallable) callable++; else blocked++;
			}
			for (let f in t.Fields)
			{
				if (f.Get != null) callable++; else blocked++;
			}
		}
		outText.AppendF("script surface: {} types, {} members bound, {} blocked", mSurface.Types.Count, callable, blocked);
		outText.Append(", domains:");
		for (let d in domains)
			outText.AppendF(" {}", d);
		outText.Append("\n");

		for (let domain in domains)
		{
			outText.AppendF("\n== domain {} ==\n", domain);
			let lastNamespace = scope String();
			for (let t in mSurface.Types)
			{
				if (t.Domain != domain)
					continue;
				if (t.Namespace != lastNamespace)
				{
					outText.AppendF("\n-- {} --\n", t.Namespace);
					lastNamespace.Set(t.Namespace);
				}
				DescribeType(t, outText);
			}
		}
	}

	private static void DescribeType(ScriptTypeInfo t, String o)
	{
		o.Append("\n");
		switch (t.Kind)
		{
		case .Global:
			o.Append("global functions");
		case .Class:
			o.AppendF("class {}", t.Name);
		case .Struct:
			o.AppendF("struct {}", t.Name);
		case .Enum:
			o.AppendF("enum {}", t.Name);
		}

		if (t.Role != .Plain)
			o.AppendF(" [{}]", t.Role);
		if (t.AllPublic)
			o.Append(" [all public]");
		if (!t.DisplayName.IsEmpty)
			o.AppendF(" \"{}\"", t.DisplayName);
		if (!t.Category.IsEmpty)
			o.AppendF(" ({})", t.Category);
		if (!t.ComponentTypeId.IsEmpty)
			o.AppendF(" id={}", t.ComponentTypeId);
		if (!t.ManagerTypeName.IsEmpty)
			o.AppendF(" manager={}", Short(t.ManagerTypeName, .. scope .()));
		else if (t.Role == .Component)
			o.Append(" manager=NONE");
		o.Append("\n");
		if (!t.Description.IsEmpty)
			o.AppendF("    // {}\n", t.Description);

		for (let v in t.EnumValues)
			o.AppendF("    {} = {}\n", v.Name, v.Value);

		for (let f in t.Fields)
		{
			o.Append("    ");
			if (f.IsStatic)
				o.Append("static ");
			o.AppendF("{}: {}", f.ScriptName, Short(f.TypeName, .. scope .()));
			if (f.Kind == .Guid && f.TypeName.StartsWith("Sedulous.Resource.Ref<"))
				o.Append(" as Guid");
			if (f.IsProperty)
				o.Append(f.CanWrite ? " { get; set; }" : " { get; }");
			else if (!f.CanWrite)
				o.Append(" (read only)");
			if (f.ScriptName != f.Name)
				o.AppendF(" [was {}]", f.Name);
			if (!f.DisplayName.IsEmpty)
				o.AppendF(" \"{}\"", f.DisplayName);
			if (!f.Category.IsEmpty)
				o.AppendF(" ({})", f.Category);
			if (f.HasRange)
				o.AppendF(" [{}..{} step {}]", f.RangeMin, f.RangeMax, f.RangeStep);
			if (!f.VisibleWhen.IsEmpty)
				o.AppendF(" when {}", f.VisibleWhen);
			if (f.Get == null)
				o.AppendF(" !blocked: {}", f.Unsupported);
			else if ((f.Set == null) && !f.Unsupported.IsEmpty)
				o.AppendF(" !set blocked: {}", f.Unsupported);
			o.Append("\n");
			if (!f.Description.IsEmpty)
				o.AppendF("        // {}\n", f.Description);
		}

		for (let m in t.Methods)
		{
			o.Append("    ");
			if (m.IsStatic && (t.Kind != .Global))
				o.Append("static ");
			o.Append(m.IsConstructor ? "new" : m.ScriptName);
			o.Append("(");
			for (let p in m.Params)
			{
				if (@p.Index > 0)
					o.Append(", ");
				if (p.IsByRef)
					o.Append("ref ");
				o.AppendF("{}: {}", p.Name, Short(p.TypeName, .. scope .()));
				if (p.HasDefault)
					o.Append(" = ...");
			}
			o.Append(")");
			if (!m.IsConstructor && (m.ReturnTypeName != "void"))
				o.AppendF(" -> {}", Short(m.ReturnTypeName, .. scope .()));
			if (m.ScriptName != m.Name)
				o.AppendF(" [was {}]", m.Name);
			if (!m.IsCallable)
				o.AppendF(" !blocked: {}", m.Unsupported);
			if (m.OnEntity)
				o.AppendF(" [on entity: {}]", m.EntityName);
			o.Append("\n");
			if (!m.Description.IsEmpty)
				o.AppendF("        // {}\n", m.Description);
		}
	}

	/// Every qualified identifier in a type name reduced to its last segment, generics and
	/// arrays included: `System.Collections.List<Sedulous.Scene.EntityHandle>` reads
	/// `List<EntityHandle>`.
	public static void Short(StringView typeName, String outShort)
	{
		let token = scope String();
		for (let c in typeName)
		{
			if ((c == '<') || (c == '>') || (c == ',') || (c == ' ') || (c == '[') || (c == ']') || (c == '*'))
			{
				Flush(token, outShort);
				outShort.Append(c);
			}
			else
			{
				token.Append(c);
			}
		}
		Flush(token, outShort);
	}

	private static void Flush(String token, String outShort)
	{
		if (token.IsEmpty)
			return;
		let dot = token.LastIndexOf('.');
		outShort.Append((dot >= 0) ? token.Substring(dot + 1) : token);
		token.Clear();
	}
}
