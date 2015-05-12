part of miscserver.router;

final Map client_config =
  {
      "callFlowServerURI"     : config.callFlowServerUri.toString(),
      "receptionServerURI"    : config.receptionServerUri.toString(),
      "contactServerURI"      : config.contactServerUri.toString(),
      "messageServerURI"      : config.messageServerUri.toString(),
      "logServerURI"          : config.logServerUri.toString(),
      "authServerURI"         : config.authServerUri.toString(),
      "systemLanguage"        : config.systemLanguage,

      "notificationSocket": {
          "interface": config.notificationSocketUri.toString(),
          "reconnectInterval": 2000
      },

      "serverLog": {
          "level": "info",
          "interface": {
              "critical": "/log/critical",
              "error": "/log/error",
              "info": "/log/info"
          }
      }
  };


shelf.Response getBobConfig(shelf.Request request) =>
  new shelf.Response.ok(JSON.encode(client_config));

shelf.Response send404(shelf.Request request) {
  return new shelf.Response.notFound(JSON.encode({"error" : "Not Found"}));
}


