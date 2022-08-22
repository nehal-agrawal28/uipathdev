public with sharing class CaseViewLookupController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, String contactId, String limitOfRecords) {
        List < sObject > returnList = new List < sObject > ();
        String searchKey = '%'+searchKeyWord + '%';
        List<String> allObjects = ObjectName.split(';');
        List<String> searchterm = new List<String>{searchKeyWord};
            if(allObjects.contains('case')){
                String whereClause = '';
                if(String.isNotBlank(contactId)){
                    whereClause = ' WHERE ContactId =: contactId and (CaseNumber Like:searchKey OR Subject Like:searchKey OR Status Like:searchKey OR Related_To__c Like:searchKey OR Priority Like:searchKey OR Environment_Of_Issue__c Like:searchKey OR Studio_Version__c Like:searchKey OR Orchestrator_Version__c Like:searchKey OR Product_Component_Version__c Like:searchKey OR Error_Message__c  Like:searchKey)';
                }
                else{
                    whereClause = ' WHERE CaseNumber Like:searchKey OR Subject Like:searchKey';
                }
                String query = 'SELECT Id, CaseNumber, Subject, Description, CreatedDate, Contact.Name, Status, RecordType.Name,Related_To__c,Studio_Version__c, Orchestrator_Version__c  FROM Case'+whereClause+' LIMIT '+limitOfRecords;
                List<sObject> cases = Database.query(query);
                returnList.addAll(cases);
                
            }
        if(allObjects.contains('knowledge__kav')){
            String whereClause1 = '(Title LIKE:searchKey OR Product_Component__c LIKE:searchKey OR Sub_Component__c LIKE:searchKey OR Studio_Version__c includes (:searchKeyWord) OR Orchestrator_Version__c includes (:searchKeyWord))  LIMIT '+limitOfRecords;
            String whereClause = ' where PublishStatus=\'Online\' And (IsVisibleInPkb = true Or IsVisibleInCsp = true) and IsLatestVersion = true AND '+whereClause1;
            String query='Select Id, KnowledgeArticleId, Title, UrlName, Question_Problem__c,Resolution__c, ArticleNumber, PublishStatus, IsVisibleInPkb,IsLatestVersion,Product_Component__c,Sub_Component__c,Studio_Version__c,Orchestrator_Version__c  from Knowledge__kav'+whereClause;
            List<sObject> articles = Database.query(query);
            returnList.addAll(articles);
        }
        
        return returnList;
    }
    @AuraEnabled
    public static String attachCaseToArticle(String kavId, String caseId){
        List<Knowledge__kav> knowledgeArticle = [Select Id, KnowledgeArticleId from Knowledge__kav where id=:kavId];
        CaseArticle caseArticleRec = new CaseArticle();
        caseArticleRec.CaseId = caseId;
        caseArticleRec.KnowledgeArticleId = knowledgeArticle[0].KnowledgeArticleId;
        insert caseArticleRec;
        return caseArticleRec.Id;
        
    }
}