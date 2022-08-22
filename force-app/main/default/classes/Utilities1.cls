/**
* Using without sharing as need to run query on Organization table
*/
public without sharing class Utilities1 {
    
    //Get instance from INSTANCE.visual.force.com page so we can build
    public Static String getInstance(){
        String instance = '';
        Organization o = [SELECT OrganizationType, InstanceName FROM Organization limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;
        if(orgType == 'Enterprise Edition' || insName.startsWithIgnoreCase('NA')){
            
            List<String> parts = ApexPages.currentPage().getHeaders().get('Host').split('\\.');
            system.debug('getInstance--CurURL'+ApexPages.currentPage().getHeaders().get('Host'));
            system.debug('getInstance--parts'+ parts);
            //Changed by Dharani-warpdrivetech 
            if(parts.size()==4)
            {
                instance = parts[parts.size() - 4] + '.';
            }
            else
            {
                instance = parts[parts.size() - parts.size()] + '.';
            }
            
            system.debug('getInstance--instance'+ instance);
        }
        return instance;
    }
    //Needed in cases if current org is sandbox
    public static String getSubdomainPrefix(){
        system.debug('i am getting called-----');
        Organization o = [SELECT OrganizationType, InstanceName FROM Organization limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;
        system.debug('InstanceName--'+o.InstanceName);
        system.debug('getUserName--'+UserInfo.getUserName().substringAfterLast('.'));
        if(insName.startsWithIgnoreCase('NA')){
            return UserInfo.getUserName().substringAfterLast('.')+ '-';
            //return 'servcloud'+'-';
        }
        return '';
    }
}