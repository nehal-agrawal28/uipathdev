// Author Charlie Jonas (charlie@callaway.cloud)
// Class to clone an SObject and it's children.
//   - Not currently optimized for bulk use!
//   See https://github.com/ChuckJonas/SObjectDeepClone for readme
public with sharing class SObjectDeepClone {
  private Map<String, ChildRelationshipProps> relationshipMap;
  private SObjectType type;
  // Save opertion result wrapper
  public class SaveResult {
    public SObject clone { get; set; }
    public Map<String, List<SObject>> cloneChildren { get; set; }
  }

  //The SObject that will be cloned. Accessible so modications can be made prior to saving
  public SObject clone;

  /**
   * @description Constructor to query object
   * @param toCloneId: Id to clone.  All creatable fields will be pulled
   * @param relationshipsToClone: Child Relationship names
   */
  public SObjectDeepClone(Id toCloneId, Set<String> relationshipsToClone) {
    type = toCloneId.getSObjectType();
    mapStringsToRelations(relationshipsToClone);
    retrieveSObject(toCloneId);
  }

  /**
   * @description Constructor without object query.  Allows more control of cloning
   * @param toClone: SObject to clone.  Must include all relevant information
   * @param relationshipsToClone: Child Relationship names
   */
  public SObjectDeepClone(SObject toClone, Set<String> relationshipsToClone) {
    type = toClone.getSObjectType();
    mapStringsToRelations(relationshipsToClone);
    this.clone = toClone;
  }

  /**
   * @description Saves the Cloned SObject
   */
  public SaveResult save(Boolean skipChildrenSave) {
    // setup the save point for rollback
    Savepoint sp = Database.setSavepoint();

    try {
      insert clone;
      Map<String, List<SObject>> cloneChildren = new Map<String, List<SObject>>();

      for (String relationshipName : this.relationshipMap.keySet()) {
        SObject[] clonedChildren = new List<SObject>{};
        ChildRelationshipProps rel = this.relationshipMap.get(relationshipName);
        for (Sobject child : clone.getSObjects(relationshipName)) {
          SObject childClone = child.clone(false);
          childClone.put(rel.field, clone.Id);
          clonedChildren.add(childClone);
        }

        if (skipChildrenSave == false) {
          insert clonedChildren;
        }
        cloneChildren.put(relationshipName, clonedChildren);
      }
      SaveResult result = new SaveResult();
      result.clone = clone;
      result.cloneChildren = cloneChildren;
      return result;
    } catch (Exception e) {
      Database.rollback(sp);
      throw e;
    }
  }
  /**
   * @description Saves the Cloned SObject and Children
   */
  public SaveResult save() {
    return this.save(false);
  }

  private void mapStringsToRelations(Set<String> relationshipStrings) {
    this.relationshipMap = new Map<string, ChildRelationshipProps>();
    Map<String, ChildRelationship> childRelationMap = new Map<String, ChildRelationship>();
    for (ChildRelationship rel : type.getDescribe().getChildRelationships()) {
      String relName = rel.getRelationshipName();
      if (relName != null) {
        //not sure why this would happen but it does
        childRelationMap.put(rel.getRelationshipName().toUpperCase(), rel);
      }
    }

    for (String relStr : relationshipStrings) {
      relStr = relStr.toUpperCase();
      if (childRelationMap.containsKey(relStr)) {
        ChildRelationship rel = childRelationMap.get(relStr);
        relationshipMap.put(rel.getRelationshipName().toUpperCase(), new ChildRelationshipProps(rel));
      } else {
        throw new DeepCloneException(
          'Child Relationship \'' +
          relStr +
          '\' does not exsist on ' +
          type.getDescribe().getName()
        );
      }
    }
  }

  private void retrieveSObject(Id toCloneId) {
    // Get a map of field name and field token
    String[] selectFields = getCreatableFields(type);

    //subqueries
    for (String relationName : this.relationshipMap.keySet()) {
      ChildRelationshipProps rel = this.relationshipMap.get(relationName);
      String[] relationFields = getCreatableFields(rel.sObjectType);
      if (relationFields.size() > 0) {
        selectFields.add('(' + buildQuery(relationFields, relationName, null) + ')');
      }
    }

    String qry = buildQuery(
      selectFields,
      type.getDescribe().getName(),
      'ID = \'' +
      String.escapeSingleQuotes(toCloneId) +
      '\''
    );

    this.clone = ((SObject) Database.query(qry)).clone(false);
  }

  private string buildQuery(String[] fields, String fromObj, string whereClause) {
    String qry = 'SELECT ' + String.join(fields, ',') + ' FROM ' + fromObj;
    if (!String.isEmpty(whereClause)) {
      qry += ' WHERE ' + whereClause;
    }
    return qry;
  }

  private String[] getCreatableFields(SObjectType objType) {
    DescribeSObjectResult describe = objType.getDescribe();

    // Get a map of field name and field token
    Map<String, Schema.SObjectField> fMap = describe.Fields.getMap();
    String[] selectFields = new List<String>{};

    if (fMap != null) {
      for (Schema.SObjectField ft : fMap.values()) {
        // loop through all field tokens (ft)
        Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
        if (fd.isCreateable()) {
          // field is creatable
          selectFields.add(fd.getName());
        }
      }
    }
    return selectFields;
  }

  //seralizable subset of ChildRelationship properties that we need
  private class ChildRelationshipProps {
    public SObjectType sObjectType;
    public SObjectField field;
    public ChildRelationshipProps(ChildRelationship rel) {
      this.sObjectType = rel.getChildSObject();
      this.field = rel.getField();
    }
  }

  public class DeepCloneException extends Exception {
  }
}