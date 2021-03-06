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

library openreception.call_flow_control_server;

import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';

import '../lib/callflowcontrol/router.dart' as router;
import '../lib/callflowcontrol/controller.dart' as Controller;
import '../lib/callflowcontrol/model/model.dart' as Model;
import 'package:esl/esl.dart' as ESL;
import 'package:logging/logging.dart';
import '../lib/configuration.dart';

Logger log = new Logger('CallFlowControl');
ArgResults parsedArgs;
ArgParser parser = new ArgParser();

class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException([this.message = ""]);

  String toString() => "NotFound: $message";
}

/**
 * TODO: Recover from text/disconnect.
 */
void main(List<String> args) {
  ///Init logging. Inherit standard values.
  Logger.root.level = config.callFlowControl.log.level;
  Logger.root.onRecord.listen(config.callFlowControl.log.onRecord);

  registerAndParseCommandlineArguments(args);

  if (showHelp()) {
    print(parser.usage);
  } else {
    router.connectAuthService();
    connectESLClient();
    router.start(port: config.callFlowControl.httpPort);
  }
}

void connectESLClient() {
  Duration period = new Duration(seconds: 3);
  final String hostname = config.callFlowControl.eslConfig.hostname;
  final String password = config.callFlowControl.eslConfig.password;
  final int port = config.callFlowControl.eslConfig.port;

  log.info('Connecting to ${hostname}:${port}');

  Controller.PBX.apiClient = new ESL.Connection();
  Controller.PBX.eventClient = new ESL.Connection();

  Model.CallList.instance.subscribe(Controller.PBX.eventClient.eventStream);

  Controller.PBX.eventClient.eventStream
      .listen(Model.ChannelList.instance.handleEvent)
      .onDone(connectESLClient); // Reconnect

  Controller.PBX.eventClient.eventStream
      .listen(Model.ActiveRecordings.instance.handleEvent);

  Controller.PBX.eventClient.eventStream.listen(Model.peerlist.handlePacket);

  Future authenticate(ESL.Connection client) =>
      client.authenticate(password).then((ESL.Reply reply) {
        if (reply.status != ESL.Reply.ok) {
          log.shout('ESL Authentication failed - exiting');
          exit(1);
        }
      });

  /// Connect API client.
  Controller.PBX.apiClient.requestStream.listen((ESL.Packet packet) async {
    switch (packet.contentType) {
      case (ESL.ContentType.authRequest):
        log.info('Connected to ${hostname}:${port}');
        authenticate(Controller.PBX.apiClient)
            .then((_) => Controller.PBX.loadPeers())
            .then((_) => Controller.PBX.loadChannels().then((_) => Model
                .CallList.instance
                .reloadFromChannels(Model.ChannelList.instance)));

        break;

      default:
        break;
    }
  });

  /// Connect event client.
  Controller.PBX.eventClient.requestStream.listen((ESL.Packet packet) {
    switch (packet.contentType) {
      case (ESL.ContentType.authRequest):
        log.info('Connected to ${hostname}:${port}');
        authenticate(Controller.PBX.eventClient).then((_) => Controller
            .PBX.eventClient
            .event(Model.PBXEvent.requiredSubscriptions,
                format: ESL.EventFormat.json)..catchError(log.shout));

        break;

      default:
        break;
    }
  });

  Future tryConnect(ESL.Connection client) async {
    await client.connect(hostname, port).catchError((error, stackTrace) {
      if (error is SocketException) {
        log.severe(
            'ESL Connection failed - reconnecting in ${period.inSeconds} seconds');
        new Timer(period, () => tryConnect(client));
      } else {
        log.severe('Failed to connect to FreeSWITCH.', error, stackTrace);
      }
    });
  }

  tryConnect(Controller.PBX.apiClient);
  tryConnect(Controller.PBX.eventClient);
}

void registerAndParseCommandlineArguments(List<String> arguments) {
  parser
    ..addFlag('help', abbr: 'h', help: 'Output this help')
    ..addOption('configfile',
        help: 'The JSON configuration file. Defaults to config.json')
    ..addOption('httpport', help: 'The port the HTTP server listens on.')
    ..addOption('servertoken', help: 'servertoken');

  parsedArgs = parser.parse(arguments);
}

bool showHelp() => parsedArgs['help'];
