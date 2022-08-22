public with sharing class DefaultDynamicApproverService implements IDynamicApproverService {
  /**
     * Custom metadata defines resolution groups and Field Maps
        Each group can map 1..N fields mapping fields on Quote to fields on DynamicApprover__c object
        Query Custom Metadata finding all Groups and Mapped fields
        Consolidate and Query All Quote Fields needed for resolving approvers
        Loop passes and issue a separate SOQL on the Dynamic Approvers object for each pass matching all fields in the Map
        Each iteration of the loop can potentially resolve any number of approvers
     *
     * @param quoteId
     *
     * @return Quote with all dynamic Approvers set
     * Quote not persisted to DB
     */
  public SBQQ__Quote__c populateDynamicApprover(Id quoteId) {
    SBQQ__Quote__c quote = getQuoteWithApproverResolutionFields(quoteId);

    Map<Integer, String> resolverGroups = getDistinctResolverGroups();

    for (Integer groupOrder : resolverGroups.keySet()) {
      String dynamicApproverQuery = getDynamicApproverQuery(quote, resolverGroups.get(groupOrder));
      System.debug('SOQL for resolving approvers : ' + dynamicApproverQuery);

      List<DynamicApprover__c> dynamicApprovers = new List<DynamicApprover__c>();

      try {
        dynamicApprovers = Database.query(dynamicApproverQuery);
      } catch (Exception e) {
        System.debug('Error during SOQL execution: ' + dynamicApproverQuery);
      }

      //For each role in dynamicApprovers, find API field name from mdt and then set that field to the approver
      Map<String, Approver_Mapping__mdt> approverMetadataMap = getRoleApproverMetadataMap();
      for (DynamicApprover__c dynamicApprover : dynamicApprovers) {
        String approverFieldApiName = approverMetadataMap.get(dynamicApprover.Role__c).Dynamic_Approver_Field_API__c;
        System.debug(
          'Setting Approver for Role ' +
          approverFieldApiName +
          '  using Rule ' +
          resolverGroups.get(groupOrder)
        );
        quote.put(approverFieldApiName, dynamicApprover.Approver__c);
      }
    }

    return quote;
  }

  private SBQQ__Quote__c getQuoteWithApproverResolutionFields(Id quoteId) {
    String quoteFieldsCSV = String.join(new List<String>(getQuoteApproverResolutionFields()), ',');
    if (quoteFieldsCSV.length() == 0) {
      quoteFieldsCSV = 'Name';
    }
    String quoteQuery = 'SELECT  Id,' + quoteFieldsCSV + ' FROM SBQQ__Quote__c WHERE Id = :quoteId';
    SBQQ__Quote__c quote = Database.query(quoteQuery);
    return quote;
  }

  private String getDynamicApproverQuery(SBQQ__Quote__c quote, String groupName) {
    String dynamicApproverFields = String.join(new List<String>(getDynamicApproverResolutionFields()), ',');
    String dynamicApproverQuery =
      'SELECT  Id, Role__c, Approver__c, ' +
      dynamicApproverFields +
      ' FROM DynamicApprover__c WHERE ';

    Map<Integer, String> resolverGroups = getDistinctResolverGroups();
    String dynamicApproverWhereClause = '';
    Map<String, String> fieldMaps = getMappingForGroup(groupName);
    for (String quoteField : fieldMaps.keySet()) {
      System.debug('>>>>> Quote field ' + quoteField + ' maps to Dynamic Approver field ' + fieldMaps.get(quoteField));
      List<String> splitQuoteFields = getSplitFields(quoteField);
      String quoteFieldValue = getFieldValue(splitQuoteFields, quote);

      // Set to value that will never match to avoid blank values matching
      if ((String.isBlank(quoteFieldValue))) {
        quoteFieldValue = 'X_X';
      }
      dynamicApproverWhereClause +=
        fieldMaps.get(quoteField) +
        '=\'' +
        (splitQuoteFields.size() == 0 ? quote.get(quoteField) : quoteFieldValue) +
        '\' AND ';
    }
    dynamicApproverQuery = dynamicApproverQuery + dynamicApproverWhereClause.removeEnd('AND ');
    return dynamicApproverQuery;
  }

  private List<String> getSplitFields(String fullFieldName) {
    return fullFieldName.split('\\.');
  }

  /**
   * Parse field value for field expr specified in dot notation
   *
   * @param splitFieldNames
   * @param obj
   *
   * @return parsed field value. Throws exception if unable to parse
   */
  private String getFieldValue(List<String> splitFieldNames, SObject obj) {
    if (splitFieldNames.size() == 1) {
      return (String) obj.get(splitFieldNames.get(0));
    } else if (splitFieldNames.size() == 2) {
      if (obj.getSObject(splitFieldNames.get(0)) == null) {
        return '';
      }
      return (String) ((obj.getSObject(splitFieldNames.get(0)))).get(splitFieldNames.get(1));
    } else if (splitFieldNames.size() == 3) {
      if (
        (obj.getSObject(splitFieldNames.get(0)) != null) &&
        ((obj.getSObject(splitFieldNames.get(0))).getSObject(splitFieldNames.get(1)) != null)
      ) {
        return (String) ((obj.getSObject(splitFieldNames.get(0))))
          .getSObject(splitFieldNames.get(1))
          .get(splitFieldNames.get(2));
      } else {
        return '';
      }
    } else if (splitFieldNames.size() == 4) {
      if (
        (obj.getSObject(splitFieldNames.get(0)) != null) &&
        ((obj.getSObject(splitFieldNames.get(0))).getSObject(splitFieldNames.get(1)) != null) &&
        ((obj.getSObject(splitFieldNames.get(0))))
          .getSObject(splitFieldNames.get(1))
          .getSObject(splitFieldNames.get(2)) != null
      ) {
        return (String) ((obj.getSObject(splitFieldNames.get(0))))
          .getSObject(splitFieldNames.get(1))
          .getSObject(splitFieldNames.get(2))
          .get(splitFieldNames.get(3));
      } else {
        return '';
      }
    } else {
      throw new ApproverResolutionException('Unable to parse value for Field  ' + String.join(splitFieldNames, '.'));
    }
  }

  /**
   * Retreives all the fields on the Quote that are used to resolve Dynamic Approvers
   *
   *
   * @return set of field names that drive approvals
   */
  private Set<String> getQuoteApproverResolutionFields() {
    List<DynamicApproverResolver__mdt> approverResolver = [SELECT QuoteField__c FROM DynamicApproverResolver__mdt];
    //Get unique Fields on the Quote object related that should trigger re-approval when modified
    Set<String> distinctFields = new Set<String>();
    for (DynamicApproverResolver__mdt dynamicApproverResolver : approverResolver) {
      distinctFields.add(dynamicApproverResolver.QuoteField__c);
    }

    return distinctFields;
  }

  /**
   * Retreives all the fields on Dynamic Approver Object that are used to resolve Dynamic Approvers
   *
   *
   * @return set of field names that drive approvals
   */
  private Set<String> getDynamicApproverResolutionFields() {
    List<DynamicApproverResolver__mdt> approverResolver = [
      SELECT DynamicApproverField__c
      FROM DynamicApproverResolver__mdt
    ];
    //Get unique Fields on the Quote object related that should trigger re-approval when modified
    Set<String> distinctFields = new Set<String>();
    for (DynamicApproverResolver__mdt dynamicApproverResolver : approverResolver) {
      distinctFields.add(dynamicApproverResolver.DynamicApproverField__c);
    }

    return distinctFields;
  }

  /**
   * Retreives all Resolver Groups
   *
   *
   * @return all Resolver Groups configured in metadata
   */
  private Map<Integer, String> getDistinctResolverGroups() {
    List<DynamicApproverResolver__mdt> approverResolver = [
      SELECT ResolverGroup__c, ResolverGroupOrder__c
      FROM DynamicApproverResolver__mdt
      ORDER BY ResolverGroupOrder__c ASC
    ];
    Map<Integer, String> resolverGroups = new Map<Integer, String>();
    for (DynamicApproverResolver__mdt dynamicApproverResolver : approverResolver) {
      resolverGroups.put(
        Integer.valueOf(dynamicApproverResolver.ResolverGroupOrder__c),
        dynamicApproverResolver.ResolverGroup__c
      );
    }

    return resolverGroups;
  }

  /**
   * Retreives field mapping for a given group
   *
   *
   * @return field mapping of quotefield, dynamicapproverfield for a given resovler group configured in metadata
   */
  private Map<String, String> getMappingForGroup(String groupName) {
    List<DynamicApproverResolver__mdt> approverResolver = [
      SELECT QuoteField__c, DynamicApproverField__c
      FROM DynamicApproverResolver__mdt
      WHERE ResolverGroup__c = :groupName
    ];
    Map<String, String> approverMap = new Map<String, String>();
    for (DynamicApproverResolver__mdt dynamicApproverResolver : approverResolver) {
      approverMap.put(dynamicApproverResolver.QuoteField__c, dynamicApproverResolver.DynamicApproverField__c);
    }
    return approverMap;
  }

  /**
   * Retreives a map of Approver info for each Role
   *
   *
   * @return
   */
  private Map<String, Approver_Mapping__mdt> getRoleApproverMetadataMap() {
    //fetch Approver Mappings
    List<Approver_Mapping__mdt> mappingList = [
      SELECT
        Id,
        DeveloperName,
        MasterLabel,
        Dynamic_Approver_Field_API__c,
        Dynamic_Approver_Role__c,
        Static_Approver_Name__c,
        Type__c,
        Label
      FROM Approver_Mapping__mdt
      WHERE Type__c = 'Dynamic Approver'
    ];
    Map<String, Approver_Mapping__mdt> roleApproverMetadataMap = new Map<String, Approver_Mapping__mdt>();
    for (Approver_Mapping__mdt approverMapping : mappingList) {
      roleApproverMetadataMap.put(approverMapping.Dynamic_Approver_Role__c, approverMapping);
    }
    return roleApproverMetadataMap;
  }

  /**
   * populate dynamic approver fields on Quote
   */
  public List<SBQQ__Quote__c> populateDynamicApprovers(List<Id> quoteIdList) {
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    for (Id id : quoteIdList) {
      quotes.add(this.populateDynamicApprover(id));
    }
    return quotes;
  }

  // custom exception class
  public class ApproverResolutionException extends Exception {
  }
}