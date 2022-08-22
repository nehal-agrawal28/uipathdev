@IsTest(isParallel=true)
public class FieldsetUIControllerTest {
	@isTest
	public static void testGetInitialData() {
		FieldsetUIController.FieldsetUIControllerWrapper wrapper = FieldsetUIController.getInitialData(
			'Opportunity',
			'Financial_Details',
			null
		);

		System.assertEquals(true, wrapper.fieldList.size() > 0, 'Financial_Details fieldset not present on Opportunity');
	}

	@isTest
	public static void testFieldsetUIValues() {
		VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
		context.entityName = 'Opportunity';

		FieldsetUIValues obj = new FieldsetUIValues(context);
		obj.getDefaultValue();
		VisualEditor.DynamicPickListRows fieldsetList = obj.getValues();
		System.assertEquals(true, fieldsetList.size() > 0, 'no fieldset present on Opportunity');
	}
}