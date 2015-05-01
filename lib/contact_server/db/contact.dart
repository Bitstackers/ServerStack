part of contactserver.database;

abstract class Contact {

  static Future<Iterable<Model.PhoneNumber>> phones(int contactID, int receptionID) {
    String sql = '''
        SELECT phonenumbers
        FROM reception_contacts
        WHERE contact_id = @contactID AND reception_id = @receptionID''';

    Map parameters =
      {'contactID': contactID,
       'receptionID': receptionID};

    return connection.query(sql, parameters).then((rows) {
      if ((rows as Iterable).isEmpty) {
        throw new Storage.NotFound('No contact found with ID $contactID'
                                   ' in reception with ID $receptionID');
      }

      Iterable<Map> phonesMap = (rows as Iterable).first.phonenumbers;

      Model.PhoneNumber mapToPhone (Map map) {

        Model.PhoneNumber p =
          new Model.PhoneNumber.empty()
            ..billing_type = map['billing_type']
            ..description = map['description']
            ..value = map['value']
            ..type = map['kind'];
        if(map['tag'] != null) {
          p.tags.add(map['tag']);
        }

        return p;
      }

      return phonesMap.map(mapToPhone);
    });
  }


  static Future<Iterable<Model.MessageEndpoint>> endpoints(int contactID, int receptionID) {
      String sql = '''
        SELECT address, address_type, confidential, enabled, priority, 
              description
        FROM messaging_end_points 
        WHERE contact_id = @contactID AND reception_id = @receptionID''';

      Map parameters =
        {'contactID': contactID,
         'receptionID': receptionID};

      return connection.query(sql, parameters).then((rows) =>
        (rows as Iterable).map((row) =>
          new Model.MessageEndpoint.fromMap(
            {'address'      : row.address,
             'type'         : row.address_type,
             'confidential' : row.confidential,
             'enabled'      : row.enabled,
             'priority'     : row.priority,
             'description'  : row.description,
             })
          ));

  }

  static Future<List<Model.Contact>> list(int receptionId) {
    String sql = '''
    SELECT rcpcon.reception_id, 
           rcpcon.contact_id, 
           rcpcon.wants_messages, 
           rcpcon.attributes, 
           rcpcon.enabled as rcpenabled,
           (SELECT row_to_json(distribution_column_seperated_roles)
              FROM (SELECT (SELECT array_to_json(array_agg(row_to_json(tmp_to)))
                            FROM (SELECT 
                                    recipient_reception_id as reception_id,
                                    reception.full_name    as reception_name,
                                    contact.full_name      as contact_name,
                                    recipient_contact_id   as contact_id
                                  FROM distribution_list dl JOIN receptions reception ON (recipient_reception_id = reception.id)
                                                            JOIN contacts contact ON (recipient_contact_id = contact.id) 
                                  WHERE dl.owner_reception_id = rcpcon.reception_id AND 
                                        dl.owner_contact_id = rcpcon.contact_id AND
                                        dl.role = 'to'
                                 ) tmp_to
                           ) AS to,
               
                           (SELECT array_to_json(array_agg(row_to_json(tmp_cc)))
                            FROM (SELECT 
                                    recipient_reception_id as reception_id,
                                    reception.full_name    as reception_name,
                                    contact.full_name      as conctact_name,
                                    recipient_contact_id   as contact_id
                                  FROM distribution_list dl JOIN receptions reception ON (recipient_reception_id = reception.id)
                                                            JOIN contacts contact ON (recipient_contact_id = contact.id) 
                                  WHERE dl.owner_reception_id = rcpcon.reception_id AND 
                                        dl.owner_contact_id = rcpcon.contact_id AND 
                                        dl.role = 'cc'
                                 ) tmp_cc
                           ) AS cc,
               
                           (SELECT array_to_json(array_agg(row_to_json(tmp_bcc)))
                            FROM (SELECT 
                                    recipient_reception_id as reception_id,
                                    reception.full_name    as reception_name,
                                    contact.full_name      as conctact_name,
                                    recipient_contact_id   as contact_id
                                  FROM distribution_list dl JOIN receptions reception ON (recipient_reception_id = reception.id)
                                                            JOIN contacts contact ON (recipient_contact_id = contact.id) 
                                  WHERE dl.owner_reception_id = rcpcon.reception_id AND 
                                        dl.owner_contact_id = rcpcon.contact_id AND
                                        dl.role = 'bcc'
                                 ) tmp_bcc
                           ) AS bcc
                   ) distribution_column_seperated_roles
             ) as distribution_list,
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

    FROM contacts con 
      JOIN reception_contacts rcpcon on con.id = rcpcon.contact_id
    WHERE rcpcon.reception_id = @receptionid''';

    Map parameters = {'receptionid' : receptionId};

    return connection.query(sql, parameters).then((rows) {
      List<Model.Contact> contacts = new List<Model.Contact>();
      for(var row in rows) {
        Map contact =
          {'reception_id'      : row.reception_id,
           'contact_id'        : row.contact_id,
           'wants_messages'    : row.wants_messages,
           'enabled'           : row.rcpenabled && row.conenabled,
           'full_name'         : row.full_name,
           'distribution_list' : row.distribution_list != null ? row.distribution_list : [],
           'contact_type'      : row.contact_type,
           'phones'            : row.phone != null ? row.phone : [],
           'endpoints'         : row.endpoints};

        if (row.attributes != null) {
          Map attributes = row.attributes;
          if(attributes != null) {
            attributes.forEach((key, value) => contact.putIfAbsent(key, () => value));

            var tmp = new Model.MessageRecipientList.empty();

            Model.Role.RECIPIENT_ROLES.forEach((String role) {
                if (contact['distribution_list'][role] is List) {
                  (contact['distribution_list'][role] as List).forEach((Map dlistMap) {
                                tmp.add(new Model.MessageRecipient.fromMap({'reception' :
                                {'id'   : dlistMap['reception_id'],
                                 'name' : dlistMap['reception_name']},
                               'contact'   :
                                {'id'   : dlistMap['contact_id'],
                                 'name' : dlistMap['contact_name']}},
                                 role : role));
                              });
                }
              });

            contact['distribution_list'] = tmp.asMap;

          }
        }
        contacts.add(new Model.Contact.fromMap(contact));
      }

      return contacts;
    });
  }

  static Future<Model.Contact> get(int receptionId, int contactId) {
      String sql = '''
      SELECT rcpcon.reception_id, 
             rcpcon.contact_id, 
             rcpcon.wants_messages, 
             rcpcon.attributes, 
             rcpcon.enabled as rcpenabled,
             (SELECT row_to_json(distribution_column_seperated_roles)
              FROM (SELECT (SELECT array_to_json(array_agg(row_to_json(tmp_to)))
                            FROM (SELECT 
                                    recipient_reception_id as reception_id,
                                    reception.full_name    as reception_name,
                                    contact.full_name      as contact_name,
                                    recipient_contact_id   as contact_id
                                  FROM distribution_list dl JOIN receptions reception ON (recipient_reception_id = reception.id)
                                                            JOIN contacts contact ON (recipient_contact_id = contact.id) 
                                  WHERE dl.owner_reception_id = rcpcon.reception_id AND 
                                        dl.owner_contact_id = rcpcon.contact_id AND
                                        dl.role = 'to'
                                 ) tmp_to
                           ) AS to,
               
                           (SELECT array_to_json(array_agg(row_to_json(tmp_cc)))
                            FROM (SELECT 
                                    recipient_reception_id as reception_id,
                                    reception.full_name    as reception_name,
                                    contact.full_name      as conctact_name,
                                    recipient_contact_id   as contact_id
                                  FROM distribution_list dl JOIN receptions reception ON (recipient_reception_id = reception.id)
                                                            JOIN contacts contact ON (recipient_contact_id = contact.id) 
                                  WHERE dl.owner_reception_id = rcpcon.reception_id AND 
                                        dl.owner_contact_id = rcpcon.contact_id AND 
                                        dl.role = 'cc'
                                 ) tmp_cc
                           ) AS cc,
               
                           (SELECT array_to_json(array_agg(row_to_json(tmp_bcc)))
                            FROM (SELECT 
                                    recipient_reception_id as reception_id,
                                    reception.full_name    as reception_name,
                                    contact.full_name      as conctact_name,
                                    recipient_contact_id   as contact_id
                                  FROM distribution_list dl JOIN receptions reception ON (recipient_reception_id = reception.id)
                                                            JOIN contacts contact ON (recipient_contact_id = contact.id) 
                                  WHERE dl.owner_reception_id = rcpcon.reception_id AND 
                                        dl.owner_contact_id = rcpcon.contact_id AND
                                        dl.role = 'bcc'
                                 ) tmp_bcc
                           ) AS bcc
                   ) distribution_column_seperated_roles
             ) as distribution_list,
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

      return connection.query(sql, parameters).then((rows) {

        Map data = {};
        if(rows != null && rows.length == 1) {
          var row = rows.first;

          data =
            {'reception_id'      : row.reception_id,
             'contact_id'        : row.contact_id,
             'wants_messages'    : row.wants_messages,
             'enabled'           : row.rcpenabled && row.conenabled,
             'full_name'         : row.full_name,
             'distribution_list' : row.distribution_list != null ? row.distribution_list : [],
             'contact_type'      : row.contact_type,
             'phones'            : row.phone != null ? row.phone : [],
             'endpoints'         : row.endpoints};

          if(row.attributes != null) {
            row.attributes.forEach((key, value) => data.putIfAbsent(key, () => value));
          }

          //FIXME: The format should be changed in the SQL return value.

          var tmp = new Model.MessageRecipientList.empty();

          Model.Role.RECIPIENT_ROLES.forEach((String role) {
              if (data['distribution_list'][role] is List) {
                (data['distribution_list'][role] as List).forEach((Map dlistMap) {
                              tmp.add(new Model.MessageRecipient.fromMap({'reception' :
                              {'id'   : dlistMap['reception_id'],
                               'name' : dlistMap['reception_name']},
                             'contact'   :
                              {'id'   : dlistMap['contact_id'],
                               'name' : dlistMap['contact_name']}},
                               role : role));
                            });
              }
            });

          data['distribution_list'] = tmp.asMap;
          return new Model.Contact.fromMap(data);
        } else {
          return Model.Contact.noContact;
        }
      });
  }

}
