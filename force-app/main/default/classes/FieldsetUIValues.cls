/**********************************************************
 * Author        :  UiPath
 * CreatedBy     :  Raghu Rankawat
 * CreatedDate   :  02-Feb-2021
 * Description   :  Used in design attribute of the FieldsetUI Aura component
 *
 * Modifications :
 * [DD-MMM-YYYY] : [Name] : [Description]
 **********************************************************/
global without sharing class FieldsetUIValues extends VisualEditor.DynamicPickList {
	VisualEditor.DesignTimePageContext context;

	global FieldsetUIValues(VisualEditor.DesignTimePageContext context) {
		this.context = context;
	}

	global override VisualEditor.DataRow getDefaultValue() {
		VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('--none--', '');
		return defaultValue;
	}
	global override VisualEditor.DynamicPickListRows getValues() {
		VisualEditor.DynamicPickListRows myValues = new VisualEditor.DynamicPickListRows();
		VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('--none--', '');
		myValues.addRow(defaultValue);

		if (context.entityName != null && context.entityName != '') {
			for (
				String fieldSetName : Schema.getGlobalDescribe()
					.get(context.entityName)
					.getDescribe()
					.fieldSets.getMap()
					.keyset()
			) {
				VisualEditor.DataRow value = new VisualEditor.DataRow(fieldSetName, fieldSetName);
				myValues.addRow(value);
			}
		}

		return myValues;
	}
}