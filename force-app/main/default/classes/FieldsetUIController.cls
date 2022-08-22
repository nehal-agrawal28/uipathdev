/**********************************************************
 * Author        :  UiPath
 * CreatedBy     :  Raghu Rankawat
 * CreatedDate   :  02-Feb-2021
 * Description   :  Controller class of the FieldsetUI Aura component
 *
 * Modifications :
 * [DD-MMM-YYYY] : [Name] : [Description]
 **********************************************************/
public without sharing class FieldsetUIController {
	public class FieldsetUIControllerWrapper {
		@AuraEnabled
		public List<FieldSetWrapper> fieldList { get; set; }
		@AuraEnabled
		public Boolean isObjectUpdateable { get; set; }
	}
	public class FieldSetWrapper {
		@AuraEnabled
		public String fieldAPI { get; set; }
		@AuraEnabled
		public Boolean required { get; set; }
		@AuraEnabled
		public Boolean isEditable { get; set; }

		public FieldSetWrapper(String fieldAPI, Boolean required, Boolean isEditable) {
			this.fieldAPI = fieldAPI;
			this.required = required;
			this.isEditable = isEditable;
		}
	}

	@AuraEnabled(cacheable=true)
	public static FieldsetUIControllerWrapper getInitialData(String sObjectName, String fieldSetName, String recordId) {
		FieldsetUIControllerWrapper wrapper = new FieldsetUIControllerWrapper();
		wrapper.fieldList = new List<FieldSetWrapper>();

		// Check record level edit permission if recordId is provided
		Boolean editDisabled = true;
		if (String.isNotBlank(recordId)) {
			for (UserRecordAccess access : [
				SELECT HasEditAccess, RecordId
				FROM UserRecordAccess
				WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId
			]) {
				if (access.HasEditAccess) {
					editDisabled = false;
				}
			}
		} else {
			editDisabled = false;
		}

		if (editDisabled) {
			wrapper.isObjectUpdateable = false;
		} else {
			wrapper.isObjectUpdateable = Schema.getGlobalDescribe().get(sObjectName).getDescribe().isUpdateable();
		}

		for (
			Schema.FieldSetMember f : Schema.getGlobalDescribe()
				.get(sObjectName)
				.getDescribe()
				.fieldSets.getMap()
				.get(fieldSetName)
				.getFields()
		) {
			if (editDisabled) {
				wrapper.fieldList.add(new FieldSetWrapper(f.getFieldPath(), f.getRequired(), false));
			} else {
				wrapper.fieldList.add(
					new FieldSetWrapper(
						f.getFieldPath(),
						f.getRequired(),
						f.getSObjectField().getDescribe().isUpdateable()
					)
				);
			}
		}

		return wrapper;
	}
}