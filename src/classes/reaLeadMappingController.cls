public with sharing class reaLeadMappingController {

    static Util util = new Util();
    
    public string ReaPublicKey {
        get{
            StaticResource sr = [
                select Body
                from StaticResource
                where Name = 'REAPublicKey'
            ];
            return sr.Body.toString(); 
        }
    }
    
    public reaLeadMappingController(){
        finalMap = ReaLeadMapping__c.getOrgDefaults();
        if(finalMap == null){
            finalMap = new ReaLeadMapping__c();
        }
        staticValueList = [select Id, Name, Value__c from REA_Lead_Static_Value__c];
        rowsToDelete = new list<REA_Lead_Static_Value__c>();
    }
    
    //public integer index {get;set;}
    
    public list<REA_Lead_Static_Value__c> rowsToDelete {get;set;}
    
    public pagereference removeRow(){
        
        integer index = integer.valueOf(ApexPages.currentPage().getParameters().get('index'));
                
        if(staticValueList[index].Id != null){
            rowsToDelete.add(staticValueList[index]);
        }
        
        system.debug('rowsToDelete: ' + rowsToDelete);
        
        staticValueList.remove(index);        
        return null; 
    }
    
    public ReaLeadMapping__c finalMap {get;set;}
    public static boolean showPageMessages {get;set;}
    public static string alertClass {get;set;}
    
    public List<SelectOption> getUserList(){
        
        List<User> uList = [select Id, Name from User where isActive = true];
        List<SelectOption> options = new List<SelectOption>();
        
        for(User u : uList){
            options.add(new SelectOption(u.id, u.Name));
        }
        
        return options;
    }
    
    public List<SelectOption> getRecordTypeList(){
        List<RecordType> rtList = [select Id, Name from RecordType where sObjectType = :finalMap.sObject__c];
        system.debug('sObject__c: ' + finalMap.sObject__c);
        system.debug('rtList : ' + rtList);
        
        List<SelectOption> options = new List<SelectOption>();
        
        for(RecordType rt : rtList){
            options.add(new SelectOption(rt.id, rt.Name));
        }
        
        return options;
    }
    
    public static set<string> stringCompatible{
        get{
            return (new Set<string> {'EMAIL','PHONE','PICKLIST','STRING','TEXTAREA','URL'});
        }
    }
    
    public List<REA_Lead_Static_Value__c> staticValueList {get;set;}
    
    public pagereference addRow(){
        
        system.debug('staticValueList: ' + staticValueList);

        staticValueList.add(new REA_Lead_Static_Value__c());
        system.debug('staticValueList: ' + staticValueList);
        
        return null;
    }
    
    public void clearStaticValues(){
        database.delete([select Id from REA_Lead_Static_Value__c]);
    }
    
    public void encryptionkeygenerator(){
        Blob blobKey = crypto.generateAesKey(128);
        String key = EncodingUtil.base64encode(blobKey);
        system.debug(key.substring(0,16));
        finalMap.Encryption_Key__c = key.substring(0,16);
    }
    
    public SelectOption[] getSobjects(){
        List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();     
        List<SelectOption> options = new List<SelectOption>();
        
        options.add(new SelectOption('',''));
        
        options.add(new SelectOption('','Standard Objects', true));
        options.add(new SelectOption('Account','Account'));
        options.add(new SelectOption('Contact','Contact'));
        options.add(new SelectOption('Lead','Lead'));
        
        options.add(new SelectOption('','', true));
        options.add(new SelectOption('','Custom Objects', true));
        
        for(Schema.SObjectType f : gd){
            
            if(f.getDescribe().isCustom()){
                if(
                    (!f.getDescribe().getName().contains('REPRO__') && 
                     !f.getDescribe().getLocalName().contains('__mdt')
                    ) || 
                    f.getDescribe().getLocalName().contains('Lead__c')
                ){
                    options.add(new SelectOption(f.getDescribe().getName(),f.getDescribe().getLabel()));
                }
            }
        }
        
        return options;
    }
    
    public SelectOption[] getStringFields() {
        
        SelectOption[] options = new SelectOption[]{};
            
            if(finalMap.sObject__c != null){
                Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                Schema.SObjectType objectSchema = schemaMap.get(finalMap.sObject__c);
                map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
                                
                options.add(new SelectOption('',''));
                
                for(string field : fieldMap.keyset()){
                    
                    schema.DisplayType thisFieldType = fieldMap.get(field).getDescribe().getType();
                    boolean canEdit = fieldMap.get(field).getDescribe().isUpdateable();

                    if(stringCompatible.contains(string.valueOf(thisFieldType)) && canEdit == true){
                        options.add(new SelectOption(fieldMap.get(field).getDescribe().getName(), fieldMap.get(field).getDescribe().getLabel()));
                    }
                }
            }
        
        system.debug(options);
        
        options.sort();
        return options;
    }
    
    public SelectOption[] getReferenceFields() {
        
        SelectOption[] options = new SelectOption[]{};
            
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(finalMap.sObject__c);
        map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
        
        
        options.add(new SelectOption('',''));
        
        for(string field : fieldMap.keyset()){
            
            schema.DisplayType thisFieldType = fieldMap.get(field).getDescribe().getType();
            boolean canEdit = fieldMap.get(field).getDescribe().isUpdateable();

            if(string.valueOf(thisFieldType) == 'REFERENCE'){
                //if(string.valueOf(fieldMap.get(field).getDescribe().getReferenceTo()).contains('project__c')){
                    options.add(new SelectOption(fieldMap.get(field).getDescribe().getName(), fieldMap.get(field).getDescribe().getLabel()));
                //}
            }
        }
        
        options.sort();
        return options;
    }
    
    public SelectOption[] getDateTimeFields() {
        
        SelectOption[] options = new SelectOption[]{};
            
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(finalMap.sObject__c);
        map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
                
        options.add(new SelectOption('',''));
        
        for(string field : fieldMap.keyset()){
            
            schema.DisplayType thisFieldType = fieldMap.get(field).getDescribe().getType();
            boolean canEdit = fieldMap.get(field).getDescribe().isUpdateable();
            
            if((string.valueOf(thisFieldType) == 'DATE' || string.valueOf(thisFieldType) == 'DATETIME') &&
               canEdit == true){
                options.add(new SelectOption(fieldMap.get(field).getDescribe().getName(), fieldMap.get(field).getDescribe().getLabel()));
            }
        }
        
        options.sort();
        return options;
    }
    
    public void saveMapping(){

        system.debug('Entering Save method');

        if(!rowsToDelete.isEmpty())
            database.delete(rowsToDelete);
        
        if(!staticValueList.isEmpty())
			database.upsert(staticValueList);

        try{
            
            database.UpsertResult saves = database.upsert(finalMap);
        	system.debug(saves);
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Lead Mapping Saved'));
            alertClass = 'slds-notify slds-notify--alert slds-theme--success slds-theme--alert-texture';
            system.debug('Mapping Settings Updated');
            
            notifyLeadOwner();
            
        } catch (exception e){
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
            alertClass = 'slds-notify slds-notify--alert slds-theme--error slds-theme--alert-texture';
            system.debug('Save Error: ' + e.getMessage());
            
        }
        
        showPageMessages = true;
        
    }
    
    public void notifyLeadOwner(){
        
        // send email logic
        
    }
    
    public void logTask(){
        
        // log task logic
        
    }
    
}