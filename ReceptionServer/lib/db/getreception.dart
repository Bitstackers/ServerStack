part of receptionserver.database;

Future<Map> getReception(int id) {
  String sql = '''
      SELECT id, full_name, attributes, enabled, extradatauri, reception_telephonenumber, last_check
      FROM receptions
      WHERE id = @id 
    ''';

  Map parameters = {'id' : id};

  return connection.query(sql, parameters).then((rows) {
    Map data = {};
    if(rows.length == 1) {
      var row = rows.first;
      data =
        {'id'           : row.id,
         'full_name'    : row.full_name,
         'enabled'      : row.enabled,
         'extradatauri' : row.extradatauri,
         'reception_telephonenumber': row.reception_telephonenumber,
         'last_check'   : row.last_check.toString(),
         'attributes'   : row.attributes};
    }

    return data;
  });
}
