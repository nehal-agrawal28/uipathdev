({
	doInit : function(component, event, helper) {
		let data = component.get ('v.data');
        component.set ('v.value', data[component.get('v.column.fieldName')]);
	},
})