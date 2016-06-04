global class JIRACXIssueController {
    private boolean collapsed {get; set;}
    public JIRAIssues jIssues {get;set;}

    global JIRACXIssueController() {}

    public JIRACXIssueWrapper[] getIssues() {
        return this.jIssues.issues;
    }
   
    public boolean getCollapsed(){
        system.debug('getting Collapsed - ' + this.collapsed);
       return this.collapsed;
    }
    public void setCollapsed(boolean newCollapse){
        system.debug('Setting collapsed - ' + newCollapse);
        this.collapsed = newCollapse;
    }
    public PageReference toggleCollapse(){
        system.debug('toggle collapse to - ' + !this.collapsed);
        setCollapsed(!this.collapsed);
        return null;
    }

    public PageReference refresh() {
        system.debug('Perform the JIRA refresh call here');
        
        return null;
    } 
    
    @RemoteAction
    global static PageReference editIssue() {
        PageReference newPage = null;
        String issue = ApexPages.currentPage().getParameters().get('id');
        if(issue !=null){
            newPage = new PageReference('/'+issue);
        }
        return newPage;
    }
    
    
// this doesn't belong here, just using for dev testing
    @RemoteAction
    global static boolean updateCaseJiras(string testit){
       system.debug('in updateAllIssues method - ');
        JIRAIntegration__c jInt = JIRAIntegration__c.getInstance();
		DateTime lastUpdate = jInt.lastIssueRefreshAll__c;
        
        if(lastUpdate == null || lastUpdate > DateTime.now())
            lastUpdate = DateTime.now().addMinutes(-10);
        // do the remote login to JIRA
        JIRALogin jl = new JIRALogin();
        if(jl != null){
	        system.debug('updating all the JIRAs');
	        jl.getAllUpdateIssues(lastUpdate);
        
            updateLastUpdate(lastUpdate);
        }
        return true;
    }
    
    @RemoteAction
    global static boolean setWatcher(ID issueId, ID userId){
    	JIRACXIssue__c curIssue = [SELECT id FROM JIRACXIssue__c WHERE id = :issueId];
    	if(curIssue != null){
				User curUser = [SELECT id FROM User WHERE id = :userId];
				JIRA_Watcher__c jw = new JIRA_Watcher__c();
				jw.issues__c = curIssue.Id;
				jw.SFUsers__c = curUser.Id;
				jw.useEmail__c = true;
				jw.useChatter__c = true;
				insert jw;
				return true;
    	}else{ system.debug('WARNING: failed to find issue - ' + issueID);}
    	return false;
    }

    @RemoteAction
    global static boolean unsetWatcher(ID issueId, String userId){
    	JIRACXIssue__c curIssue = [SELECT id FROM JIRACXIssue__c WHERE id = :issueId];
    	if(curIssue != null){
    		system.debug('getting issue - ' + issueId + ' and watcher - ' + userId);
    		JIRA_Watcher__c jw = [SELECT id FROM JIRA_Watcher__c WHERE SFUsers__c = :userId AND issues__r.id = :issueId];
			if(jw != null){
				delete jw;
				return true;
			}
			else {system.debug('WARNING: attempted to add existing watcher - ' + userID + ' for issue - ' + issueID);}
    	}else{ system.debug('WARNING: failed to find issue - ' + issueID);}
    	return false;
    }

    @RemoteAction
    global static boolean setLastUpdate(){
       system.debug('in setLastUpdate method - ');

        DateTime lastUpdate = DateTime.now().addMinutes(-20);
            // if updating the last update time:
            system.debug('saving lastUpdate - '+ lastUpdate);
            List<JIRAIntegration__c> updJInt = [Select Id, lastIssueRefreshAll__c From JIRAIntegration__c ]; 
            if(updJint.size() == 0){
                JIRAIntegration__c newJInt = new JIRAIntegration__c();
                newJInt.lastIssueRefreshAll__c = lastUpdate;
                insert newJInt;
            }else if (updJint.size() == 1) {
                updJInt[0].lastIssueRefreshAll__c = lastUpdate;
                update updJInt;
            }else{
                for(integer i=0; i<updJInt.size();i++)
                    updJInt[i].lastIssueRefreshAll__c = lastUpdate;
                update updJInt;                
            }
                
        return true;
    }
    public static void updateLastUpdate(DateTime inUpdate){
   
        DateTime lastUpdate = DateTime.now().addMinutes(-20);
            // if updating the last update time:
            system.debug('saving lastUpdate - '+ lastUpdate);
            List<JIRAIntegration__c> updJInt = [Select Id, lastIssueRefreshAll__c From JIRAIntegration__c ]; 
            if(updJint.size() == 0){
                JIRAIntegration__c newJInt = new JIRAIntegration__c();
                newJInt.lastIssueRefreshAll__c = lastUpdate;
                insert newJInt;
            }else if (updJint.size() == 1) {
                updJInt[0].lastIssueRefreshAll__c = lastUpdate;
                update updJInt;
            }else{
                for(integer i=0; i<updJInt.size();i++)
                    updJInt[i].lastIssueRefreshAll__c = lastUpdate;
                update updJInt;                
            }
    }

    /*
    global PageReference loadIssues(ID searchId) {
        if(searchId != null){
            if(searchId.getSObjectType() == Schema.Case.SObjectType){
                Case sfCase = [SELECT id, Product_Family__c, project__c from case where ID = :searchId]; 
                if(sfCase != null){return loadCaseIssues(sfCase);}
                	else{ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Invalid Search type'));}
            }
        }else{ ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'JIRA Search item cannot be null'));}
        return null;
    }        
    */
    /*
    public PageReference loadCaseIssues(Case sfCase){
        // do the remote login to JIRA
        JIRALogin jl = new JIRALogin();
        JIRACXIssue__c[] Objissues = jl.getJIRAbyCase(sfCase.id);  // using the 15 character Id for ease of using the URL
		jIssues = new JIRAIssues();
        system.debug('Case referenced in ' + Objissues.size() + ' JIRAs');
        for(JIRACXIssue__c ji : Objissues) {
           if(ji != null){
               jIssues.issues.add(new JIRACXIssueWrapper(ji, true));
               system.debug('adding item to issues list');
            }
        }
        system.debug('issues has ' + jIssues.issues.size());
        return null;
    }
    */
    public  PageReference updateAllIssues() {
       system.debug('in updateAllIssues method');
        List<JIRACXIssue__c> updIssues = new List<JIRACXIssue__c>();
        for(JIRACXIssueWrapper jw : jIssues.issues){
            if(jw != null){
                JIRACXIssue__c ji = jw.getIssue();
                system.debug('saving JIRA ' + ji.JIRAKey__c);
                updIssues.add(ji);
            }
        }
        
        upsert updIssues JIRACXIssue__c.Fields.JIRAKey__c;
        
        return null;
    }
}