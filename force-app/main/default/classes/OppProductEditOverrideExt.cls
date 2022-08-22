/*******************************************************************************
* @author         :    Bharti Mewada
* @date           :    Sept 2019
* @description    :    Extension class for the VF Page OppProductEditOverride
* @Revisions      :
        #1        :   Created 
*******************************************************************************/
public class OppProductEditOverrideExt{
    Boolean isCPQOpp = false;
    OpportunityLineItem oppProduct;
    public OppProductEditOverrideExt(ApexPages.StandardController controller){
           //oppProduct = (OpportunityLineItem) controller.getRecord();
           oppProduct = [Select id,CPQ_Opp__c FROM  OpportunityLineItem  WHERE ID =: controller.getId() LIMIT 1];
           isCPQOpp = oppProduct.CPQ_Opp__c;
        }

        public pageReference redirect()
        {
            if(isCPQOpp)
            {
                return new pagereference('/'+oppProduct.id);
            }
            else
            {
                 return new pagereference('/'+oppProduct.id+'/e?nooverride=1');
            }
        }

}