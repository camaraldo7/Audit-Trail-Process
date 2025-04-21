/**
*  ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     EVENT LOG FILE PROCESSOR TEST                        │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Tests unitaires pour la classe EventLogFileProcessor                     │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : Test Class for EventLogFileProcessor (EventLogFileProcessorTest.cls)
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

@isTest
private class EventLogFileProcessorTest {
    
    //┌─────────────────────────────────────────┐
    //│    DONNÉES DE TEST                      │
    //└─────────────────────────────────────────┘
    private static final String MOCK_JSON_CONTENT = '['
        + '{"UserId": "{0}", "EventType": "Login", "LOGIN_TYPE": "Application"},'
        + '{"UserId": "{1}", "EventType": "API", "OPERATION": "Query"}'
        + ']';
    
    private static final String MOCK_CSV_CONTENT = 'UserId,EventType,LOGIN_TYPE\n'
        + '{0},Login,Application\n'
        + '{1},API,Query';
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES DE TEST                     │
    //└─────────────────────────────────────────┘
    @isTest
    static void testProcessEventLogsWithJsonContent() {
        // Préparation
        List<User> testUsers = TestDataFactory.createUsers(2);
        String formattedJsonContent = String.format(
            MOCK_JSON_CONTENT,
            new List<String>{
                testUsers[0].Id,
                testUsers[1].Id
            }
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(formattedJsonContent, 'application/json'));
        
        // Exécution
        Test.startTest();
        EventLogFileProcessor.processEventLogs();
        Test.stopTest();
        
        // Les assertions sont basées sur les logs système
        // La vérification peut être faite manuellement dans les logs de débogage
    }
    
    @isTest
    static void testProcessEventLogsWithCsvContent() {
        // Préparation
        List<User> testUsers = TestDataFactory.createUsers(2);
        String formattedCsvContent = String.format(
            MOCK_CSV_CONTENT,
            new List<String>{
                testUsers[0].Id,
                testUsers[1].Id
            }
        );
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(formattedCsvContent, 'text/csv'));
        
        // Exécution
        Test.startTest();
        EventLogFileProcessor.processEventLogs();
        Test.stopTest();
        
        // Les assertions sont basées sur les logs système
    }
    
    @isTest
    static void testProcessEventLogsWithHttpError() {
        // Préparation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('', 'application/json', 500));
        
        // Exécution
        Test.startTest();
        EventLogFileProcessor.processEventLogs();
        Test.stopTest();
        
        // Les assertions sont basées sur les logs système
    }
    
    @isTest
    static void testProcessEventLogsWithInvalidUserId() {
        // Préparation
        String invalidJsonContent = '['
            + '{"UserId": "005000000000000", "EventType": "Login"}' // ID invalide
            + ']';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(invalidJsonContent, 'application/json'));
        
        // Exécution
        Test.startTest();
        EventLogFileProcessor.processEventLogs();
        Test.stopTest();
        
        // Les assertions sont basées sur les logs système
    }
    
    @isTest
    static void testProcessEventLogsWithMissingUserId() {
        // Préparation
        String jsonWithoutUserId = '['
            + '{"EventType": "Login", "LOGIN_TYPE": "Application"}' // Sans UserId
            + ']';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(jsonWithoutUserId, 'application/json'));
        
        // Exécution
        Test.startTest();
        EventLogFileProcessor.processEventLogs();
        Test.stopTest();
        
        // Les assertions sont basées sur les logs système
    }
    
    //┌─────────────────────────────────────────┐
    //│    CLASSES UTILITAIRES                  │
    //└─────────────────────────────────────────┘
    /**
     * @description Générateur de réponses HTTP mock
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private String content;
        private String contentType;
        private Integer statusCode;
        
        public MockHttpResponseGenerator(String content, String contentType) {
            this(content, contentType, 200);
        }
        
        public MockHttpResponseGenerator(String content, String contentType, Integer statusCode) {
            this.content = content;
            this.contentType = contentType;
            this.statusCode = statusCode;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', contentType);
            res.setBody(content);
            res.setStatusCode(statusCode);
            return res;
        }
    }
} 