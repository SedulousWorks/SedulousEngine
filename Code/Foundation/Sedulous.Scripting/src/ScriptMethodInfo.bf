using System;
using System.Collections;

namespace Sedulous.Scripting;

/// One callable on a surface type: a method, or a constructor when IsConstructor.
class ScriptMethodInfo
{
	/// The Beef name.
	public String Name = new .() ~ delete _;
	/// The name a script uses. The Beef name unless [ScriptName] renamed it, which is how an
	/// overload set is told apart in a language without overloading.
	public String ScriptName = new .() ~ delete _;
	public String DisplayName = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	public String ReturnTypeName = new .() ~ delete _;
	/// How the result crosses; Nil for void.
	public ScriptValueKind ReturnKind = .Nil;
	public bool IsStatic = false;
	public bool IsConstructor = false;
	public List<ScriptParamInfo> Params = new .() ~ DeleteContainerAndItems!(_);
	/// The emitted callable, null when the member could not be bound.
	public ScriptThunk Invoke = null;
	/// Why it could not be bound: the type the frame cannot carry. Empty when it could.
	public String Unsupported = new .() ~ delete _;

	public bool IsCallable => Invoke != null;

	/// Adds a parameter. Chains, for the generated populate code.
	public ScriptMethodInfo Param(StringView name, StringView typeName, ScriptValueKind kind,
		bool byRef = false, StringView defaultText = default)
	{
		let p = new ScriptParamInfo();
		p.Name.Set(name);
		p.TypeName.Set(typeName);
		p.Kind = kind;
		p.IsByRef = byRef;
		p.Default.Set(defaultText);
		Params.Add(p);
		return this;
	}

	public ScriptMethodInfo Returns(ScriptValueKind kind)
	{
		ReturnKind = kind;
		return this;
	}

	/// The arguments a call must supply: the parameters without a default.
	public int RequiredParams
	{
		get
		{
			int n = 0;
			for (let p in Params)
			{
				if (!p.HasDefault)
					n++;
			}
			return n;
		}
	}

	public ScriptMethodInfo Describe(StringView description)
	{
		Description.Set(description);
		return this;
	}

	public ScriptMethodInfo Display(StringView displayName)
	{
		DisplayName.Set(displayName);
		return this;
	}

	public ScriptMethodInfo Bind(ScriptThunk thunk)
	{
		Invoke = thunk;
		return this;
	}

	public ScriptMethodInfo Blocked(StringView reason)
	{
		Unsupported.Set(reason);
		return this;
	}

	/// Renames for the script.
	public ScriptMethodInfo Named(StringView scriptName)
	{
		ScriptName.Set(scriptName);
		return this;
	}
}
