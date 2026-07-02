namespace TowerDefense;

/// Naming-compatibility alias. TowerDefenseModule IS the application now
/// (extends DefaultApplication). Program.bf uses TowerDefenseModule directly;
/// this subclass exists only so that any remaining references to
/// "TowerDefenseApp" continue to compile.
class TowerDefenseApp : TowerDefenseModule { }
