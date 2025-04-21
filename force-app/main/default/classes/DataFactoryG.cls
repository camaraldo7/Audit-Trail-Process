/**
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     DATA FACTORY GENERATOR                               │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Génération de données de test pour Salesforce                            │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : Une classe DataFactoryG générique pour Salesforce Apex qui permettra de générer facilement des données de test.
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

public class DataFactoryG {
    
    //┌─────────────────────────────────────────┐
    //│    CRÉATION D'OBJETS SIMPLES            │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée un enregistrement SObject avec des champs remplis aléatoirement
     * @param sObjectType Le type de SObject à créer
     * @return L'instance SObject créée
     */
    public static SObject createSObject(String sObjectType) {
        return createSObject(sObjectType, null);
    }
    
    /**
     * @description Crée un enregistrement SObject avec des champs spécifiques
     * @param sObjectType Le type de SObject à créer
     * @param fieldValues Map des valeurs de champs à définir
     * @return L'instance SObject créée
     */
    public static SObject createSObject(String sObjectType, Map<String,Object> fieldValues) {
        // 📦 Création de l'objet
        SObject sObj = Schema.getGlobalDescribe().get(sObjectType).newSObject();
        
        // 🔄 Application des valeurs de champs
        if(fieldValues != null) {
            for(String field : fieldValues.keySet()) {
                sObj.put(field, fieldValues.get(field));
            }
        }
        
        return sObj;
    }
    
    //┌─────────────────────────────────────────┐
    //│    CRÉATION DE LISTES D'OBJETS          │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée et insère plusieurs enregistrements SObject
     * @param sObjectType Le type de SObject à créer
     * @param count Le nombre d'enregistrements à créer
     * @return Liste des SObjects créés et insérés
     */
    public static List<SObject> createSObjectList(String sObjectType, Integer count) {
        return createSObjectList(sObjectType, count, null);
    }
    
    /**
     * @description Crée et insère plusieurs enregistrements SObject avec des champs spécifiques
     * @param sObjectType Le type de SObject à créer
     * @param count Le nombre d'enregistrements à créer
     * @param fieldValues Map des valeurs de champs à définir
     * @return Liste des SObjects créés et insérés
     */
    public static List<SObject> createSObjectList(String sObjectType, Integer count, Map<String,Object> fieldValues) {
        // 📋 Création de la liste
        List<SObject> sObjects = new List<SObject>();
        
        // 🔄 Génération des objets
        for(Integer i = 0; i < count; i++) {
            sObjects.add(createSObject(sObjectType, fieldValues));
        }
        
        return sObjects;
    }
    
    //┌─────────────────────────────────────────┐
    //│    GÉNÉRATEURS DE DONNÉES               │
    //└─────────────────────────────────────────┘
    /**
     * @description Génère une chaîne aléatoire
     * @param length Longueur de la chaîne souhaitée
     * @return Chaîne aléatoire
     */
    public static String generateRandomString(Integer length) {
        // 🎲 Caractères possibles
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        
        while (randStr.length() < length) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        
        return randStr;
    }
    
    /**
     * @description Génère un email aléatoire
     * @return Email aléatoire
     */
    public static String generateRandomEmail() {
        // 📧 Génération d'email
        return generateRandomString(8) + '@' + generateRandomString(8) + '.com';
    }
    
    /**
     * @description Génère un numéro de téléphone aléatoire
     * @return Numéro de téléphone aléatoire
     */
    public static String generateRandomPhone() {
        // 📱 Génération de numéro français
        String phone = '+33';
        for(Integer i = 0; i < 9; i++) {
            phone += String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 10));
        }
        return phone;
    }

    /**
     * @description Crée une position géographique aléatoire en France métropolitaine
     * @return Map avec Latitude et Longitude
     */
    public static Map<String, Double> generateRandomGeoLocation() {
        // 🗺️ Coordonnées de la France métropolitaine
        Double minLat = 41.3;  // Sud de la France
        Double maxLat = 51.1;  // Nord de la France
        Double minLong = -4.8; // Ouest de la France
        Double maxLong = 8.2;  // Est de la France
        
        // 📍 Génération des coordonnées
        Decimal latitude = Decimal.valueOf(minLat + (Math.random() * (maxLat - minLat)));
        Decimal longitude = Decimal.valueOf(minLong + (Math.random() * (maxLong - minLong)));
        
        return new Map<String, Double>{
            'latitude' => latitude.setScale(6).doubleValue(),
            'longitude' => longitude.setScale(6).doubleValue()
        };
    }
    
    //┌─────────────────────────────────────────┐
    //│    GESTION DES RELATIONS                │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée une relation lookup ou master-detail
     * @param parentObjectType Type d'objet parent (ex: 'Account')
     * @param parentFields Champs à définir sur l'objet parent
     * @return ID de l'enregistrement parent créé
     */
    public static Id createParentRecord(String parentObjectType, Map<String, Object> parentFields) {
        // 👨‍👦 Création du parent
        SObject parent = createSObject(parentObjectType, parentFields);
        insert parent;
        return parent.Id;
    }
    
    /**
     * @description Crée plusieurs enregistrements enfants liés à un parent
     * @param childObjectType Type d'objet enfant (ex: 'Contact')
     * @param parentId ID de l'enregistrement parent
     * @param lookupFieldName Nom du champ de relation (ex: 'AccountId')
     * @param count Nombre d'enregistrements enfants à créer
     * @param additionalFields Champs supplémentaires pour les enfants
     * @return Liste des enregistrements enfants créés
     */
    public static List<SObject> createChildRecords(
        String childObjectType,
        Id parentId,
        String lookupFieldName,
        Integer count,
        Map<String, Object> additionalFields
    ) {
        // 👨‍👦 Configuration de la relation
        if (additionalFields == null) {
            additionalFields = new Map<String, Object>();
        }
        additionalFields.put(lookupFieldName, parentId);
        
        // 📋 Création des enfants
        List<SObject> children = createSObjectList(childObjectType, count, additionalFields);
        insert children;
        return children;
    }
    
    /**
     * @description Crée une hiérarchie complète d'objets (parent avec enfants)
     * @param parentObjectType Type d'objet parent
     * @param parentFields Champs du parent
     * @param childObjectType Type d'objet enfant
     * @param childCount Nombre d'enfants
     * @param lookupFieldName Nom du champ de relation
     * @param childFields Champs des enfants
     * @return Map contenant le parent et la liste des enfants
     */
    public static Map<String, Object> createParentChildHierarchy(
        String parentObjectType,
        Map<String, Object> parentFields,
        String childObjectType,
        Integer childCount,
        String lookupFieldName,
        Map<String, Object> childFields
    ) {
        // 👨‍👦 Création du parent
        SObject parent = createSObject(parentObjectType, parentFields);
        insert parent;
        
        // 👨‍👧‍👦 Création des enfants
        List<SObject> children = createChildRecords(
            childObjectType,
            parent.Id,
            lookupFieldName,
            childCount,
            childFields
        );
        
        return new Map<String, Object>{
            'parent' => parent,
            'children' => children
        };
    }
    
    //┌─────────────────────────────────────────┐
    //│    GÉOLOCALISATION                      │
    //└─────────────────────────────────────────┘
    /**
     * @description Crée un enregistrement avec des coordonnées géographiques
     * @param objectType Type d'objet
     * @param latitudeField Nom du champ de latitude
     * @param longitudeField Nom du champ de longitude
     * @param additionalFields Autres champs à définir
     * @return L'enregistrement créé avec géolocalisation
     */
    public static SObject createGeolocatedRecord(
        String objectType,
        String latitudeField,
        String longitudeField,
        Map<String, Object> additionalFields
    ) {
        // 🌍 Préparation des champs
        if (additionalFields == null) {
            additionalFields = new Map<String, Object>();
        }
        
        // 📍 Génération des coordonnées
        Map<String, Double> coordinates = generateRandomGeoLocation();
        additionalFields.put(latitudeField, coordinates.get('latitude'));
        additionalFields.put(longitudeField, coordinates.get('longitude'));
        
        // 💾 Création et sauvegarde
        SObject record = createSObject(objectType, additionalFields);
        insert record;
        return record;
    }
    
    //┌─────────────────────────────────────────┐
    //│    EVENT LOG FILE GENERATION            │
    //└─────────────────────────────────────────┘
    
    /**
     * @description Crée un EventLogFile avec le contenu JSON spécifié
     * @param eventType Type d'événement
     * @param userId ID de l'utilisateur
     * @param additionalFields Champs supplémentaires à inclure dans le JSON
     * @return EventLogFile créé
     */
    public static EventLogFile createEventLogFile(String eventType, Id userId, Map<String, Object> additionalFields) {
        Map<String, Object> content = new Map<String, Object>{
            'UserId' => userId,
            'EventType' => eventType,
            'Timestamp' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        };
        
        if (additionalFields != null) {
            content.putAll(additionalFields);
        }
        
        EventLogFile logFile = new EventLogFile(
            EventType = eventType,
            LogDate = Date.today(),
            LogFile = Blob.valueOf(JSON.serializePretty(content))
        );
        
        return logFile;
    }
    
    /**
     * @description Crée un EventLogFile de type Login
     * @param userId ID de l'utilisateur
     * @return EventLogFile créé
     */
    public static EventLogFile createLoginEventLog(Id userId) {
        Map<String, Object> additionalFields = new Map<String, Object>{
            'LOGIN_TYPE' => 'Application',
            'STATUS' => 'Success',
            'LOGIN_KEY' => '1234567890',
            'SOURCE_IP' => '192.168.1.1'
        };
        
        return createEventLogFile('Login', userId, additionalFields);
    }
    
    /**
     * @description Crée un EventLogFile de type API
     * @param userId ID de l'utilisateur
     * @return EventLogFile créé
     */
    public static EventLogFile createAPIEventLog(Id userId) {
        Map<String, Object> additionalFields = new Map<String, Object>{
            'OPERATION' => 'Query',
            'STATUS_CODE' => '200',
            'API_VERSION' => '57.0',
            'ENDPOINT' => '/services/data/v57.0/query'
        };
        
        return createEventLogFile('API', userId, additionalFields);
    }
    
    /**
     * @description Crée un EventLogFile de type URI
     * @param userId ID de l'utilisateur
     * @return EventLogFile créé
     */
    public static EventLogFile createURIEventLog(Id userId) {
        Map<String, Object> additionalFields = new Map<String, Object>{
            'URI' => '/apex/MyPage',
            'METHOD' => 'GET',
            'STATUS_CODE' => '200',
            'RESPONSE_TIME' => '150'
        };
        
        return createEventLogFile('URI', userId, additionalFields);
    }
    
    /**
     * @description Crée un EventLogFile de type Report
     * @param userId ID de l'utilisateur
     * @return EventLogFile créé
     */
    public static EventLogFile createReportEventLog(Id userId) {
        Map<String, Object> additionalFields = new Map<String, Object>{
            'REPORT_ID' => '00O000000000001',
            'ROWS_PROCESSED' => '1000',
            'EXECUTION_TIME' => '2500',
            'STATUS' => 'Success'
        };
        
        return createEventLogFile('Report', userId, additionalFields);
    }
    
    /**
     * @description Crée un EventLogFile avec contenu CSV
     * @param userId ID de l'utilisateur
     * @return EventLogFile créé
     */
    public static EventLogFile createCSVEventLog(Id userId) {
        String csvContent = 'USER_ID,LOGIN_TYPE,STATUS,TIMESTAMP\n' +
                          userId + ',Application,Success,' + System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        EventLogFile logFile = new EventLogFile(
            EventType = 'Login',
            LogDate = Date.today(),
            LogFile = Blob.valueOf(csvContent)
        );
        
        return logFile;
    }
    
    /**
     * @description Crée un EventLogFile avec contenu invalide
     * @return EventLogFile créé
     */
    public static EventLogFile createInvalidEventLog() {
        EventLogFile logFile = new EventLogFile(
            EventType = 'Unknown',
            LogDate = Date.today(),
            LogFile = Blob.valueOf('Contenu invalide')
        );
        
        return logFile;
    }
} 