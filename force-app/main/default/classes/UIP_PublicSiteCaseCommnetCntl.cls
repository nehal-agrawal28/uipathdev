public without sharing class UIP_PublicSiteCaseCommnetCntl {
  public UIP_PublicSiteCaseCommnetCntl() {
  }

  /*@AuraEnabled
    public static String validateContactEmail (String email, Boolean skipOTP) {
        Map <String, Object> resMap = new Map <String, Object> ();
        
        if (String.isBlank(email)) {
            resMap.put ('status', 'ERROR');
            resMap.put ('message', Label.OTP_Error_Required_Field);
        } else {
            List <Contact> contactList = new List<Contact> ([SELECT Id, Name, Email FROM Contact 
                                                             WHERE Email =: email LIMIT 1]);
            if (contactList != null && !contactList.isEmpty ()) {
                resMap.put ('status', 'SUCCESS');
                resMap.put ('result', contactList [0]);
                Integer OTP = UIP_PublicSiteCaseUtility.getRandonNumber (Integer.valueOf(Label.MaxOTPLength));
                if(!skipOTP){
                    sendEmail(new String[] {email}, String.valueOf(OTP));
                    List<CaseViewOtp__c> caseViewOtp = [Select Id, Name, Value__c from CaseViewOtp__c where Name = :email];
                    CaseViewOtp__c cv = new CaseViewOtp__c();
                    if(caseViewOtp!=null && !caseViewOtp.isEmpty()){
                        cv.Id =   caseViewOtp[0].Id;
                    }   
                    cv.Name = email;
                    cv.Value__c = String.valueOf(OTP);
                    upsert cv;
                }
                //resMap.put ('OTP', OTP);
                
                resMap.put ('message', Label.OTP_SENT);	
            } else {
                resMap.put ('status', 'ERROR');
                resMap.put ('message', Label.OTP_Error_Contact_Not_Found);
            }
        }
        return JSON.serialize(resMap);
    }
    @AuraEnabled
    public static String validateContactEmail (String email) {
        Map <String, Object> resMap = new Map <String, Object> ();
        
        if (String.isBlank(email)) {
            resMap.put ('status', 'ERROR');
            resMap.put ('message', Label.OTP_Error_Required_Field);
        } else {
            List <Contact> contactList = new List<Contact> ([SELECT Id, Name, Email FROM Contact 
                                                             WHERE Email =: email LIMIT 1]);
            if (contactList != null && !contactList.isEmpty ()) {
                resMap.put ('status', 'SUCCESS');
                resMap.put ('result', contactList [0]);
                Integer OTP = UIP_PublicSiteCaseUtility.getRandonNumber (Integer.valueOf(Label.MaxOTPLength));
                
                sendEmail(new String[] {email}, String.valueOf(OTP));
                List<CaseViewOtp__c> caseViewOtp = [Select Id, Name, Value__c from CaseViewOtp__c where Name = :email];
                CaseViewOtp__c cv = new CaseViewOtp__c();
                if(caseViewOtp!=null && !caseViewOtp.isEmpty()){
                    cv.Id =   caseViewOtp[0].Id;
                }   
                cv.Name = email;
                cv.Value__c = String.valueOf(OTP);
                upsert cv;
                resMap.put ('message', Label.OTP_SENT);	
            } else {
                resMap.put ('status', 'ERROR');
                resMap.put ('message', Label.OTP_Error_Contact_Not_Found);
            }
        }
        return JSON.serialize(resMap);
    }
    
    public void authenticateContactEmail () {
        hasError=false;
        if (String.isBlank(caseEmail) || caseEmail == null) {
            hasError=true;
            errorMessage = Label.OTP_Error_Required_Field+' '+caseEmail;
        } else {
            List <Contact> contactList = new List<Contact> ([SELECT Id, Name, Email FROM Contact 
                                                             WHERE Email =: caseEmail LIMIT 1]);
            if (contactList != null && !contactList.isEmpty ()) {
                contactRecord = contactList [0];
                Integer OTP = UIP_PublicSiteCaseUtility.getRandonNumber (Integer.valueOf(Label.MaxOTPLength));
                sendEmail(new String[] {caseEmail}, String.valueOf(OTP));
                List<CaseViewOtp__c> caseViewOtp = [Select Id, Name, Value__c from CaseViewOtp__c where Name = :caseEmail];
                CaseViewOtp__c cv = new CaseViewOtp__c();
                if(caseViewOtp!=null && !caseViewOtp.isEmpty()){
                    cv.Id =   caseViewOtp[0].Id;
                }   
                cv.Name = caseEmail;
                cv.Value__c = String.valueOf(OTP);
                upsert cv;
                
            } else {
                hasError=true;
                errorMessage = Label.OTP_Error_Contact_Not_Found;
            }
        }
    }*/

  @AuraEnabled
  public static Contact getContactDetails(String email) {
    return [SELECT Id, Name, Email FROM Contact WHERE Email = :email LIMIT 1];
  }
  @InvocableMethod
  public static void verifyOtp(List<String> email) {
    Integer OTP = UIP_PublicSiteCaseUtility.getRandonNumber(Integer.valueOf(Label.MaxOTPLength));
    sendEmail(new List<String>{ email[0] }, String.valueOf(OTP));
    List<CaseViewOtp__c> caseViewOtp = [
      SELECT Id, Name, Email__c, Value__c
      FROM CaseViewOtp__c
      WHERE Email__c = :email[0]
    ];
    CaseViewOtp__c cv = new CaseViewOtp__c();
    if (caseViewOtp != null && !caseViewOtp.isEmpty()) {
      cv.Id = caseViewOtp[0].Id;
    }
    cv.Name = email[0].length() > 38 ? email[0].substring(0, 38) : email[0];
    cv.Email__c = email[0];
    cv.Value__c = String.valueOf(OTP);
    upsert cv;
  }

  /*@AuraEnabled
    public static String validateCaseNumberAndEmail (String caseNumber, String email) {
        Map <String, Object> resMap = new Map <String, Object> ();
        
        if (String.isBlank(caseNumber) || String.isBlank(email)) {
            resMap.put ('status', 'ERROR');
            resMap.put ('message', Label.OTP_Error_Required_Field);
        } else {
            List <Case> caseList = new List<Case> ([SELECT Id, CaseNumber, RecordTypeId, RecordType.Name FROM Case 
                                                    WHERE CaseNumber =: caseNumber AND Contact.Email =: email LIMIT 1]);
            if (caseList != null && !caseList.isEmpty ()) {
                resMap.put ('status', 'SUCCESS');
                resMap.put ('result', caseList [0]);
                Integer OTP = UIP_PublicSiteCaseUtility.getRandonNumber (Integer.valueOf(Label.MaxOTPLength));
                sendEmail(new String[] {email}, String.valueOf(OTP));
                //resMap.put ('OTP', OTP);
                resMap.put ('message', Label.OTP_SENT);	
            } else {
                resMap.put ('status', 'ERROR');
                resMap.put ('message', Label.OTP_Error_Case_Not_Found);
            }
        }
        return JSON.serialize(resMap);
    }*/

  private static Boolean sendEmail(String[] toAddresses, String OTP) {
    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();

    message.toAddresses = toAddresses;
    message.optOutPolicy = 'FILTER';
    message.subject = Label.Email_Subject_For_OTP;
    message.optOutPolicy = 'FILTER';
    if (Label.UseOrgWideFromAddress != null && Label.UseOrgWideFromAddress == '1') {
      message.setOrgWideEmailAddressId(Label.OrganizationEmailAddress);
    }
    message.plainTextBody = Label.Email_Body_For_OTP + ' ' + OTP;
    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{ message };
    List<Messaging.SendEmailResult> results = Messaging.sendEmail(messages);
    if (results[0].success) {
      return true;
    } else {
      System.debug('The email failed to send: ' + results[0].errors[0].message);
      return false;
    }
  }

  @AuraEnabled
  public static String getAllCasesByContactId(String contactId) {
    Map<String, Object> resMap = new Map<String, Object>();
    if (String.isBlank(contactId)) {
      resMap.put('status', 'ERROR');
      resMap.put('message', Label.OTP_Error_Required_Field);
    } else {
      List<Case> caseList = new List<Case>(
        [
          SELECT
            Id,
            ClosedDate,
            CaseNumber,
            Subject,
            Description,
            CreatedDate,
            Contact.Name,
            Status,
            RecordType.Name,
            Survey_Id__c,
            ContactId,
            (SELECT Id FROM SurveyTakers__r)
          FROM Case
          WHERE ContactId = :contactId
          ORDER BY LastModifiedDate DESC
          LIMIT :(Limits.getLimitDMLStatements() - Limits.getDMLStatements())
        ]
      );
      if (caseList != null && !caseList.isEmpty()) {
        resMap.put('status', 'SUCCESS');
        resMap.put('result', caseList);
      } else {
        resMap.put('status', 'ERROR');
        resMap.put('message', Label.No_Cases_Found);
      }
    }
    return JSON.serialize(resMap);
  }

  @AuraEnabled
  public static String getCase(String caseNumber, String recordTypeName) {
    Map<String, Object> resMap = new Map<String, Object>();

    String strFieldSetName = 'DefaultFieldSet';

    List<CaseFieldSetMap__mdt> caseFieldSetList = new List<CaseFieldSetMap__mdt>(
      [
        SELECT FieldSetName__c, RecordTypeName__c
        FROM CaseFieldSetMap__mdt
        WHERE RecordTypeName__c = :recordTypeName
        LIMIT 1
      ]
    );
    if (caseFieldSetList != null && !caseFieldSetList.isEmpty()) {
      strFieldSetName = caseFieldSetList[0].FieldSetName__c;
    }

    String whereCondition =
      ' WHERE RecordType.Name  = \'' +
      recordTypeName +
      '\' AND CaseNumber = \'' +
      caseNumber +
      '\'' +
      '  LIMIT 1';

    DataTableResponse response = UIP_PublicSiteCaseUtility.getTableData('Case', strFieldSetName, whereCondition, true);

    if (Test.isRunningTest()) {
      List<DataTableColumns> colRes = UIP_PublicSiteCaseUtility.getColumns('Case', strFieldSetName);
    }
    resMap.put('status', 'SUCCESS');
    resMap.put('result', response);

    return JSON.serialize(resMap);
  }

  @AuraEnabled
  public static List<EmailMessage> getEmailAndAttachmentByCaseId(String caseId) {
    Map<String, Object> resMap = new Map<String, Object>();

    List<EmailMessage> emailList = new List<EmailMessage>(
      [
        SELECT
          Id,
          HtmlBody,
          TextBody,
          Subject,
          IsExternallyVisible,
          FromName,
          FromAddress,
          Incoming,
          HasAttachment,
          MessageDate,
          ToAddress
        FROM EmailMessage
        WHERE ParentID = :caseId
        ORDER BY CreatedDate DESC
        LIMIT :(Limits.getLimitQueryRows() - Limits.getQueryRows())
      ]
    );

    resMap.put('emailMessages', emailList);

    return emailList;//JSON.serialize(resMap);
  }

  @AuraEnabled
  public static List<Attachment> getAttachmentByCaseId(String caseId) {
    return new List<Attachment>(
      [SELECT Id, Name, ContentType, CreatedDate, Description FROM Attachment WHERE ParentID = :caseId LIMIT 49999]
    );
  }

  @AuraEnabled
  public static List<EmailMessage> getEmailsByCaseId(String caseId) {
    return new List<EmailMessage>(
      [
        SELECT
          Id,
          HtmlBody,
          TextBody,
          Subject,
          IsExternallyVisible,
          FromName,
          FromAddress,
          Incoming,
          HasAttachment,
          MessageDate,
          ToAddress
        FROM EmailMessage
        WHERE ParentID = :caseId
        ORDER BY CreatedDate DESC
        LIMIT 49999
      ]
    );
  }

  @AuraEnabled
  public static List<Knowledge__kav> getArticlesByCaseId(String caseId) {
    List<CaseArticle> caseArticles = [SELECT Id, KnowledgeArticleId, CaseId FROM CaseArticle WHERE CaseId = :caseId];
    List<String> knowledgeArticleIds = new List<String>();
    for (CaseArticle ca : caseArticles) {
      knowledgeArticleIds.add(ca.KnowledgeArticleId);
    }
    List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
    if (knowledgeArticleIds.size() > 0) {
      knowledgeArticles = [
        SELECT
          Id,
          KnowledgeArticleId,
          Title,
          UrlName,
          Question_Problem__c,
          Resolution__c,
          ArticleNumber,
          PublishStatus,
          IsVisibleInPkb,
          IsLatestVersion,
          Product_Component__c,
          Sub_Component__c,
          Studio_Version__c,
          Orchestrator_Version__c
        FROM Knowledge__kav
        WHERE
          PublishStatus = 'Online'
          AND (IsVisibleInPkb = TRUE
          OR IsVisibleInCsp = TRUE)
          AND IsLatestVersion = TRUE
          AND KnowledgeArticleId IN :knowledgeArticleIds
      ];
    }
    return knowledgeArticles;
  }

  @AuraEnabled
  public static List<Knowledge__kav> getAllArticles() {
    return [
      SELECT
        Id,
        KnowledgeArticleId,
        Title,
        UrlName,
        Question_Problem__c,
        Resolution__c,
        ArticleNumber,
        PublishStatus,
        IsVisibleInPkb,
        IsLatestVersion,
        Product_Component__c,
        Sub_Component__c,
        Studio_Version__c,
        Orchestrator_Version__c
      FROM Knowledge__kav
      WHERE
        Language = 'en_US'
        AND PublishStatus = 'Online'
        AND (IsVisibleInPkb = TRUE
        OR IsVisibleInCsp = TRUE)
        AND IsLatestVersion = TRUE
    ];
  }

  /* @AuraEnabled
    public static String checkOTPValidity(String otp, String email) { 
        Map <String, Object> resMap = new Map <String, Object>();
        String emailFormatted = email.replaceAll('[^a-zA-Z0-9\\s+]', '');
        List<CaseViewOtp__c> caseViewOtp = [Select Id, Name, Value__c from CaseViewOtp__c where Name = :email];
        if(caseViewOtp!=null && !caseViewOtp.isEmpty()){
            String expectedOtp = caseViewOtp[0].Value__c;
            if(expectedOtp.equalsIgnoreCase(otp)){
                resMap.put('valid', true);
                delete caseViewOtp;
            }else{
                resMap.put('valid', false);
            }
            
        }else{
            resMap.put('valid',false);
        }
        return JSON.serialize(resMap);
    }    */
  /*@AuraEnabled
public static String resendOTP (String caseNumber, String email) { 
Map <String, Object> resMap = new Map <String, Object> ();

//TODO

return JSON.serialize(resMap);	
}*/
}