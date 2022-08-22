@IsTest(isParallel=true)
public class UIP_PublicSiteCaseCommnetCntlTest {
	@testSetup 
    public static void setUpData (){
        Account newAccount = new Account (Name = 'Raj');
        newAccount.RecordTypeId = Utilities.getRecordTypeId('Customer', 'Account');
        newAccount.BillingStreet = 'Test  Street';
        newAccount.BillingCity = 'Test City';
        newAccount.BillingPostalCode = '123abc';
        newAccount.BillingCountry = 'United Kingdom';
        newAccount.Phone = '12345678';
        newAccount.Industry = 'Others';
        insert newAccount;
        Contact c = new Contact (LastName = 'Tesr', AccountId = newAccount.Id, Email='test@mail.com', Department__c = 'IT');
        insert c;
        Case ca = new Case (AccountId = newAccount.Id, ContactId = c.Id, Origin = 'Web');
        insert ca;
        
        Attachment attach = new Attachment ();
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
		attach.ParentId = ca.Id;
        insert attach;
        
        
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = false;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = ca.Id; 
        insert email;
        
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = email.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
    }
    
    /*static testmethod void test_1 () {
        UIP_PublicSiteCaseCommnetCntl cntl = new UIP_PublicSiteCaseCommnetCntl ();
        String res = UIP_PublicSiteCaseCommnetCntl.validateCaseNumberAndEmail ('' ,'');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
    }
    
    static testmethod void test_2 () {
        String res = UIP_PublicSiteCaseCommnetCntl.validateCaseNumberAndEmail ('111111', 'test@mail.com');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
    }
    
    static testmethod void validate_Email_1 () {
        String res = UIP_PublicSiteCaseCommnetCntl.validateContactEmail ('test@mail.com');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('SUCCESS', String.valueOf(resMap.get ('status')));
    }
    static testmethod void validate_Email_2 () {
        String res = UIP_PublicSiteCaseCommnetCntl.validateContactEmail ('');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
    }
    static testmethod void validate_Email_3 () {
        String res = UIP_PublicSiteCaseCommnetCntl.validateContactEmail ('testee@mail.com');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
    }*/
    static testmethod void getAllCasesByContactId_1 () {
        String res = UIP_PublicSiteCaseCommnetCntl.getAllCasesByContactId ('');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
    }
    
    static testmethod void getAllCasesByContactId_2 () {
        Contact c = [SELECT Id from Contact WHERE Email='test@mail.com' LIMIT 1];
        String res = UIP_PublicSiteCaseCommnetCntl.getAllCasesByContactId (c.Id);
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('SUCCESS', String.valueOf(resMap.get ('status')));
    }
    static testmethod void getAllCasesByContactId_3 () {
        Contact c = [SELECT Id from Contact WHERE Email='test@mail.com' LIMIT 1];
        String res = UIP_PublicSiteCaseCommnetCntl.getAllCasesByContactId (c.Id+'1');
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('ERROR', String.valueOf(resMap.get ('status')));
    }
    
   /* static testmethod void test_3 () {
        Case caseObj = [SELECT Id, CaseNumber, ContactEmail, RecordType.Name from Case LIMIT 1];
        String res = UIP_PublicSiteCaseCommnetCntl.validateCaseNumberAndEmail (caseObj.CaseNumber ,caseObj.ContactEmail);
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('SUCCESS', String.valueOf(resMap.get ('status')));
        
        res = UIP_PublicSiteCaseCommnetCntl.getCase (caseObj.CaseNumber, caseObj.RecordType.Name);
        List<Attachment> attachList = UIP_PublicSiteCaseCommnetCntl.getAttachmentByCaseId (caseObj.Id);
        System.assertEquals(attachList.size(), 1);
        List<EmailMessage> emailList = UIP_PublicSiteCaseCommnetCntl.getEmailsByCaseId (caseObj.Id);
        System.assertEquals(emailList.size(), 1);
        res = UIP_PublicSiteCaseCommnetCntl.getEmailAndAttachmentByCaseId (caseObj.Id);
 		resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        List<Object> resEmails = (List<Object>)resMap.get('emailMessages');
        System.assertEquals(resEmails.size(), 1);
        
        //List<Object> attachmentWrapList = (List<Object>)resMap.get('attachments');
        //System.assertEquals(attachmentWrapList.size(), 2);
    }
    
    static testmethod void test_4 () {
        Case caseObj = [SELECT Id, CaseNumber, ContactEmail from Case LIMIT 1];
        String res = UIP_PublicSiteCaseCommnetCntl.validateCaseNumberAndEmail (caseObj.CaseNumber ,caseObj.ContactEmail);
        Map<String, Object> resMap =  (Map<String, Object>)(JSON.deserializeUntyped(res));
        System.assertEquals('SUCCESS', String.valueOf(resMap.get ('status')));
    }
    */
    static testmethod void test_getArticles() {
        Case caseObj = [SELECT Id, CaseNumber, ContactId,ContactEmail from Case LIMIT 1];
        UIP_PublicSiteCaseCommnetCntl.getArticlesByCaseId (caseObj.Id);
        UIP_PublicSiteCaseCommnetCntl.getAllArticles();
        CaseViewLookupController.fetchLookUpValues('test','case;knowledge__kav',caseObj.ContactId,'5');
    }

}