/**
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     DATA FACTORY GENERATOR TEST                          │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Tests unitaires pour la génération de données de test                    │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : Une classe de test pour démontrer l'utilisation de DataFactoryG.cls.
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

@IsTest
public class DataFactoryGTest {
    
    //┌─────────────────────────────────────────┐
    //│    TESTS DES OBJETS SIMPLES             │
    //└─────────────────────────────────────────┘
    /**
     * @description Test de création d'un compte simple
     */
    @IsTest
    static void testCreateSingleAccount() {
        // 📝 Préparation des données
        Map<String, Object> accountFields = new Map<String, Object>{
            'Name' => 'Test Account',
            'Phone' => DataFactoryG.generateRandomPhone(),
            'Website' => 'www.test.com'
        };
        
        // ▶️ Exécution du test
        Test.startTest();
        Account acc = (Account)DataFactoryG.createSObject('Account', accountFields);
        insert acc;
        Test.stopTest();
        
        // ✅ Vérification
        Account insertedAcc = [SELECT Id, Name, Phone, Website FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Test Account', insertedAcc.Name);
        System.assertEquals(accountFields.get('Website'), insertedAcc.Website);
    }
    
    /**
     * @description Test de création de plusieurs contacts
     */
    @IsTest
    static void testCreateMultipleContacts() {
        // 📝 Préparation des données
        Integer numberOfContacts = 5;
        Map<String, Object> contactFields = new Map<String, Object>{
            'LastName' => 'Test Contact',
            'Email' => DataFactoryG.generateRandomEmail()
        };
        
        // ▶️ Exécution du test
        Test.startTest();
        List<SObject> contacts = DataFactoryG.createSObjectList('Contact', numberOfContacts, contactFields);
        insert contacts;
        Test.stopTest();
        
        // ✅ Vérification
        List<Contact> insertedContacts = [SELECT Id FROM Contact];
        System.assertEquals(numberOfContacts, insertedContacts.size());
    }
    
    //┌─────────────────────────────────────────┐
    //│    TESTS DES GÉNÉRATEURS                │
    //└─────────────────────────────────────────┘
    /**
     * @description Test des générateurs de données aléatoires
     */
    @IsTest
    static void testRandomGenerators() {
        // 🎲 Test de génération de chaîne aléatoire
        String randomStr = DataFactoryG.generateRandomString(10);
        System.assertEquals(10, randomStr.length());
        
        // 📧 Test de génération d'email
        String email = DataFactoryG.generateRandomEmail();
        System.assert(email.contains('@'));
        
        // 📱 Test de génération de numéro de téléphone
        String phone = DataFactoryG.generateRandomPhone();
        System.assert(phone.startsWith('+33'));
        System.assertEquals(12, phone.length());
    }
    
    /**
     * @description Test de création d'un utilisateur
     */
    @IsTest
    static void testCreateUser() {
        // 👤 Préparation du profil
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // 📝 Préparation des données utilisateur
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
        
        // ▶️ Exécution du test
        Test.startTest();
        User u = (User)DataFactoryG.createSObject('User', userFields);
        insert u;
        Test.stopTest();
        
        // ✅ Vérification
        User insertedUser = [SELECT Id, Username, Email FROM User WHERE Id = :u.Id];
        System.assertEquals(userFields.get('Email'), insertedUser.Email);
        System.assertEquals(userFields.get('Username'), insertedUser.Username);
    }
    
    //┌─────────────────────────────────────────┐
    //│    TESTS DE GÉOLOCALISATION             │
    //└─────────────────────────────────────────┘
    /**
     * @description Test de génération de coordonnées géographiques
     */
    @IsTest
    static void testGeoLocation() {
        // 🗺️ Génération des coordonnées
        Map<String, Double> coordinates = DataFactoryG.generateRandomGeoLocation();
        
        // ✅ Vérifications de base
        System.assertNotEquals(null, coordinates.get('latitude'));
        System.assertNotEquals(null, coordinates.get('longitude'));
        
        // 📍 Vérification des limites géographiques
        System.assert(coordinates.get('latitude') >= 41.3);
        System.assert(coordinates.get('latitude') <= 51.1);
        System.assert(coordinates.get('longitude') >= -4.8);
        System.assert(coordinates.get('longitude') <= 8.2);
    }
    
    //┌─────────────────────────────────────────┐
    //│    TESTS DES RELATIONS                  │
    //└─────────────────────────────────────────┘
    /**
     * @description Test de création d'une hiérarchie parent-enfant
     */
    @IsTest
    static void testParentChildRelationship() {
        // 📝 Préparation des données
        Map<String, Object> accountFields = new Map<String, Object>{
            'Name' => 'Test Account'
        };
        
        Map<String, Object> contactFields = new Map<String, Object>{
            'LastName' => 'Test Contact',
            'Email' => DataFactoryG.generateRandomEmail()
        };
        
        // ▶️ Exécution du test
        Test.startTest();
        Map<String, Object> hierarchy = DataFactoryG.createParentChildHierarchy(
            'Account',
            accountFields,
            'Contact',
            3,
            'AccountId',
            contactFields
        );
        Test.stopTest();
        
        // ✅ Vérifications
        Account parentAccount = (Account)hierarchy.get('parent');
        List<Contact> childContacts = (List<Contact>)hierarchy.get('children');
        
        System.assertNotEquals(null, parentAccount.Id);
        System.assertEquals(3, childContacts.size());
        
        // 👨‍👦 Vérification des relations
        for(Contact c : childContacts) {
            System.assertEquals(parentAccount.Id, c.AccountId);
        }
    }
    
    /**
     * @description Test de création d'un enregistrement géolocalisé
     */
    @IsTest
    static void testGeolocatedRecord() {
        // 📝 Préparation des données
        Map<String, Object> additionalFields = new Map<String, Object>{
            'Name' => 'Test Location'
        };
        
        // ▶️ Exécution du test
        Test.startTest();
        Account acc = (Account)DataFactoryG.createGeolocatedRecord(
            'Account',
            'Latitude__c',
            'Longitude__c',
            additionalFields
        );
        Test.stopTest();
        
        // ✅ Vérification
        Account insertedAcc = [SELECT Id, Name, Latitude__c, Longitude__c 
                             FROM Account 
                             WHERE Id = :acc.Id];
        
        System.assertNotEquals(null, insertedAcc.Latitude__c);
        System.assertNotEquals(null, insertedAcc.Longitude__c);
    }
    
    //┌─────────────────────────────────────────┐
    //│    TESTS EVENT LOG FILE                  │
    //└─────────────────────────────────────────┘
    /**
     * @description Test de création d'un EventLogFile générique
     */
    @IsTest
    static void testCreateEventLogFile() {
        // 📝 Préparation
        Id mockUserId = '005000000000000';
        Map<String, Object> additionalFields = new Map<String, Object>{
            'TEST_FIELD' => 'Test Value'
        };
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFile result = DataFactoryG.createEventLogFile('Test', mockUserId, additionalFields);
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(null, result, 'L\'EventLogFile ne devrait pas être null');
        System.assertEquals('Test', result.EventType, 'Le type d\'événement devrait correspondre');
        
        // Vérification du contenu JSON
        String content = result.LogFile.toString();
        Map<String, Object> jsonContent = (Map<String, Object>)JSON.deserializeUntyped(content);
        System.assertEquals(mockUserId, jsonContent.get('UserId'), 'L\'ID utilisateur devrait correspondre');
        System.assertEquals('Test Value', jsonContent.get('TEST_FIELD'), 'Le champ supplémentaire devrait être présent');
    }
    
    /**
     * @description Test de création d'un EventLogFile de type Login
     */
    @IsTest
    static void testCreateLoginEventLog() {
        // 📝 Préparation
        Id mockUserId = '005000000000000';
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFile result = DataFactoryG.createLoginEventLog(mockUserId);
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(null, result, 'L\'EventLogFile ne devrait pas être null');
        System.assertEquals('Login', result.EventType, 'Le type d\'événement devrait être Login');
        
        // Vérification du contenu JSON
        String content = result.LogFile.toString();
        Map<String, Object> jsonContent = (Map<String, Object>)JSON.deserializeUntyped(content);
        System.assertEquals('Application', jsonContent.get('LOGIN_TYPE'), 'Le type de login devrait être Application');
        System.assertEquals('Success', jsonContent.get('STATUS'), 'Le statut devrait être Success');
    }
    
    /**
     * @description Test de création d'un EventLogFile de type API
     */
    @IsTest
    static void testCreateAPIEventLog() {
        // 📝 Préparation
        Id mockUserId = '005000000000000';
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFile result = DataFactoryG.createAPIEventLog(mockUserId);
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(null, result, 'L\'EventLogFile ne devrait pas être null');
        System.assertEquals('API', result.EventType, 'Le type d\'événement devrait être API');
        
        // Vérification du contenu JSON
        String content = result.LogFile.toString();
        Map<String, Object> jsonContent = (Map<String, Object>)JSON.deserializeUntyped(content);
        System.assertEquals('Query', jsonContent.get('OPERATION'), 'L\'opération devrait être Query');
        System.assertEquals('200', jsonContent.get('STATUS_CODE'), 'Le code status devrait être 200');
    }
    
    /**
     * @description Test de création d'un EventLogFile avec contenu CSV
     */
    @IsTest
    static void testCreateCSVEventLog() {
        // 📝 Préparation
        Id mockUserId = '005000000000000';
        
        // ▶️ Exécution
        Test.startTest();
        EventLogFile result = DataFactoryG.createCSVEventLog(mockUserId);
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(null, result, 'L\'EventLogFile ne devrait pas être null');
        System.assertEquals('Login', result.EventType, 'Le type d\'événement devrait être Login');
        
        // Vérification du contenu CSV
        String content = result.LogFile.toString();
        List<String> lines = content.split('\n');
        System.assertEquals(2, lines.size(), 'Le fichier CSV devrait avoir 2 lignes');
        System.assert(lines[1].contains(mockUserId), 'L\'ID utilisateur devrait être présent dans le CSV');
    }
    
    /**
     * @description Test de création d'un EventLogFile invalide
     */
    @IsTest
    static void testCreateInvalidEventLog() {
        // ▶️ Exécution
        Test.startTest();
        EventLogFile result = DataFactoryG.createInvalidEventLog();
        Test.stopTest();
        
        // ✅ Vérifications
        System.assertNotEquals(null, result, 'L\'EventLogFile ne devrait pas être null');
        System.assertEquals('Unknown', result.EventType, 'Le type d\'événement devrait être Unknown');
        System.assertEquals('Contenu invalide', result.LogFile.toString(), 'Le contenu devrait être invalide');
    }
} 