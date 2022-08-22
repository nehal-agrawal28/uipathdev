/*----------------------------------------------------------------------
Name:       ChineseCaseHelper.cls
Purpose:    An Apex Class to Create Case for China

------------------------------History----------------------------------
Version     Author      Date                    Detail Description 
-------     -------     --------------          ------------------
1.0                Initial Development 
----------------------------------------------------------------------*/
@RestResource(urlMapping='/CreateChinaCase/*')
global class ChineseCaseHelper{
    
    @HttpPost
    global static ResponseWrapperChina doPostCase() {
        
        final String SOURCE_LINK = Label.SourceLink;
        final Integer SUCCESS_CODE = 200;
        final Integer ERROR_CODE = 400;
        final String CASE_SUCCESS = 'Case Inserted Successfully';
        final String SUCCESS_ARG ='Success';
        final String ERROR_ARG ='Error';
        final String WEB_ARG ='Web';
        final String ACADEMY_STATUS = 'New';
        final String ACADEMY_ORGIN = 'Web';
        
        ResponseWrapperChina resObj = new ResponseWrapperChina();
        RestRequest reqObj = RestContext.request;
        Blob body = reqObj.requestBody;
        String requestString = body.toString();
        Id incidentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Incident').getRecordTypeId();
        Id academyRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Academy').getRecordTypeId();
        RequestWrapperChina reqParams = new RequestWrapperChina();
        reqParams = ( RequestWrapperChina )JSON.deserialize( requestString,RequestWrapperChina.class );
        
        Case caseObj = new Case();
        system.debug ('reqParams.isacademycase' + reqParams.isacademycase);
        if( NULL != reqParams.isacademycase && reqParams.isacademycase ){
            caseObj.Status = ACADEMY_STATUS;
            caseObj.Origin = ACADEMY_ORGIN;
            caseObj.SuppliedName = String.isNotBlank( reqParams.name ) ? reqParams.name : '';//
            caseObj.SuppliedEmail = String.isNotBlank( reqParams.email ) ? reqParams.email : '';//
            caseObj.Subject = String.isNotBlank( reqParams.subject ) ? reqParams.subject : '';//
            caseObj.Description = String.isNotBlank( reqParams.description ) ? reqParams.description : '';//
            caseObj.Job_Level__c =  String.isNotBlank( reqParams.joblevel ) ? reqParams.joblevel : '';//
            caseObj.What_is_your_request_related_to__c = String.isNotBlank( reqParams.reqrelatedto ) ? reqParams.reqrelatedto : '';//
            caseObj.Request_Sub_Category__c =  String.isNotBlank( reqParams.reqsubcategory ) ? reqParams.reqsubcategory : '';//
            caseObj.Webform_Acknowledgement__c =  reqParams.webformack;
            caseObj.RecordTypeId = academyRecordTypeId;
            caseObj.Is_Free_Mailer__c = reqParams.isfreemailer;
            
            if( reqParams.isfreemailer ){
                Database.DMLOptions option = new Database.DMLOptions();
                option.EmailHeader.triggerAutoResponseEmail = true;
                option.AssignmentRuleHeader.useDefaultRule = true;
                caseObj.setOptions (option);
            }
        }
        else {
            caseObj.Origin = WEB_ARG; //
            caseObj.SuppliedName = String.isNotBlank( reqParams.name ) ? reqParams.name : '';//
            caseObj.SuppliedEmail = String.isNotBlank( reqParams.email ) ? reqParams.email : '';//
            caseObj.End_Customer_s_Name__c = String.isNotBlank( reqParams.accountname ) ? reqParams.accountname : '';//
            caseObj.SuppliedPhone = String.isNotBlank( reqParams.phone ) ? reqParams.phone : '';//
            caseObj.Subject = String.isNotBlank( reqParams.subject ) ? reqParams.subject : '';//
            caseObj.Description = String.isNotBlank( reqParams.description ) ? reqParams.description : '';//
            caseObj.Error_Message__c = String.isNotBlank( reqParams.errormessage ) ? reqParams.errormessage : '';//
            caseObj.License_Code__c = String.isNotBlank( reqParams.licensecode ) ? reqParams.licensecode : '';//
            caseObj.Country__c = String.isNotBlank( reqParams.country ) ? reqParams.country : '';//
            caseObj.Related_To__c = String.isNotBlank( reqParams.productcomponent ) ? reqParams.productcomponent : '';//
            caseObj.Priority = String.isNotBlank( reqParams.priority ) ? reqParams.priority : '';//
            caseObj.Environment_Of_Issue__c = String.isNotBlank( reqParams.environment ) ? reqParams.environment : '';//
            caseObj.No_Of_Robots_Impacted_By_Issue__c = String.isNotBlank( reqParams.numofrobotsimpacted ) ? reqParams.numofrobotsimpacted : '';//
            caseObj.Studio_Version__c = String.isNotBlank( reqParams.studioversion ) ? reqParams.studioversion : '';//
            caseObj.Orchestrator_Version__c = String.isNotBlank( reqParams.orchestratorversion ) ? reqParams.orchestratorversion : '';   //
            caseObj.RecordTypeId = incidentRecordTypeId;    //
            caseObj.Webform_Acknowledgement__c = reqParams.webformack;//
            caseObj.Case_Source_Link__c = SOURCE_LINK;  //
            caseObj.AccountId = String.isNotBlank( reqParams.AccountId ) ? reqParams.AccountId : ''; //
            caseObj.Subscription_Type__c = String.isNotBlank( reqParams.subscriptiontype ) ? reqParams.subscriptiontype : ''; 
            caseObj.Product_Component_Version__c = String.isNotBlank( reqParams.productcomponentversion ) ? reqParams.productcomponentversion : '';
            caseObj.Device_Id__c = String.isNotBlank( reqParams.deviceId ) ? reqParams.deviceId : '';//
        }
        
        try{
            
            
            insert caseObj;
            
            List<ContentVersion> cVersionList = new List<ContentVersion>();
            
            if( NULL != reqParams.attachments && reqParams.attachments.size() > 0 ){
                
                for( RequestWrapperChina.Attachments attObj : reqParams.attachments ){
                    
                    ContentVersion cVersionObj = new ContentVersion();
                    cVersionObj.PathOnClient = String.isNotBlank( attObj.pathonclient ) ? attObj.pathonclient :'';
                    cVersionObj.Title = String.isNotBlank( attObj.name ) ? attObj.name :'';
                    cVersionObj.VersionData = EncodingUtil.base64Decode( attObj.bodyInbase64encoded );//File
                    cVersionList.add(cVersionObj);
                    
                }
                
                List<ContentDocumentLink> cDocLinkList = new List<ContentDocumentLink>();
                if( NULL != cVersionList && cVersionList.size() > 0 ){
                    try{
                        insert cVersionList;
                        
                        for(ContentVersion cvObj : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN : cVersionList]){
                            //Insert ContentDocumentLink
                            ContentDocumentLink cDocLink = new ContentDocumentLink();
                            cDocLink.ContentDocumentId = cvObj.ContentDocumentId;
                            cDocLink.LinkedEntityId = caseObj.Id;
                            cDocLinkList.add(cDocLink);
                            
                        }
                        
                        if( NULL != cDocLinkList && cDocLinkList.size() > 0 ){
                            insert cDocLinkList;
                        }
                        
                    }catch(Exception error){
                        resObj.statusCode = ERROR_CODE;
                        resObj.message =error.getMessage() + error.getTypeName() + error.getCause();
                        resObj.status = ERROR_ARG;
                        resObj.caseNumber = NULL ;
                        
                        return resObj;
                    }
                    
                }
                
                
            }
        }catch( Exception error ){
            resObj.statusCode = ERROR_CODE;
            resObj.message = error.getMessage() + error.getTypeName() + error.getCause();
            resObj.status = ERROR_ARG;
            resObj.caseNumber = NULL ;
            
            return resObj;
        }
        
        //return success response
        Case CaseReq  = [SELECT Id, CaseNumber FROM CASE WHERE Id= :caseObj.Id];
        resObj.statusCode = SUCCESS_CODE;
        resObj.message = CASE_SUCCESS;
        resObj.status = SUCCESS_ARG;
        resObj.caseNumber = CaseReq.CaseNumber;
        
        return resObj;
    }
}