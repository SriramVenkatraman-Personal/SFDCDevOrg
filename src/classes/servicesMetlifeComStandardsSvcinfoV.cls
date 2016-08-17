//Generated by wsdl2apex

public class servicesMetlifeComStandardsSvcinfoV {
    public class UserID_element {
        public String UserType;
        private String[] UserType_att_info = new String[]{'UserType'};
        private String[] apex_schema_type_info = new String[]{'http://services.metlife.com/standards/svcinfo/v1','true','false'};
        private String[] field_order_type_info = new String[]{};
    }
    public class ServiceRequestInfoType {
        public DateTime RequestDateTime;
        public String RequestID;
        public String SessionID;
        public String ProxyUserID;
        public servicesMetlifeComStandardsSvcinfoV.UserID_element[] UserID;
        private String[] RequestDateTime_type_info = new String[]{'RequestDateTime','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] RequestID_type_info = new String[]{'RequestID','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] SessionID_type_info = new String[]{'SessionID','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] ProxyUserID_type_info = new String[]{'ProxyUserID','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] UserID_type_info = new String[]{'UserID','http://services.metlife.com/standards/svcinfo/v1',null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{'http://services.metlife.com/standards/svcinfo/v1','true','false'};
        private String[] field_order_type_info = new String[]{'RequestDateTime','RequestID','SessionID','ProxyUserID','UserID'};
    }
    public class ServiceResponseInfoType {
        public Integer ReturnCode;
        public String ReasonCode;
        public String ReasonMessage;
        public String Detail;
        private String[] ReturnCode_type_info = new String[]{'ReturnCode','http://services.metlife.com/standards/svcinfo/v1',null,'1','1','false'};
        private String[] ReasonCode_type_info = new String[]{'ReasonCode','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] ReasonMessage_type_info = new String[]{'ReasonMessage','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] Detail_type_info = new String[]{'Detail','http://services.metlife.com/standards/svcinfo/v1',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://services.metlife.com/standards/svcinfo/v1','true','false'};
        private String[] field_order_type_info = new String[]{'ReturnCode','ReasonCode','ReasonMessage','Detail'};
    }
}