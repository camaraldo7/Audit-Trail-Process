/**
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     EVENT LOG FILE PROCESSOR OPT                         │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Traitement optimisé des fichiers journaux d'événements Salesforce        │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : 
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

public class EventLogFileProcessorOpt {
    
    //┌─────────────────────────────────────────┐
    //│    CONSTANTES                           │
    //└─────────────────────────────────────────┘
    private static final String USER_ID_FIELD = 'UserId';
    private static final Integer BATCH_SIZE = 200;
    
    //┌─────────────────────────────────────────┐
    //│    CLASSES INTERNES                     │
    //└─────────────────────────────────────────┘
    public class EventLogInfo {
        public Id logFileId { get; set; }
        public String eventType { get; set; }
        public Id userId { get; set; }
        public String logContent { get; set; }
        public Map<String, Object> additionalInfo { get; set; }
        
        public EventLogInfo() {
            this.additionalInfo = new Map<String, Object>();
        }
    }
    
    public class EventLogProcessorException extends Exception {}
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES PRINCIPALES                 │
    //└─────────────────────────────────────────┘
    /**
     * @description Récupère les fichiers journaux dans une plage de dates
     * @param startDate Date de début
     * @param endDate Date de fin
     * @return Liste des fichiers journaux
     */
    public List<EventLogFile> getEventLogFiles(Date startDate, Date endDate) {
        // 🔍 Validation des dates
        if (startDate == null || endDate == null) {
            throw new EventLogProcessorException('Les dates de début et de fin sont requises');
        }
        if (startDate > endDate) {
            throw new EventLogProcessorException('La date de début doit être antérieure à la date de fin');
        }
        
        // 📋 Récupération des logs
        return [
            SELECT Id, EventType, LogDate, LogFile, LogFileLength
            FROM EventLogFile
            WHERE LogDate >= :startDate
            AND LogDate <= :endDate
            ORDER BY LogDate DESC
            LIMIT :BATCH_SIZE
        ];
    }
    
    /**
     * @description Traite les fichiers journaux dans une plage de dates
     * @param startDate Date de début
     * @param endDate Date de fin
     * @return Liste des informations extraites
     */
    public List<EventLogInfo> processEventLogs(Date startDate, Date endDate) {
        List<EventLogInfo> results = new List<EventLogInfo>();
        
        // 📥 Récupération des logs
        List<EventLogFile> logFiles = getEventLogFiles(startDate, endDate);
        
        // 🔄 Traitement de chaque log
        for (EventLogFile logFile : logFiles) {
            EventLogInfo info = processEventLogFile(logFile);
            if (info != null) {
                results.add(info);
            }
        }
        
        return results;
    }
    
    /**
     * @description Traite un fichier journal individuel
     * @param logFile Fichier journal à traiter
     * @return Informations extraites du log
     */
    public EventLogInfo processEventLogFile(EventLogFile logFile) {
        EventLogInfo info = new EventLogInfo();
        info.logFileId = logFile.Id;
        info.eventType = logFile.EventType;
        
        try {
            // 📄 Lecture du contenu
            String content = logFile.LogFile.toString();
            info.logContent = content;
            
            // 🔍 Extraction des informations selon le format
            if (content.startsWith('{')) {
                processJSONContent(content, info);
            } else if (content.contains(',')) {
                processCSVContent(content, info);
            } else {
                info.eventType = 'Unknown';
            }
            
        } catch (Exception e) {
            // ⚠️ Gestion des erreurs
            System.debug(LoggingLevel.ERROR, 'Erreur lors du traitement du log: ' + e.getMessage());
            info.eventType = 'Unknown';
        }
        
        return info;
    }
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES D'EXTRACTION                │
    //└─────────────────────────────────────────┘
    /**
     * @description Traite le contenu au format JSON
     * @param content Contenu JSON
     * @param info Objet à remplir
     */
    private void processJSONContent(String content, EventLogInfo info) {
        Map<String, Object> jsonData = (Map<String, Object>)JSON.deserializeUntyped(content);
        
        // 👤 Extraction de l'ID utilisateur
        if (jsonData.containsKey(USER_ID_FIELD)) {
            info.userId = (Id)jsonData.get(USER_ID_FIELD);
        }
        
        // 📊 Extraction des informations supplémentaires selon le type
        extractAdditionalInfo(jsonData, info);
    }
    
    /**
     * @description Traite le contenu au format CSV
     * @param content Contenu CSV
     * @param info Objet à remplir
     */
    private void processCSVContent(String content, EventLogInfo info) {
        List<String> lines = content.split('\n');
        if (lines.size() < 2) return;
        
        // 📑 Analyse des en-têtes et des valeurs
        List<String> headers = lines[0].split(',');
        List<String> values = lines[1].split(',');
        
        Map<String, String> csvData = new Map<String, String>();
        for (Integer i = 0; i < headers.size() && i < values.size(); i++) {
            csvData.put(headers[i].trim(), values[i].trim());
        }
        
        // 👤 Extraction de l'ID utilisateur
        if (csvData.containsKey(USER_ID_FIELD)) {
            info.userId = (Id)csvData.get(USER_ID_FIELD);
        }
        
        // 📊 Ajout des informations supplémentaires
        for (String header : csvData.keySet()) {
            if (header != USER_ID_FIELD) {
                info.additionalInfo.put(header, csvData.get(header));
            }
        }
    }
    
    /**
     * @description Extrait les informations supplémentaires selon le type d'événement
     * @param jsonData Données JSON
     * @param info Objet à remplir
     */
    private void extractAdditionalInfo(Map<String, Object> jsonData, EventLogInfo info) {
        for (String key : jsonData.keySet()) {
            if (key != USER_ID_FIELD && key != 'EventType') {
                info.additionalInfo.put(key, jsonData.get(key));
            }
        }
    }
} 