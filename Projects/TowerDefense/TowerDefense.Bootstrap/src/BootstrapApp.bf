namespace TowerDefense.Bootstrap;

/// Thin DefaultApplication subclass that hosts BootstrapModule.
/// BootstrapModule is the actual IApplication (extends DefaultApplication),
/// so this wrapper is no longer needed. Kept as an alias for naming
/// compatibility with Program.bf references.
class BootstrapApp : BootstrapModule { }
