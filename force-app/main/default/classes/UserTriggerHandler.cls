public class UserTriggerHandler {

    public static void ShareOpportunities(List<User> users) {
        
        List<OpportunityShare> OpportunityShrs = new List<OpportunityShare>();
        
        Map<Id, Set<Id>> userForAccount = new Map<Id, Set<Id>>();
        for (User usr : [SELECT Id, Contact.AccountId FROM User WHERE Id IN :users]) {
            if (usr.Contact.AccountId != null) {
                if (!userForAccount.containsKey(usr.Contact.AccountId)) {
                    userForAccount.put(usr.Contact.AccountId, new Set<Id>());
                }
            	userForAccount.get(usr.Contact.AccountId).add(usr.Id);
            }
        }
        
        if (userForAccount.size() > 0) {
            
            Map<Id, User> creators = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE Contact.AccountId IN :userForAccount.keyset()]);
            
            List<Opportunity> opps = [SELECT Id, CreatedById FROM Opportunity WHERE CreatedById IN :creators.keyset()];
            
            if (opps.size() > 0) {
                
                for (Opportunity opp : opps) {
                    
                    Id accId = creators.get(opp.CreatedById).Id;
                    
                    if (userForAccount.containsKey(accId)) {
                        for (Id usrId : userForAccount.get(accId)) {
                            
                            OpportunityShare pUser = new OpportunityShare();
                            pUser.OpportunityId = opp.Id;
                            pUser.UserOrGroupId = usrId;
                            pUser.OpportunityAccessLevel = 'Read';
                            pUser.RowCause = Schema.OpportunityShare.RowCause.Manual;
                            OpportunityShrs.add(pUser);
                            
                        }
                    }
                    
                }
                
            }
            
        }
        
        Database.SaveResult[] lsr = Database.insert(OpportunityShrs, false);
		
    }
    
   public static void removeInactiveLicenses(User[] records) {
    User[] inactives = new User[0];
    for(User record: records) {
        if(!record.IsActive) {
            inactives.add(record);
        }
    }
    if(!inactives.isEmpty()) {
        delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN :inactives AND PermissionSet.IsOwnedByProfile = FALSE];
        delete [SELECT Id FROM PermissionSetLicenseAssign WHERE AssigneeId IN :inactives];
        delete [SELECT Id FROM UserPackageLicense WHERE UserId IN :inactives];
    }
   }
}