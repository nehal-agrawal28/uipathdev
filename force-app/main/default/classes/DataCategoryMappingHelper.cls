public class DataCategoryMappingHelper {
    
    public static void mapDataCategories(List<Knowledge__kav> articles){
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
    List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
    try {
        //Making the call to the describeDataCategoryGroups to
        //get the list of category groups associated
        List<String> objType = new List<String>();
        objType.add('KnowledgeArticleVersion');
        describeCategoryResult = Schema.describeDataCategoryGroups(objType);

        //Creating a list of pair objects to use as a parameter
        //for the describe call
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();

        //Looping throught the first describe result to create
        //the list of pairs for the second describe call
        for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
           DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
           p.setSobject(singleResult.getSobject());
           p.setDataCategoryGroupName(singleResult.getName());
           pairs.add(p);
         }

        //describeDataCategoryGroupStructures()
        describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
		Map<String, List<String>> mapping = new Map<String, List<String>>();
        Map<String, String> apimapping = new Map<String, String>();
        Map<String, String> apimapping1 = new Map<String, String>();
         //Getting data from the result
         for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
            //Get name of the associated Sobject

            //Get the name of the data category group
            mapping.put(singleResult.getName(), new List<String>());
			
            //Get the top level categories
            DataCategory [] toplevelCategories =  singleResult.getTopCategories();
             for(DataCategory dc : toplevelCategories){
                 for(DataCategory dc1 : dc.getChildCategories()){
                     apimapping1.put(dc1.getLabel(),dc1.getName());
                     apimapping.put(dc1.getLabel(),singleResult.getName());
                     //System.debug(dc1.getLabel()+'***'+singleResult.getName());
                 }
                 
             }
         }
        //List<Knowledge__kav> articles = [Select Id,Product_Component__c,ArticleNumber from Knowledge__kav where Product_Component__c !=''];
        List<Knowledge__DataCategorySelection> selections = new List<Knowledge__DataCategorySelection>();
        for(Knowledge__kav article : articles){
           
            //System.debug('article'+article);
            Knowledge__DataCategorySelection sel = new Knowledge__DataCategorySelection();
			sel.ParentId = article.Id;
            //System.debug(article.Product_Component__c+'---'+apimapping.get(article.Product_Component__c));
                if(article.Product_Component__c == 'All' || article.Product_Component__c == 'N/A' || apimapping1.get(article.Product_Component__c)==null){
                	sel.DataCategoryGroupName= 'On_Prem_Cloud';
                    sel.DataCategoryName= 'All';
                }else{
                    sel.DataCategoryGroupName= apimapping.get(article.Product_Component__c);
                    
                    String category = apimapping1.get(article.Product_Component__c);
                    if(category == 'Studio' || category == 'Robot' || category == 'Orchestrator'){
                        sel.DataCategoryName=apimapping1.get(article.Product_Component__c)+'_Licensing';
                    }else{
                        sel.DataCategoryName=apimapping1.get(article.Product_Component__c);
	                    }
                    
                }
			
                
			selections.add(sel);
			}
        if(selections.size()>0){
            insert selections;
        }
       } 
       catch (Exception e){
			System.debug('exception'+e.getMessage());
        }
    }
    
    
    
    
   /* public static void method1(){
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
    List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
    try {
        //Making the call to the describeDataCategoryGroups to
        //get the list of category groups associated
        List<String> objType = new List<String>();
        objType.add('KnowledgeArticleVersion');
        describeCategoryResult = Schema.describeDataCategoryGroups(objType);

        //Creating a list of pair objects to use as a parameter
        //for the describe call
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();

        //Looping throught the first describe result to create
        //the list of pairs for the second describe call
        for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
           DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
           p.setSobject(singleResult.getSobject());
           p.setDataCategoryGroupName(singleResult.getName());
           pairs.add(p);
         }

        //describeDataCategoryGroupStructures()
        describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
		Map<String, List<String>> mapping = new Map<String, List<String>>();
        Map<String, String> apimapping = new Map<String, String>();
         //Getting data from the result
         for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
            //Get name of the associated Sobject

            //Get the name of the data category group
            mapping.put(singleResult.getName(), new List<String>());
			
            //Get the top level categories
            DataCategory [] toplevelCategories =  singleResult.getTopCategories();
             for(DataCategory dc : toplevelCategories){
                 for(DataCategory dc1 : dc.getChildCategories()){
                 	mapping.get(singleResult.getName()).add(dc1.getLabel());
                     apimapping.put(dc1.getName(),dc1.getLabel());
                     System.debug(dc1.getName()+'***'+dc1.getLabel());
                 }
                 
             }
         }
        List<Knowledge__kav> articles = [Select Id,Product_Component__c,ArticleNumber from Knowledge__kav where Product_Component__c !=''];
        
        
       } 
       catch (Exception e){

        }
    }

    public static void method2(){
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
    List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
    try {
        //Making the call to the describeDataCategoryGroups to
        //get the list of category groups associated
        List<String> objType = new List<String>();
        objType.add('KnowledgeArticleVersion');
        describeCategoryResult = Schema.describeDataCategoryGroups(objType);

        //Creating a list of pair objects to use as a parameter
        //for the describe call
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();

        //Looping throught the first describe result to create
        //the list of pairs for the second describe call
        for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
           DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
           p.setSobject(singleResult.getSobject());
           p.setDataCategoryGroupName(singleResult.getName());
           pairs.add(p);
         }

        //describeDataCategoryGroupStructures()
        describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
		Map<String, List<String>> mapping = new Map<String, List<String>>();
        Map<String, String> apimapping = new Map<String, String>();
        Map<String, String> apimapping1 = new Map<String, String>();
         //Getting data from the result
         for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
            //Get name of the associated Sobject

            //Get the name of the data category group
            mapping.put(singleResult.getName(), new List<String>());
			
            //Get the top level categories
            DataCategory [] toplevelCategories =  singleResult.getTopCategories();
             for(DataCategory dc : toplevelCategories){
                 for(DataCategory dc1 : dc.getChildCategories()){
                     apimapping1.put(dc1.getLabel(),dc1.getName());
                     apimapping.put(dc1.getLabel(),singleResult.getName());
                     //System.debug(dc1.getLabel()+'***'+singleResult.getName());
                 }
                 
             }
         }
        List<Knowledge__kav> articles = [Select Id,Product_Component__c,ArticleNumber from Knowledge__kav where Product_Component__c !='' and Language = 'en_US'];
        List<Knowledge__DataCategorySelection> selections = new List<Knowledge__DataCategorySelection>();
        for(Knowledge__kav article : articles){
           
                
            
            //System.debug('article'+article);
            Knowledge__DataCategorySelection sel = new Knowledge__DataCategorySelection();
			sel.ParentId = article.Id;
            //System.debug(article.Product_Component__c+'---'+apimapping.get(article.Product_Component__c));
                if(article.Product_Component__c == 'All' || article.Product_Component__c == 'N/A' || apimapping1.get(article.Product_Component__c)==null){
                	sel.DataCategoryGroupName= 'On_Prem_Cloud';
                    sel.DataCategoryName= 'All';
                }else{
                    sel.DataCategoryGroupName= apimapping.get(article.Product_Component__c);
                    
                    String category = apimapping1.get(article.Product_Component__c);
                    if(category == 'Studio' || category == 'Robot' || category == 'Orchestrator'){
                        sel.DataCategoryName=apimapping1.get(article.Product_Component__c)+'_Licensing';
                    }else{
                        sel.DataCategoryName=apimapping1.get(article.Product_Component__c);
	                    }
                    
                        
                    
                }
			
                
			selections.add(sel);
			
        }
        insert selections;
       } 
       catch (Exception e){
			System.debug('exception'+e.getMessage());
        }
    }

    public static void method3(){
        List<Knowledge__kav> onlineArticles = [Select Id, KnowledgeArticleId from Knowledge__kav where PublishStatus='Online' and IsLatestVersion=true and IsVisibleInPkb = false and IsVisibleInCsp = true];
        List<String> newArticleIds = new List<String>();
        for(Knowledge__kav onlineArticle: onlineArticles){
           
            String kaIdStr = onlineArticle.KnowledgeArticleId;
            Id kaId = kaIdStr;
             System.debug('kaIdStr'+kaIdStr);
             System.debug('kaId'+kaId);
			String newArticleId = KbManagement.PublishingService.editOnlineArticle(kaId, false); 
            newArticleIds.add(newArticleId);          
        }

		List<Knowledge__kav> article = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id in :newArticleIds];
        List<Knowledge__kav> newArticles = new List<Knowledge__kav>();
        for(Knowledge__kav a : article){
			a.IsVisibleInPkb = true;
			//a.IsVisibleInCsp = true;  
            newArticles.add(a);
        }
		update newArticles;
        
        for(Knowledge__kav newArticle: newArticles){
            KbManagement.PublishingService.publishArticle(newArticle.KnowledgeArticleId, true);
        }


    }*/
}