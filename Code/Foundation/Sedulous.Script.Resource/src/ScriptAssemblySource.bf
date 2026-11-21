using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Script.Resource;

/// One class a project assembly declares, as its build described it: what the cook of the
/// class's own asset takes its handlers and inspector properties from.
[Serializable]
class ScriptAssemblyClass
{
	public String ClassName = new .() ~ delete _;
	public List<String> Handlers = new .() ~ DeleteContainerAndItems!(_);
	public List<BehaviorProperty> Properties = new .() ~ DeleteContainerAndItems!(_);
}

/// The cooked record of a project's script assembly. A language whose classes build together
/// (every file of a project in one assembly, so they share types) builds once into this, and
/// each class's own record names it (BehaviorClassSource.Assembly).
[Serializable]
class ScriptAssemblySource
{
	/// The backend id.
	public String Language = new .() ~ delete _;
	/// The built assembly.
	public List<uint8> Image = new .() ~ delete _;
	/// Its debug symbols, so a fault names its file and line; may be empty.
	public List<uint8> Symbols = new .() ~ delete _;
	public List<ScriptAssemblyClass> Classes = new .() ~ DeleteContainerAndItems!(_);

	/// The class named `name`, or null when the assembly declares none so named.
	public ScriptAssemblyClass FindClass(StringView name)
	{
		for (let c in Classes)
		{
			if (c.ClassName == name)
				return c;
		}
		return null;
	}
}
