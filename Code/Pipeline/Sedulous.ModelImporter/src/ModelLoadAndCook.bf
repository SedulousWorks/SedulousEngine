using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Loading a model file and cooking it in one call.
///
/// The convenience over doing both by hand, and the seam an application or an editor drives.
/// It keeps the loader dependency INSIDE this library: a caller wanting a cooked model does
/// not have to know which formats exist or how to register them.
static class ModelLoadAndCook
{
	/// Loads a model file and cooks it, returning the manifest's identity.
	///
	/// A load failure skips the cook entirely, so a file that did not parse never produces
	/// half a model in the database.
	public static Result<Guid, ModelLoadResult> LoadAndCook(StringView path, ContentDatabase outDb,
		StringView namePrefix)
	{
		let model = scope Model();
		let loaded = ModelFileLoad.Load(path, model);
		if (loaded != .Ok)
			return .Err(loaded);

		if (ModelCook.Cook(model, outDb, namePrefix) case .Ok(let manifestId))
			return .Ok(manifestId);
		return .Err(.InvalidData);
	}
}
