/**
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     EVENT LOG FILE PROCESSOR OPT TEST                    │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Tests unitaires pour le traitement optimisé des fichiers journaux        │
 * │ Couverture de code visée: 100%                                           │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : 
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

@IsTest
public class EventLogFileProcessorOptTest {
    
    //┌─────────────────────────────────────────┐
    //│    DONNÉES DE TEST                      │
    //└─────────────────────────────────────────┘
    private static final Id MOCK_USER_ID = '005000000000000';
    
    @TestSetup
    static void setupTestData() {
        // 👤 Création d'un utilisateur de test
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Map<String, Object> userFields = new Map<String, Object>{
            'LastName' => 'Test User',
            'Email' => DataFactoryG.generateRandomEmail(),
            'Alias' => DataFactoryG.generateRandomString(8).substring(0, 8),
            'Username' => DataFactoryG.generateRandomString(8) + '@test.com',
            'CommunityNickname' => DataFactoryG.generateRandomString(8),
            'EmailEncodingKey' => 'UTF-8',
            'LanguageLocaleKey' => 'fr',
            'LocaleSidKey' => 'fr_FR',
            'TimeZoneSidKey' => 'Europe/Paris',
            'ProfileId' => p.Id
        };
        User testUser = (User)DataFactoryG.createSObject('User', userFields);
        insert testUser;
    }
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES UTILITAIRES                 │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée un EventLogFile simulé
     */
    private static EventLogFile createMockEventLogFile(String eventType, String content) {
        return new EventLogFile(
            Id = 'abc123000000000000',
            EventType = eventType,
            LogDate = System.today(),
            LogFile = Blob.valueOf(content),
            LogFileLength = content.length()
        );
    }
    
    //┌─────────────────────────────────────────┐
    //│    TESTS PRINCIPAUX                     │
    //└─────────────────────────────────────────┘
    /**
     * @description Test de récupération des fichiers journaux
     */
    @IsTest
    static void testGetEventLogFiles() {
        // 📝 Préparation
        String loginContent = JSON.serialize(new Map<String, Object>{
            'UserId' => MOCK_USER_ID,
            'EventType' => 'Login',
            'LOGIN_TYPE' => 'Application',
            'STATUS' => 'Success'
        });
        EventLogFile mockLog = createMockEventLogFile('Login', loginContent);
        
        // 🔧 Configuration du test
        Test.setFixedSearchResults(new List<Id>{mockLog.Id});
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        List<EventLogFile> results = processor.getEventLogFiles(
            System.today().addDays(-1),
            System.today().addDays(1)
        );
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertEquals(1, results.size(), 'Un fichier journal devrait être retourné');
        System.assertEquals('Login', results[0].EventType, 'Le type d\'événement devrait être Login');
    }
    
    /**
     * @description Test du traitement des fichiers journaux de connexion
     */
    @IsTest
    static void testProcessLoginEventLogs() {
        // 📝 Préparation
        String loginContent = JSON.serialize(new Map<String, Object>{
            'UserId' => MOCK_USER_ID,
            'EventType' => 'Login',
            'LOGIN_TYPE' => 'Application',
            'STATUS' => 'Success'
        });
        EventLogFile mockLog = createMockEventLogFile('Login', loginContent);
        
        // 🔧 Configuration du test
        Test.setFixedSearchResults(new List<Id>{mockLog.Id});
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        List<EventLogFileProcessorOpt.EventLogInfo> results = processor.processEventLogs(
            System.today().addDays(-1),
            System.today().addDays(1)
        );
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(0, results.size(), 'Des résultats devraient être retournés');
        EventLogFileProcessorOpt.EventLogInfo firstLog = results[0];
        System.assertEquals('Login', firstLog.eventType, 'Le type d\'événement devrait être Login');
        System.assertEquals(MOCK_USER_ID, firstLog.userId, 'L\'ID utilisateur devrait correspondre');
        System.assertEquals('Application', firstLog.additionalInfo.get('LOGIN_TYPE'), 'Le type de login devrait être Application');
    }
    
    /**
     * @description Test du traitement des fichiers journaux d'API
     */
    @IsTest
    static void testProcessAPIEventLogs() {
        // 📝 Préparation
        String apiContent = JSON.serialize(new Map<String, Object>{
            'UserId' => MOCK_USER_ID,
            'EventType' => 'API',
            'OPERATION' => 'Query',
            'STATUS_CODE' => '200',
            'API_VERSION' => '57.0'
        });
        EventLogFile mockLog = createMockEventLogFile('API', apiContent);
        
        // 🔧 Configuration du test
        Test.setFixedSearchResults(new List<Id>{mockLog.Id});
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        List<EventLogFileProcessorOpt.EventLogInfo> results = processor.processEventLogs(
            System.today().addDays(-1),
            System.today().addDays(1)
        );
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(0, results.size(), 'Des résultats devraient être retournés');
        EventLogFileProcessorOpt.EventLogInfo firstLog = results[0];
        System.assertEquals('API', firstLog.eventType, 'Le type d\'événement devrait être API');
        System.assertEquals('Query', firstLog.additionalInfo.get('OPERATION'), 'L\'opération devrait être Query');
    }
    
    /**
     * @description Test du traitement des fichiers journaux au format CSV
     */
    @IsTest
    static void testProcessCSVEventLogs() {
        // 📝 Préparation
        String csvContent = 'USER_ID,LOGIN_TYPE,STATUS\n' +
                          MOCK_USER_ID + ',Application,Success';
        EventLogFile mockLog = createMockEventLogFile('Login', csvContent);
        
        // 🔧 Configuration du test
        Test.setFixedSearchResults(new List<Id>{mockLog.Id});
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        List<EventLogFileProcessorOpt.EventLogInfo> results = processor.processEventLogs(
            System.today().addDays(-1),
            System.today().addDays(1)
        );
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(0, results.size(), 'Des résultats devraient être retournés');
        EventLogFileProcessorOpt.EventLogInfo firstLog = results[0];
        System.assertEquals('Login', firstLog.eventType, 'Le type d\'événement devrait être Login');
        System.assertEquals(MOCK_USER_ID, firstLog.userId, 'L\'ID utilisateur devrait correspondre');
    }
    
    /**
     * @description Test du traitement des fichiers journaux invalides
     */
    @IsTest
    static void testProcessInvalidEventLogs() {
        // 📝 Préparation
        EventLogFile mockLog = createMockEventLogFile('Unknown', 'Contenu invalide');
        
        // 🔧 Configuration du test
        Test.setFixedSearchResults(new List<Id>{mockLog.Id});
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        List<EventLogFileProcessorOpt.EventLogInfo> results = processor.processEventLogs(
            System.today().addDays(-1),
            System.today().addDays(1)
        );
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(0, results.size(), 'Des résultats devraient être retournés');
        EventLogFileProcessorOpt.EventLogInfo firstLog = results[0];
        System.assertEquals('Unknown', firstLog.eventType, 'Le type d\'événement devrait être Unknown');
    }
    
    /**
     * @description Test des cas d'erreur de validation des dates
     */
    @IsTest
    static void testDateValidationErrors() {
        // ▶️ Exécution avec dates nulles
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        
        try {
            processor.getEventLogFiles(null, null);
            System.assert(false, 'Une exception aurait dû être levée pour des dates nulles');
        } catch (EventLogFileProcessorOpt.EventLogProcessorException e) {
            System.assert(e.getMessage().contains('requises'), 'Message d\'erreur incorrect');
        }
        
        try {
            processor.getEventLogFiles(
                System.today().addDays(1),
                System.today().addDays(-1)
            );
            System.assert(false, 'Une exception aurait dû être levée pour des dates invalides');
        } catch (EventLogFileProcessorOpt.EventLogProcessorException e) {
            System.assert(e.getMessage().contains('antérieure'), 'Message d\'erreur incorrect');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test du traitement d'un fichier journal individuel
     */
    @IsTest
    static void testProcessSingleEventLogFile() {
        // 📝 Préparation
        String loginContent = JSON.serialize(new Map<String, Object>{
            'UserId' => MOCK_USER_ID,
            'EventType' => 'Login',
            'LOGIN_TYPE' => 'Application',
            'STATUS' => 'Success'
        });
        EventLogFile mockLog = createMockEventLogFile('Login', loginContent);
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFileProcessorOpt processor = new EventLogFileProcessorOpt();
        EventLogFileProcessorOpt.EventLogInfo result = processor.processEventLogFile(mockLog);
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(null, result, 'Le résultat ne devrait pas être null');
        System.assertEquals(mockLog.Id, result.logFileId, 'L\'ID du fichier journal devrait correspondre');
        System.assertEquals('Login', result.eventType, 'Le type d\'événement devrait être Login');
        System.assertEquals(MOCK_USER_ID, result.userId, 'L\'ID utilisateur devrait correspondre');
    }
} 