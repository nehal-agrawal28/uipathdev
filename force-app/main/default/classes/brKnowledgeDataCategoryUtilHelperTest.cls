/**
 * Unit test class for brKnowledgeDataCategoryUtilHelperTest class
 */
@IsTest
private class brKnowledgeDataCategoryUtilHelperTest {

    @IsTest
    static void testGetAllCategories() {
        List<brKnowledgeDataCategoryWrapper> items = brKnowledgeDataCategoryUtilHelper.getAllCategories('group', 'category');
        System.assertNotEquals(null, items);
    }

    @IsTest
    static void testGetChildrenForCategory1() {
        brKnowledgeDataCategoryWrapper parentCategory = new brKnowledgeDataCategoryWrapper();
        brKnowledgeDataCategoryWrapper childCategory = new brKnowledgeDataCategoryWrapper();
        childCategory.name = 'group1__c:category1__c';
        childCategory.child = new List<brKnowledgeDataCategoryWrapper>();
        List<brKnowledgeDataCategoryWrapper> childCategories = new List<brKnowledgeDataCategoryWrapper>{childCategory};

        parentCategory.child = childCategories;

        brKnowledgeDataCategoryWrapper item = brKnowledgeDataCategoryUtilHelper.getChildrenForCategory(parentCategory, 'group', 'category');
        System.assertEquals(null, item);
    }

    @IsTest
    static void testGetChildrenForCategory2() {
        brKnowledgeDataCategoryWrapper parentCategory = new brKnowledgeDataCategoryWrapper();
        brKnowledgeDataCategoryWrapper childCategory = new brKnowledgeDataCategoryWrapper();
        childCategory.name = 'group__c:category__c';
        childCategory.child = new List<brKnowledgeDataCategoryWrapper>();
        List<brKnowledgeDataCategoryWrapper> childCategories = new List<brKnowledgeDataCategoryWrapper>{childCategory};

        parentCategory.child = childCategories;

        brKnowledgeDataCategoryWrapper item = brKnowledgeDataCategoryUtilHelper.getChildrenForCategory(parentCategory, 'group', 'category');
        System.assertNotEquals(null, item);
    }

    @IsTest
    static void testGetChildrenCategoriesList(){
        List<String> children = brKnowledgeDataCategoryUtilHelper.getChildrenCategoriesList('Group:category');
        System.assertNotEquals(null, children);
    }

    @IsTest
    static void testGetChildrenNames(){
        List<String> children = brKnowledgeDataCategoryUtilHelper.getChildrenNames(null, 'Group:Category', false);
        System.assertNotEquals(null, children);
    }

    @IsTest
    static void testGetCategoriesParentageMap(){
        Map<String, List<String>> children = brKnowledgeDataCategoryUtilHelper.getCategoriesParentageMap(new List<String>{'Cat1'});
        System.assertNotEquals(null, children);
    }

    @IsTest
    static void testGetCategoriesParentage() {
        Map<String, List<String>> testData = new Map<String, List<String>>();
        testData.put('testCat', new List<String>{'childA', 'childB'});
        List<String> output = brKnowledgeDataCategoryUtilHelper.getCategoriesParentage(testData);
        System.assertNotEquals(null, output);
    }
}