public with sharing class Util {

    public static string ReaPublicKey {
      get {
        StaticResource sr = [SELECT Id, Body
                             FROM  StaticResource
                             WHERE DeveloperName = 'REAPublicKey'
                             LIMIT 1];
        return sr.body.toString();
      }
    }
    
    public REALeadMapping__c[] getReaLeadMapping(){
        REALeadMapping__c[] cs = [SELECT Id
                                  , First_Name__c
                                  , Last_Name__c
                                  , Email__c
                                  , sObject__c
                                  FROM REALeadMapping__c
                                  WHERE SetupOwnerId = :UserInfo.getOrganizationId() limit 1];
        return cs; 
    }

    public static string base64UrlEncode(string forEncoding){

        forEncoding = forEncoding.replace('-','+').replace('_','/');
        return forEncoding;

    }

    public static boolean verifyJwtSignature(string header, string payload, string signature){

          /*HMACSHA256(
              base64UrlEncode(header) + "." +
              base64UrlEncode(payload),
              base64Encode(secret)
          )*/


        string signatureInput = header + '.' + payload;

        //Crypto.generateMac('HMACSHA256', blob.valueOf(signatureInput), blob.valueOf(ReaPublicKey));

        //Crypto.sign('RSA-SHA256', blob.valueOf(input), blob.valueOf(key));

        system.debug(Crypto.generateMac('HMACSHA256', blob.valueOf(signatureInput), blob.valueOf(ReaPublicKey)));

        return true;

    }

}