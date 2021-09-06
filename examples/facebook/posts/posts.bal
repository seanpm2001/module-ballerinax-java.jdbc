// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/sql;
import ballerinax/java.jdbc;

configurable string jdbcFBUrl = ?;
configurable string pageId = ?;
configurable string InitiateOAuth = ?;
configurable string appId = ?;
configurable string appSecret = ?;
configurable string pageAccessToken = ?;

jdbc:Options options = {
    requestGeneratedKeys: jdbc:ALL,
    properties: {
                    InitiateOAuth: InitiateOAuth,
                    AuthenticateAsPage: pageId,
                    OAuthClientId: appId,
                    OAuthClientSecret: appSecret,
                    OAuthAccessToken: pageAccessToken
                }
};

jdbc:Client dbClient = check new (jdbcFBUrl, options = options);

listener http:Listener fbListener = new (9092);

service /facebook/posts on fbListener {

    resource function get getIds() returns string[]|error {
        string[] postIds = [];
        stream<record {}, error?> resultStream = dbClient->query(`SELECT * FROM Posts`);
        _ = check resultStream.forEach(function(record {} result) {
            postIds.push(<string>result["ID"]);
        });
        return postIds;
    }

    resource function post create(@http:Payload string msg) returns string|error {
        sql:ParameterizedQuery query = `INSERT INTO Posts (message) VALUES (${msg})`;
        _ = check dbClient->execute(query);
        return "Created new post";
    }

    resource function delete delete/[string id]() returns string|error {
        sql:ParameterizedQuery query = `DELETE FROM Posts WHERE ID = ${id}`;
        _ = check dbClient->execute(query);
        return "Post deleted successfully";
    }
}
