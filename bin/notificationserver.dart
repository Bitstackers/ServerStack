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

library openreception.notification_server;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

import '../lib/configuration.dart';
import '../lib/notification_server/router.dart' as router;

Logger log = new Logger('NotificationServer');
ArgResults parsedArgs;
ArgParser parser = new ArgParser();

void main(List<String> args) {
  ///Init logging. Inherit standard values.
  Logger.root.level = config.notificationServer.log.level;
  Logger.root.onRecord.listen(config.notificationServer.log.onRecord);

  try {
    Directory.current = dirname(Platform.script.toFilePath());

    registerAndParseCommandlineArguments(args);

    if (showHelp()) {
      print(parser.usage);
    } else {
      router.connectAuthService();
      router.start(
          hostname: config.notificationServer.externalHostName,
          port: config.notificationServer.httpPort);
    }
  } catch (error, stackTrace) {
    log.shout(error, stackTrace);
  }
}

void registerAndParseCommandlineArguments(List<String> arguments) {
  parser.addFlag('help', abbr: 'h', help: 'Output this help');
  parser.addOption('configfile',
      help: 'The JSON configuration file. Defaults to config.json');
  parser.addOption('httpport',
      help: 'The port the HTTP server listens on.  Defaults to 4200');

  parsedArgs = parser.parse(arguments);
}

bool showHelp() => parsedArgs['help'];
