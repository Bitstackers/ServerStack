library userController;

import 'dart:io';
import 'dart:convert';

import '../utilities/http.dart';
import '../utilities/logger.dart';
import '../database.dart';
import '../model.dart';
import '../view/user.dart';

class UserController {
  Database db;

  UserController(Database this.db);

  void createUser(HttpRequest request) {
    extractContent(request)
    .then(JSON.decode)
    .then((Map data) => db.createUser(data['name'], data['extension']))
    .then((int id) => writeAndCloseJson(request, userIdAsJson(id)))
    .catchError((error) {
      logger.error('create user failed: $error');
      Internal_Error(request);
    });
  }

  void deleteUser(HttpRequest request) {
    int userId = pathParameter(request.uri, 'user');

    db.deleteContact(userId)
    .then((int rowsAffected) => writeAndCloseJson(request, JSON.encode({})))
    .catchError((error) {
      logger.error('deleteUser url: "${request.uri}" gave error "${error}"');
      Internal_Error(request);
    });
  }

  void getUser(HttpRequest request) {
    int userId = pathParameter(request.uri, 'user');

    db.getUser(userId).then((User user) {
      if(user == null) {
        request.response.statusCode = 404;
        return writeAndCloseJson(request, JSON.encode({}));
      } else {
        return writeAndCloseJson(request, userAsJson(user));
      }
    }).catchError((error) {
      logger.error('get user Error: "$error"');
      Internal_Error(request);
    });
  }

  void getUserList(HttpRequest request) {
    db.getUserList().then((List<User> list) {
      return writeAndCloseJson(request, listUserAsJson(list));
    }).catchError((error) {
      logger.error('get user list Error: "$error"');
      Internal_Error(request);
    });
  }

  void updateUser(HttpRequest request) {
    int userId = pathParameter(request.uri, 'user');
    extractContent(request)
      .then(JSON.decode)
      .then((Map data) => db.updateUser(userId, data['name'], data['extension']))
      .then((int id) => writeAndCloseJson(request, userIdAsJson(id)))
      .catchError((error) {
        logger.error('updateUser url: "${request.uri}" gave error "${error}"');
        Internal_Error(request);
      });
  }

  void getUserGroups(HttpRequest request) {
    int userId = pathParameter(request.uri, 'user');
    db.getUserGroups(userId)
      .then((List<UserGroup> data) => writeAndCloseJson(request, userGroupAsJson(data)) )
      .catchError((error) {
        logger.error('getUserGroups: url: "${request.uri}" gave error "${error}"');
	      Internal_Error(request);
      });
  }

  void joinUserGroups(HttpRequest request) {
    int userId = pathParameter(request.uri, 'user');
    int groupId = pathParameter(request.uri, 'group');

    db.joinUserGroup(userId, groupId).then((_) {
      writeAndCloseJson(request, '{}');
    }).catchError((error) {
      logger.error('joinUserGroups: url: "${request.uri}" gave error "${error}"');
      Internal_Error(request);
    });
  }

  void leaveUserGroups(HttpRequest request) {
    int userId = pathParameter(request.uri, 'user');
    int groupId = pathParameter(request.uri, 'group');

    db.leaveUserGroup(userId, groupId).then((_) {
      writeAndCloseJson(request, '{}');
    }).catchError((error) {
      logger.error('leaveUserGroups: url: "${request.uri}" gave error "${error}"');
      Internal_Error(request);
    });
  }

  void getGroupList(HttpRequest request) {
    db.getGroupList()
      .then((List<UserGroup> data) => writeAndCloseJson(request, userGroupAsJson(data)) )
      .catchError((error) {
        logger.error('getGroupList: url: "${request.uri}" gave error "${error}"');
        Internal_Error(request);
      });
  }
}