/**
 * File Name: Quotes_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public with sharing class Quotes_PP extends fflib_SObjectDomain implements IQuotes_PP {
  public Quotes_PP(List<SBQQ__Quote__c> records) {
    super(records, Schema.SBQQ__Quote__c.SObjectType);
  }

  public static IQuotes_PP newInstance(Set<Id> ids) {
    return (IQuotes_PP) Application_PP.Domain.newInstance(ids);
  }

  public static IQuotes_PP newInstance(List<SBQQ__Quote__c> records) {
    return (IQuotes_PP) Application_PP.Domain.newInstance(records, Schema.SBQQ__Quote__c.SObjectType);
  }

  public Set<Id> getAccountIds() {
    Set<Id> result = new Set<Id>();
    result = Utilities_PP.pluckIdField(getQuotes(), SBQQ__Quote__c.SBQQ__Account__c);
    return result;
  }

  public Set<Id> getDistributorIds() {
    Set<Id> result = new Set<Id>();
    result = Utilities_PP.pluckIdField(getQuotes(), SBQQ__Quote__c.SBQQ__Distributor__c);
    return result;
  }

  public Set<Id> getPartnerIds() {
    Set<Id> result = new Set<Id>();
    result = Utilities_PP.pluckIdField(getQuotes(), SBQQ__Quote__c.SBQQ__Partner__c);
    return result;
  }

  public List<SBQQ__Quote__c> getQuotes() {
    return (List<SBQQ__Quote__c>) getRecords();
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Quotes_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new Quotes_PP(sObjectList);
    }
  }
}