using System;
using System.Collections;
using Sedulous.Json;

namespace Sedulous.Editor.Mcp;

/// What validating a scene stream found: whether it parsed, the reason when not, the
/// warnings the reader raised on the way (a genuinely unknown component type, a duplicate
/// entity id), and the shape of what loaded.
class SceneParseReport
{
	public bool Valid = false;
	/// Empty when valid.
	public String Error = new .() ~ delete _;
	public List<String> Warnings = new .() ~ DeleteContainerAndItems!(_);
	public int EntityCount = 0;
	public int RootCount = 0;
	public String SceneName = new .() ~ delete _;

	/// {valid, error?, warnings[], sceneName?, entityCount?, rootCount?, componentValidation}.
	public JsonValue ToJson()
	{
		let json = JsonValue.MakeObject();
		json.Set("valid", JsonValue.MakeBool(Valid));
		if (!Valid)
			json.Set("error", JsonValue.MakeString(Error));
		let warnings = JsonValue.MakeArray();
		for (let warning in Warnings)
			warnings.Add(JsonValue.MakeString(warning));
		json.Set("warnings", warnings);
		if (Valid)
		{
			json.Set("sceneName", JsonValue.MakeString(SceneName));
			json.Set("entityCount", JsonValue.MakeNumber((double)EntityCount));
			json.Set("rootCount", JsonValue.MakeNumber((double)RootCount));
		}
		// The honesty marker: component payloads validate through the FULL engine manager
		// set, so the warnings list every genuinely unknown component type.
		json.Set("componentValidation", JsonValue.MakeString("full"));
		return json;
	}
}
