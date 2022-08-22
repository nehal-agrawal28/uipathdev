public without sharing class Portal_VFOpportunities {

    public integer noOpps { get; set; }
    public decimal oppAmount { get; set; }
    
    public Portal_VFOpportunities() {
        
        User myUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
        
        noOpps = 0;
        oppAmount = 0;
        
        if (myUser.Contact.AccountId != null) {
            List<User> creators = [SELECT Id FROM User WHERE Contact.AccountId = :myUser.Contact.AccountId];
            
            for (Opportunity opp : [SELECT Amount FROM Opportunity WHERE CreatedById IN :creators]) {
                noOpps++;
                if (opp.Amount != null) {
                    oppAmount += opp.Amount;
                }
            }
        }
        
    }
    
}