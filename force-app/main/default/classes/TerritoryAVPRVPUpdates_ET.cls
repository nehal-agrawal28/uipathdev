/**
 * @AUTHOR: UIPath
 * @DATE: 30/05/2022
 * @DESCRIPTION: This is class to update AVP RVP on Parnter Territories
 */
public class TerritoryAVPRVPUpdates_ET implements IGenericBatch {
  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    List<Territory2> territoryList = (List<Territory2>) sobjectList;
    Set<Id> lstUserIds = new Set<Id>();
    Set<Id> lstTerrIds = new Set<Id>();
    Map<Id, User> mapUserIdtoUser = new Map<Id, User>();
    List<User> lstuserDetails = new List<User>();
    Map<Id, List<UserTerritory2Association>> TerrAssMap = new Map<Id, List<UserTerritory2Association>>();

    for (Territory2 terrObj : territoryList) {
      lstTerrIds.add(terrObj.Id);
    }

    UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.SObjectType
    );

    UsersSelector_ET userSelector = (UsersSelector_ET) Application_ET.Selector.newInstance(User.SObjectType);

    List<UserTerritory2Association> userAssociationList = userAssociationSelector.selectByRoleInTerritory(
      lstTerrIds,
      new Set<String>{ ETMConstant.PARTNER_LEADER }
    );

    for (UserTerritory2Association userAssociation : userAssociationList) {
      if (TerrAssMap.containsKey(userAssociation.Territory2Id)) {
        TerrAssMap.get(userAssociation.Territory2Id).add(userAssociation);
      } else {
        TerrAssMap.put(userAssociation.Territory2Id, new List<UserTerritory2Association>{ userAssociation });
        lstUserIds.add(userAssociation.UserId);
      }
    }

    //fetch user Name from user Ids
    if (lstUserIds.size() > 0) {
      lstuserDetails = userSelector.selectById(lstUserIds);
    }

    for (User u : lstuserDetails) {
      mapUserIdtoUser.put(u.Id, u);
    }

    for (Territory2 terr : territoryList) {
      if (TerrAssMap.containsKey(terr.Id)) {
        for (UserTerritory2Association terrUta : TerrAssMap.get(terr.Id)) {
          if (terr.Sales_Area__c == true) {
            terr.AVP_Id__c = terrUta.UserId;
            terr.AVP_Name__c = mapUserIdtoUser.containsKey(terrUta.UserId)
              ? mapUserIdtoUser.get(terrUta.UserId).Name
              : null;
          }

          if (terr.Sales_Region__c == true) {
            terr.RVP_Id__c = terrUta.UserId;
            terr.RVP_Name__c = mapUserIdtoUser.containsKey(terrUta.UserId)
              ? mapUserIdtoUser.get(terrUta.UserId).Name
              : null;
          }
        }
      }
    }
    try {
      Database.SaveResult[] updateTerrLst = Database.update(territoryList, false);
      Logger.debug(new LogMessage('Partner Territory  AVP RVP Result', ''), updateTerrLst);
    } catch (Exception ex) {
      Logger.debug(new LogMessage('Partner Territory  AVP RVP failed', ex.getLineNumber()));
    } finally {
      logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
  }
}