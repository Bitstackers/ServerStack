/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library openreception.reception_server.router;

import 'dart:async';

import 'dart:io' as io;

import '../configuration.dart';
import 'controller.dart' as controller;

import 'package:logging/logging.dart';
import 'package:openreception_framework/database.dart' as Database;
import 'package:openreception_framework/storage.dart' as storage;
import 'package:openreception_framework/service.dart' as Service;
import 'package:openreception_framework/service-io.dart' as Service_IO;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;

const String libraryName = 'receptionserver.router';
final Logger _log = new Logger(libraryName);

final Map<String, String> corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE'
};

Future<io.HttpServer> start(
    {String hostname: '0.0.0.0', int port: 4010}) async {
  final Service.Authentication _authService = new Service.Authentication(
      config.authServer.externalUri,
      config.userServer.serverToken,
      new Service_IO.Client());

  final Service.NotificationService _notification =
      new Service.NotificationService(config.notificationServer.externalUri,
          config.userServer.serverToken, new Service_IO.Client());

  /**
   * Validate a token by looking it up on the authentication server.
   */
  Future<shelf.Response> _lookupToken(shelf.Request request) async {
    var token = request.requestedUri.queryParameters['token'];

    try {
      await _authService.validate(token);
    } on storage.NotFound {
      return new shelf.Response.forbidden('Invalid token');
    } on io.SocketException {
      return new shelf.Response.internalServerError(
          body: 'Cannot reach authserver');
    } catch (error, stackTrace) {
      _log.severe(
          'Authentication validation lookup failed: $error:$stackTrace');

      return new shelf.Response.internalServerError(body: error.toString());
    }

    /// Do not intercept the request, but let the next handler take care of it.
    return null;
  }

  /**
   * Authentication middleware.
   */
  shelf.Middleware checkAuthentication = shelf.createMiddleware(
      requestHandler: _lookupToken, responseHandler: null);

  /**
   * Controllers.
   */
  final Database.Connection _connection =
      await Database.Connection.connect(config.database.dsn);

  controller.Organization organization = new controller.Organization(
      new Database.Organization(_connection), _notification);

  controller.Reception reception = new controller.Reception(
      new Database.Reception(_connection), _notification);

  var router = shelf_route.router()
    ..get('/organization', organization.list)
    ..get('/organization/receptionmap', organization.receptionMap)
    ..post('/organization', organization.create)
    ..get('/organization/{oid}', organization.get)
    ..put('/organization/{oid}', organization.update)
    ..delete('/organization/{oid}', organization.remove)
    ..get('/organization/{oid}/contact', organization.contacts)
    ..get('/organization/{oid}/reception', organization.receptions)
    ..get('/reception', reception.list)
    ..post('/reception', reception.create)
    ..get('/reception/{rid}', reception.get)
    ..get('/reception/extension/{exten}', reception.getByExtension)
    ..get('/reception/{rid}/extension', reception.extensionOf)
    ..put('/reception/{oid}', reception.update)
    ..delete('/reception/{oid}', reception.remove);
  var handler = const shelf.Pipeline()
      .addMiddleware(
          shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
      .addMiddleware(checkAuthentication)
      .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
      .addHandler(router.handler);

  _log.fine('Serving interfaces:');
  shelf_route.printRoutes(router, printer: (String item) => _log.fine(item));

  return await shelf_io.serve(handler, hostname, port);
}
