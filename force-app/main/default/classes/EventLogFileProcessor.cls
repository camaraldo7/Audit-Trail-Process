/**
 * @description       : Voici une classe Apex qui gère la récupération des fichiers journaux d'événements, 
 *                      le téléchargement de leur contenu et une tentative d'extraction des informations utilisateur (en se basant sur la présence 
 *                      d'un champ UserId dans le contenu du journal). Garde à l'esprit que l'extraction des informations 
 *                      utilisateur peut varier considérablement en fonction du type d'événement.
 * @author            : Mamadou Lamine CAMARA
 * @group             : 
 * @last modified on  : 20-04-2025 
 * @last modified by  : Mamadou Lamine CAMARA
**/

public class EventLogFileProcessor {

    public static void processEventLogs() {
        List<EventLogFile> eventLogFiles = [SELECT Id, EventType, LogDate, LogFileLength 
                                            FROM EventLogFile 
                                            ORDER BY LogDate 
                                            DESC LIMIT 10]; // Limiter pour éviter les traitements trop longs

        for (EventLogFile logFile : eventLogFiles) {
            String logFileContent = downloadEventLogFile(logFile.Id);
            if (!String.isEmpty(logFileContent)) {
                List<Map<String, Object>> events = parseLogFileContent(logFile.EventType, logFileContent);
                for (Map<String, Object> event : events) {
                    String userId = (String) event.get('UserId'); // Tenter de récupérer l'UserId

                    if (!String.isEmpty(userId)) {
                        User relatedUser = getUserDetails(userId);
                        if (relatedUser != null) {
                            System.debug('Événement: ' + logFile.EventType + ', Date: ' + logFile.LogDate + ', Utilisateur: ' + relatedUser.Name + ' (' + relatedUser.Id + ')');
                            // Tu peux stocker ces informations dans un objet personnalisé, une liste, etc.
                        } else {
                            System.debug('Événement: ' + logFile.EventType + ', Date: ' + logFile.LogDate + ', UserId trouvé: ' + userId + ' mais utilisateur non trouvé.');
                        }
                    } else {
                        System.debug('Événement: ' + logFile.EventType + ', Date: ' + logFile.LogDate + ', UserId non trouvé dans le contenu.');
                        // Gérer les événements où l'UserId n'est pas directement disponible
                    }
                }
            } else {
                System.debug('Impossible de télécharger le contenu du fichier journal: ' + logFile.Id);
            }
        }
    }

    private static String downloadEventLogFile(Id logFileId) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('/services/data/v59.0/sobjects/EventLogFile/' + logFileId + '/LogFile'); // Adapter la version de l'API si nécessaire
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json'); // Le contenu est souvent en JSON

            HttpResponse res = new Http().send(req);

            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                System.debug('Erreur lors du téléchargement du fichier journal ' + logFileId + ': ' + res.getStatusCode() + ' - ' + res.getStatus());
                return null;
            }
        } catch (Exception e) {
            System.debug('Erreur lors de la tentative de téléchargement du fichier journal ' + logFileId + ': ' + e.getMessage());
            return null;
        }
    }

    private static List<Map<String, Object>> parseLogFileContent(String eventType, String logFileContent) {
        List<Map<String, Object>> events = new List<Map<String, Object>>();
        try {
            // Tenter de parser comme du JSON (format courant pour les EventLogFile)
            events = (List<Map<String, Object>>) JSON.deserializeUntyped(logFileContent);
        } catch (JSONException e) {
            System.debug('Le contenu du fichier journal pour le type ' + eventType + ' n\'est pas au format JSON standard. Tentative de parsing ligne par ligne (CSV?).');
            // Si ce n'est pas du JSON, tenter de parser ligne par ligne (peut-être du CSV)
            List<String> lines = logFileContent.split('\n');
            if (!lines.isEmpty()) {
                List<String> headers = lines[0].split(','); // Supposer des virgules comme séparateur
                for (Integer i = 1; i < lines.size(); i++) {
                    List<String> values = lines[i].split(',');
                    if (headers.size() == values.size()) {
                        Map<String, Object> event = new Map<String, Object>();
                        for (Integer j = 0; j < headers.size(); j++) {
                            event.put(headers[j].trim(), values[j].trim());
                        }
                        events.add(event);
                    }
                }
            }
        }
        return events;
    }

    private static User getUserDetails(String userId) {
        try {
            return [SELECT Id, Name, Email FROM User WHERE Id = :userId];
        } catch (QueryException e) {
            System.debug('Utilisateur non trouvé avec l\'ID: ' + userId + ' - ' + e.getMessage());
            return null;
        }
    }
}