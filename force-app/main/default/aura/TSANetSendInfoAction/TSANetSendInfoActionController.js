({
	init : function(cmp, event, helper) {
        cmp.set('v.isLoaded', false)
        helper.fetch(cmp, 'c.getTSANetInfo', { recordId: cmp.get('v.recordId') }).then(data => {
            cmp.set('v.record', data.record)
            cmp.set('v.state', data)
            cmp.set('v.isLoaded', true)
        })
	},
            
    close : function(cmp, event){
        $A.get('e.force:refreshView').fire();
    }
})