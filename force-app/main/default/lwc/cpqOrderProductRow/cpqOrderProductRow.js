import { LightningElement, api } from "lwc";

export default class CpqOrderProductRow extends LightningElement {
	@api isRootItem;
	@api requiredById;
	@api orderItems;
	@api hierarchyLevel;
	@api productList;
	@api deploymentList;
	@api orchestrationTypeList;
	@api fieldPermissionMap;
	hierarchyLevelChild;
	indentClass;
	childrenItem;
  currentOrderItems

	connectedCallback() {
		if (!this.currentOrderItems) {
			this.currentOrderItems = [];
			this.childrenItem = [];
			for (let item of this.orderItems) {
				if (
					(this.isRootItem == "true" && !item.SBQQ__RequiredBy__c) ||
					(item.SBQQ__RequiredBy__c && this.requiredById && item.SBQQ__RequiredBy__c === this.requiredById)
				) {
					this.currentOrderItems.push(item);
				}else{
          this.childrenItem.push(item);
        }
			}

			this.hierarchyLevelChild = parseInt(this.hierarchyLevel, 10) + 1;
			this.indentClass = "ml" + (parseInt(this.hierarchyLevel, 10) + 1);
		}
	}

	dataChange(event) {
		this.dispatchEvent(
			new CustomEvent("notifychange", {
				bubbles: true,
				composed: true,
				detail: {
					Id: event.target.dataset.itemId,
					field: event.target.dataset.itemField,
					value: event.target.value
				}
			})
		);
	}
}