global class FlowToApexQueries_ET {
  @InvocableMethod(label='Get User Territory Associations' description='Get User Territory Associations')
  public static List<List<Response_ET>> getUserTerritory2Associations(List<Request> req) {
    Set<Id> setOfTerritory2Ids = new Set<Id>();
    List<List<Response_ET>> outputResponse = new List<List<Response_ET>>();
    List<Response_ET> responseList = new List<Response_ET>();
    UserTerritory2AssociationsSelector_ET userAssociationSelector = (UserTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
      UserTerritory2Association.getSObjectType()
    );

    List<Id> listOfTerritory2Ids = req[0].listOfTerritory2Ids;
    if (!listOfTerritory2Ids.isEmpty() && listOfTerritory2Ids.size() > 0) {
      setOfTerritory2Ids.addAll(listOfTerritory2Ids);
      Response_ET response = new Response_ET();
      response.listOfUserTerritory2Associations = userAssociationSelector.selectByRoleInTerritory(
        setOfTerritory2Ids,
        new Set<String>{
          ETMConstant.GSI_PARTNER_MANAGER,
          ETMConstant.STRATEGIC_PARTNER_MANAGER,
          ETMConstant.GLOBAL_GSI_ALLI_PART_MANAGER,
          ETMConstant.DISTRIBUTION_PARTNER_MANAGER,
          ETMConstant.SEC_GSI_PARTNER_MANAGER,
          ETMConstant.GLOBAL_GSI_PARTNER_MANAGER,
          ETMConstant.JAPAN_REGION_PARTNER_MANAGER,
          ETMConstant.PRIMARY_ACCOUNT_MANAGER,
          ETMConstant.INTERIM_ACCOUNT_MANAGER,
          ETMConstant.REGION_PARTNER_MANAGER
        }
      );
      responseList.add(response);
    }
    outputResponse.add(responseList);
    return outputResponse;
  }

  public class Request {
    @InvocableVariable(required=true)
    public List<Id> listOfTerritory2Ids;
  }
}