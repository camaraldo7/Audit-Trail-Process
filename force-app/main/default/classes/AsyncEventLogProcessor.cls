/**
 * ┌──────────────────────────────────────────────────────────────────────────┐
 * │                     ASYNC EVENT LOG PROCESSOR                            │
 * ├──────────────────────────────────────────────────────────────────────────┤
 * │ Traitement asynchrone des fichiers journaux d'événements                 │
 * │ Version: 1.0                                                             │
 * └──────────────────────────────────────────────────────────────────────────┘
 * @description       : Pour optimiser le traitement des fichiers journaux d'événements en mode asynchrone,
 *                      nous pouvons utiliser la classe Queueable d'Apex. Cela permet de mettre en file d'attente le traitement et 
 *                      d'éviter les limitations de temps d'exécution des transactions synchrones.
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

public class AsyncEventLogProcessor implements Queueable {
    
    //┌─────────────────────────────────────────┐
    //│    CONSTANTES                           │
    //└─────────────────────────────────────────┘
    private static final String API_VERSION = 'v59.0';
    private static final String API_ENDPOINT = '/services/data/' + API_VERSION + '/sobjects/EventLogFile/{0}/LogFile';
    private static final Integer CHUNK_SIZE = 10;
    private static final Integer MAX_RETRIES = 3;
    
    //┌─────────────────────────────────────────┐
    //│    VARIABLES PRIVÉES                    │
    //└─────────────────────────────────────────┘
    private final List<Id> logFileIds;
    private final Integer retryCount;
    
    //┌─────────────────────────────────────────┐
    //│    CONSTRUCTEURS                        │
    //└─────────────────────────────────────────┘
    /**
     * @description Constructeur principal
     * @param logFileIds Liste des IDs de fichiers journaux à traiter
     */
    public AsyncEventLogProcessor(List<Id> logFileIds) {
        this(logFileIds, 0);
    }
    
    /**
     * @description Constructeur avec compteur de tentatives
     * @param logFileIds Liste des IDs de fichiers journaux à traiter
     * @param retryCount Nombre de tentatives effectuées
     */
    private AsyncEventLogProcessor(List<Id> logFileIds, Integer retryCount) {
        this.logFileIds = logFileIds;
        this.retryCount = retryCount;
    }
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES PUBLIQUES                   │
    //└─────────────────────────────────────────┘
    /**
     * @description Point d'entrée pour le traitement asynchrone
     * @param context Contexte d'exécution Queueable
     */
    public void execute(QueueableContext context) {
        try {
            processLogFiles();
        } catch (Exception e) {
            handleExecutionError(e);
        }
    }
    
    /**
     * @description Démarre le traitement des fichiers journaux
     */
    public static void enqueueProcessing() {
        try {
            List<EventLogFile> allLogFiles = [
                SELECT Id 
                FROM EventLogFile 
                WHERE LogDate = LAST_N_DAYS:7
                ORDER BY LogDate DESC
            ];
            
            for (List<Id> chunk : splitIntoChunks(allLogFiles)) {
                System.enqueueJob(new AsyncEventLogProcessor(chunk));
            }
            
            System.debug(LoggingLevel.INFO, 'Traitement de ' + allLogFiles.size() + 
                        ' fichiers journaux mis en file d\'attente.');
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erreur lors de la mise en file d\'attente: ' + e.getMessage());
            throw new AsyncEventLogProcessorException('Erreur lors de la mise en file d\'attente', e);
        }
    }
    
    //┌─────────────────────────────────────────┐
    //│    MÉTHODES PRIVÉES                     │
    //└─────────────────────────────────────────┘
    /**
     * @description Traite les fichiers journaux
     */
    private void processLogFiles() {
        List<EventLogFile> logFiles = [
            SELECT Id, EventType, LogDate, LogFileLength 
            FROM EventLogFile 
            WHERE Id IN :logFileIds
        ];
        
        for (EventLogFile logFile : logFiles) {
            try {
                processLogFile(logFile);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Erreur lors du traitement du fichier ' + 
                           logFile.Id + ': ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Traite un fichier journal individuel
     * @param logFile Fichier journal à traiter
     */
    private void processLogFile(EventLogFile logFile) {
        String logContent = downloadEventLogFile(logFile.Id);
        if (String.isBlank(logContent)) return;
        
        List<Map<String, Object>> events = parseLogFileContent(logFile.EventType, logContent);
        for (Map<String, Object> event : events) {
            processEvent(event, logFile);
        }
    }
    
    /**
     * @description Traite un événement individuel
     * @param event Données de l'événement
     * @param logFile Fichier journal associé
     */
    private void processEvent(Map<String, Object> event, EventLogFile logFile) {
        String userId = (String)event.get('UserId');
        if (String.isBlank(userId)) {
            logEventProcessing(logFile, null, 'UserId non trouvé dans le contenu');
            return;
        }
        
        User relatedUser = getUserDetails(userId);
        if (relatedUser == null) {
            logEventProcessing(logFile, userId, 'Utilisateur non trouvé');
            return;
        }
        
        logEventProcessing(logFile, relatedUser);
    }
    
    /**
     * @description Télécharge le contenu d'un fichier journal
     * @param logFileId ID du fichier journal
     * @return Contenu du fichier journal
     */
    private static String downloadEventLogFile(Id logFileId) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(String.format(API_ENDPOINT, new List<String>{logFileId}));
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            
            HttpResponse res = new Http().send(req);
            return handleHttpResponse(res, logFileId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erreur lors du téléchargement du fichier ' + 
                        logFileId + ': ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Parse le contenu d'un fichier journal
     * @param eventType Type d'événement
     * @param logContent Contenu du fichier
     * @return Liste des événements parsés
     */
    private static List<Map<String, Object>> parseLogFileContent(String eventType, String logContent) {
        try {
            return parseJsonContent(logContent);
        } catch (JSONException je) {
            System.debug(LoggingLevel.WARN, 'Tentative de parsing CSV pour ' + eventType);
            return parseCsvContent(logContent);
        }
    }
    
    /**
     * @description Parse le contenu JSON
     * @param content Contenu à parser
     * @return Liste des événements parsés
     */
    private static List<Map<String, Object>> parseJsonContent(String content) {
        return (List<Map<String, Object>>)JSON.deserializeUntyped(content);
    }
    
    /**
     * @description Parse le contenu CSV
     * @param content Contenu à parser
     * @return Liste des événements parsés
     */
    private static List<Map<String, Object>> parseCsvContent(String content) {
        List<Map<String, Object>> events = new List<Map<String, Object>>();
        List<String> lines = content.split('\n');
        
        if (lines.isEmpty()) return events;
        
        List<String> headers = lines[0].split(',');
        for (Integer i = 1; i < lines.size(); i++) {
            Map<String, Object> event = parseCSVLine(lines[i], headers);
            if (!event.isEmpty()) {
                events.add(event);
            }
        }
        
        return events;
    }
    
    /**
     * @description Parse une ligne CSV
     * @param line Ligne à parser
     * @param headers En-têtes CSV
     * @return Map des valeurs parsées
     */
    private static Map<String, Object> parseCSVLine(String line, List<String> headers) {
        Map<String, Object> event = new Map<String, Object>();
        List<String> values = line.split(',');
        
        if (headers.size() != values.size()) return event;
        
        for (Integer i = 0; i < headers.size(); i++) {
            event.put(headers[i].trim(), values[i].trim());
        }
        
        return event;
    }
    
    /**
     * @description Récupère les détails d'un utilisateur
     * @param userId ID de l'utilisateur
     * @return Utilisateur trouvé ou null
     */
    private static User getUserDetails(String userId) {
        try {
            return [SELECT Id, Name, Email FROM User WHERE Id = :userId LIMIT 1];
        } catch (QueryException e) {
            return null;
        }
    }
    
    /**
     * @description Gère la réponse HTTP
     * @param response Réponse HTTP
     * @param logFileId ID du fichier journal
     * @return Contenu de la réponse ou null
     */
    private static String handleHttpResponse(HttpResponse response, Id logFileId) {
        if (response.getStatusCode() == 200) {
            return response.getBody();
        }
        
        System.debug(LoggingLevel.ERROR, 'Erreur HTTP ' + response.getStatusCode() + 
                    ' pour ' + logFileId + ': ' + response.getStatus());
        return null;
    }
    
    /**
     * @description Divise une liste en chunks
     * @param records Liste à diviser
     * @return Liste de chunks
     */
    private static List<List<Id>> splitIntoChunks(List<EventLogFile> records) {
        List<List<Id>> chunks = new List<List<Id>>();
        List<Id> currentChunk = new List<Id>();
        
        for (EventLogFile record : records) {
            currentChunk.add(record.Id);
            if (currentChunk.size() == CHUNK_SIZE) {
                chunks.add(currentChunk);
                currentChunk = new List<Id>();
            }
        }
        
        if (!currentChunk.isEmpty()) {
            chunks.add(currentChunk);
        }
        
        return chunks;
    }
    
    /**
     * @description Gère les erreurs d'exécution
     * @param e Exception à traiter
     */
    private void handleExecutionError(Exception e) {
        System.debug(LoggingLevel.ERROR, 'Erreur lors de l\'exécution: ' + e.getMessage());
        
        if (retryCount < MAX_RETRIES) {
            System.enqueueJob(new AsyncEventLogProcessor(logFileIds, retryCount + 1));
        } else {
            System.debug(LoggingLevel.ERROR, 'Nombre maximum de tentatives atteint pour les IDs: ' + 
                        String.join(logFileIds, ', '));
        }
    }
    
    /**
     * @description Journalise le traitement d'un événement
     * @param logFile Fichier journal
     * @param user Utilisateur associé
     */
    private void logEventProcessing(EventLogFile logFile, User user) {
        System.debug(LoggingLevel.INFO, 
            'Événement: ' + logFile.EventType + 
            ', Date: ' + logFile.LogDate + 
            ', Utilisateur: ' + user.Name + 
            ' (' + user.Id + ')'
        );
    }
    
    /**
     * @description Journalise le traitement d'un événement avec erreur
     * @param logFile Fichier journal
     * @param userId ID utilisateur
     * @param message Message d'erreur
     */
    private void logEventProcessing(EventLogFile logFile, String userId, String message) {
        System.debug(LoggingLevel.WARN,
            'Événement: ' + logFile.EventType +
            ', Date: ' + logFile.LogDate +
            (String.isNotBlank(userId) ? ', UserId: ' + userId : '') +
            ', Message: ' + message
        );
    }
    
    /**
     * @description Exception personnalisée pour le processeur
     */
    public class AsyncEventLogProcessorException extends Exception {}
} 