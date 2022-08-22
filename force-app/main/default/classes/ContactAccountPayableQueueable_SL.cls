/**
 * SLTECH-33969 : Set Account Payable contact on the Account record
 */
public with sharing class ContactAccountPayableQueueable_SL extends AbstractQueueable {
  private Map<Id, Account> accountWithRelationshipMap;
  private Set<Id> accIdToProcess = new Set<Id>();

  public ContactAccountPayableQueueable_SL(List<SObject> contactsLst, List<Id> accountIds) {
    super('ContactAccountPayableQueueable_SL');
    //to allow for logging against record. only used in non-bulk contexts
    if (contactsLst != null && contactsLst.size() == 1) {
      this.setPrimaryRecordId(contactsLst.get(0).Id);
    }

    accIdToProcess.addAll(accountIds);
    this.constructRelationshipMap(contactsLst);
  }

  public ContactAccountPayableQueueable_SL(List<SObject> contactsLst) {
    super('ContactAccountPayableQueueable_SL');
    //to allow for logging against record. only used in non-bulk contexts
    if (contactsLst != null && contactsLst.size() == 1) {
      this.setPrimaryRecordId(contactsLst.get(0).Id);
    }

    this.constructRelationshipMap(contactsLst);
  }

  private void constructRelationshipMap(List<SObject> contactsLst) {
    for (AccountContactRelation accountContact : [
      SELECT AccountId
      FROM AccountContactRelation
      WHERE ContactId IN :contactsLst
    ]) {
      accIdToProcess.add(accountContact.AccountId);
    }

    this.accountWithRelationshipMap = new Map<Id, Account>(
      [
        SELECT
          Id,
          (
            SELECT Id, ContactId
            FROM AccountContactRelations
            WHERE Contact.Role__c = 'Accounts Payable'
            ORDER BY LastModifiedDate DESC
          )
        FROM Account
        WHERE Id IN :accIdToProcess
      ]
    );
  }

  public override void work() {
    this.updateAPContactOnAccounts();
  }

  private void updateAPContactOnAccounts() {
    List<Account> accountsToUpdate = new List<Account>();
    for (Account acc : this.accountWithRelationshipMap.values()) {
      Account accToUpdate = new Account(Id = acc.Id);

      if (acc.AccountContactRelations != null && acc.AccountContactRelations.size() > 0) {
        accToUpdate.AP_Contact__c = acc.AccountContactRelations.get(0).ContactId;
      } else {
        accToUpdate.AP_Contact__c = null;
      }
      accountsToUpdate.add(accToUpdate);
    }
    update accountsToUpdate;
  }

  /**
   * Set Account Payable on Parent Account
   */
  public static void setAccountPayablesOnInsert(List<Contact> contactsLst) {
    List<Contact> eligibleContacts = (List<Contact>) Collection.of(contactsLst)
      .filter(Match.field(Contact.Role__c).equals('Accounts Payable'))
      .asList();

    if (!eligibleContacts.isEmpty()) {
      AbstractQueueable.enqueue(new ContactAccountPayableQueueable_SL(eligibleContacts));
    }
  }
  public static void setAccountPayablesOnUpdate(List<Contact> contactsLst, Map<Id, SObject> oldContactsMap) {
    ContactAccountPayableQueueable_SL.ContactAccountPayableCheck contactAccountPayableCheck = new ContactAccountPayableQueueable_SL.ContactAccountPayableCheck(
      contactsLst,
      oldContactsMap
    );
    List<Contact> eligibleContacts = (List<Contact>) Collection.of(contactsLst)
      .filter(contactAccountPayableCheck)
      .asList();

    if (!eligibleContacts.isEmpty()) {
      AbstractQueueable.enqueue(new ContactAccountPayableQueueable_SL(eligibleContacts));
    }
  }

  /**
   * Check if Contact is or it was Account Payable
   */
  public class ContactAccountPayableCheck implements SObjectPredicate {
    Map<Id, SObject> existingRecords = new Map<Id, SObject>();
    public ContactAccountPayableCheck(List<Contact> records, Map<Id, SObject> existingRecords) {
      this.existingRecords = existingRecords;
    }

    public Boolean apply(Contact record) {
      if (existingRecords.containsKey(record.Id)) {
        Contact existingRecord = (Contact) existingRecords.get(record.Id);
        if (
          existingRecord.Role__c != record.Role__c &&
          (record.Role__c == 'Accounts Payable' ||
          existingRecord.Role__c == 'Accounts Payable')
        ) {
          return true;
        }
      }
      return false;
    }
    public Boolean apply(SObject record) {
      return apply((Contact) record);
    }
  }

  /**
   * Set Account Payable on AccountContactRelation creation
   */
  public static void setAccountPayablesOnRelationInsert(List<AccountContactRelation> relationList) {
    List<Contact> eligibleContacts = new List<Contact>();
    for (AccountContactRelation rel : [
      SELECT Id, AccountId, Account.AP_Contact__c, ContactId, Contact.Role__c
      FROM AccountContactRelation
      WHERE Id IN :relationList
    ]) {
      if (rel.ContactId != null && rel.Contact.Role__c == 'Accounts Payable') {
        eligibleContacts.add(new Contact(Id = rel.ContactId, Role__c = rel.Contact.Role__c));
      }
    }

    if (!eligibleContacts.isEmpty()) {
      AbstractQueueable.enqueue(new ContactAccountPayableQueueable_SL(eligibleContacts));
    }
  }
  public static void setAccountPayablesOnRelatinDelete(List<AccountContactRelation> relationList) {
    List<Contact> eligibleContacts = [
      SELECT Id, Role__c, AccountId
      FROM Contact
      WHERE
        Id IN :Collection.of(relationList).pluckIds(AccountContactRelation.ContactId)
        AND Role__c = 'Accounts Payable'
    ];
    List<Id> accountIds = Collection.of(relationList).pluckIds(AccountContactRelation.AccountId); // after delete scenario handling

    if (!eligibleContacts.isEmpty()) {
      AbstractQueueable.enqueue(new ContactAccountPayableQueueable_SL(eligibleContacts, accountIds));
    }
  }
}