library router;

import 'dart:async';
import 'dart:io';

import '../../Shared/httpserver.dart';
import '../../Shared/common.dart';

import 'package:intl/intl.dart';
import 'package:route/server.dart';
import 'package:route/pattern.dart';

part 'router/log.dart';

final Pattern debugUrl = new UrlPattern('/log/debug');
final Pattern infoUrl = new UrlPattern('/log/info');
final Pattern errorUrl = new UrlPattern('/log/error');
final Pattern criticalUrl = new UrlPattern('/log/critical');
final List<Pattern> allUniqueUrls = [debugUrl, infoUrl, errorUrl, criticalUrl];

void setup(HttpServer server) {
  Router router = new Router(server)
    ..filter(matchAny(allUniqueUrls), authFilter)
    ..serve(debugUrl, method: 'POST').listen(logDebug)
    ..serve(infoUrl, method: 'POST').listen(logInfo)
    ..serve(errorUrl, method: 'POST').listen(logError)
    ..serve(criticalUrl, method: 'POST').listen(logCritical)
    ..defaultStream.listen(page404);
}