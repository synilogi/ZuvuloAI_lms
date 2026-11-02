/* Runs before every API test file (vitest.config.ts › setupFiles).
 *
 * Supertest starts a server for each request with `listen(0)` — every interface, dual-stack — and then
 * connected to 127.0.0.1. On a machine where other programs (IDEs, language servers, databases, the Dart VM
 * services of a running Flutter build) hold ports on 127.0.0.1 or ::1 specifically, the operating system
 * could give the test server one of those same port numbers — both bindings are allowed — and the request
 * then went to the other program instead: an unrelated 404, a raw 400, a response that was not HTTP at all
 * ("Expected HTTP/"), or a hang. The failures moved from test to test with whichever request drew such a port.
 * Connecting over ::1 instead only moved the collision to programs holding ::1.
 *
 * So the test server now binds 127.0.0.1 itself: the operating system then hands out only a port nobody holds
 * on that address, and the request goes to that address. Binding a named address finishes asynchronously, so
 * the request is sent once the server is listening. The suite speaks plain HTTP throughout. */
import type { AddressInfo, Server } from 'node:net';
import request from 'supertest';

const HOST = '127.0.0.1';
/** Stands in for the port in the URL until the server has one. */
const PENDING = ':0/';

interface SupertestProto {
  _server?: Server;
  url: string;
  serverAddress(app: Server, path: string): string;
  end(callback?: unknown): unknown;
}

const proto = (request as unknown as { Test: { prototype: SupertestProto } }).Test.prototype;

proto.serverAddress = function (this: SupertestProto, app: Server, path: string): string {
  const address = app.address() as AddressInfo | null;
  if (address) return `http://${HOST}:${address.port}${path}`;
  this._server = (app as unknown as { listen(port: number, host: string): Server }).listen(0, HOST);
  return `http://${HOST}${PENDING}${path.replace(/^\//, '')}`;
};

const end = proto.end;
proto.end = function (this: SupertestProto, callback?: unknown) {
  const server = this._server;
  if (!server || !this.url.includes(PENDING) || server.listening) {
    if (server?.listening) this.url = this.url.replace(PENDING, `:${(server.address() as AddressInfo).port}/`);
    return end.call(this, callback);
  }
  server.once('listening', () => {
    this.url = this.url.replace(PENDING, `:${(server.address() as AddressInfo).port}/`);
    end.call(this, callback);
  });
  return this;
};
