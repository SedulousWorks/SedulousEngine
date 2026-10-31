using System;
using System.Collections;
using Sedulous.Http;
using Sedulous.Http.Client;
using Sedulous.Http.Script;
using Sedulous.Script;

namespace Sedulous.Http.Script.Tests;

/// The Http facade over a stand-in client that records what is sent and answers when the test
/// says, so the facade is checked without a network: Get, Post, and Request with its headers
/// reach the client as asked; handlers hear (status, body, error) on the pump; a cancelled request
/// is never answered; the client is made only on the first request; a run with no factory gets
/// nought back. The script languages reach it through the run (GameInstance).
class HttpFacadeTests
{
	private class Recorded
	{
		public uint64 Id;
		public HttpClientRequest Request ~ delete _;
		public delegate void(HttpClientResponse response) Done ~ delete _;
		public bool Cancelled = false;
		public bool Delivered = false;
	}

	/// Answers only when told; Pump delivers what Answer queued, as a real client does.
	private class FakeClient : IHttpClient
	{
		public List<Recorded> Log = new .() ~ DeleteContainerAndItems!(_);
		private List<(Recorded recorded, HttpClientResponse response)> mQueued = new .() ~ delete _;
		private uint64 mNext = 0;

		public ~this()
		{
			for (let q in mQueued)
				delete q.response;
		}

		public uint64 Send(HttpClientRequest request, delegate void(HttpClientResponse response) done)
		{
			let r = new Recorded();
			r.Id = ++mNext;
			r.Request = request;
			r.Done = done;
			Log.Add(r);
			return r.Id;
		}

		public void Cancel(uint64 id)
		{
			for (let r in Log)
			{
				if (r.Id == id)
					r.Cancelled = true;
			}
		}

		public void Pump()
		{
			for (let q in mQueued)
			{
				q.recorded.Delivered = true;
				if (!q.recorded.Cancelled)
					q.recorded.Done(q.response);
				delete q.response;
			}
			mQueued.Clear();
		}

		public int Pending
		{
			get
			{
				var pending = 0;
				for (let r in Log)
				{
					if (!r.Cancelled && !r.Delivered)
						pending++;
				}
				return pending;
			}
		}

		/// Queues the answer to request `index`, delivered on the next Pump.
		public void Answer(int index, int32 status, StringView body, StringView error = default)
		{
			let response = new HttpClientResponse();
			response.Status = status;
			response.Body.AddRange(Span<uint8>((uint8*)body.Ptr, body.Length));
			response.Error.Set(error);
			mQueued.Add((Log[index], response));
		}
	}

	/// A script handler that records the arguments it was called with.
	private class Heard : ScriptDelegate
	{
		public List<String> Calls;

		public this(List<String> calls)
		{
			Calls = calls;
		}

		public override bool IsAlive => true;

		public override bool Invoke(Span<ScriptValue> args, ref ScriptValue result)
		{
			let call = new String();
			call.AppendF("{} [{}] [{}]", args[0].Data.Int, args[1].Data.String, args[2].Data.String);
			Calls.Add(call);
			return true;
		}
	}

	/// A facade whose factory makes `fake` (counting the calls), and what its handlers heard.
	private class Bed
	{
		public HttpFacade Http = new .() ~ delete _;
		public FakeClient Fake;
		public int Made = 0;
		public List<String> Heard = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			Http.SetFactory(new () =>
				{
					Made++;
					Fake = new FakeClient();
					return Fake;
				});
		}

		public ScriptDelegate Handler() => new HttpFacadeTests.Heard(Heard);
	}

	[Test]
	public static void GetPostAndRequestReachTheClientAsAsked()
	{
		let bed = scope Bed();
		Test.Assert(bed.Made == 0, "no request, no client");
		let a = bed.Http.Get("https://example.com/scores", bed.Handler());
		let b = bed.Http.Post("https://example.com/score", "application/json", "{\"s\":5}", bed.Handler());
		let c = bed.Http.Request("PUT", "https://example.com/name", "X-Token: abc\r\nnot a header\nAccept:  text/plain", "Rae", bed.Handler());
		Test.Assert(bed.Made == 1, "made once, on the first request");
		Test.Assert((a == 1) && (b == 2) && (c == 3));
		let log = bed.Fake.Log;
		Test.Assert(log[0].Request.Method == "GET");
		Test.Assert(log[0].Request.Url == "https://example.com/scores");
		Test.Assert(log[1].Request.Method == "POST");
		Test.Assert(log[1].Request.Headers[0].Value == "application/json");
		Test.Assert(StringView((char8*)log[1].Request.Body.Ptr, log[1].Request.Body.Count) == "{\"s\":5}");
		Test.Assert(log[2].Request.Method == "PUT");
		Test.Assert(log[2].Request.Headers.Count == 2, "a line without a colon is skipped");
		Test.Assert((log[2].Request.Headers[0].Name == "X-Token") && (log[2].Request.Headers[0].Value == "abc"));
		Test.Assert((log[2].Request.Headers[1].Name == "Accept") && (log[2].Request.Headers[1].Value == "text/plain"));
		Test.Assert(StringView((char8*)log[2].Request.Body.Ptr, log[2].Request.Body.Count) == "Rae");
	}

	[Test]
	public static void HandlersHearStatusBodyAndErrorOnThePumpACancelledOneNever()
	{
		let bed = scope Bed();
		bed.Http.Get("https://example.com/a", bed.Handler());
		let cancelled = bed.Http.Get("https://example.com/b", bed.Handler());
		bed.Http.Get("https://example.com/c", bed.Handler());
		bed.Fake.Answer(0, 200, "hello");
		bed.Fake.Answer(2, 0, "", "timed out after 30 s");
		bed.Http.Cancel(cancelled);
		Test.Assert(bed.Heard.IsEmpty, "nothing before the pump");
		bed.Http.Pump();
		Test.Assert(bed.Heard.Count == 2);
		Test.Assert(bed.Heard[0] == "200 [hello] []");
		Test.Assert(bed.Heard[1] == "0 [] [timed out after 30 s]");
		Test.Assert(bed.Fake.Log[1].Cancelled);
	}

	[Test]
	public static void ARunWithNoFactoryGetsNoughtAndResetDropsTheRequests()
	{
		let none = scope HttpFacade();
		let heard = scope List<String>();
		defer { ClearAndDeleteItems!(heard); }
		Test.Assert(none.Get("https://example.com/", new Heard(heard)) == 0);
		Test.Assert(none.Pending == 0);
		none.Pump();
		Test.Assert(heard.IsEmpty);

		let bed = scope Bed();
		bed.Http.Get("https://example.com/", bed.Handler());
		Test.Assert(bed.Http.Pending == 1);
		bed.Http.Reset();
		Test.Assert(bed.Http.Pending == 0, "the client and its requests went");
		bed.Http.Get("https://example.com/again", bed.Handler());
		Test.Assert(bed.Made == 2, "a new client for the next request");
	}
}
