using System;
using System.Collections;

namespace Sedulous.Net.Tls;

/// Certificates a client trusts: a PEM bundle, and certificates in DER (the Windows store hands
/// them so). Either may be empty.
class TlsRoots
{
	public String Pem = new .() ~ delete _;
	public List<List<uint8>> Der = new .() ~ DeleteContainerAndItems!(_);

	public bool IsEmpty => Pem.IsEmpty && Der.IsEmpty;
}
