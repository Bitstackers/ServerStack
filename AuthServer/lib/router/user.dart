part of authenticationserver.router;

void userinfo(HttpRequest request) {  
  cache.loadToken(queryParameter(request.uri, 'token')).then((String token) {
    Map json = JSON.decode(token);
    String url = 'https://www.googleapis.com/oauth2/v1/userinfo?alt=json&access_token=${json['access_token']}';
    
    return http.get(url).then((http.Response response) {
      Map googleProfile = JSON.decode(response.body);
      return db.getUser(googleProfile['email']).then((Map agent) {
        agent['remote_attributes'] = googleProfile;
        writeAndClose(request, JSON.encode(agent));
      });
    });
  }).catchError((error) {
    serverError(request, 'authenticationserver.router.userinfo: $error');
  });  
}