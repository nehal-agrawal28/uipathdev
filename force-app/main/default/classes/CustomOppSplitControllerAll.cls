public with sharing class CustomOppSplitControllerAll 
{
    public Id opportunityId {get; set;}
    public User opportunityOwner {get; set;}
    public List<OppSplitWrapper> oppSplitWrapperList {get; set;}
    public Boolean showWarningMessage {get; set;}
    public List<OpportunityTeamMember> oppTeamMemberList {get; set;}
    public List<Opportunity_Split__c> oppSplitList {get; set;} 
    public String errorMessage {get; set;}
    public Boolean isReadOnly {get; set;}
    public Boolean isEditable {get; set;}
    public Opportunity mainOpp {get; set;}
    public String approvalStatus {get; set;}
    public String profileName {get; set;}
    public Boolean needApprovalAsAdmin {get; set;}
    public Map<String, Decimal> roleToPercentageSumCurrent {get; set;}
    public Map<String, Decimal> roleToPercentageSumOld {get; set;}
    
    public boolean loaded { get; set; }

    public CustomOppSplitControllerAll(ApexPages.StandardController ctrl) 
    {
        opportunityId = ctrl.getId();
        showWarningMessage = false;
        errorMessage = '';
        isReadOnly = false;
        isEditable = false;
        approvalStatus = 'New';
        needApprovalAsAdmin = false;
        roleToPercentageSumCurrent = new Map<String, Decimal>();
        roleToPercentageSumOld = new Map<String, Decimal>();
        
        loaded = false;

        mainOpp = [SELECT Approval_Process_Status__c, Owner.Id, Owner.Profile.Name, Owner.UserRole.Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        opportunityOwner = mainOpp.Owner;

        Id profileId = Userinfo.getProfileId();
        profileName = [Select Id,Name from Profile where Id=:profileId Limit 1].Name;
    }

    public void setLoaded() {
        loaded = true;
    }
    
    public void LoadTableData()
    {
        List<AvailableTeamMemberRole__mdt> availableRoles = 
            [
                SELECT Id, Role__c
                FROM AvailableTeamMemberRole__mdt
            ];

        Set<String> roleSet = new Set<String>();

        for(AvailableTeamMemberRole__mdt role : availableRoles)
        {
            roleSet.add(role.Role__c);
        }

        oppSplitWrapperList = new List<OppSplitWrapper>();

        oppSplitList =
            [
                SELECT User__r.Profile.Name, User__r.UserRole.Name,User__r.Goal_Master_Role__c, Included_in_Compensation__c, Id, Percentage__c, User__c, Opportunity__c, User__r.Name, Role__c, User__r.GIC_Sales__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opportunityId
            ];
        
        oppTeamMemberList =
            [
                SELECT User.Profile.Name, User.UserRole.Name, Id, TeamMemberRole, UserId, User.GIC_Sales__c, User.Name
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opportunityId
                AND TeamMemberRole IN :roleSet
            ];
       
        
        for(Opportunity_Split__c oppSplit : oppSplitList)
        {
            
            OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
            oppSplitWrapper.oppSplit = oppSplit;
            oppSplitWrapper.teamMember = null;
            oppSplitWrapperList.add(oppSplitWrapper);
           
        }
        
        CheckIfWarningNeeded();
        CheckIfReadOnly();
    }
    
    
    
    public void AddMissingSplits()
    {
        Set<String> ExcludePAMGeoSet = new Set<String>{'AMER', 'EMEA', 'Japan'};
        
        List<AvailableTeamMemberRole__mdt> availableRoles = 
            [
                SELECT Id, Role__c, Percentage__c
                FROM AvailableTeamMemberRole__mdt
            ];
        
        Map<String, Decimal> AvailableTeamMemberRoles = new Map<String, Decimal>();
        Set<String> roleSet = new Set<String>();

        for(AvailableTeamMemberRole__mdt role : availableRoles)
        {
            roleSet.add(role.Role__c);
            AvailableTeamMemberRoles.put(role.Role__c, role.Percentage__c);
        }

        List<Opportunity_Split__c> oppSplits =
            [
                SELECT Id, User__c, Opportunity__c, Role__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opportunityId
            ];
       
        Set<String> OppSplitsRolesNumberSet = new Set<String>();
        for(Opportunity_Split__c oppspl: oppSplits ) {
            OppSplitsRolesNumberSet.add(oppspl.User__c + '-' + oppspl.Role__c);
        }
        
        List<OpportunityTeamMember> oppTeamMembers =
            [
                SELECT User.Profile.Name, User.UserRole.Name, Id, TeamMemberRole, UserId, User.GIC_Sales__c, 
                    User.Name, Opportunity.CurrencyIsoCode, Opportunity.Account_Geo__c, Created_on_opportunity_insert__c
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opportunityId
                AND TeamMemberRole IN :roleSet
            ];
            
        Set<Id> userIds = new Set<Id>();
        for(OpportunityTeamMember otm: oppTeamMembers) {
            userIds.add(otm.UserId);
        }
        
        Map<Id, User> oppOwnersMap = new Map<Id, User>([SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name 
                FROM User
                WHERE Id IN: userIds
            ]);
        List<Opportunity_Split__c> oppSplitToInsert = new List<Opportunity_Split__c>();
        for(OpportunityTeamMember oppTeam: oppTeamMembers) {
            if(!(ExcludePAMGeoSet.contains(oppTeam.Opportunity.Account_Geo__c) && oppTeam.TeamMemberRole == 'Partner Account Manager' && oppTeam.Created_on_opportunity_insert__c == true) &&
            !(oppTeam.Opportunity.Account_Geo__c == 'Japan' &&  oppTeam.TeamMemberRole == 'Partner Account Manager' && oppTeam.Created_on_opportunity_insert__c == false)) {
                if(AvailableTeamMemberRoles.containsKey(oppTeam.TeamMemberRole)) {
                    if(!OppSplitsRolesNumberSet.contains(oppTeam.UserId + '-' + oppTeam.TeamMemberRole)) {
                        Opportunity_Split__c oppSplit = new Opportunity_Split__c();
                        oppSplit.Opportunity__c = oppTeam.OpportunityId;
                        oppSplit.User__c = oppTeam.UserId;
                        if(!AvailableTeamMemberRoles.containsKey(oppTeam.TeamMemberRole)) {
                            oppSplit.Percentage__c = AvailableTeamMemberRoles.get(oppTeam.TeamMemberRole);
                        } else
                            oppSplit.Percentage__c = 0;
                        if(oppTeam.TeamMemberRole == 'Opportunity Owner' && oppOwnersMap.containsKey(oppTeam.UserId)) {
                            User u = oppOwnersMap.get(oppTeam.UserId);
                            if((u.Profile.Name).contains('Partner') || (u.UserRoleId != null && u.UserRole.Name.contains('Partner')))
                                oppSplit.Role__c = 'Partner Account Manager';
                            else
                                oppSplit.Role__c = oppTeam.TeamMemberRole; 
                        } else {
                            oppSplit.Role__c = oppTeam.TeamMemberRole; 
                        }                       
                        oppSplit.CurrencyIsoCode = oppTeam.Opportunity.CurrencyIsoCode;
                        oppSplitToInsert.add(oppSplit);
                    }
                }
            }
        }
       
            
        if(oppSplitToInsert.size() > 0) {
            insert oppSplitToInsert;
        }   
        List<Opportunity_Split__c> oppSplitL =
            [
                SELECT User__r.Profile.Name, User__r.UserRole.Name,User__r.Goal_Master_Role__c, Included_in_Compensation__c, Id, Percentage__c, User__c, Opportunity__c, User__r.Name, Role__c, User__r.GIC_Sales__c
                FROM Opportunity_Split__c
                WHERE Opportunity__c = :opportunityId
            ];
        oppSplitWrapperList = new List<OppSplitWrapper>();
        for(Opportunity_Split__c oppSplit : oppSplitL)
        {
            
            OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
            oppSplitWrapper.oppSplit = oppSplit;
            oppSplitWrapper.teamMember = null;
            oppSplitWrapperList.add(oppSplitWrapper);
           
        }
    }
    
    public void EditOppSplit()
    {
        isEditable = true;
    }

    public void CheckIfReadOnly()
    {
        if(approvalStatus == 'Approved' || approvalStatus == 'Pending')
        {
            if(profileName == 'System Administrator' || profileName == 'Super Admin' || profileName == 'Data Stewards' || profileName == 'Sales Operations Advanced' || profileName == 'Sales Ops Geo Leads' || profileName == 'Compensation')
            {
                isReadOnly = false;
            }
            else
            {
                isReadOnly = true;
            }
        }
        else
        {
            isReadOnly = false;
        }
    }

    public void RequestApproval()
    {
        try
        { 
            needApprovalAsAdmin = false;

            // check to see if the record is already locked from a previous approval process
            if(Approval.isLocked(opportunityId) == false)
            {
                // Create an approval request for the opportunity
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Submitting request for approval.');
                req1.setObjectId(opportunityId);
                                        
                // Submit the record to specific process and skip the criteria evaluation
                req1.setProcessDefinitionNameOrId('Split_Percentage_Approval');
                req1.setSkipEntryCriteria(true);
                
                // Submit the approval request for the account
                Approval.ProcessResult result = Approval.process(req1);

                errorMessage = 'You need additional approval for this split';

                List<ProcessInstance> procInstanceList =
                    [
                        SELECT Id, Status, CompletedDate
                        FROM ProcessInstance
                        WHERE TargetObjectId = :opportunityId
                        ORDER BY CompletedDate DESC
                    ];

                Boolean foundCompletedItem = false;

                for(ProcessInstance procInstanceItem : procInstanceList)
                {
                    if(procInstanceItem.CompletedDate == null)
                    {
                        errorMessage = 'Approval Requested - Pending';
                        approvalStatus = 'Pending';
                        break;
                    }
                    else if(foundCompletedItem == false)
                    {
                        foundCompletedItem = true;
                        errorMessage = 'Approval Requested - ' + procInstanceItem.Status;
                        approvalStatus = procInstanceItem.Status;
                    }
                }

                CheckIfReadOnly();
            }
        }
        catch(Exception e)
        {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(msg);

            return;
        }
    }

    public void UpdateFieldsInfo()
    {
        List<Opportunity_Split__c> oppSplitsToUpdate = new List<Opportunity_Split__c>();

        for(OppSplitWrapper oppSplitWrapper : oppSplitWrapperList)
        {
            oppSplitsToUpdate.add(oppSplitWrapper.oppSplit);
        }

        try
        { 
            update oppSplitsToUpdate;
            isEditable = false;
            showWarningMessage = false;
            
            // save old percentage sum values
            roleToPercentageSumOld = roleToPercentageSumCurrent.clone();

            CheckIfWarningNeeded();
            CheckIfReadOnly();
            
        }
        catch(Exception e)
        {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(msg);

            return;
        }
    }

    public void CheckIfWarningNeeded()
    {
        Set<String> usedRoleSet = new Set<String>();
        needApprovalAsAdmin = false;

        for(OpportunityTeamMember oppTeamMember : oppTeamMemberList)
        { 
            if(oppTeamMember.User.GIC_Sales__c == true || usedRoleSet.contains(oppTeamMember.TeamMemberRole))
            {
                continue;
            }

            if(oppTeamMember.TeamMemberRole == 'Opportunity Owner' && ((oppTeamMember.User.UserRole != null && oppTeamMember.User.UserRole.Name.contains('Inside Sales')) || oppTeamMember.User.Profile.Name.contains('Inside Sales')))
            {
                continue;
            }

            // add only once the percentage for same role splits.
            usedRoleSet.add(oppTeamMember.TeamMemberRole);

            // make a list with all the members from both 'Opportunity Owner' and 'Sales Representative'
            if(oppTeamMember.TeamMemberRole == 'Sales Representative')
            {
                usedRoleSet.add('Opportunity Owner');
            }
            else if(oppTeamMember.TeamMemberRole == 'Opportunity Owner')
            {
                usedRoleSet.add('Sales Representative');
            }

            roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, 0);

            for(Opportunity_Split__c oppSplit : oppSplitList)
            {
                if(oppSplit.User__r.GIC_Sales__c == true)
                {
                    continue;
                }

                if(oppSplit.Role__c == 'Opportunity Owner' && ((oppTeamMember.User.UserRole != null && oppSplit.User__r.UserRole.Name.contains('Inside Sales')) || oppSplit.User__r.Profile.Name.contains('Inside Sales')))
                {
                    continue;
                }

                if(oppTeamMember.TeamMemberRole == 'Sales Representative' && oppSplit.Role__c == 'Opportunity Owner')
                {
                    roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) + oppSplit.Percentage__c);
                }
                else if(oppTeamMember.TeamMemberRole == 'Opportunity Owner' && oppSplit.Role__c == 'Sales Representative')
                {
                    roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) + oppSplit.Percentage__c);
                }
                else if(oppTeamMember.TeamMemberRole == oppSplit.Role__c)
                {
                    roleToPercentageSumCurrent.put(oppTeamMember.TeamMemberRole, roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) + oppSplit.Percentage__c);
                }
            }
            
            if(roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) > 125)
            {
                showWarningMessage = true;
                errorMessage = 'You need additional approval for this split';

                List<ProcessInstance> procInstanceList =
                    [
                        SELECT Id, Status, CompletedDate
                        FROM ProcessInstance
                        WHERE TargetObjectId = :opportunityId
                        ORDER BY CompletedDate DESC
                    ];

                Boolean foundCompletedItem = false;

                for(ProcessInstance procInstanceItem : procInstanceList)
                {
                    if(procInstanceItem.CompletedDate == null)
                    {
                        errorMessage = 'Approval Requested - Pending';
                        approvalStatus = 'Pending';
                        break;
                    }
                    else if(foundCompletedItem == false)
                    {
                        foundCompletedItem = true;
                        errorMessage = 'Approval Requested - ' + procInstanceItem.Status;
                        approvalStatus = procInstanceItem.Status;
                    }
                }

                // if you are an admin and updated the pecentage sum to a higher value then it was approved initially, fire the approval process again
                if(roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) != null && roleToPercentageSumOld.get(oppTeamMember.TeamMemberRole) != null && roleToPercentageSumCurrent.get(oppTeamMember.TeamMemberRole) > roleToPercentageSumOld.get(oppTeamMember.TeamMemberRole))
                {
                    if(approvalStatus != 'Pending')
                    {
                        errorMessage = 'You need additional approval for this split';
                        needApprovalAsAdmin = true;
                    }
                    else
                    {
                        errorMessage = 'Approval Requested - Pending';
                        needApprovalAsAdmin = false;
                    }
                }
            }
        }
    }

    public class OppSplitWrapper
    {
        public Opportunity_Split__c oppSplit {get; set;}
        public OpportunityTeamMember teamMember {get; set;}
        public Boolean hasTeamMember {get; set;}

        public OppSplitWrapper()
        {
            oppSplit = new Opportunity_Split__c();
            teamMember = new OpportunityTeamMember();
            hasTeamMember = true;
        }
    }
}