public with sharing class ODataEmployee {
    Map<String, String> parNameVal = new Map<String, String>();

    public ODataEmployee(ApexPages.StandardController controller) {

    }

    public Employees__x att {
        get {
//              if (att == null) {
                    // String id = ApexPages.currentPage().getParameters().get('Id');
                    if (Id != null) att = [SELECT sriram68__FirstName__c, sriram68__LastName__c, sriram68__Photo__c FROM Employees__x WHERE Id = :id][0];
//              }
              return att;
        }
        private set;
    }

    public String image {
        get {
              if (att == null) return null;
              return att.Photo__c.substring(106);
        }
    }

    public String firstName {
        get {
              if (att == null) return null;
              return att.FirstName__c;
        }
    }

    public String lastName {
        get {
              if (att == null) return null;
              return att.LastName__c;
        }
    }

    public String id {
        get {
              if (employeeIds.size() > 0) return employeeIds[0];
              if (parNameVal.size() > 0 && parNameVal.get('Id') != null) return parNameVal.get('Id');
              return ApexPages.currentPage().getParameters().get('Id');
        }
    }

    String[] employeeIds = new String[]{};
        
    public PageReference getEmployee() {
        return null;
    }
        
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        for (Employees__x emp : [SELECT Id, sriram68__FirstName__c, sriram68__LastName__c FROM Employees__x]) {
            options.add(new SelectOption(emp.Id, emp.LastName__c + ', ' + emp.FirstName__c));

/*
            options.add(new SelectOption('x08500000000001','x08500000000001'));
            options.add(new SelectOption('x08500000000002','x08500000000002'));
            options.add(new SelectOption('x08500000000003','x08500000000003')); 
*/
        }
        return options;
    }
        
    public String[] getemployeeIds() {
        return employeeIds;
    }
        
    public void setemployeeIds(String[] employeeIds) {
        this.employeeIds = employeeIds;
    }
        
    public String signedRequest {
        get {
                if (ApexPages.currentPage().getParameters().get('signed_request') == null) return null;
                String [] vsplit = ApexPages.currentPage().getParameters().get('signed_request').split('\\.',0);
                system.debug(vsplit[0]);
                system.debug(vsplit[1]);
                
                String encodedSig = vsplit[0];
                String encodedEnvelope = vsplit[1];
                
                Blob bEnv = EncodingUtil.base64Decode(encodedEnvelope);
                String sJson = benv.toString(); 
                system.debug(sJson); 

                // Parse JSON response to get all the totalPrice field values.
                JSONParser parser = JSON.createParser(sJson);
                while (parser.nextToken() != null && !(parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'parameters')) {
                }

                String parName;
                String parVal;

                while (parser.nextToken() != JSONToken.END_OBJECT && parser.getCurrentToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                        parName = parser.getText();
                        parser.nextToken();
                        parVal = parser.getText();
                        parNameVal.put(parName, parVal);
                    }
                }
        
                return sJson;
        }
    }
}