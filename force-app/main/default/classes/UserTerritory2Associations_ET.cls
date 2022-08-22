/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is UserTerritory2Association object domain class
 */
public without sharing class UserTerritory2Associations_ET extends fflib_SObjectDomain {
  UserTerritory2AssociationsService_ET service = (UserTerritory2AssociationsService_ET) Application_ET.Service.newInstance(
    UserTerritory2AssociationsService_ET.class
  );

  public UserTerritory2Associations_ET(List<UserTerritory2Association> userTerritory2Associations) {
    super(userTerritory2Associations, Schema.UserTerritory2Association.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    service.validateUserTerritory2Association(getRecords());
    service.validatePartnerManagerRoles(getRecords(), null);
  }

  public override void onAfterInsert() {
    service.processUserAssociationUpdate(null, getRecords());
    service.setRecalculateCompensationFlag(getRecords(), null);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    service.validateUserTerritory2Association(getRecords());
    service.validatePartnerManagerRoles(getRecords(), (Map<Id, UserTerritory2Association>) existingRecords);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>{ UserTerritory2Association.RoleInTerritory2 };
    service.processUserAssociationUpdate(
      (Map<Id, UserTerritory2Association>) existingRecords,
      (List<UserTerritory2Association>) getChangedRecords(fields)
    );
    service.setRecalculateCompensationFlag(getRecords(), (Map<Id, UserTerritory2Association>) existingRecords);
  }

  public override void onAfterDelete() {
    service.processUserAssociationDelete(getRecords(), true);
    service.setRecalculateCompensationFlag(getRecords(), null);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new UserTerritory2Associations_ET(sObjectList);
    }
  }
}