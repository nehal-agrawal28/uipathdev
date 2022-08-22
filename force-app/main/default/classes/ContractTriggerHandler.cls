public with sharing class ContractTriggerHandler extends TriggerHandler {
	public override void afterInsert() {
		this.populateContractRef();
	}

	private void populateContractRef() {
		Map<Id, Contract> contractToUpdate = new Map<Id, Contract>();
		for (Contract contract : (List<Contract>) Trigger.new) {
			if (String.isBlank(contract.contract_ref__c) && contract.AccountId != null) {
				contractToUpdate.put(contract.Id, null);
			}
		}

		if (contractToUpdate.size() > 0) {
			contractToUpdate = new Map<Id, Contract>(
				[
					SELECT Id, Account.Name, ContractNumber, contract_ref__c
					FROM Contract
					WHERE Id IN :contractToUpdate.keyset()
				]
			);

			// Update contract_ref__c field
			for (Contract contract : contractToUpdate.values()) {
				String prefix = contract.Account.Name.replace(' ', '').toUpperCase();
				if (prefix.length() > 4) {
					prefix = prefix.substring(0, 4);
				}
				contract.contract_ref__c = prefix + '-' + contract.ContractNumber;
			}

			update contractToUpdate.values();
		}
	}
}