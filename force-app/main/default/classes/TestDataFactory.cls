/**
*  ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     TEST DATA FACTORY                                    │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Classe utilitaire pour la création de données de test                    │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : une DataFactory pour créer des enregistrements EventLogFile et une classe test 
 *                      pour chacune des classes (EventLogFileProcessor et AsyncEventLogProcessor)
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

@isTest
public class TestDataFactory {
    
    //┌─────────────────────────────────────────┐
    //│    CONSTANTES                           │
    //└─────────────────────────────────────────┘
    private static final String MOCK_EVENT_LOG_ID = '07L000000000001AAA';
    
    //┌─────────────────────────────────────────┐
    //│    CRÉATION D'EVENTLOGFILE              │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée des EventLogFile simulés pour les tests
     * @param numberOfRecords Nombre d'enregistrements à créer
     * @return Liste d'EventLogFile simulés
     */
    public static List<EventLogFile> createMockEventLogFiles(Integer numberOfRecords) {
        List<EventLogFile> mockRecords = new List<EventLogFile>();
        
        for (Integer i = 0; i < numberOfRecords; i++) {
            String mockId = MOCK_EVENT_LOG_ID.substring(0, 15) + String.valueOf(i).leftPad(3, '0');
            EventLogFile record = new EventLogFile(
                Id = mockId,
                EventType = 'Login',
                LogDate = System.today(),
                LogFileLength = 1024,
                LogFile = Blob.valueOf(JSON.serialize(new Map<String, Object>{
                    'UserId' => UserInfo.getUserId(),
                    'EventType' => 'Login',
                    'LOGIN_TYPE' => 'Application',
                    'STATUS' => 'Success'
                }))
            );
            mockRecords.add(record);
        }
        
        return mockRecords;
    }
    
    /**
     * @description Crée des EventLogFile simulés avec des champs personnalisés
     * @param numberOfRecords Nombre d'enregistrements à créer
     * @param customFields Map des champs personnalisés
     * @return Liste d'EventLogFile simulés
     */
    public static List<EventLogFile> createMockEventLogFiles(Integer numberOfRecords, Map<String, Object> customFields) {
        List<EventLogFile> mockRecords = new List<EventLogFile>();
        
        for (Integer i = 0; i < numberOfRecords; i++) {
            String mockId = MOCK_EVENT_LOG_ID.substring(0, 15) + String.valueOf(i).leftPad(3, '0');
            EventLogFile record = new EventLogFile(
                Id = mockId,
                EventType = customFields.containsKey('EventType') ? (String)customFields.get('EventType') : 'Login',
                LogDate = customFields.containsKey('LogDate') ? (Date)customFields.get('LogDate') : System.today(),
                LogFileLength = customFields.containsKey('LogFileLength') ? (Integer)customFields.get('LogFileLength') : 1024,
                LogFile = customFields.containsKey('LogFile') ? (Blob)customFields.get('LogFile') : 
                         Blob.valueOf(JSON.serialize(customFields))
            );
            mockRecords.add(record);
        }
        
        return mockRecords;
    }
    
    //┌─────────────────────────────────────────┐
    //│    CRÉATION D'UTILISATEURS              │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée des utilisateurs de test
     * @param numberOfRecords Nombre d'utilisateurs à créer
     * @return Liste d'utilisateurs créés
     */
    public static List<User> createUsers(Integer numberOfRecords) {
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> usersToInsert = new List<User>();
        
        for (Integer i = 0; i < numberOfRecords; i++) {
            String uniqueString = String.valueOf(Datetime.now().getTime() + i);
            User user = new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Username = uniqueString + '@test.com',
                Email = uniqueString + '@test.com',
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardUserProfile.Id
            );
            usersToInsert.add(user);
        }
        
        insert usersToInsert;
        return usersToInsert;
    }
    
    /**
     * @description Crée des utilisateurs de test avec des champs personnalisés
     * @param numberOfRecords Nombre d'utilisateurs à créer
     * @param customFields Map des champs personnalisés
     * @return Liste d'utilisateurs créés
     */
    public static List<User> createUsers(Integer numberOfRecords, Map<String, Object> customFields) {
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> usersToInsert = new List<User>();
        
        for (Integer i = 0; i < numberOfRecords; i++) {
            String uniqueString = String.valueOf(Datetime.now().getTime() + i);
            User user = new User(
                FirstName = customFields.containsKey('FirstName') ? (String)customFields.get('FirstName') : 'Test',
                LastName = customFields.containsKey('LastName') ? (String)customFields.get('LastName') : 'User' + i,
                Username = customFields.containsKey('Username') ? (String)customFields.get('Username') : uniqueString + '@test.com',
                Email = customFields.containsKey('Email') ? (String)customFields.get('Email') : uniqueString + '@test.com',
                Alias = customFields.containsKey('Alias') ? (String)customFields.get('Alias') : 'tuser' + i,
                TimeZoneSidKey = customFields.containsKey('TimeZoneSidKey') ? (String)customFields.get('TimeZoneSidKey') : 'GMT',
                LocaleSidKey = customFields.containsKey('LocaleSidKey') ? (String)customFields.get('LocaleSidKey') : 'en_US',
                EmailEncodingKey = customFields.containsKey('EmailEncodingKey') ? (String)customFields.get('EmailEncodingKey') : 'UTF-8',
                LanguageLocaleKey = customFields.containsKey('LanguageLocaleKey') ? (String)customFields.get('LanguageLocaleKey') : 'en_US',
                ProfileId = standardUserProfile.Id
            );
            
            // Ajout des champs personnalisés supplémentaires
            for (String field : customFields.keySet()) {
                if (!new Set<String>{'FirstName', 'LastName', 'Username', 'Email', 'Alias', 
                                   'TimeZoneSidKey', 'LocaleSidKey', 'EmailEncodingKey', 
                                   'LanguageLocaleKey', 'ProfileId'}.contains(field)) {
                    user.put(field, customFields.get(field));
                }
            }
            
            usersToInsert.add(user);
        }
        
        insert usersToInsert;
        return usersToInsert;
    }
} 