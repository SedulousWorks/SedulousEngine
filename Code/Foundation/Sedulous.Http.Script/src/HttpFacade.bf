using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Script;

namespace Sedulous.Http.Script;

/// `Http`: a game's scripts send requests and hear the answers by callback on the game's thread,
/// through the run's IHttpClient (native, or the browser's in a web build).
///
///     Http.Get("https://example.com/scores", function (status, body, error) ... end)
///
/// A handler hears (status, body, error): the status and body text of the response (a 404 is a
/// response), or status 0 and why in `error` when none came (no network, a timeout, a refused
/// certificate). Bodies are text both ways for now.
///
/// The run owns one and installs it on its runtime. The client is made by the run's factory on
/// the first request, so a game that never asks starts no thread and opens nothing; the run pumps
/// it each frame, and Reset drops it with its requests when the scripts that sent them stop. A
/// game in the editor's play mode is a game like any other.
[Scriptable, ServiceFacade("Http")]
class HttpFacade
{
	public typealias Factory = delegate IHttpClient();

	/// OWNED: what makes the client.
	private Factory mFactory ~ delete _;
	/// OWNED: made on the first request.
	private IHttpClient mClient ~ delete _;
	/// A request waiting for its answer, and the handler that hears it.
	private class Waiting
	{
		public uint64 Id;
		/// OWNED; null when the script passed none.
		public ScriptDelegate Handler ~ delete _;
	}

	/// The requests under way by id, OWNED until their answer is delivered or they go. The
	/// client's callback holds its Waiting, which lives exactly as long as the request: an
	/// answered one goes in Answer, a cancelled one is never answered.
	private Dictionary<uint64, Waiting> mWaiting = new .() ~ DeleteDictionaryAndValues!(_);

	/// Takes OWNERSHIP of `factory`, which replaces any earlier one.
	public void SetFactory(Factory factory)
	{
		delete mFactory;
		mFactory = factory;
	}

	/// The client, made now if this is the first request; null when the run has no factory.
	public IHttpClient Client
	{
		get
		{
			if ((mClient == null) && (mFactory != null))
				mClient = mFactory();
			return mClient;
		}
	}

	/// Delivers the answers that have arrived; their handlers run here. Each frame.
	public void Pump()
	{
		if (mClient != null)
			mClient.Pump();
	}

	/// Drops the client and every request under way, their handlers never called: when the
	/// scripts that sent them stop.
	public void Reset()
	{
		DeleteAndNullify!(mClient);
		for (let entry in mWaiting)
			delete entry.value;
		mWaiting.Clear();
	}

	/// Requests sent and not yet answered or cancelled.
	public int Pending => (mClient != null) ? mClient.Pending : 0;

	/// GETs `url`; `handler(status, body, error)` hears the answer. The request's id (for Cancel),
	/// or nought when this run has no HTTP (the handler is then never called). TAKES OWNERSHIP of
	/// the handler.
	[Scriptable, ScriptCallback("void HttpHandler(int status, const string &in body, const string &in error)")]
	public int32 Get(StringView url, ScriptDelegate handler) => Send(HttpClientRequest.Get(url), handler);

	/// POSTs `body` as `contentType` to `url`, as Get does.
	[Scriptable, ScriptCallback("void HttpHandler(int status, const string &in body, const string &in error)")]
	public int32 Post(StringView url, StringView contentType, StringView body, ScriptDelegate handler) =>
		Send(HttpClientRequest.Post(url, contentType, body), handler);

	/// Any method; `headers` is "Name: value" lines (empty for none; a line without a colon is
	/// skipped), as Get does.
	[Scriptable, ScriptCallback("void HttpHandler(int status, const string &in body, const string &in error)")]
	public int32 Request(StringView method, StringView url, StringView headers, StringView body, ScriptDelegate handler)
	{
		let request = new HttpClientRequest(url);
		request.Method.Set(method);
		request.Body.AddRange(Span<uint8>((uint8*)body.Ptr, body.Length));
		for (var line in headers.Split('\n'))
		{
			if (line.EndsWith('\r'))
				line = line.Substring(0, line.Length - 1);
			let colon = line.IndexOf(':');
			if (colon < 0)
				continue;
			var value = line.Substring(colon + 1);
			while (value.StartsWith(' '))
				value = value.Substring(1);
			request.Headers.Add(new .(line.Substring(0, colon), value));
		}
		return Send(request, handler);
	}

	/// Its handler is never called; a request under way is dropped.
	[Scriptable]
	public void Cancel(int32 id)
	{
		if ((id <= 0) || (mClient == null))
			return;
		mClient.Cancel((uint64)id);
		if (mWaiting.GetAndRemove((uint64)id) case .Ok(let entry))
			delete entry.value;
	}

	/// Sends `request` (taken) with `handler` (taken) waiting for its answer.
	private int32 Send(HttpClientRequest request, ScriptDelegate handler)
	{
		let client = Client;
		if (client == null)
		{
			delete request;
			delete handler;
			return 0;
		}
		let waiting = new Waiting();
		waiting.Handler = handler;
		waiting.Id = client.Send(request, new [=this, =waiting](response) => Answer(waiting, response));
		mWaiting[waiting.Id] = waiting;
		return (int32)waiting.Id;
	}

	/// The answer goes to the request's handler as (status, body, error), and the request goes.
	private void Answer(Waiting waiting, HttpClientResponse response)
	{
		mWaiting.Remove(waiting.Id);
		defer delete waiting;
		if ((waiting.Handler == null) || !waiting.Handler.IsAlive)
			return;
		var args = ScriptValue[3](.FromInt(response.Status), .FromString(response.BodyText), .FromString(response.Error));
		var result = ScriptValue.Nil;
		waiting.Handler.Invoke(.(&args[0], 3), ref result);
	}
}
