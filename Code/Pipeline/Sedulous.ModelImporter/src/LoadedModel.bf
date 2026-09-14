using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// The worker phase's payload: a fully loaded model.
///
/// Parsing the file and decoding its images is nearly all of a model import's cost, and none
/// of it touches a project or a database, so it runs off the interface thread and arrives
/// here. The fan out on the main thread then reads from this instead of the file.
class LoadedModel
{
	public Model Model = new .() ~ delete _;
}
