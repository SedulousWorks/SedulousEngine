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
	public bool IsStatic = false;
	public bool IsConstructor = false;
	public List<ScriptParamInfo> Params = new .() ~ DeleteContainerAndItems!(_);

	/// Adds a parameter. Chains, for the generated populate code.
	public ScriptMethodInfo Param(StringView name, StringView typeName, bool byRef = false,
		StringView defaultText = default)
	{
		let p = new ScriptParamInfo();
		p.Name.Set(name);
		p.TypeName.Set(typeName);
		p.IsByRef = byRef;
		p.Default.Set(defaultText);
		Params.Add(p);
		return this;
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

	/// Renames for the script.
	public ScriptMethodInfo Named(StringView scriptName)
	{
		ScriptName.Set(scriptName);
		return this;
	}
}
