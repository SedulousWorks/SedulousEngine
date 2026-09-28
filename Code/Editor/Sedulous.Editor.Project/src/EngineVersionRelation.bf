namespace Sedulous.Editor.Core;

/// How a project's stamped engine version relates to THIS engine. Drives the manager's
/// open time prompt: Same and Unstamped open silently, ProjectOlder offers a backup then
/// the upgrade, ProjectNewer warns hard, this editor maybe not reading newer data.
enum EngineVersionRelation
{
	Same,
	ProjectOlder,
	ProjectNewer,
	/// An empty or unparseable stamp.
	Unstamped
}
