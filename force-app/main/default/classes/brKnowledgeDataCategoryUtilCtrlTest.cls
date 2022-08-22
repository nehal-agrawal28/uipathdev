@IsTest
private class brKnowledgeDataCategoryUtilCtrlTest {
/*

    @TestSetup
    static void setup() {
        List<SObject> articles = KnowledgeTestUtils.createTestArticles(1);
        System.assertEquals(true, articles.size() == 1, 'Wrong number of articles created');
    }
*/

    @IsTest
    static void testGetCategoryItems() {
        List<brKnowledgeDataCategoryWrapper> items = brKnowledgeDataCategoryUtilCtrl.getCategoryItems('group', 'category');
        System.assertNotEquals(null, items);
    }

    @IsTest
    static void testGetCategoriesParentageMap() {
        List<String> output = brKnowledgeDataCategoryUtilCtrl.getCategoriesParentage(new List<String>{'category'});
        System.assertNotEquals(null, output);
    }
}