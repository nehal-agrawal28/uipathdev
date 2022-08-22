public without sharing class Users_PP extends fflib_SObjectDomain {
  private static String GLOBAL_PARTNER_PORTAL_GROUP = 'GlobalPartnerPortalUsers';

  public Users_PP(List<User> records) {
    super(records, User.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterInsert() {
    selectPartnerCommunityUsers().assignGroup(GLOBAL_PARTNER_PORTAL_GROUP);
    selectPartnerCommunityUsers().sharePartner();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    onChangedProfile().processCommunityProfileUpdate();
  }

  private Users_PP selectPartnerCommunityUsers() {
    Map<Id, String> profileNameById = getPartnerProfileByName();
    List<User> communityUsers = new List<User>();
    for (User user : (List<User>) Records) {
      if (profileNameById.containsKey(user.ProfileId)) {
        communityUsers.add(user);
      }
    }

    return new Users_PP(communityUsers);
  }

  public void assignGroup(String groupName) {
    AbstractQueueable.enqueue(new AssignGroupAction_PP((List<User>) Records, groupName));
  }

  public void sharePartner() {
    AbstractQueueable.enqueue(new SharePartnerToUser_PP((List<User>) Records));
  }

  public Users_PP onChangedProfile() {
    List<SObject> changedRecords = getChangedRecords(new Set<Schema.SObjectField>{ User.ProfileId });

    return new Users_PP(changedRecords);
  }

  private Map<Id, String> getPartnerProfileByName() {
    final ProfilesSelector_PP profilesSelector = (ProfilesSelector_PP) Application_PP.Selector.newInstance(
      Profile.SObjectType
    );
    final List<Profile> communityProfiles = profilesSelector.elevatedSelectByName(
      new Set<String>{
        System.Label.UiPath_Partner_Comm_Admin_Profile_Name,
        System.Label.UiPath_Partner_Comm_Content_User_Profile_Name,
        System.Label.UiPath_Partner_Comm_Manager_Profile_Name,
        System.Label.UiPath_Partner_Comm_User_Profile_Name,
        System.Label.UiPath_Partner_Comm_User_Profile_Name_Non_Login
      }
    );

    final Map<Id, String> profileNameById = new Map<Id, String>{};
    for (Profile communityProfile : communityProfiles) {
      profileNameById.put(communityProfile.Id, communityProfile.Name);
    }

    return profileNameById;
  }

  private void processCommunityProfileUpdate() {
    Map<Id, String> profileNameById = getPartnerProfileByName();

    final Set<String> userCommunityRoleNames = new Set<String>{};
    for (User changedUser : (List<User>) Records) {
      userCommunityRoleNames.add(changedUser.ContactAccountName__c + ' Partner User');
      userCommunityRoleNames.add(changedUser.ContactAccountName__c + ' Partner Manager');
    }

    final Map<String, Id> userRoleIdByName = new Map<String, Id>{};
    final UserRolesSelector_PP userRolesSelector = (UserRolesSelector_PP) Application_PP.Selector.newInstance(
      UserRole.SObjectType
    );
    for (UserRole communityRole : userRolesSelector.selectByName(userCommunityRoleNames, false)) {
      userRoleIdByName.put(communityRole.Name, communityRole.Id);
    }

    for (User changedUser : (List<User>) Records) {
      if (profileNameById.containsKey(changedUser.ProfileId)) {
        final String partnerUserRoleName = (changedUser.ContactAccountName__c + ' Partner User');
        final String partnerManagerRoleName = (changedUser.ContactAccountName__c + ' Partner Manager');

        final String profileName = profileNameById.get(changedUser.ProfileId);
        if (
          profileName.equalsIgnoreCase(System.Label.UiPath_Partner_Comm_User_Profile_Name) ||
          profileName.equalsIgnoreCase(System.Label.UiPath_Partner_Comm_Content_User_Profile_Name)
        ) {
          changedUser.UserRoleId = userRoleIdByName.get(partnerUserRoleName);
        } else if (profileName.equalsIgnoreCase(System.Label.UiPath_Partner_Comm_Manager_Profile_Name)) {
          changedUser.UserRoleId = userRoleIdByName.get(partnerManagerRoleName);
        }
      }
    }
  }

  public Set<Id> getAccountIds() {
    return Utilities_PP.pluckIdField(getRecords(), User.AccountId);
  }

  public Set<Id> getManagerIds() {
    return Utilities_PP.pluckIdField(getRecords(), User.ManagerId);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Users_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new Users_PP(sObjectList);
    }
  }
}