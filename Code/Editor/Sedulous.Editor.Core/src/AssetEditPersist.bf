using System;
using Sedulous.Core;
using Sedulous.Content;

namespace Sedulous.Editor.Core;

/// Writes a live asset edit back to its source through the database it is handed.
typealias AssetEditPersist = delegate Result<void, ErrorCode>(ContentDatabase db);
