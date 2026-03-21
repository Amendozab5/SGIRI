package com.apweb.backend.service;

import com.apweb.backend.model.ComentarioTicket;
import com.apweb.backend.model.Ticket;
import com.apweb.backend.model.User;
import com.apweb.backend.repository.UserRepository;
import com.apweb.backend.repository.CatalogoItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.apweb.backend.repository.RoleRepository;
import java.util.*;

@Service
public class ChatbotService {

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private CatalogoItemRepository catalogoItemRepository;

    private final RestTemplate restTemplate = new RestTemplate();

    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=";

    private static final String SYSTEM_PROMPT = 
        "Eres 'Giri', el asistente virtual de soporte técnico de SGIRI. " +
        "Tu personalidad es amable, servicial y ligeramente tecnológica (puedes usar algún emoji ocasionalmente). " +
        "Tu objetivo es ayudar al cliente a resolver problemas de internet remotamente.\n\n" +
        "REGLAS DE RESPUESTA:\n" +
        "1. SALUDO: Si el usuario te saluda, salúdalo amablemente por su nombre (si lo sabes) o como 'estimado cliente'.\n" +
        "2. BOTONES: Siempre que ofrezcas opciones o pasos a seguir, añade al final de tu mensaje una lista de botones en este formato exacto: " +
        "[BOT_BUTTONS: Opción 1 | Opción 2 | Opción 3]. Esto ayuda al usuario a responder rápido.\n" +
        "3. RESTRICCIÓN: Solo hablas de servicios de internet/red de SGIRI. Si preguntan otra cosa, declina amablemente.\n" +
        "4. ESCALADO: Si detectas un daño físico irreparable (cables rotos, equipos quemados) o si el usuario pide un humano tras 2 intentos fallidos, informa al usuario que el caso requiere ser atendido presencialmente por un técnico en sitio. Usa el botón 'Solicitar Visita Técnica' y añade la etiqueta: [ESCALAR_HUMANO].\n" +
        "5. Sé conciso: Máximo 2 párrafos cortos por respuesta.";

    public String getAiResponse(Ticket ticket, String clientMessage) {
        System.out.println("[CHATBOT_LOG] Getting AI response for Ticket #" + ticket.getIdTicket());
        if (apiKey == null || apiKey.isEmpty()) {
            System.err.println("[CHATBOT_LOG] API key is missing or empty!");
            return "ERROR: KEY_NOT_CONFIGURED";
        }

        // 1. Prepare context
        String context = buildContext(ticket, clientMessage);
        System.out.println("[CHATBOT_LOG] Context built. Size: " + context.length());

        // 2. Call Gemini
        String response = callGemini(context);
        System.out.println("[CHATBOT_LOG] AI Response received (first 50 chars): " + (response.length() > 50 ? response.substring(0, 50) : response));
        return response;
    }

    private String buildContext(Ticket ticket, String currentMessage) {
        StringBuilder sb = new StringBuilder();
        sb.append(SYSTEM_PROMPT).append("\n\n");
        sb.append("Detalles del Ticket:\n");
        sb.append("Asunto: ").append(ticket.getAsunto()).append("\n");
        sb.append("Descripción Inicial: ").append(ticket.getDescripcion()).append("\n\n");
        sb.append("Historial de chat:\n");

        if (ticket.getComentarios() != null) {
            // Sort comments by date to ensure context order
            List<ComentarioTicket> comments = new ArrayList<>(ticket.getComentarios());
            comments.sort(Comparator.comparing(ComentarioTicket::getFechaCreacion));
            
            for (ComentarioTicket c : comments) {
                if (c.getVisibleParaCliente() != null && c.getVisibleParaCliente()) {
                    String sender = (c.getUsuario() != null && "SOPORTE_IA".equals(c.getUsuario().getUsername())) ? "BOT" : "CLIENTE";
                    sb.append(sender).append(": ").append(c.getComentario()).append("\n");
                }
            }
        }
        sb.append("CLIENTE: ").append(currentMessage).append("\n");
        sb.append("BOT: ");
        return sb.toString();
    }

    private String callGemini(String prompt) {
        try {
            String url = GEMINI_URL + apiKey;

            Map<String, Object> part = new HashMap<>();
            part.put("text", prompt);

            Map<String, Object> content = new HashMap<>();
            content.put("parts", Collections.singletonList(part));

            Map<String, Object> body = new HashMap<>();
            body.put("contents", Collections.singletonList(content));

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

            @SuppressWarnings("unchecked")
            ResponseEntity<Map<String, Object>> response = (ResponseEntity<Map<String, Object>>) (ResponseEntity<?>) restTemplate.postForEntity(url, entity, Map.class);

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> candidates = (List<Map<String, Object>>) response.getBody().get("candidates");
                
                if (candidates != null && !candidates.isEmpty()) {
                    Map<String, Object> firstCandidate = candidates.get(0);
                    
                    @SuppressWarnings("unchecked")
                    Map<String, Object> contentObj = (Map<String, Object>) firstCandidate.get("content");
                    
                    if (contentObj != null) {
                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> parts = (List<Map<String, Object>>) contentObj.get("parts");
                        
                        if (parts != null && !parts.isEmpty()) {
                            Map<String, Object> firstPart = parts.get(0);
                            return (String) firstPart.get("text");
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Gemini Error: " + e.getMessage());
            return "Lo siento, estoy experimentando dificultades técnicas. Por favor, intenta de nuevo o solicita un técnico.";
        }
        return "No pude procesar tu solicitud en este momento.";
    }

    public User getOrCreateBotUser() {
        return userRepository.findByUsername("SOPORTE_IA").orElseGet(() -> {
            System.out.println("[CHATBOT_LOG] Creating new bot user: SOPORTE_IA");
            User bot = new User();
            bot.setUsername("SOPORTE_IA");
            bot.setPassword("SYSTEM_ONLY");
            
            // Assign ADMIN_MASTER role (id 4 or find by code)
            roleRepository.findByCodigo("ADMIN_MASTER").ifPresentOrElse(
                bot::setRole,
                () -> roleRepository.findAll().stream().findFirst().ifPresent(bot::setRole)
            );
            
            // Assign ACTIVO state from ESTADO_USUARIO catalog
            catalogoItemRepository.findFirstByCodigo("ACTIVO")
                .ifPresentOrElse(
                    bot::setEstado,
                    () -> catalogoItemRepository.findAll().stream().findFirst().ifPresent(bot::setEstado)
                );
            
            User savedBot = userRepository.save(bot);
            System.out.println("[CHATBOT_LOG] Bot user created with ID: " + savedBot.getId());
            return savedBot;
        });
    }
}
