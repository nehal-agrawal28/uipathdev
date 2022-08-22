/**
 * Helper util class, must NOT be included into manage package
 * it isolates all calls to DataCategory API
 */
global with sharing class brKnowledgeDataCategoryUtilHelper {

    global static List<brKnowledgeDataCategoryWrapper> getAllCategories(String groupName, String categoryName) {
        List<brKnowledgeDataCategoryWrapper> items = new List<brKnowledgeDataCategoryWrapper>();

            brKnowledgeDataCategoryWrapper item;
            brKnowledgeDataCategoryWrapper childItem;

            if(String.isBlank(groupName)) {
                groupName = null;
            }

            List<DescribeDataCategoryGroupStructureResult> categoryStructRes = Schema.describeDataCategoryGroupStructures(getDataCategoryGroupPairs(groupName), false);

            for (DescribeDataCategoryGroupStructureResult struct : categoryStructRes) {
                List<brKnowledgeDataCategoryWrapper> childItems = new List<brKnowledgeDataCategoryWrapper>();
                DataCategory[] topCategories = struct.getTopCategories();

                if(topCategories.size() > 0 && topCategories[0].getName() == 'All') {
                    topCategories = topCategories[0].getChildCategories();
                }

                for(DataCategory dc: topCategories) {
                    childItem = new brKnowledgeDataCategoryWrapper();
                    childItem.name = struct.getName() + '__c:' + dc.getName() + '__c';
                    childItem.label = dc.getLabel();
                    childItem.ArticleCount = 0;
                    childItem.child = getChildCategories(dc, struct.getName());
                    childItem.selected = false;
                    childItem.opened = false;

                    childItems.add(childItem);
                }

                item = new brKnowledgeDataCategoryWrapper();
                item.name = struct.getName();
                item.label = struct.getLabel();
                item.ArticleCount = 0;
                item.child = childItems;
                item.selected = false;
                item.opened = false;

                items.add(item);
            }

            if(String.isNotBlank(groupName) && String.isNotBlank(categoryName) && items.size() > 0) {
                List<brKnowledgeDataCategoryWrapper> children = new List<brKnowledgeDataCategoryWrapper>();

                for(brKnowledgeDataCategoryWrapper catInner: items[0].child) {
                    if(groupName + '__c:' + categoryName + '__c' == catInner.name) {
                        children.add(catInner);
                        break;
                    }

                    brKnowledgeDataCategoryWrapper catItem = brKnowledgeDataCategoryUtilHelper.getChildrenForCategory(catInner, groupName, categoryName);

                    if(catItem != null) {
                        children.add(catItem);
                        break;
                    }
                }
                items[0].child = children;
            }

            return items;

    }

    public static brKnowledgeDataCategoryWrapper getChildrenForCategory(brKnowledgeDataCategoryWrapper parentCategory, String groupName, String categoryName) {
        brKnowledgeDataCategoryWrapper item;

        for(brKnowledgeDataCategoryWrapper catInner: parentCategory.child) {
            if(groupName + '__c:' + categoryName + '__c' == catInner.name) {
                return catInner;
            }

            item = getChildrenForCategory(catInner, groupName, categoryName);

            if(item != null) {
                break;
            }
        }
        return item;
    }

    private static List<brKnowledgeDataCategoryWrapper> getChildCategories(DataCategory rootCategory, String groupName) {
        List<brKnowledgeDataCategoryWrapper> items = new List<brKnowledgeDataCategoryWrapper>();
            brKnowledgeDataCategoryWrapper item;

            DataCategory[] children = rootCategory.getChildCategories();

            for (DataCategory ch : children) {
                item = new brKnowledgeDataCategoryWrapper();
                item.name = groupName + '__c:' + ch.getName() + '__c';
                item.label = ch.getLabel();
                item.ArticleCount = 0;
                item.child = getChildCategories(ch, groupName);
                item.selected = false;
                item.opened = false;

                items.add(item);
            }
        return items;

    }

    private static List<DataCategoryGroupSobjectTypePair> getDataCategoryGroupPairs(String categoryGroup) {

        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
            List<String> objType = new List<String>();
            objType.add('KnowledgeArticleVersion');

            List<DescribeDataCategoryGroupResult> categoryGroups = Schema.describeDataCategoryGroups(objType);

            for (DescribeDataCategoryGroupResult group_res: categoryGroups) {
                DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                p.setSobject('KnowledgeArticleVersion');

                if (categoryGroup != null && !Test.isRunningTest()) {
                    //System.debug('categoryGroup: ' + categoryGroup);
                    p.setDataCategoryGroupName(categoryGroup);
                    pairs.add(p);
                    break;
                } else {
                    //System.debug('categoryGroup2: ' + group_res.getName());
                    p.setDataCategoryGroupName(group_res.getName());
                    pairs.add(p);
                }
            }
        return pairs;

    }

    public static List<String> getCategoriesParentage(Map<String, List<String>> parentageMap){
        List<String> parentageList = new List<String>();
        for (String parentCategory : parentageMap.keySet()) {
            parentageList.add(parentCategory + '#' + String.join(parentageMap.get(parentCategory), ','));
        }
        System.debug(parentageList);
        return parentageList;
    }

    public static Map<String, List<String>> getCategoriesParentageMap(List<String> categories){
        Map<String, List<String>> parentageMap = new  Map<String, List<String>>();
        for (String categoryName : categories) {
            List<String>  categoryParentage = brKnowledgeDataCategoryUtilHelper.getChildrenCategoriesList(categoryName);
            parentageMap.put(categoryName, categoryParentage);
        }
        return parentageMap;
    }

    public static List<String> getChildrenCategoriesList(String targetParentName){
        List<String> parentage = new List<String>();
        List<brKnowledgeDataCategoryWrapper> items = brKnowledgeDataCategoryUtilHelper.getAllCategories('', '');//labels only
        for(brKnowledgeDataCategoryWrapper item :items){
            parentage.addAll(getChildrenNames(item.child, targetParentName, false));
        }
        return parentage;
    }

    public static List<String> getChildrenNames(List<brKnowledgeDataCategoryWrapper> categoryChildren, String targetParentName, Boolean doRecord){
        List<String> parentage = new List<String>();
        if (categoryChildren != null && categoryChildren.size() > 0) {
            for (brKnowledgeDataCategoryWrapper childItem : categoryChildren) {
                if (doRecord) {
                    parentage.add(childItem.name.substringAfter(':'));//take only category without data group name
                }
                Boolean doRecordFlag = false;
                if (targetParentName == childItem.name || doRecord) {
                    doRecordFlag = true;
                }
                parentage.addAll(getChildrenNames(childItem.child, targetParentName, doRecordFlag));
            }
        }
        return parentage;
    }
}