global with sharing class brKnowledgeDataCategoryUtilCtrl {

    @AuraEnabled
    global static List<brKnowledgeDataCategoryWrapper> getCategoryItems(String groupName, String categoryName) {
        try {
            List<brKnowledgeDataCategoryWrapper> items = brKnowledgeDataCategoryUtilHelper.getAllCategories(groupName, categoryName);

            return items;

        } catch (Exception ex) { System.debug(ex.getMessage()); new AuraHandledException('Failed to load categories'); } return null;
    }

    @AuraEnabled
    global static List<String> getCategoriesParentage(List<String> selectedCategories) {
        Map<String, List<String>> parentageMap = brKnowledgeDataCategoryUtilHelper.getCategoriesParentageMap(selectedCategories);
        return brKnowledgeDataCategoryUtilHelper.getCategoriesParentage(parentageMap);
    }

}