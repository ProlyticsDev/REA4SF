@RestResource(urlMapping='/repro/rea/lead/v1/*')

global with sharing class REALeadListener {
    
    static Util util = new Util();
    
    static REALeadMapping__c mapping {
        get{
            return REALeadMapping__c.getOrgDefaults();
        }
    }
    
    public static List<REA_Lead_Static_Value__c> staticValues{
        get{
            return [select Id, Name, Value__c from REA_Lead_Static_Value__c];
        }
    }
    
    static blob vector = blob.valueOf(mapping.Encryption_Key__c);
    static blob key = blob.valueOf(mapping.REA_Private_Key__c);

    public static List<sObject> insertObjList {get;set;}
    
    public static List<Leads> leads{get;set;}
	public class Leads {
		public String agency_id;
		public List<String> agent_recipients;
		public String sent_at;
		public Integer rea_primary_key;
		public Integer rea_listing_id;
		public Integer rea_parent_id;
		public String consumer_name;
		public String email;
		public String phone;
		public String listing_address;
		public String comments;
		public String about_me;
		public String preferred_contact_method;
		public String enquiry_source;
	}

	
	public static REALeadListener parse(String payload) {
		return (REALeadListener) JSON.deserialize(payload, REALeadListener.class);
	}
    
    // Used to generate an encrypted string for testing purposes
    public static void encryptionUtil(string payload){

        Blob data = Blob.valueOf(payload);
        Blob encrypted = Crypto.encrypt('AES128', key, vector, data);

        system.debug(EncodingUtil.base64Encode(encrypted));
        
    }

    public System.RestResponse saveLeads(List<Leads> leadLIst){

        insertObjList = new List<sobject>();
        
        Schema.SObjectType targetObject = Schema.getGlobalDescribe().get(mapping.sObject__c);
        
        for(Leads l : leads){
            
            system.debug('Lead: ' + l);
            system.debug('l.Consumer_Name: ' + l.consumer_name);
            
            sObject obj = Schema.getGlobalDescribe().get(mapping.sObject__c).newsObject();
            if(l.consumer_name.contains(' ')){
                if(mapping.First_Name__c != null)
                    obj.put(mapping.First_Name__c, l.consumer_name.substringBefore(' '));
                if(mapping.Last_Name__c != null)
                    obj.put(mapping.Last_Name__c, l.consumer_name.substringAfter(' '));
            } else {
                if(mapping.Last_Name__c != null)
                    obj.put(mapping.Last_Name__c, l.consumer_name);
            }
            
            if(mapping.Email__c != null)
                obj.put(mapping.Email__c, l.email);
            
            if(mapping.Phone__c != null)
                obj.put(mapping.Phone__c, l.phone);
            
            if(mapping.Enquiry_Sent_At__c != null)
                obj.put(mapping.Enquiry_Sent_At__c, date.valueOf(l.sent_at));
            
            //rea_primary_key
            //rea_listing_id
            //rea_parent_id
            
            if(mapping.Comments__c != null)
                obj.put(mapping.Comments__c, l.comments);
            
            //obj.put(mapping.About_Me__c, l.about_me);
            //obj.put(mapping.Preferred_Contact_Method__c, l.preferred_contact_method);
            
            if(mapping.Enquiry_Source__c != null)
                obj.put(mapping.Enquiry_Source__c, l.enquiry_source);
            
            if(mapping.OwnerId__c != null){
                obj.put('OwnerId', mapping.OwnerId__c);
            }
            
            if(mapping.RecordTypeId__c != null){
                obj.put('RecordTypeId', mapping.RecordTypeId__c);
            }
            
            for(REA_Lead_Static_Value__c sv : staticValues){
                obj.put(sv.Name, sv.Value__c); 
            }
            
            /*if(l.rea_parent_id != null){
                string projectObjectName = string.valueOf(Schema.getGlobalDescribe().get(mapping.sObject__c).getDescribe().fields.getMap().get(mapping.Project__c).getDescribe().getReferenceTo()[0]);
                string projectId = database.query('select Id from ' + projectObjectName + ' where ReaID__c = \'' + l.rea_parent_id + '\' limit 1').Id;
                
                if(projectId != null)
                    obj.put(mapping.Project__c, projectId);
            }*/
            
            if(l.rea_listing_id != null){
                string propertyObjectName = string.valueOf(Schema.getGlobalDescribe().get(mapping.sObject__c).getDescribe().fields.getMap().get(mapping.Property__c).getDescribe().getReferenceTo()[0]);
                string propertyId = database.query('select Id from ' + propertyObjectName + ' where ReaID__c = \'' + l.rea_listing_id + '\' limit 1')[0].Id;
                
                if(propertyId != null){
                    obj.put(mapping.Property__c, propertyId);
                    //obj.put(mapping.Project__c, )
                    // testing GITHUB with this text
                }
            }
            
            
            insertObjList.add(obj);
        }

        database.insert(insertObjList); 
        return null;

    }

    @HttpPost
    global static string incomingLead(){
        
        RestRequest req = RestContext.request;
	
        string payLoad = req.requestBody.toString();
        payload = payload.replace('-','+').replace('_','/');

        List<string> paramList = payload.split('\\.');
                
        string reqBody = EncodingUtil.base64Decode(paramList[1]).toString();
        string signature = paramList[2];
        //Blob decrypted = Crypto.decrypt('AES128', key, vector, data);

        reqBody = reqBody.replace('""','null')
                         .replace('\\','\\\\');

        system.debug('reqBody:' + reqBody);
        system.debug('signature: ' + signature);
        //system.debug('reqBody escaped: ' + reqBody.escapeQuotes());
                
        parse(reqBody);
        //parse('{"leads":[{"agency_id":"XYZABC","agent_recipients":["agent1@agency.com","agent2@agency.com"],"sent_at":"2016-05-05T06:20:03Z","rea_primary_key":"998877","rea_listing_id":"12345678","rea_parent_id":null,"consumer_name":"Tom Jones","email":"tomjones001@hotmail.com","phone":"0291913344","listing_address":"511 Church St Richmond, VIC 3121","comments":"I am interested in this property. Plesae call","about_me":"About me","preferred_contact_method":"Phone","enquiry_source":"realestate.com.au"}]}');
        
        if(!leads.isEmpty()){
            
            system.debug(leads); 
            
        }

    return null;

    }
    
}