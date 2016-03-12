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

part of openreception.cdr_server.controller;

class Cdr {
  final Logger _log = new Logger('cdr_server.controller.cdr');

  /**
   * Constructor.
   */
  Cdr();

  Future<shelf.Response> process(shelf.Request request) async {
    String direction;
    DateTime from;
    String kind;
    List<String> rids = new List<String>();
    DateTime to;
    List<String> uids = new List<String>();

    try {
      from = DateTime.parse(shelf_route.getPathParameter(request, 'from'));
      to = DateTime.parse(shelf_route.getPathParameter(request, 'to'));

      if (from.isAtSameMomentAs(to) || from.isAfter(to)) {
        throw new FormatException('Invalid timestamps. From must be before to');
      }

      kind = shelf_route
          .getPathParameter(request, 'kind')
          .toString()
          .toLowerCase();
      if (!['list', 'summary'].contains(kind)) {
        throw new FormatException('Invalid kind value');
      }

      direction = shelf_route
          .getPathParameter(request, 'direction')
          .toString()
          .toLowerCase();
      if (!['both', 'inbound', 'outbound'].contains(direction)) {
        throw new FormatException('Invalid direction value');
      }

      if (request.requestedUri.queryParameters.containsKey('rids')) {
        rids = request.requestedUri.queryParameters['rids'].split(',');
      }

      if (request.requestedUri.queryParameters.containsKey('uids')) {
        uids = request.requestedUri.queryParameters['uids'].split(',');
      }
    } on FormatException catch (error) {
      _log.warning('Bad request string: ${request.requestedUri}');
      _log.warning(error.message);
      return new shelf.Response.internalServerError(
          body: 'Cannot parse request string');
    }

    return io.Process.run('dart', [
      '/home/thomas/projects/dart/cdrctl/bin/cdrctl.dart',
      'report',
      '-f',
      '2016-02-01',
      '--json'
    ]).then((ProcessResult pr) {
      // return _okJson('Got stuff!!');
      return _okJson(JSON.decode(pr.stdout));
    });
  }
}
