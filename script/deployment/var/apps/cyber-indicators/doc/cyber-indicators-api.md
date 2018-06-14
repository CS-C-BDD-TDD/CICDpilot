Cyber Indicators API
====================

The Cyber Indicators system serves all information using web services.  Computer applications and analysts that wish to either read or write information to the API can use this guide to get connected.

# Initial Setup

Who may access the API?
----------------------

Anyone who has an API key may read data from the application.  Accredited NSD systems may write data to the production application.

Please contact the NSD Product Lead for more information concerning the accreditation process, and how to gain API write access approval.

Machine Accounts are used to write to the application.  Machine accounts may not log in to the web interface.

# Requesting API Access

The steps to access the API are:

1. Request API access
2. Generate an [API Key Hash](#api_key_hash)
3. Use the API

Read-only access
----------------

Please contact a Cyber Indicators administrator and request that an API Key is created for your account.

Write access
------------

This is intended for accreddited systems.  Please provide the accreddited system name to the NSD Product Lead.

## Granting API access as a Cyber Indicators administrator

*Note: There is no role named 'administrator' in Cyber Indicators, but for the purposes of this guide, a user who has the privilege to edit other user accounts will be referred to as an administrator.*

## Read-only analyst access

1. In the navigation menu, click "Users"
2. Find the user who is requesting the API key
3. Click "Edit"
4. Click the "Generate API Key" button
5. The system will generate an API key for the user.  Click the "Click to show" text to shown the API key.  Send this API key to the user in a secure manner
6. The the user's initial API Key secret.  In the text box below "Change API Key Secret", type in an API Key secret.  Click the "Change API Key Secret" button.  The user's API Key secret is now set.
7. Securely send the API Key and API Key Secret to the user.  The user will use these credentials to generate an API Key Hash to communicate with the API

## Read / write machine Access

1. Accredited NSD systems may be authorized for write access to the API.
2. Create a Cyber Indicators account for the system.  (In the navigation menu, click users.  Click the "New" button.
3. The username of the user does not need to match an Active Directory username, but rather should be the name of the system which will be using the API.  Be sure to assign the user to a group which has the proper write permissions to support what that machine user will be doing.
4.  After creating the user, click on "Edit", and follow the steps for the "Read-only analyst accesss" above to generate the API Key and API Key secret for the machine user
5. The account must be converted to be a machine user.  Only a System Administrator may perform this step.
6. As a system administrator, run the following as root, substituting the correct TNS_ADMIN_PATH and USERNAME_FROM_STEP_3 for what you used in step 3 when creating the user:

```bash
TNS_ADMIN=TNS_ADMIN_PATH /var/apps/cyber-indicators/bin/rake machineuser:set['USERNAME_FROM_STEP_3']
```

You can change the user back to a regular user by changing 'set' to 'unset'

Example:

```bash
TNS_ADMIN=/etc /var/apps/cyber-indicators/bin/rake machineuser:set['username_from_step_3']
```

## <a name="api_key_hash"/></a>Generating your API Key Hash

1. Login to a Linux or Unix workstation.
2. Run the following command, substitute in your API_KEY and API_KEY_SECRET

```bash
echo -n API_KEY@API_KEY_SECRET | sha256sum
```

3. The output will be your API Key Hash.  Spaces or dashes following the letters and numbers in the output are NOT part of the API Key Hash.

Example

```bash
➜ echo -n 9054e40b4d7b07c001af76adf1db70befb94a77fe44e5745c937efb417e4b1e4@my_secret | sha256sum
2b801c6d2685d186edd6fec641c3ec2544175daac7caba5af25f65b2f83f3e9d  -
```

In this example, the API Key Hash is `2b801c6d2685d186edd6fec641c3ec2544175daac7caba5af25f65b2f83f3e9d`

## Revoking an API key

API Keys may be revoked from either regular users or machine users by performing the following steps:

1. Click Users
2. Click the username
3. Click Edit
4. Under API Key, click the "Revoke API Key" button

## Adding your API key to your HTTP request

Your API Key and API Key Hash must be submitted with every request to the API.  Failure to do so will result in an HTTP 401 unauthorized status message returned. 

You must place this information in your HTTP request headers as API_KEY and API_KEY_HASH.  

!Example! Using cURL to pass an HTTP request header:

```bash
curl -H "Accept: application/json" \
-H "api_key: YOUR_API_KEY" \
-H "api_key_hash: YOUR_API_KEY_HASH" \
"https://CYBER_INDIACTORS_HOSTNAME/cyber-indicators/SOME_API_CALL"
```

## Data formats

The API can return resources in multiple formats.  JSON is the most widely supported format in the API.  When you request data from the API, it is important to specify which format you'd like to receive.

To specify the return format for your data, add the HTTP request header "Accept" to your request.  For example: `curl -H "Accept: application/json" -H "api_key: YOUR_API_KEY" -H "api_key_hash: YOUR_API_KEY_HASH" "https://CYBER_INDICATORS_HOSTNAME/cyber-indicators/SOME_API_CALL"`

Some routes may allow you to simply append your format to the end of the route.  For example: `/domains` becomes `/domains.json`.  This method is not preferred because it can lead to ambiguous requests.  For example, consider the following route: `/domain/example.com.json`.  It is unclear whether the user is requesting data from the API about the domain `example.com` in JSON format, or information on the domain `example.com.json`.

## Sending Data to the API

Machine accounts may write to the application.

The application will make a "best guess" as to the data format.  You may specify the data format your request is sending by adding the HTTP request header "Content-Type".  For example:

```bash
curl -v -H "Accept: application/json" -H "Content-Type: application/json" -H "api_key: YOUR_API_KEY" -H "api_key_hash: YOUR_API_KEY_HASH" --data '{}' "https://CYBER_INDICATORS_HOSTNAME/cyber-indicators/SOME_API_CALL"
```

!Note! If the --data parameter is passed JSON properties and values are wrapped in double-quotes.  For example:

```bash
--data '{"title":"new-title","description":"new description","indicator_type":"benign"}'
```


## HTTP Return Status Codes

The API returns different status codes to let your program know whether the request was successful or not:

* HTTP 200 OK - The request succeeded
* HTTP 400 Bad Request - Something is malformed in your request
* HTTP 401 Unauthorized - Incorrect API Key or API Key hash
* HTTP 403 Access Denied - You are using the correct API Key, but you don't have permission to see what you are requesting
* HTTP 404 Not Found - What you're requesting isn't in the system
* HTTP 422 Unprocessable Entity - The system understands your request, but it was incorrectly formed.  For example, you try to set an ISA marking of "For official use only!" instead of the correct "FOUO"
* HTTP 500 Internal Server Error - Something's wrong with the application.  Please submit a ticket to the NCPS help desk with the URL you're trying to access, along with any parameters you are passing.

More detailed error codes may apply depending on what went wrong.  You should configure your application to assume a successful call will return 2xx and an unsuccessful call will return 4xx.

## API Result Limits

API queries return the maximum number of results.

By default, most queries in the API return a maximum number of results which is set by a system administrator.  This number defaults to 100 results.  You can get the next 100 results by specifying the query parameter `offset=100`.  Machine API accounts may change the number of results returned by specifying `limit` query parameter.  To get 500 results, you would add `limit=500` to the query parameters.  There is no command to get unlimited results.

# API Routes

The rest of this guide will assume that you already have an API key and API key hash.  If you wish to write to the API, your Cyber Indicators account must be configured by a Cyber Indicators admin as a machine user as described above.

The API routes discussed in this guide are:

* `https://hostname/cyber-indicators/domains`
* `https://hostname/cyber-indicators/indicators`
* `https://hostname/cyber-indicators/search`

# Sample API Usage

Here's an example for how to get recent indicators from the API using curl.

```bash
curl -v -H "api_key:API_KEY" -H "api_key_hash:API_KEY_HASH" -H "Accept:application/json" "https://SERVER_FQDN/cyber-indicators/indicators"
```
!Note! Replace API_KEY with the api key of your user account.

!Note! Replace API_KEY_HASH with the api key has of your user account.

!Note! Replace SERVER_FQDN with the fully-qualified domain name of the Cyber Indicators application server.

## Listing Indicators

**Route:** `/indicators` - List the most recent indicators added to the system

**Parameters**

'amount': The number of records you would like returned.  There is no option for unlimited.  The system has a setting which sets the max number of records returned.  This setting is defaulted to 100.

'offset': Skip the first number of offset records.  If the amount is set to 100, this will allow you to get the second set of results by passing offset=100

'ebt', 'iet: Exclusive Begin Time and Inclusive End Time.  Will only retrieve indicators updated between these timestamps.  Note that you must include both ebt and iet.

'column': By default, indicator results are sorted by their updated timestamp.  Other choices include: 'title,'created_at','indicator_type','description','stix_id','dms_label'

'direction': Which direction the results should be sorted in.  'asc' for ascending order or 'desc' for descending.  Useful only if column is also specified

'indicator_type': Return only results of a particular indicator type.  Options include: 'anonymization','benign','c2','compromised','domain_watchlist','exfiltration','file_hash_watchlist','host_characteristics','ip_watchlist','malicious_email','malware_artifacts','url_watchlist'

'dms_label': Retrieve only indicators with the specified DMS Label

**Sample**

```
GET /indicators
Params
 amount=2
```

```json
{ "indicators" : [ { "composite_operator" : null,
        "confidences" : [ { "value" : "low" } ],
        "created_at" : "2015-02-19 15:26:14 UTC",
        "description" : "description",
        "dms_label" : null,
        "downgrade_request_id" : null,
        "alternative_id" : null,
        "guid" : "2b2cfd8d-8611-42cc-83ae-c9e9693d7c00",
        "indicator_type" : "Benign",
        "indicator_type_vocab_name" : null,
        "indicator_type_vocab_ref" : null,
        "is_composite" : false,
        "is_negated" : false,
        "is_reference" : false,
        "observables" : [ { "address" : { "address" : "1.2.100.100/32",
                  "address_input" : "1.2.100.100",
                  "category" : "ipv4-addr",
                  "created_at" : "2015-02-19 15:26:14 UTC",
                  "cybox_object_id" : "f05680c6-05f0-45b8-a0ef-a93250a0e29d",
                  "guid" : "1f8bf531-364f-4b6b-a512-7d886565c066",
                  "ip_value_calculated_end" : 16933988,
                  "ip_value_calculated_start" : 16933988,
                  "updated_at" : "2015-02-19 15:26:14 UTC"
                },
              "cybox_object_id" : "3fa2f568-d81c-47a0-b050-1811e8d56d90",
              "dns_record" : null,
              "domain" : null,
              "email_message" : null,
              "file" : null,
              "guid" : "20ebc3ba-df45-41ea-8d33-9386dc6d1c25",
              "http_session" : null,
              "mutex" : null,
              "network_connection" : null,
              "registry" : null,
              "remote_object_id" : "f05680c6-05f0-45b8-a0ef-a93250a0e29d",
              "remote_object_type" : "Address",
              "stix_indicator_id" : "NCCIC:Indicator-2b2cfd8d-8611-42cc-83ae-c9e9693d7c00",
              "uri" : null
            } ],
        "parent_id" : null,
        "resp_entity_stix_ident_id" : null,
        "stix_id" : "NCCIC:Indicator-2b2cfd8d-8611-42cc-83ae-c9e9693d7c00",
        "stix_timestamp" : null,
        "title" : "Indicator 100",
        "updated_at" : "2015-02-19 15:27:48 UTC"
      },
      { "composite_operator" : null,
        "confidences" : [ { "value" : "medium" } ],
        "created_at" : "2015-02-19 15:26:12 UTC",
        "description" : "description",
        "dms_label" : null,
        "downgrade_request_id" : null,
        "guid" : "a9382de6-12e2-4d46-a005-2be1756aa8ec",
        "indicator_type" : "Benign",
        "indicator_type_vocab_name" : null,
        "indicator_type_vocab_ref" : null,
        "is_composite" : false,
        "is_negated" : false,
        "is_reference" : false,
        "observables" : [ { "address" : { "address" : "1.2.100.99/32",
                  "address_input" : "1.2.100.99",
                  "category" : "ipv4-addr",
                  "created_at" : "2015-02-19 15:26:13 UTC",
                  "cybox_object_id" : "e8ef8ed9-037c-4bf6-a1e0-0f8aaded4048",
                  "guid" : "36cc6fe8-a93d-4f06-b2e3-2da943a0dd87",
                  "ip_value_calculated_end" : 16933987,
                  "ip_value_calculated_start" : 16933987,
                  "updated_at" : "2015-02-19 15:26:13 UTC"
                },
              "cybox_object_id" : "a7d8f03c-d76f-4956-9bc0-24feb7a6c1a2",
              "dns_record" : null,
              "domain" : null,
              "email_message" : null,
              "file" : null,
              "guid" : "dbe9a1c4-9b4b-4762-bcf1-1f6eb2215333",
              "http_session" : null,
              "mutex" : null,
              "network_connection" : null,
              "registry" : null,
              "remote_object_id" : "e8ef8ed9-037c-4bf6-a1e0-0f8aaded4048",
              "remote_object_type" : "Address",
              "stix_indicator_id" : "NCCIC:Indicator-a9382de6-12e2-4d46-a005-2be1756aa8ec",
              "uri" : null
            } ],
        "parent_id" : null,
        "resp_entity_stix_ident_id" : null,
        "stix_id" : "NCCIC:Indicator-a9382de6-12e2-4d46-a005-2be1756aa8ec",
        "stix_timestamp" : null,
        "title" : "Indicator 99",
        "updated_at" : "2015-02-19 15:27:45 UTC"
      }
    ],
  "metadata" : { "total_count" : 117 }
}
```

## Searching for Indicators

**Route:** `/indicators` - Search for indicators using the search engine

*Note: This is the same route as the /indicators route, but if the parameter 'q' is specified, the search platform will use used to query for indicators instead of the database.  This means different parameters are valid, so it's being documented as a separate route*

**Parameters**

`q`: Search Query text.  Required for search.

'amount': The number of records you would like returned.  There is no option for unlimited.  The system has a setting which sets the max number of records returned.  This setting is defaulted to 100.

'offset': Skip the first number of offset records.  If the limit is set to 100, this will allow you to get the second set of results

'ebt', 'iet: Exclusive Begin Time and Inclusive End Time.  Will only retrieve indicators updated between these timestamps.  Note that you must include both ebt and iet.

'indicator_type': Return only results of a particular indicator type.  Options include: 'anonymization','benign','c2','compromised','domain_watchlist','exfiltration','file_hash_watchlist','host_characteristics','ip_watchlist','malicious_email','malware_artifacts','url_watchlist'

## Searching for Objects

**Route:** `/search` - Search for indicators using the search engine

**Parameters**

`q`: Search Query text.  Required for search.

'amount': The number of records you would like returned.  There is no option for unlimited.  The system has a setting which sets the max number of records returned.  This setting is defaulted to 100.

'offset': Skip the first number of offset records.  If the limit is set to 100, this will allow you to get the second set of results

'ebt', 'iet: Exclusive Begin Time and Inclusive End Time.  Will only retrieve indicators updated between these timestamps.  Note that you must include both ebt and iet.

'indicator_type': Return only results of a particular indicator type.  Options include: 'anonymization','benign','c2','compromised','domain_watchlist','exfiltration','file_hash_watchlist','host_characteristics','ip_watchlist','malicious_email','malware_artifacts','url_watchlist'

**Example**

GET '/search?q=indicator&amount=1&offset=2'

```json
{  
   "indicators":[  
      {  
         "composite_operator":null,
         "description":"description",
         "indicator_type":"benign",
         "indicator_type_vocab_name":null,
         "indicator_type_vocab_ref":null,
         "is_composite":false,
         "is_negated":false,
         "is_reference":false,
         "parent_id":null,
         "resp_entity_stix_ident_id":null,
         "stix_id":"NCCIC:Indicator-bdd9ca63-88f4-4119-a4d1-4d4ba168b355",
         "dms_label":null,
         "stix_timestamp":null,
         "title":"Indicator 92",
         "created_at":"2015-03-24 15:29:55 UTC",
         "updated_at":"2015-03-24 15:30:15 UTC",
         "guid":"bdd9ca63-88f4-4119-a4d1-4d4ba168b355",
         "downgrade_request_id":null,
         "alternative_id" : null,
         "color":null,
         "observables":[  
            {  
               "cybox_object_id":"NCCIC:Observable-042fc30e-4022-4ba7-8979-c332d7ab35c5",
               "stix_indicator_id":"NCCIC:Indicator-bdd9ca63-88f4-4119-a4d1-4d4ba168b355",
               "remote_object_id":"NCCIC:Address-31e87fcf-ea43-4ea3-89cd-b534e98a3573",
               "remote_object_type":"Address",
               "guid":"042fc30e-4022-4ba7-8979-c332d7ab35c5",
               "dns_record":null,
               "domain":null,
               "email_message":null,
               "file":null,
               "http_session":null,
               "address":{  
                  "address":"1.2.100.92/32",
                  "address_input":"1.2.100.92",
                  "category":"ipv4-addr",
                  "cybox_object_id":"NCCIC:Address-31e87fcf-ea43-4ea3-89cd-b534e98a3573",
                  "ip_value_calculated_start":16933980,
                  "ip_value_calculated_end":16933980,
                  "created_at":"2015-03-24 15:29:55 UTC",
                  "updated_at":"2015-03-24 15:29:55 UTC",
                  "guid":"31e87fcf-ea43-4ea3-89cd-b534e98a3573"
               },
               "mutex":null,
               "network_connection":null,
               "registry":null,
               "uri":null
            }
         ],
         "confidences":[  
            {  
               "value":"low"
            }
         ]
      }
   ],
   "metadata":{  
      "total_indicators_count":113,
      "total_weather_map_data_count":0
   }
}
```



## Get Detailed Information About an Indicator

**Route** `/indicators/STIX_ID` - Get information about an indicator with the specified STIX_ID

**Parameters**

* format - Optional.  Set to 'stix' and instead of JSON, a STIX representation of the indicator will be returned.

**Example**

GET `/indicators/NCCIC:Indicator-f9cb03e2-4a06-43a5-8282-fc6d021bb94b`

```json
{ "audits" : [ { "audit_type" : "confidence",
        "details" : null,
        "event_time" : "2015-02-25 18:15:33 UTC",
        "justification" : null,
        "message" : "Confidence 'medium' added to indicator 'Example watchlist untrusted malware source'",
        "system_name" : "CIAP",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "user_guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076"
      },
      { "audit_type" : "confidence",
        "details" : null,
        "event_time" : "2015-02-25 18:15:33 UTC",
        "justification" : null,
        "message" : "Confidence 'medium' added to indicator 'Example watchlist untrusted malware source'",
        "system_name" : "CIAP",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "user_guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076"
      },
      { "audit_type" : "tag",
        "details" : null,
        "event_time" : "2015-02-25 18:15:32 UTC",
        "justification" : null,
        "message" : "Tagged Indicator with 'FO02'",
        "system_name" : "CIAP",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "user_guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076"
      },
      { "audit_type" : "tag",
        "details" : null,
        "event_time" : "2015-02-25 18:15:32 UTC",
        "justification" : null,
        "message" : "Tagged Indicator with 'FO01'",
        "system_name" : "CIAP",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "user_guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076"
      },
      { "audit_type" : "link",
        "details" : null,
        "event_time" : "2015-02-25 18:15:08 UTC",
        "justification" : null,
        "message" : "Address '147.27.180.39' attached to Indicator 'Example watchlist untrusted malware source'",
        "system_name" : "CIAP",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "user_guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076"
      },
      { "audit_type" : "create",
        "details" : "{\"title\"=>\"Example watchlist untrusted malware source\", \"description\"=>\"This is an example indicator\", \"indicator_type\"=>\"Exfiltration\", \"stix_id\"=>\"6bb61900-2258-11e4-8c21-0800200caa66\", \"guid\"=>\"40f5e069-4041-4df5-9c98-1c7550041b4f\", \"created_by_user_guid\"=>\"201f22b5-8d91-4e6c-9fde-2bcae4132076\", \"created_by_organization_guid\"=>\"5f9fc51b-944e-45ff-a648-bd6ab509d0e9\", \"updated_by_user_guid\"=>\"201f22b5-8d91-4e6c-9fde-2bcae4132076\", \"updated_by_organization_guid\"=>\"5f9fc51b-944e-45ff-a648-bd6ab509d0e9\", \"created_at\"=>Wed, 25 Feb 2015 18:15:07 UTC +00:00, \"id\"=>5}",
        "event_time" : "2015-02-25 18:15:07 UTC",
        "justification" : null,
        "message" : "Indicator created",
        "system_name" : "CIAP",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "user_guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076"
      }
    ],
  "composite_operator" : null,
  "confidences" : [ { "description" : "Ingested Confidence",
        "is_official" : true,
        "set_at" : "2015-02-25 18:15:33 UTC",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "value" : "medium"
      },
      { "description" : "Ingested Confidence",
        "is_official" : false,
        "set_at" : "2015-02-25 18:15:33 UTC",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "value" : "medium"
      },
      { "description" : "Ingested Confidence",
        "is_official" : false,
        "set_at" : "2015-02-25 18:15:33 UTC",
        "user" : { "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "username" : "svcadmin"
          },
        "value" : "medium"
      }
    ],
  "created_at" : "2015-02-25 18:15:07 UTC",
  "created_by_user" : { "api_key" : null,
      "created_at" : "2015-02-25 18:15:05 UTC",
      "disabled_at" : null,
      "email" : "svcadmin@indicators.app",
      "first_name" : "Admin",
      "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
      "id" : 1,
      "last_name" : "User",
      "phone" : null,
      "terms_accepted_at" : "2015-02-25 18:20:49 UTC",
      "updated_at" : "2015-02-25 18:20:49 UTC",
      "username" : "svcadmin"
    },
  "description" : "This is an example indicator",
  "dms_label" : null,
  "downgrade_request_id" : null,
  "alternative_id" : null,
  "exported_indicators" : [  ],
  "guid" : "40f5e069-4041-4df5-9c98-1c7550041b4f",
  "indicator_type" : "Exfiltration",
  "indicator_type_vocab_name" : null,
  "indicator_type_vocab_ref" : null,
  "is_composite" : false,
  "is_negated" : false,
  "is_reference" : false,
  "notes" : [ { "created_at" : "2015-02-25 22:43:27 UTC",
        "guid" : "6f6821ee-f001-44ec-8a7f-e1cd45111209",
        "justification" : null,
        "note" : "This is an analyst note about the indicator",
        "user" : { "api_key" : null,
            "created_at" : "2015-02-25 18:15:05 UTC",
            "disabled_at" : null,
            "email" : "svcadmin@indicators.app",
            "first_name" : "svcAdmin",
            "guid" : "201f22b5-8d91-4e6c-9fde-2bcae4132076",
            "id" : 1,
            "last_name" : "User",
            "phone" : null,
            "terms_accepted_at" : "2015-02-25 18:20:49 UTC",
            "updated_at" : "2015-02-25 18:20:49 UTC",
            "username" : "svcadmin"
          }
      } ],
  "observables" : [ { "address" : { "address" : "147.27.180.39/32",
            "address_input" : "147.27.180.39",
            "category" : "ipv4-addr",
            "created_at" : "2015-02-25 18:15:08 UTC",
            "cybox_object_id" : "a106acb9-4200-4d47-b442-06a86331cddd",
            "guid" : "c573c943-41e2-4956-a882-15a2f3c669ce",
            "ip_value_calculated_end" : 2468066343,
            "ip_value_calculated_start" : 2468066343,
            "updated_at" : "2015-02-25 18:15:08 UTC",
            "agencies_sensors_seen_on" : "CSOSA52M-DOLM-DOT7-FAA45",
            "com_threat_score" : "0.59",
            "created_at" : "2015-02-25 18:15:08 UTC",
            "updated_at" : "2015-02-25 18:15:08 UTC",
            "first_date_seen" : "2015-01-25 13:09:03 -0500\"",
            "gov_threat_score" : "0.23",
            "iso_country_code" : "USA",
            "last_date_seen" : "2015-02-25 14:09:03 -0500\""
          },
        "cybox_object_id" : "e5aaeaf9-40f7-4f0c-bb3d-87b501f9c70a",
        "dns_record" : null,
        "domain" : null,
        "email_message" : null,
        "file" : null,
        "guid" : "2e0dbdcb-5f60-4afe-b2ac-ca6dc214f697",
        "http_session" : null,
        "mutex" : null,
        "network_connection" : null,
        "registry" : null,
        "remote_object_id" : "a106acb9-4200-4d47-b442-06a86331cddd",
        "remote_object_type" : "Address",
        "stix_indicator_id" : "6bb61900-2258-11e4-8c21-0800200caa66",
        "uri" : null
      } ],
  "parent_id" : null,
  "related_indicators" : [  ],
  "resp_entity_stix_ident_id" : null,
  "sightings" : [  ],
  "stix_id" : "6bb61900-2258-11e4-8c21-0800200caa66",
  "stix_timestamp" : null,
  "system_tags" : [ { "guid" : "69dd1663-4fcd-438a-8de7-dd0ba5ace133",
        "id" : 11,
        "is_permanent" : false,
        "name" : "FO01",
        "type" : "system-tag"
      },
      { "guid" : "5d0e6078-5ebb-42e8-aa78-03ad5869de28",
        "id" : 12,
        "is_permanent" : false,
        "name" : "FO02",
        "type" : "system-tag"
      }
    ],
  "title" : "Example watchlist untrusted malware source",
  "updated_at" : "2015-02-25 18:15:33 UTC",
  "user_tags" : [  ]
}
```

## Show all Indicators tagged with a System Tag

**Route:** GET `/system_tags/TAG_NAME` - Gets all indicators tagged with TAG_NAME.  TAG_NAME can be either name or GUID of the tag.

**Example**

GET `/system_tags/FO12`

## Adding and Updating Indicators

**Route:** POST `/indicators` - To add a new indicator

**Route:** PUT `/indicators/STIX_ID` - To update an existing indicator

*Note: To generate a proper ACS ISA Marking, two separate ISA Marking Structures are required: ISAMarkingType and ISAMarkingAssertion.  The ISAMarkingType has custodian (required), the originator (optional), and the created_at time (optional).  The ISAMarkingsAssertiontype has classification (coded to U), countires, controlled unclassified information, entity, formal determination, organizations, shareability group, is_default_marking, privilege_default, public_release, public_released_by and public_released_on.  Acceptable and recommended values for "isa_markings_attributes" can be found in the ESSA Information Sharing Architecture Access Control Specification document, v2.0. https://www.us-cert.gov/essa  All references to section numbers and appendicies below refer to this document.*

**HTTP Request Body**

```json
  {
    "title"                     : "Required.  Title of Indicator",
    "indicator_type"            : "Required.  Can be 'anonymization','benign','c2','compromised','domain_watchlist','exfiltration','file_hash_watchlist','host_characteristics','ip_watchlist','malicious_email','malware_artifacts','url_watchlist'",
    "description":              : "Required.  Can be any text to describe the indicator",
    /* STIX Marking attributes are optional, but if you choose to include them, certain fields are required */
    "stix_markings_attributes"   : [{
      "isa_assertion_structure_attributes" : {
        "public_release"            : "true or false.  Do not quote true or false.  If true, all Control Set restrictions are ignored by definition. Defaults to false.",
        "cs_countries"              : "Control Set - Countries.  This is a JSON array of strings with capitalized three leter country codes. 'USA', 'CAN' etc. For use with ISAMarkingsAssertionType.",
        "cs_orgs"                   : "Control Set - Organizations.  This is a JSON array of strings with the organization abbreviations found in Appendix A: List of Organizations, from the ESSA ACS v2.0 document.  For example: [\"USA.DHS\",\"USA.DOC\"].  For use with ISAMarkingsAssertionType.",
        "cs_entity"                 : "Control Set - Entity.  This is a JSON array of strings.  Allowable values are MIL, GOV, CTR, SVR, SVC, DEV and NET. These are based on the Unified Identity Attribute Set Reference 5 from the ESSA ACS v2.0 document.  For use with ISAMarkingsAssertionType.",
        "cs_cui"                    : "Control Set - Controlled Unclassified information.  This is a JSON array of strings.  Allowable values are under section 2.7.3.3 in the ESSA ISA ACS v2.0 guide.  For use with ISAMarkingsAssertionType.",
        "cs_shargrp"                : "Control Set - Shareability Group.  This is a JSON array of strings.  Allowable values found in section 2.7.6.1.",
        "cs_formal_determination"   : "Control Set - Formal Determination. ",
        "public_released_by"        : "For items which are publically releasable, this is described in section 2.6.6.  \"The authority that authorized the public release\"",
        "public_released_on"        : "For items which are publically releasable, this is described in section 2.6.6.  \"The date of public release\"",
        "is_default_marking"        : "Optional.  Defaults to false.",
        "privilege_default"         : "Optional.  Defaults to deny."
      },
      isa_marking_structure_attributes: {
         "re_custodian"             : "Responsible Entity - Custodian.  Single value.  Found in section 2.3.1.  Allowable values in Appendix A.",
         "re_originator"            : "Responsible Entity - Originator.  Single value.  Found in section 2.3.2.  Recommended values in Appendix A.",
         "data_item_created_at"     : "Responsible Entity - Data Item Created At.  Single Date Value."
      }
    }],
    "stix_id"                   : "Optional.  If not included, the system will generate a STIX ID",
    "downgrade_request_id"      : "Optional.  If the indicator was formerly classified, you can store the downgrade request ID here.",
    "alternative_id"            : "Optional.  Used to capture alternative system ids in STIX format"
    "dms_label"                 : "Optional.  For use by DMS system",
    /* confidence_attributes are optional.  You must specify them in an array of 1 or more */
    "confidences_attributes" : {[{
        "value"       : "Required for each confidence added to indicator.  Possible values are 'low', 'medium','high' or 'unknown'",
        "is_official" : "Optional.  May set to true if you have permission to set an official confidence value. Do not quote this value",
        "description" : "Optional description by analyst about the confidence rating"
      }]}
  }
```

## Download a Package in STIX Format

**Route:** GET `stix_packages/STIX_ID/download_stix_package.xml`

## Upload a file in STIX format

**Route:** POST `/uploads`

*Note: Put the STIX file into the HTTP body with a Content-Type header of application/xml*

**Paramaters**

`overwrite` - Set to `Y` to have the upload overwrite any existing items in the system
`validate_only` - Set to `Y` to have the STIX file validated against the CIAP data model without saving items to the system.

*Note: This will return a result code of 201 (Created) if the STIX file validated successfully, and 406 (Not Acceptable) if not.

## Silk File Format PMAP

To get the PMAP file format for all IPs in a particular tag

**Route:** GET `/pmap/TAG_NAME`

*Note: substitute the tag name (formerly collection name), for the TAG_NAME is the route above*

Example: GET `/pmap/FO12`

## Silk File Format IP Set

To get the IP Set file format for all IPs in a particular tag

**Route:** GET `/ipset/TAG_NAME`

*Note: substitute the tag name (formerly collection name), for the TAG_NAME is the route above*

Example: GET `/ipset/FO12`

## Listing Domains

**Route:** GET `/domains`

## Listing a Single Domain

**Route:** GET `/domains/CYBOX_ID`

## Creating a Domain

**Route:** POST `/domains` - Create a domain

**HTTP Request Body**

```json
  {
    "name_input": "The domain",
    "name_condition": "The relevant condition of type cyboxCommon:ConditionTypeEnum to apply to the domain name"
  }
```

## Listing Addresses

**Route:** GET `/addresses`

## Listing a Single Address

**Route:** GET `/addresses/CYBOX_ID`

## Creating an Address

**Route:** POST `/addresses` - Create an address

**HTTP Request Body**

```json
  {
    "address_input": "The IP address"
  }
```

## Listing Emails

**Route:** GET `/email_messages`

## Listing a Single Email

**Route:** GET `/email_messages/CYBOX_ID`

## Creating an Email

**Route:** POST `/email_messages` - Create an email message

**HTTP Request Body**

*Note: Only one field of subject, from_input, reply_to_input, or sender_input is required*

*Note: You must have permission to view PII fields in order to upload or download certain fields marked below.*

```json
  {
    "email_date":"Date of email",
    "message_id":"Message ID",
    "subject":"Email subject",
    "x_originating_ip":"originating IP",
    /* You must be able to view PII fields in order to upload or download from_input, from_is_spoofed, message_id, raw_body, raw_header, reply_to_input, sender_input, sender_is_spoofed, x_mailer */
    "from_input":"The From field specifies the email address of the sender of the email message.",
    "from_is_spoofed":"Do not quote this field.  true or false.",
    "message_id":"The Message_ID field specifies the automatically generated ID of the email message.",
    "raw_body":"The Raw_Body field specifies the complete (raw) body of the email message.",
    "raw_header":"The Raw_Header field specifies the complete (raw) headers of the email message.",
    "reply_to_input":"The In_Reply_To field specifies the message ID of the message that this email is a reply to.",
    "sender_input":"The Sender field specifies the email address of the sender who is acting on behalf of the author listed in the From: field.",
    "sender_is_spoofed":"Do not quote this field.  true or false.",
    "x_mailer":"The X-Mailer field specifies the software used to send the email message. This field is non-standard."
  }
```

## Listing Files

**Route:** GET `/files`

## Listing a Single File

**Route:** GET `/files/CYBOX_ID`

## Creating a File

**Route:** POST `/files` - Create a file

**HTTP Request Body**

```json
  {
    "file_name"               : "The name of the file.",
    "file_name_condition"     : "Optional. Defines the relevant condition of type cyboxCommon:ConditionTypeEnum to apply to the file.",
    "file_path"               : "Optional. The path to the file, not including the device.",
    "file_path_condition"     : "Optional. Defines the relevant condition of type cyboxCommon:ConditionTypeEnum to apply to the file path.",
    "size_in_bytes"           : "Optional. Size in bytes.",
    "size_in_bytes_condition" : "Optional. Defines the relevant condition of type cyboxCommon:ConditionTypeEnum to apply to the size_in_byes",
    /* file_hashes_attributes are optional.  You may specify one more multiple in the array */
    "file_hashes_attributes" : [{
      "hash_type"         : "'MD5', 'SHA1', 'SHA256' or 'SSDEEP'",
      "simple_hash_value" : "value of MD5, SHA1, or SHA256",
      "fuzzy_hash_value"  : "value of SSDEEP"
    }]
  }
```

## Listing DNS Records

**Route:** GET `/dns_records`

## Listing a Single DNS Record

**Route:** GET `/dns_records/CYBOX_ID`

## Creating a DNS Record

**Route:** POST `/dns_records` - Create a DNS record

**HTTP Request Body**

```json
  {
    "address_input" : "Required. The IP address to which to domain name in the DNS cache entry resolves to.",
    "address_class" : "Required. The address class (e.g. IN, TXT, ANY, etc.) for the DNS record.",
    "domain_input"  : "Required.  The name of the domain to which the DNS cache entry points.",
    "entry_type"    : "Required. The resource record type (e.g. SOA or A) for the DNS record.",
    "queried_date"  : "Optional. Date the DNS record was queried."
  }
```

## Listing HTTP Sessions

**Route:** GET `/http_sessions`

## Listing a Single HTTP Session

**Route:** GET `/http_sessions/CYBOX_ID`

## Creating an HTTP Session

**Route:** POST `/http_sessions` - Create an http session

**HTTP Request Body**

```json
  {
    "user_agent" : "Required. The HTTP Request User-Agent field, which defines the user agent string of the user agent."
  }
```

## Listing Links

**Route:** GET `/links`

## Listing a Single Link

**Route:** GET `/links/CYBOX_ID`

## Creating a Link

**Route:** POST `/links` - Create a Link

**HTTP Request Body**

```json
  {
    "label" : "The Label associated with the Link",
    "uri_attributes" : {
        "uri_input" : "The URI"
    }
  }
```

## Listing Mutexes

**Route:** GET `/mutexes`

## Listing a Single Mutex

**Route:** GET `/mutexes/CYBOX_ID`

## Creating a Mutex

**Route:** POST `/mutexes` - Create a mutex

**HTTP Request Body**

```json
  {
    "name" : "Required. Name of the mutex."
  }
```

## Listing Network Connections

**Route:** GET `/network_connections`

## Listing a Single Network Connection

**Route:** GET `/network_connections/CYBOX_ID`

## Creating a Network Connection

**Route:** POST `/network_connections` - Create a network connection

**HTTP Request Body**

```json
  {
    "dest_socket_address"      : "Required. Destination socket address",
    "dest_socket_is_spoofed"   : "Optional. Do not quote this field. Specify if destination socket is spoofed with true or false",
    "dest_socket_port"         : "Optional. Destination socket port",
    "dest_socket_protocol"     : "Optional. Destination socket protocol",
    "source_socket_address"    : "Optional. Source socket address",
    "source_socket_is_spoofed" : "Optional. Do not quote this field. Specify if source socket is spoofed with true or false",
    "source_socket_port"       : "Optional. Source socket port",
    "source_socket_protocol"   : "Optional. Source socket protocol",
  }
```

## Listing Registry Entries

**Route:** GET `/registries`

## Listing a single Registry Entry

**Route:** GET `/registries/CYBOX_ID`

## Creating a Registry Entry

**Route:** POST `/registries` - Create a registry entry

**HTTP Request Body**

```json
  {
    "hive" : "Required. Registry hive name.",
    "key" : "Required. Registry Key Name.",
    /* One or more registry_values_attributes are required */
    "registry_values_attributes" : [{
      "reg_name"  : "Registry Name",
      "reg_value" : "Registry Value"
    }]
  }
```

## Listing URIs

**Route:** GET `/uris`

## Listing a Single URI

**Route:** GET `/uris/CYBOX_ID`

#### Creating a URI

**Route:** POST `/uris` - Create a URI

**HTTP Request Body**

```json
  {
    "uri_input": "The URI"
  }
```

## Adding a Note To an Indicator

**Route:** POST `/notes`

**HTTP Request Body**

```json
  {
    "targetClass" : "Required.  Must be 'Indicator'",
    "targetGuid"  : "Required.  GUID of the indicator you are marking with a note.'",
    "note"        : "Required.  Text of the note."
  }
```

## Destroying a Note

**Route:** DELETE `/notes/:note_guid`

## Determine If a Domain Name Is Valid

*Note: Cyber Indicators will accept any string up to 255 characters as a domain.*

**Route:** GET `/domains/valid`

**HTTP Request Body**

```json
  {
    "domain" : "Required.  Domain name"
  }
```

## Create or Update a STIX Package

**Route:** POST `/stix_packages` - Create a new STIX package

**Route:** PUT `/stix_packages/STIX_ID` - Update an existing STIX package

**HTTP Request Body**

```json
  {
    "title"                     : "Required",
    /* STIX Marking attributes are optional, but if you choose to include them, certain fields are required */
    "stix_markings_attributes"   : [{
        "isa_assertion_structure_attributes" : {
            "public_release"            : "true or false.  Do not quote true or false.  If true, all Control Set restrictions are ignored by definition. Defaults to false.",
            "cs_countries"              : "Control Set - Countries.  This is a JSON array of strings with capitalized three leter country codes. 'USA', 'CAN' etc. For use with ISAMarkingsAssertionType.",
            "cs_orgs"                   : "Control Set - Organizations.  This is a JSON array of strings with the organization abbreviations found in Appendix A: List of Organizations, from the ESSA ACS v2.0 document.  For example: [\"USA.DHS\",\"USA.DOC\"].  For use with ISAMarkingsAssertionType.",
            "cs_entity"                 : "Control Set - Entity.  This is a JSON array of strings.  Allowable values are MIL, GOV, CTR, SVR, SVC, DEV and NET. These are based on the Unified Identity Attribute Set Reference 5 from the ESSA ACS v2.0 document.  For use with ISAMarkingsAssertionType.",
            "cs_cui"                    : "Control Set - Controlled Unclassified information.  This is a JSON array of strings.  Allowable values are under section 2.7.3.3 in the ESSA ISA ACS v2.0 guide.  For use with ISAMarkingsAssertionType.",
            "cs_shargrp"                : "Control Set - Shareability Group.  This is a JSON array of strings.  Allowable values found in section 2.7.6.1.",
            "cs_formal_determination"   : "Control Set - Formal Determination. ",
            "public_released_by"        : "For items which are publically releasable, this is described in section 2.6.6.  \"The authority that authorized the public release\"",
            "public_released_on"        : "For items which are publically releasable, this is described in section 2.6.6.  \"The date of public release\"",
            "is_default_marking"        : "Optional.  Defaults to false.",
            "privilege_default"         : "Optional.  Defaults to deny."
        },
        isa_marking_structure_attributes: {
             "re_custodian"             : "Responsible Entity - Custodian.  Single value.  Found in section 2.3.1.  Allowable values in Appendix A.",
             "re_originator"            : "Responsible Entity - Originator.  Single value.  Found in section 2.3.2.  Recommended values in Appendix A.",
             "data_item_created_at"     : "Responsible Entity - Data Item Created At.  Single Date Value."
        }
    }],
    "stix_id"                   : "Optional.  If none is provided, one will be generated",
    /* indicator_stix_ids is optional.  If included, the STIX package will now include only the set of indicators passed in here*/
    "indicator_stix_ids"        : ["INDICATOR_STIX_ID_1","INDICATOR_STIX_ID_2"],
    /* You must be able to view PII information in the system to add or update description fields */
    "short_description"         : "Optional. Summary of package",
    "description"               : "Optional. Description of package"
  }
```

## Attach an Observable to an Indicator

**Route:** POST `/observables`

**HTTP Request Body**

```json
  {
    "cybox_object_id"    : "Cybox Object ID of observable",
    "remote_object_id"   : "Cybox Object ID of observable",
    "remote_object_type" : "Type of observable (e.g. 'Address','Domain',etc.)",
    "stix_indicator_id"  : "STIX ID of indicator",
    "justification"      : "Optional. Added to audit record"
  }
```

## Detach an Observable From an Indicator

**Route:** DELETE `/observables/CYBOX_ID` - Remove observable with a given Cybox ID

## Show Indicators Exported to E3A or E2

*Note: To view indicators exported to ECS, please use the /system_tags/exported_to_ecs route*

**Route:** GET `/exported_indicators`

*Note: This API call returns STIX.  Please add the Accept header with text/xml to your API request*

**Parameters**

`system` - Required.  'e3a' or 'e2'

## Pushing Weather Map Indicators

*Note: The system admin guide details how to configure replications, which will allow uploading weather mpp indicators to CIAP, and having them automatically replicated to CIR.

**Route:** POST `/ipreputation`

*Note: This API call accepts only CSV formatted files in the body of the request. Please add the Content-Type header with text/csv to your request*

*Note: CSV data should be arranged in the following order:

IP Address, ISO Country Code, .COM Reputation Score, .GOV Reputation Score, Composite Reputation Score, Agencies Sensors Seen On, First Date Seen On, Last Date Seen On, Threat Category List

## Add a heatmap image for an organization

*Note: The system admin guide details how to configure replications, which will allow uploading weather map images to CIAP, and having them automatically replicated to CIR.

**Route:** POST `/heatmaps`

** Headers **

You must set an HTTP header of "Content-type" to the MIME type of the image you are uploading.  This could be image/jpeg or image/png

**Parameters**

`organization_token` - Required.  When a user who belongs to the organization with this token is logged in, they will see the image on the weather map page when logged in.

*Note: This API call accepts only .png or .jpg formatted files in the body of the request

**HTTP Request Body**

```
Required - The HTTP request body should only be binary data of the image to be displayed.  PNG is preferred, but any MIME type supported by major browsers should function.
```

This API call exists on both CIAP and CIR.  However, if you configure the replications feature in CIAP, as defined in the system admin guide, uploading an image to CIAP will automatically forward the image to CIR.
