# Mock Rest API

## Installation
1. Unzip into a folder.
2. `bundle install`

## Running locally
Generate an API key (anything will do), and assign it to an environment variable:
```
export API_KEY=<your key>
```
Start server with bundler and rack:

```
bundle exec rackup
```

## Interface

Requests shoud include the header `x-api-key` with the value set to your generated API key.

Organizations:
```
GET /orgs

[<int>org_id...]
```
Organization:
```
GET /orgs/<id>

{ "id": <int>,
  "name": <string>,
  "parent_id": <int>,
  "type": <string> }
```
Accounts:
```
GET /accounts

[<int>account_id...]
```
Account:
```
GET /accounts/<id>

{ "id": <int>,
  "org_id": <int>
  "revenue": <int> }
```

Users:
```
GET /users

[<int>user_id...]
```

User:
```
GET /users/id
{ "id": <int>,
  "first_name": <string>,
  "last_name": <string>,
  "email": "<string>,
  "role": <string>,
  "org_id": <int>,
  "admin_accounts": [<int..>] }
```

Users by org:
```
GET /users/org/<org_id>

[<int>user_id...]
```
Admin users by org:
```
GET /users/org/:org_id/admin

[<int>user_id...]
```

## Data
**Organizations** can be of type `parent`, `subsidiary`, or `sole`:

1. Sole organizations do not have parent or child organizations.
2. A subsidiary organization is can have a parent org, and child orgs.
4. A subsidiary operationally acts as a 'master' org to all of it's children.

**Accounts** are purchased services, by individual organizations. Revenue is yearly billings.

A **user** can be an organization `owner`, an organization `contact`, or an account `admin`.

## Challenge

1. Write a program in that pulls data from this API, and creates a data structure (or set of data structures) that flattens it. The result is that all accounts and users be rolled up to the highest level org (i.e., no parent):

        
        Input:
        Org A: accounts[1,2,3]
           Child1: accounts[3,4]
              Child2[5,6]
        Result:
        Org A: accounts[1,2,3,4,5,6]
        
2. Subsidiary orgs should be treated as 'top-level'. Example:

        Input:
        OrgA:accounts[1,2,3]
           ChildA: accounts[4,5]
              ChildB (type subsidiary): accounts[6,7]
                ChildC: accounts[8,9]
        Result:
        OrgA: accounts[1,2,3,4,5]
        ChildB: accounts[6,7,8,9]
     However, if desired, one should be able to 'connect' a subsidiary to to master parent record, if interested in treating the parent and subsidiary org as one.
3. Use the `revenue` field from the `accounts` endpoint to create a support score for each organization.
    * The score should be numeric, starting at 1 for accounts that pay between $0-$50,000, 2 for $50,000-$100,000, etc..
    * The support score of the parent orgs should include the revenue of subsidiary hierarchies. Subsidiary's score should only include revenue from their hierarchy.
4. Serialize the data structure(s) into a JSON object, and write it to a text file.

### Requirements:
1. Written in ruby
2. Uses only the ruby standard library
3. No alterations to App code, or data*
4. Comments and readable code - explain yourself!
5. You have 1 week to complete the challenge.
6. Once completed, zip up the file, along with the generated JSON and send it in.

*If you think you've found a bug in the API code, let us know. We didn't intentionally add any bugs to tho mock api, and debugging it is not part of the challenge. 




 









