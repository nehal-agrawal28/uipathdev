({
	doInit : function(component, event, helper) {
	},
	validateEmailAndCaseNumber : function (component, event, helper) {
		//let caseNumber = component.get ('v.caseNumber');
		let email = component.get ('v.caseEmail');
		
		helper.resetVal (component, ['v.errorMessage'], null);

		/*if (!caseNumber || caseNumber === undefined || caseNumber === '') {
			component.find ('caseNumber').setCustomValidity($A.get('$Label.c.Empty_Case_Number'));
            component.find ('caseNumber').reportValidity ();
            return;
		} else {
			component.find ('caseNumber').setCustomValidity('');
            component.find ('caseNumber').reportValidity ();
		}*/

		if (!email || email === undefined || email === '') {
			component.find ('caseEmail').setCustomValidity($A.get('$Label.c.Empty_Case_Email'));
            component.find ('caseEmail').reportValidity ();
            return;
		} else {
			component.find ('caseEmail').setCustomValidity('');
            component.find ('caseEmail').reportValidity ();
		}

		if (helper.validateEmail (email)) {
			component.find ('caseEmail').setCustomValidity('');
            component.find ('caseEmail').reportValidity ();
		} else {
			component.find ('caseEmail').setCustomValidity($A.get('$Label.c.Empty_Case_Email'));
            component.find ('caseEmail').reportValidity ();
            return;
		}
		helper.validateEmailAndCaseNumber (component, event, email);
 	},
 	closeModel : function (component, event, helper) {
 		helper.toggleOTPModal (component, false);
 	},
 	validateOTP : function (component, event, helper) {
 		let userOTP = component.get ('v.userEnteredOTP');
 		let sysOTP 	= component.get ('v.systemGeneratedOTP');

 		if (userOTP || userOTP === undefined || userOTP === null) {
 			component.find ('otpInput').setCustomValidity($A.get('$Label.c.Empty_OTP'));
 			component.find ('otpInput').reportValidity ();
 		} else {
 			component.find ('otpInput').setCustomValidity('');
 			component.find ('otpInput').reportValidity ();
 		}

 		if  (userOTP && sysOTP && Number (userOTP) === Number (sysOTP)) {
 			//helper.fetchCaseDetails (component, event);
            helper.fetchAllDetails (component, event);
 			helper.toggleOTPModal (component, false);
 		}  else {
 			component.find ('otpInput').setCustomValidity($A.get('$Label.c.Invalid_OTP'));
 			component.find ('otpInput').reportValidity ();
 		}
 	},
 	checkIsNumber : function (component, event, helper) {
        let val = event.getSource().get ('v.value');
        if (val && val !== undefined && isNaN(val)) {
            val = val.substring (0, (val.length-1));
            event.getSource().set ('v.value', val);
        }
    },
    closeEmailModel : function (component, event, helper) {
    	helper.toggleEmailModal (component, false);
    },
    openEmailPopup : function (component, event, helper) {
    	let index = event.target.getAttribute ('data-index');
    	if (index !== undefined) {
    		helper.openEmailPopup (component, index);
    	}
    },
    reset : function (component, event, helper) {
    	helper.toggleInputs (component, ['v.isFindBtnEnabled'], true);
    	helper.toggleInputs (component, ['v.isEmailDisabled', 'v.isCaseNumberDisabled', 'v.showCaseDetails'], false);
    	helper.resetVal (component, ['v.caseNumber', 'v.caseEmail', 'v.userEnteredOTP', 'v.systemGeneratedOTP', 
    								'v.emailMessage', 'v.emailList', 'v.attachmentList', 'v.caseResponse', 'v.caseObj', 'v.caseList', 'v.contactObj'], null);
    	helper.clearTimeOutToReload (component);
    },
    getCaseDetails : function (component, event, helper) {
        let index = event.target.getAttribute ('data-index');
    	if (index !== undefined) {
    		helper.getCaseDetails (component, index);
    	}
    },

})