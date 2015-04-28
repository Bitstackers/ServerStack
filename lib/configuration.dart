library server_stack.configuration;

import 'dart:io' as IO;
import 'package:logging/logging.dart';

class Log {
  final Level level = Level.ALL;
  final onRecord = logEntryDispatch;
}

class ConfigServerDefault {
  int HttpPort = 4080;
}
abstract class StandardConfig {
  final Log log = Configuration.logDefaults;
}

class CallFlowControl extends StandardConfig {
  final String dialoutPrefix = '';
}

class ConfigServer extends StandardConfig {
  final ConfigServerDefault defaults = new ConfigServerDefault ();
}

class ContactServer extends StandardConfig {}
class CDRServer extends StandardConfig {}
class MessageDispatcher extends StandardConfig {}
class ManagementServer extends StandardConfig {}
class MessageServer extends StandardConfig {}
class NotificationServer extends StandardConfig {}
class ReceptionServer extends StandardConfig {}

void logEntryDispatch(LogRecord record) {
  if (record.level.value > Level.INFO.value) {
    IO.stderr.writeln(record);
  } else {
    IO.stdout.writeln(record);
  }
}

abstract class Configuration {
  static final logDefaults = new Log();

  static final CallFlowControl callFlowControl = new CallFlowControl();
  static final ConfigServer configserver = new ConfigServer();
  static final ContactServer contactServer = new ContactServer();
  static final MessageDispatcher messageDispatcher = new MessageDispatcher();
  static final CDRServer cdrServer= new CDRServer();
  static final ManagementServer managementServer= new ManagementServer();
  static final MessageServer messageServer= new MessageServer();
  static final NotificationServer notificationServer= new NotificationServer();
  static final ReceptionServer receptionServer= new ReceptionServer();

}