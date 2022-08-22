global with sharing class brKnowledgeDataCategoryWrapper {
    @AuraEnabled
    global String name;

    @AuraEnabled
    global String label;

    @AuraEnabled
    global Integer ArticleCount;

    @AuraEnabled
    global List<brKnowledgeDataCategoryWrapper> child;

    @AuraEnabled
    global Boolean selected;

    @AuraEnabled
    global Boolean opened;
}