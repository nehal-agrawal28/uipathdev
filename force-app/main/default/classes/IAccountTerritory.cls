public Interface IAccountTerritory {
	Map<Id, ObjectTerritory2Association> getValidAccountTerritory(Set<Id> accountIds);
    Map<Id, Territory2> getAccountPrimarySalesTerritory(Set<Id> accountIds);
    
}