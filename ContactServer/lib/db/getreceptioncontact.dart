part of contactserver.database;

Future<Map> getContact(int receptionId, int contactId) {
    String sql = '''
      SELECT rcpcon.reception_id, 
             rcpcon.contact_id, 
             rcpcon.wants_messages, 
             rcpcon.attributes, 
             rcpcon.enabled as rcpenabled,
             rcpcon.distribution_list,
             con.full_name, 
             con.contact_type, 
             con.enabled as conenabled,
             rcpcon.phonenumbers as phone,

             (SELECT coalesce(array_to_json(array_agg(row_to_json(contact_end_point))), '[]')
              FROM (SELECT address, address_type, confidential, enabled, priority, description
                    FROM messaging_end_points
                    WHERE reception_id = rcpcon.reception_id AND
                          contact_id = rcpcon.contact_id
                    ORDER BY priority ASC) contact_end_point) AS endpoints
        
          FROM   contacts con 
            JOIN reception_contacts rcpcon on con.id = rcpcon.contact_id
          WHERE  rcpcon.reception_id = @receptionid
             AND rcpcon.contact_id = @contactid ;''';

    Map parameters = {'receptionid' : receptionId,
                      'contactid': contactId};

    return database.query(_pool, sql, parameters).then((rows) {
      Map data = {};
      if(rows != null && rows.length == 1) {
        var row = rows.first;
        data =
          {'reception_id'      : row.reception_id,
           'contact_id'        : row.contact_id,
           'wants_messages'    : row.wants_messages,
           'enabled'           : row.rcpenabled && row.conenabled,
           'full_name'         : row.full_name,
           'distribution_list' : row.distribution_list != null ? JSON.decode(row.distribution_list) : [],
           'contact_type'      : row.contact_type,
           'phones'            : row.phone != null ? JSON.decode(row.phone) : [],
           'endpoints'         : JSON.decode(row.endpoints)};

        if(row.attributes != null) {
          JSON.decode(row.attributes).forEach((key, value) => data.putIfAbsent(key, () => value));
        }
      }

      return data;
    });
}
