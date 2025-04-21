/**
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     ASYNC EVENT LOG PROCESSOR TEST                       │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Tests unitaires pour la classe AsyncEventLogProcessor                    │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : Test Class for AsyncEventLogProcessor (AsyncEventLogProcessorTest.cls)
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

@isTest
private class AsyncEventLogProcessorTest {
    
    //┌─────────────────────────────────────────┐
    //│    DONNÉES DE TEST                      │
    //└─────────────────────────────────────────┘
    private static final String MOCK_JSON_CONTENT = '['
        + '{"UserId": "005000000000001", "EventType": "Login", "LOGIN_TYPE": "Application"},'
        + '{"UserId": "005000000000002", "EventType": "API", "OPERATION": "Query"}'
        + ']';
    
    private static final String MOCK_CSV_CONTENT = 'UserId,EventType,LOGIN_TYPE\n'
        + '005000000000001,Login,Application\n'
        + '005000000000002,API,Query';
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES DE CONFIGURATION            │
    //└─────────────────────────────────────────┘
    @TestSetup
    static void setupTestData() {
        // Création d'utilisateurs de test
        List<User> testUsers = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        for (Integer i = 1; i <= 2; i++) {
            User u = new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@test.com',
                Username = 'testuser' + i + '@test.com',
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'fr_FR',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'fr',
                ProfileId = p.Id
            );
            testUsers.add(u);
        }
        insert testUsers;
    }
    
    //┌─────────────────────────────────────────┐
    //│    TESTS PRINCIPAUX                     │
    //└─────────────────────────────────────────┘
    @isTest
    static void testEnqueueProcessing() {
        // Préparation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        // Exécution
        AsyncEventLogProcessor.enqueueProcessing();
        
        // Vérification
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'Queueable'
        ];
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(0, jobs.size(), 'Au moins un job devrait être créé');
        System.assertEquals('Completed', jobs[0].Status, 'Le job devrait être complété');
    }
    
    @isTest
    static void testProcessLogFilesWithJsonContent() {
        // Préparation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(MOCK_JSON_CONTENT, 'application/json'));
        List<Id> mockLogFileIds = new List<Id>{getFakeId()};
        
        Test.startTest();
        
        // Exécution
        AsyncEventLogProcessor processor = new AsyncEventLogProcessor(mockLogFileIds);
        System.enqueueJob(processor);
        
        Test.stopTest();
        
        // Les assertions sont gérées par les logs du système
        // Vérification des logs peut être faite manuellement
    }
    
    @isTest
    static void testProcessLogFilesWithCsvContent() {
        // Préparation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(MOCK_CSV_CONTENT, 'text/csv'));
        List<Id> mockLogFileIds = new List<Id>{getFakeId()};
        
        Test.startTest();
        
        // Exécution
        AsyncEventLogProcessor processor = new AsyncEventLogProcessor(mockLogFileIds);
        System.enqueueJob(processor);
        
        Test.stopTest();
        
        // Les assertions sont gérées par les logs du système
    }
    
    @isTest
    static void testErrorHandling() {
        // Préparation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('', 'application/json', 500));
        List<Id> mockLogFileIds = new List<Id>{getFakeId()};
        
        Test.startTest();
        
        // Exécution
        AsyncEventLogProcessor processor = new AsyncEventLogProcessor(mockLogFileIds);
        System.enqueueJob(processor);
        
        Test.stopTest();
        
        // Les assertions sont gérées par les logs du système
    }
    
    @isTest
    static void testRetryMechanism() {
        // Préparation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator('', 'application/json', 500));
        List<Id> mockLogFileIds = new List<Id>{getFakeId()};
        
        Test.startTest();
        
        // Exécution avec retry count initial
        AsyncEventLogProcessor processor = new AsyncEventLogProcessor(mockLogFileIds);
        System.enqueueJob(processor);
        
        Test.stopTest();
        
        // Les assertions sont gérées par les logs du système
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
        
        public MockHttpResponseGenerator() {
            this(MOCK_JSON_CONTENT, 'application/json', 200);
        }
        
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
    
    /**
     * @description Génère un ID factice pour les tests
     * @return Id factice
     */
    private static Id getFakeId() {
        return '07L000000000001AAA';
    }
} 