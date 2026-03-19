({

	init : function(cmp, event, helper) {
        helper.fetch(cmp, 'c.getCaseInformation', { caseId: cmp.get('v.recordId') }).then(data => {
            cmp.set('v.state', data)
        }).catch(error => {
            console.error(error)
        })
	},
            
    close : function(cmp, event){
        $A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
    }    
})