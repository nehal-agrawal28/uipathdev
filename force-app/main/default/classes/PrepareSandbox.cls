/**
 * Class to run post-script actions for sandbox creation or refresh
 */
public class PrepareSandbox implements SandboxPostCopy {

    /**
     * invocation during sandbox spin up
     *
     * @param context the post-refresh script context
     */
    public void runApexClass(SandboxContext context) {

        createUsers(context.sandboxName());
    }

    /**
     * Can be executed using anonymous apex in existing sandboxes
     */
    public static void createUsers(){

        createUsers(null);

    }

    /**
     * Creates or updates sandbox users according to the email addresses stored in sandboxUsers custom metadata
     *
     * @param sandboxContextName the sandbox name if available from the sandbox context
     */
    @TestVisible
    private static void createUsers(String sandboxContextName){
        
        //maximum user email len = 69 (max username (80) - (max sandbox name (10) + period (1)))
		Integer MAX_USER_EMAIL_LEN = 69; 

        //only execute in a sandbox or a test
        if(!runningInASandbox() && !Test.isRunningTest()){
            return;
        }

        //retrieve the metadata
        SandboxUsers__mdt sandboxUsers = [SELECT Id, Users__c FROM SandboxUsers__mdt LIMIT 1];

        //the list of email addresses for users
        List<String> usersEmails = sandboxUsers.Users__c.split(',');

        //set of email addresses for users - keeps running list of users to update/create
        Set<String> usersEmailsSet = new Set<String>(usersEmails);
        
        //0. remove any email addresses that might be too long
        for(String s : usersEmailsSet){
            if(s.length() > MAX_USER_EMAIL_LEN){
                usersEmailsSet.remove(s);
            }
        }


        //1. Remove existing - check to see if any users have already had .invalid suffix stripped (eg. they initiated the sandbox refresh) and remove//
        for(User u : [select id, email from user where email in :usersEmailsSet]){
            usersEmailsSet.remove(u.Email);
        }
        //


        //2. Update existing - for remaining users create a companion list and set for user emails with the .invalid suffix  (eg. they exist in production and have suffix applied)
        List<String> usersEmailsListInvalid = new List<String>();

        for(String s : usersEmailsSet){
            usersEmailsListInvalid.add(s+'.invalid');
        }

        Set<String> usersEmailsInvalid = new Set<String>(usersEmailsListInvalid);


        //list of users found in the sandbox to update
        List<User> usersToUpdate = new List<User>();


        //check for users with the .invalid suffix and then remove the .invalid from their email address
        for(User u : [select id, email from user where email in :usersEmailsListInvalid]){
            //usersEmailsInvalid.remove(u.Email);
            u.email = u.email.substringBefore('.invalid');
            usersEmailsSet.remove(u.Email);
            usersToUpdate.add(u);
        }

        //


        //3. Create new users - for remaining email addresses, prep inserts//
        List<User> usersToCreate = new List<User>();

        String sandboxName;
        Id sysAdmId;

        //set sandbox context using context var or the running user
        if(sandboxContextName != null){
            sandboxName = sandboxContextName;
            sysAdmId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        }
        else{
            sandboxName = UserInfo.getUserName().substringAfterLast('.');
            sysAdmId = UserInfo.getProfileId();
        }
        


        //check context vars are set
        if(sandboxName != null && sysAdmId != null){

            //for the remaining users to create
            for(String userE : usersEmailsSet){

                //extract first and last name from email address
                String[] names = userE.split('\\.');
                
                String alias = userE.substringBefore('@') + String.valueOf(System.today());
                alias = alias.right(8);
                

                User u = new User(
                        Alias = alias,
                        Username = userE + '.' +sandboxName,
                        Email = userE,
                        FirstName = names[0],
                        LastName = names[1].substringBefore('@'),
                        LOCALESIDKEY = 'en_US',
                        LANGUAGELOCALEKEY= 'en_US',
                        EMAILENCODINGKEY='ISO-8859-1',
                        TIMEZONESIDKEY='Europe/London',
                        CURRENCYISOCODE='USD',
                        ProfileId=sysAdmId,
                        IsActive=true
                );

                usersToCreate.add(u);
            }

			
            //DML//

            if(usersToUpdate.size() > 0){
                Database.Update(usersToUpdate);
            }


            if(usersToCreate.size() > 0){
                Database.insert(usersToCreate);

            }

            //
        }
    }

    /**
     * Utility method to check env type
     *
     * @return boolean whether the running org is a sandbox
     */
    private static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}