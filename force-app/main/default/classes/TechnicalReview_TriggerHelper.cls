public class TechnicalReview_TriggerHelper {
    
    public void onAfterInsert(List<Technical_Review__c> newTechnicalReview) {
        
        Set<Id> articleIds = new Set<Id>();
        Set<Id> reviewIds= new Set<Id>();
        Map<Id,List<Technical_Review__c>> CntofTechReview =new  Map<Id,List<Technical_Review__c>>();
        for(Technical_Review__c review: newTechnicalReview)
        {
            articleIds.add(review.Knowledge_Article__c) ;
            reviewIds.add(review.Id) ;
           
        }
        system.debug('ArticleId'+articleIds );
        for(Technical_Review__c review:[Select Id,Knowledge_Article__c, Technical_Review_date__c,Technical_Check_Result__c,technical_reviewer__c from Technical_Review__c 
                                        where Knowledge_Article__c in :articleIds ORDER BY CreatedDate Desc])
        { 
           // system.debug('review record '+review);
            if(CntofTechReview.containsKey(review.Knowledge_Article__c))
            {
                CntofTechReview.get(review.Knowledge_Article__c).add(review) ;
            }
            else
            {
                CntofTechReview.put(review.Knowledge_Article__c,new List<Technical_Review__c>{review}); 
            }
        }
        system.debug('Map values'+ CntofTechReview);
        //List<KNowledge__kav> listUpdateknow= new List<KNowledge__kav>([Select Id,First_Technical_Check_Result__c,times_technically_reviewed__c,First_Technical_Check_date__c from KNowledge__kav where id in :articleIds]); //commented by Deepali - to fix the error appearing on creation of Tech Revview on Published Articles 
        //Added by Deepali start
        String queryPublishedArticle = 'Select Id,First_Technical_Check_Result__c,times_technically_reviewed__c,First_Technical_Check_date__c from KNowledge__kav where id in :articleIds AND PublishStatus = \'Draft\'';
        List<KNowledge__kav> listUpdateknow = Database.query(queryPublishedArticle);
        //Added by Deepali end
        for(KNowledge__kav know: listUpdateknow )
        {
            List<Technical_Review__c> review1= new List<Technical_Review__c>(CntofTechReview.get(know.Id)); 
            system.debug('Review list '+ review1);
            if(review1.Size()>0)
            {
            system.debug('Review list top record '+ review1[0]);
            system.debug('Count of technical'+ review1.size());
           
            know.First_Technical_Check_Result__c=review1[review1.size()-1].Technical_Check_Result__c;
            know.First_Technical_Check_date__c= review1[review1.size()-1].Technical_Review_date__c; 
            }
            else
            {
           
                know.First_Technical_Check_Result__c='';
                know.First_Technical_Check_date__c=null;
            }
           // know.first
        }
        update listUpdateknow;
    }
    
    
    
    
    
    
}