// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/security-context/security-context-v1.xml
//
// security_context_v1 Protocol Copyright: 
/// 
/// Copyright © 2021 Simon Ser
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a
/// copy of this software and associated documentation files (the "Software"),
/// to deal in the Software without restriction, including without limitation
/// the rights to use, copy, modify, merge, publish, distribute, sublicense,
/// and/or sell copies of the Software, and to permit persons to whom the
/// Software is furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice (including the next
/// paragraph) shall be included in all copies or substantial portions of the
/// Software.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
/// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
/// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
/// DEALINGS IN THE SOFTWARE.
/// 

library client;

import 'package:wayland/wayland.dart';
import 'package:wayland/generated/wayland.dart';
import 'dart:async';
import 'dart:typed_data';


/// client security context manager
/// 
/// This interface allows a client to register a new Wayland connection to
/// the compositor and attach a security context to it.
/// 
/// This is intended to be used by sandboxes. Sandbox engines attach a
/// security context to all connections coming from inside the sandbox. The
/// compositor can then restrict the features that the sandboxed connections
/// can use.
/// 
/// Compositors should forbid nesting multiple security contexts by not
/// exposing wp_security_context_manager_v1 global to clients with a security
/// context attached, or by sending the nested protocol error. Nested
/// security contexts are dangerous because they can potentially allow
/// privilege escalation of a sandboxed client.
/// 
/// Warning! The protocol described in this file is currently in the testing
/// phase. Backward compatible changes may be added together with the
/// corresponding interface version bump. Backward incompatible changes can
/// only be done by creating a new major version of the extension.
/// 
class WpSecurityContextManagerV1 extends Proxy{
  final Context context;

  WpSecurityContextManagerV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// destroy the manager object
/// 
/// Destroy the manager. This doesn't destroy objects created with the
/// manager.
/// 
  Future<void> destroy() async {
    print("WpSecurityContextManagerV1::destroy ");
    final message = WaylandMessage(
      objectId,
      0,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// create a new security context
/// 
/// Creates a new security context with a socket listening FD.
/// 
/// The compositor will accept new client connections on listen_fd.
/// listen_fd must be ready to accept new connections when this request is
/// sent by the client. In other words, the client must call bind(2) and
/// listen(2) before sending the FD.
/// 
/// close_fd is a FD closed by the client when the compositor should stop
/// accepting new connections on listen_fd.
/// 
/// The compositor must continue to accept connections on listen_fd when
/// the Wayland client which created the security context disconnects.
/// 
/// After sending this request, closing listen_fd and close_fd remains the
/// only valid operation on them.
/// 
/// [id]:
/// [listen_fd]: listening socket FD
/// [close_fd]: FD closed when done
  Future<WpSecurityContextV1> createListener(int listenFd, int closeFd) async {
  var id =  WpSecurityContextV1(context);
    print("WpSecurityContextManagerV1::createListener  id: $id listenFd: $listenFd closeFd: $closeFd");
    final message = WaylandMessage(
      objectId,
      1,
      [
        id,
        listenFd,
        closeFd,
      ],
      [
        WaylandType.newId,
        WaylandType.fd,
        WaylandType.fd,
      ],
    );
    await context.sendMessage(message);
    return id;
  }

}

/// 
/// 

enum WpSecurityContextManagerV1error {
/// listening socket FD is invalid
  invalidListenFd,
/// nested security contexts are forbidden
  nested,
}



/// client security context
/// 
/// The security context allows a client to register a new client and attach
/// security context metadata to the connections.
/// 
/// When both are set, the combination of the application ID and the sandbox
/// engine must uniquely identify an application. The same application ID
/// will be used across instances (e.g. if the application is restarted, or
/// if the application is started multiple times).
/// 
/// When both are set, the combination of the instance ID and the sandbox
/// engine must uniquely identify a running instance of an application.
/// 
class WpSecurityContextV1 extends Proxy{
  final Context context;

  WpSecurityContextV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// destroy the security context object
/// 
/// Destroy the security context object.
/// 
  Future<void> destroy() async {
    print("WpSecurityContextV1::destroy ");
    final message = WaylandMessage(
      objectId,
      0,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// set the sandbox engine
/// 
/// Attach a unique sandbox engine name to the security context. The name
/// should follow the reverse-DNS style (e.g. "org.flatpak").
/// 
/// A list of well-known engines is maintained at:
/// https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/security-context/engines.md
/// 
/// It is a protocol error to call this request twice. The already_set
/// error is sent in this case.
/// 
/// [name]: the sandbox engine name
  Future<void> setSandboxEngine(String name) async {
    print("WpSecurityContextV1::setSandboxEngine  name: $name");
    final message = WaylandMessage(
      objectId,
      1,
      [
        name,
      ],
      [
        WaylandType.string,
      ],
    );
    await context.sendMessage(message);
  }

/// set the application ID
/// 
/// Attach an application ID to the security context.
/// 
/// The application ID is an opaque, sandbox-specific identifier for an
/// application. See the well-known engines document for more details:
/// https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/security-context/engines.md
/// 
/// The compositor may use the application ID to group clients belonging to
/// the same security context application.
/// 
/// Whether this request is optional or not depends on the sandbox engine used.
/// 
/// It is a protocol error to call this request twice. The already_set
/// error is sent in this case.
/// 
/// [app_id]: the application ID
  Future<void> setAppId(String appId) async {
    print("WpSecurityContextV1::setAppId  appId: $appId");
    final message = WaylandMessage(
      objectId,
      2,
      [
        appId,
      ],
      [
        WaylandType.string,
      ],
    );
    await context.sendMessage(message);
  }

/// set the instance ID
/// 
/// Attach an instance ID to the security context.
/// 
/// The instance ID is an opaque, sandbox-specific identifier for a running
/// instance of an application. See the well-known engines document for
/// more details:
/// https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/security-context/engines.md
/// 
/// Whether this request is optional or not depends on the sandbox engine used.
/// 
/// It is a protocol error to call this request twice. The already_set
/// error is sent in this case.
/// 
/// [instance_id]: the instance ID
  Future<void> setInstanceId(String instanceId) async {
    print("WpSecurityContextV1::setInstanceId  instanceId: $instanceId");
    final message = WaylandMessage(
      objectId,
      3,
      [
        instanceId,
      ],
      [
        WaylandType.string,
      ],
    );
    await context.sendMessage(message);
  }

/// register the security context
/// 
/// Atomically register the new client and attach the security context
/// metadata.
/// 
/// If the provided metadata is inconsistent or does not match with out of
/// band metadata (see
/// https://gitlab.freedesktop.org/wayland/wayland-protocols/-/blob/main/staging/security-context/engines.md),
/// the invalid_metadata error may be sent eventually.
/// 
/// It's a protocol error to send any request other than "destroy" after
/// this request. In this case, the already_used error is sent.
/// 
  Future<void> commit() async {
    print("WpSecurityContextV1::commit ");
    final message = WaylandMessage(
      objectId,
      4,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

}

/// 
/// 

enum WpSecurityContextV1error {
/// security context has already been committed
  alreadyUsed,
/// metadata has already been set
  alreadySet,
/// metadata is invalid
  invalidMetadata,
}

