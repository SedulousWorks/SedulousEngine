using System;
using Sedulous.Net.Tls;

namespace Sedulous.Net.WebSocket;

/// What a gateway needs to speak wss://: the TLS backend and the host's certificate chain and
/// key. A browser on an https page may only open wss://.
class WebSocketTls
{
	/// BORROWED: the application's, outliving the gateway.
	public ITlsBackend Backend = null;
	public TlsServerConfig Config = new .() ~ delete _;
}
