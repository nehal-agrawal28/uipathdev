const processActiveContracts = result => {
	let rows = [];
	let columns = [
		{ key: "ContractNumber", label: "Contract Number" },
		{ key: "BillTo", label: "Bill To" },
		{ key: "DealType", label: "Deal Type" },
		{ key: "Opportunity", label: "Opportunity" },
		{ key: "Amount", label: "Amount" },
		{ key: "Uplift%", label: "Uplift %" },
		{ key: "RenewalOpportunity", label: "Renewal Opportunity" },
		{ key: "StartDate", label: "Start Date" },
		{ key: "EndDate", label: "End Date" },
		{ key: "Status", label: "Status" }
	];
	let subColumns = [
		{ key: "ProductName", label: "Product Name" },
		{ key: "NetPrice", label: "Net Price" },
		{ key: "Quantity", label: "Quantity" },
		{ key: "StartDate", label: "Start Date" },
		{ key: "EndDate", label: "End Date" },
		{ key: "Uplift%", label: "Uplift %" },
		{ key: "UpliftException", label: "Uplift Exception" }
	];

	for (let con of result.dataList) {
		let row = {
			key: con.Id,
			selected: false,
			cellData: [
				{ key: con.Id + "ContractNumber", data: con.ContractNumber, isLookup: true, lookupId: con.Id },
				{ key: con.Id + "BillTo", data: con.Bill_To__r?.Name, isLookup: true, lookupId: con.Bill_To__c },
				{ key: con.Id + "DealType", isText: true, data: con.Deal_Type__c },
				{
					key: con.Id + "Opportunity",
					data: con.SBQQ__Opportunity__r?.Name,
					isLookup: true,
					lookupId: con.SBQQ__Opportunity__c
				},
				{
					key: con.Id + "Amount",
					isCurrency: true,
					currencyCode: con.CurrencyIsoCode,
					data: con.SBQQ__Opportunity__r.Amount
				},
				{
					key: con.Id + "Uplift%",
					isText: true,
					data: con.SBQQ__RenewalUpliftRate__c
				},
				{
					key: con.Id + "RenewalOpportunity",
					data: con.SBQQ__RenewalOpportunity__r?.Name,
					isLookup: true,
					lookupId: con.SBQQ__RenewalOpportunity__c
				},
				{ key: con.Id + "StartDate", isDate: true, data: con.StartDate },
				{ key: con.Id + "EndDate", isDate: true, data: con.EndDate },
				{
					key: con.Id + "Status",
					isText: true,
					data: Date.parse(con.EndDate) >= new Date() ? "Active" : "Expired"
				}
			],
			drawerData: [
				{
					key: con.Id + "Quote",
					label: "Quote",
					data: con.SBQQ__Quote__r?.Name,
					isLookup: true,
					lookupId: con.SBQQ__Quote__c
				},
				{
					key: con.Id + "Order",
					label: "Order",
					data: con.SBQQ__Order__r?.Name,
					isLookup: true,
					lookupId: con.SBQQ__Order__c
				},
				{
					key: con.Id + "Owner",
					label: "Owner",
					data: con.Owner?.Name,
					isLookup: true,
					lookupId: con.OwnerId
				},
				{
					key: con.Id + "RenewalOwner",
					label: "Renewal Owner",
					data: con.SBQQ__RenewalOwner__r?.Name,
					isLookup: true,
					lookupId: con.SBQQ__RenewalOwner__c
				},
				{
					key: con.Id + "Pricebook",
					label: "Pricebook",
					data: con.Pricebook2?.Name,
					isLookup: true,
					lookupId: con.Pricebook2Id
				}
			]
			// ,
			// rowActionData: [
			// 	{
			// 		key: con.Id + "Action1",
			// 		label: "Action 1",
			// 		value: "Action1"
			// 	}
			// ]
		};
		if (con.SBQQ__Subscriptions__r && con.SBQQ__Subscriptions__r.length > 0) {
			row.subTableData = { columnData: subColumns, rowData: [] };

			for (let subLine of con.SBQQ__Subscriptions__r) {
				row.subTableData.rowData.push({
					key: subLine.Id,
					selected: false,
					cellData: [
						{
							key: subLine.Id + "ProductName",
							data: subLine.SBQQ__Product__r?.Name,
							isLookup: true,
							lookupId: subLine.Id
						},
						{
							key: subLine.Id + "NetPrice",
							isCurrency: true,
							currencyCode: con.CurrencyIsoCode,
							data: subLine.SBQQ__NetPrice__c
						},
						{
							key: subLine.Id + "Quantity",
							isText: true,
							data: subLine.SBQQ__Quantity__c
						},
						{ key: subLine.Id + "StartDate", isDate: true, data: subLine.SBQQ__StartDate__c },
						{ key: subLine.Id + "EndDate", isDate: true, data: subLine.SBQQ__EndDate__c },
						{ key: subLine.Id + "Uplift%", isText: true, data: subLine.SBQQ__RenewalUpliftRate__c },
						{ key: subLine.Id + "UpliftException", isText: true, data: subLine.Uplift_Exception_Reason__c },
					]
				});
			}
		}
		rows.push(row);
	}

	return {
		columns: columns,
		rows: rows
	};
};

export { processActiveContracts };