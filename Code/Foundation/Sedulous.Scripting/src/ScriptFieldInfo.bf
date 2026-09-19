using System;

namespace Sedulous.Scripting;

/// One data member on a surface type: a field, or a property when IsProperty.
class ScriptFieldInfo
{
	public String Name = new .() ~ delete _;
	public String ScriptName = new .() ~ delete _;
	public String TypeName = new .() ~ delete _;
	public String DisplayName = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	public String Category = new .() ~ delete _;
	/// The [VisibleWhen] condition, empty when unconditional.
	public String VisibleWhen = new .() ~ delete _;
	public bool IsStatic = false;
	public bool IsProperty = false;
	/// A property without a setter, or a readonly field, reads only.
	public bool CanWrite = true;
	public bool HasRange = false;
	public float RangeMin = 0.0f;
	public float RangeMax = 0.0f;
	public float RangeStep = 0.0f;

	public ScriptFieldInfo Describe(StringView description)
	{
		Description.Set(description);
		return this;
	}

	public ScriptFieldInfo Display(StringView displayName)
	{
		DisplayName.Set(displayName);
		return this;
	}

	public ScriptFieldInfo Categorised(StringView category)
	{
		Category.Set(category);
		return this;
	}

	public ScriptFieldInfo Ranged(float min, float max, float step)
	{
		HasRange = true;
		RangeMin = min;
		RangeMax = max;
		RangeStep = step;
		return this;
	}

	public ScriptFieldInfo When(StringView condition)
	{
		VisibleWhen.Set(condition);
		return this;
	}

	public ScriptFieldInfo Named(StringView scriptName)
	{
		ScriptName.Set(scriptName);
		return this;
	}

	public ScriptFieldInfo ReadOnly()
	{
		CanWrite = false;
		return this;
	}
}
