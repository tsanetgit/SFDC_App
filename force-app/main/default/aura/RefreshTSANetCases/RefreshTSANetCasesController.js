({
	init : function(cmp, event, helper) {
        let caseId = cmp.get('v.recordId');
        helper.fetch(cmp, 'c.refreshOnCase', { caseId }).then(response => {
        	$A.get('e.force:refreshView').fire();
        	helper.navigateToRecord(cmp, event, helper)
        }).catch(error => {
        	$A.get('e.force:refreshView').fire()
            helper.navigateToRecord(cmp, event, helper)
        })
	}
})