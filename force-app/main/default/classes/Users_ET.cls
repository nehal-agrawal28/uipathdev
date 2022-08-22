/**
 * @AUTHOR: UIPath
 * @DATE: 21/10/2021
 * @DESCRIPTION: This is domain class for User. Used for ETM.
 */
public without sharing class Users_ET extends fflib_SObjectDomain {
  public Users_ET(List<User> records) {
    super(records, User.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ User.IsActive };

    List<User> changedUsers = getChangedRecords(fields);

    UsersService_ET userService = (UsersService_ET) Application_ET.Service.newInstance(UsersService_ET.class);
    userService.validateUsers(changedUsers);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Users_ET(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new Users_ET(sObjectList);
    }
  }
}