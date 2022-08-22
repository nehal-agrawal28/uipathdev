public with sharing class CustomOppSplitController 
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

    public CustomOppSplitController(ApexPages.StandardController ctrl) 
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
                SELECT User.Profile.Name, User.UserRole.Name, Id, TeamMemberRole, UserId, User.GIC_Sales__c, User.Name, Opportunity.Account_Geo__c, Created_on_opportunity_insert__c 
                FROM OpportunityTeamMember
                WHERE OpportunityId = :opportunityId
                AND TeamMemberRole IN :roleSet
            ];
            
        List<Opportunity_Split__c> oppSplitListToCreate = new List<Opportunity_Split__c>();
        List<Opportunity_Split__c> oppSplitListToUpdate = new List<Opportunity_Split__c>();

        Set<Id> osIds = new Set<Id>();
        for(OpportunityTeamMember oppTeamMember : oppTeamMemberList)
        { 
            Boolean foundSplit = false;
            
            for(Opportunity_Split__c oppSplit : oppSplitList)
            {
                if(oppSplit.User__c == oppTeamMember.UserId)
                {
                    osIds.add(oppSplit.Id);
                    foundSplit = true;

                    if (oppSplit.Percentage__c == null) {
                        oppSplit.Percentage__c = 0;
                    }
                    OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                    oppSplitWrapper.oppSplit = oppSplit;
                    oppSplitWrapper.teamMember = oppTeamMember;
                    if (oppSplit.Percentage__c == null) {
                        oppSplit.Percentage__c = 0;
                    }

                    oppSplitWrapperList.add(oppSplitWrapper);
                    
                    // Daca Opportunity Owner are pe User rol care contine cuvantul "Partner" sau profil care contine "Partner" ---> la split sa se schimbe rolul din "Opportunity Owner" in "Partner Account Manager"
                    if (oppTeamMember.UserId == opportunityOwner.Id) {
                        if (opportunityOwner.Profile.Name.contains('Partner') || (oppTeamMember.User.UserRole != null && opportunityOwner.UserRole.Name.contains('Partner'))) {
                            if (oppSplit.Role__c == 'Opportunity Owner') {
                                oppSplit.Role__c = 'Partner Account Manager';
                                oppSplitListToUpdate.add(oppSplit);
                            }
                        } /*else {
                            if (oppSplit.Role__c == 'Partner Account Manager') {
                                oppSplit.Role__c = 'Opportunity Owner';
                                oppSplitListToUpdate.add(oppSplit);
                            }
                        }*/
                    }
                }
            }
            System.debug('Found split is: ' + foundSplit);
            System.debug('Role set contains test automation' + roleSet.contains('Test Automation Representative'));
            System.debug('Team member role is: ' + oppTeamMember.TeamMemberRole);
            if((oppTeamMember.Opportunity.Account_Geo__c == 'AMER' || oppTeamMember.Opportunity.Account_Geo__c == 'EMEA') 
                && oppTeamMember.TeamMemberRole == 'Partner Account Manager'
                && oppTeamMember.Created_on_opportunity_insert__c == true )
                foundSplit = true;
            // no opportunity split was found for this teamMember's User
            if(foundSplit == false)
            {
                Opportunity_Split__c oppSplit = new Opportunity_Split__c();
                oppSplit.User__c = oppTeamMember.UserId;

                // Opportunity Split for the opp owner will have assigned by default the percentage to 100%
                if(oppTeamMember.UserId == opportunityOwner.Id || oppTeamMember.TeamMemberRole == 'GSI Representative' || oppTeamMember.TeamMemberRole == 'Global Account Manager'
                        || oppTeamMember.TeamMemberRole == 'Test Automation Representative' || oppTeamMember.TeamMemberRole == 'EPS Representative'
                        || oppTeamMember.TeamMemberRole == 'Key Account Manager')
                {
                    oppSplit.Percentage__c = 100;
                    System.debug('I am inside the 100% rule');
                }
                else if(oppTeamMember.TeamMemberRole == 'Captive Sales Representative'){
                        oppSplit.Percentage__c = 25;
                        System.debug('I am inside the Captives rule');
                }
                else
                {
                    oppSplit.Percentage__c = 0;
                    System.debug('I am inside the 0% rule');
                }

                oppSplit.Opportunity__c = opportunityId;
                oppSplit.Role__c = oppTeamMember.TeamMemberRole;
                // Daca Opportunity Owner are pe User rol care contine cuvantul "Partner" sau profil care contine "Partner" ---> la split sa se schimbe rolul din "Opportunity Owner" in "Partner Account Manager"
                if (oppTeamMember.UserId == opportunityOwner.Id) {
                    if ( opportunityOwner.Profile.Name.contains('Partner') || 
                         (opportunityOwner.UserRole != null && opportunityOwner.UserRole.Name.contains('Partner'))) {
                        if (oppSplit.Role__c == 'Opportunity Owner') {
                            oppSplit.Role__c = 'Partner Account Manager';
                        }
                    }
                }

                oppSplitListToCreate.add(oppSplit);
            }
        }
        
        for(Opportunity_Split__c oppSplit : oppSplitList)
        {
            if(!osIds.contains(oppSplit.Id))
            {
                if (oppSplit.Percentage__c == null) {
                    oppSplit.Percentage__c = 0;
                }
                OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                oppSplitWrapper.oppSplit = oppSplit;
                oppSplitWrapper.teamMember = null;
                oppSplitWrapperList.add(oppSplitWrapper);
            }
        }
        boolean rebuild = false;
        
        if (oppSplitListToUpdate.size() > 0) {
            try 
            {
                update oppSplitListToUpdate;
            } 
            catch (Exception ex) 
            {
                ApexPages.addMessages(ex);
            }
            
            rebuild = true;
        }

        if(oppSplitListToCreate.size() > 0)
        {
            try 
            {
                insert oppSplitListToCreate;
            } 
            catch (Exception ex) 
            {
                ApexPages.addMessages(ex);
            }

            rebuild = true;
        }
        
        if (rebuild) {
            oppSplitList =
                [
                    SELECT User__r.Profile.Name, User__r.UserRole.Name, User__r.Goal_Master_Role__c,Id, Percentage__c, Included_in_Compensation__c, User__c, Opportunity__c, User__r.Name, Role__c, User__r.GIC_Sales__c
                    FROM Opportunity_Split__c
                    WHERE Opportunity__c = :opportunityId
                ];
            
            oppSplitWrapperList = new List<OppSplitWrapper>();
            osIds = new Set<Id>();

            for(OpportunityTeamMember oppTeamMember : oppTeamMemberList)
            { 
                for(Opportunity_Split__c oppSplit : oppSplitList)
                {
                    if(oppSplit.User__c == oppTeamMember.UserId)
                    {
                        osIds.add(oppSplit.Id);
                        if (oppSplit.Percentage__c == null) {
                            oppSplit.Percentage__c = 0;
                        }
                        OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                        oppSplitWrapper.oppSplit = oppSplit;
                        oppSplitWrapper.teamMember = oppTeamMember;

                        oppSplitWrapperList.add(oppSplitWrapper);
                    }
                }
            }
            for(Opportunity_Split__c oppSplit : oppSplitList)
            {
                if(!osIds.contains(oppSplit.Id))
                {
                    if (oppSplit.Percentage__c == null) {
                        oppSplit.Percentage__c = 0;
                    }
                    OppSplitWrapper oppSplitWrapper = new OppSplitWrapper();
                    oppSplitWrapper.oppSplit = oppSplit;
                    oppSplitWrapper.teamMember = null;
                    oppSplitWrapperList.add(oppSplitWrapper);
                }
            }
        }

        CheckIfWarningNeeded();
        CheckIfReadOnly();
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