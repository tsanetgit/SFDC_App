({
	init : function(cmp, event, helper) {
        const caseId = cmp.get('v.recordId');
        helper.fetch(cmp, 'c.refreshOnCase', { caseId }).then(() => {
        	$A.get('e.force:refreshView').fire();
        	helper.navigateToRecord(cmp)
        }).catch(() => {
        	$A.get('e.force:refreshView').fire()
            helper.navigateToRecord(cmp)
        })
	}
})