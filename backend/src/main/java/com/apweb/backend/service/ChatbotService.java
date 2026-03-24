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
import com.apweb.backend.repository.InformeTrabajoTecnicoRepository;
import com.apweb.backend.model.InformeTrabajoTecnico;
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

    @Autowired
    private InformeTrabajoTecnicoRepository informeRepository;

    private final RestTemplate restTemplate = new RestTemplate();

    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent?key=";

    private static final String SYSTEM_PROMPT = 
        "Eres 'Giri', el asistente virtual experto de soporte técnico de SGIRI. " +
        "Tu misión es ayudar a los clientes a resolver problemas con su servicio de Internet, basándote PRIMERO en el historial de soluciones exitosas de la empresa.\n\n" +
        "CONOCIMIENTO MAESTRO (Base de Datos de SGIRI):\n" +
        "A continuación se te proporcionarán ejemplos de reportes técnicos reales de incidencias pasadas y cómo se resolvieron. " +
        "Siempre que el problema del cliente coincida con algún reporte histórico, DEBES sugerir los pasos que el técnico aplicó en ese entonces.\n\n" +
        "REGLAS DE RESPUESTA:\n" +
        "1. PRIORIDAD: Usa el historial técnico adjunto antes que cualquier conocimiento general. No digas 'Busqué en nuestra base de datos', simplemente actúa como el experto que ya sabe la solución.\n" +
        "2. SALUDO: Sé amable. Saluda al cliente por su nombre si está disponible.\n" +
        "3. INTERACCIÓN: No escales a visita técnica de inmediato. Intenta guiar al usuario a través de 1 o 2 pasos de solución lógica basados en el conocimiento previo.\n" +
        "4. BOTONES: Siempre incluye botones de respuesta rápida al final: [BOT_BUTTONS: Sí, funcionó | Sigo sin internet | Hablar con un técnico].\n" +
        "5. ESCALADO: Si detectas que el problema requiere intervención física (ej: cambio de cable, equipo quemado) o el usuario no logra resolverlo tras tus sugerencias, ofrece el botón 'Solicitar Visita Técnica'.\n" +
        "6. CIERRE: Si el problema se resuelve, usa [RESOLUCION_SOPORTE] y el botón 'Finalizar chat'.\n" +
        "7. CONCISIÓN: Máximo 2 párrafos cortos.";


    public String getAiResponse(Ticket ticket, String clientMessage) {
        System.out.println("[CHATBOT_LOG] Getting AI response for Ticket #" + ticket.getIdTicket());
        if (apiKey == null || apiKey.isEmpty()) {
            System.err.println("[CHATBOT_LOG] API key is missing or empty!");
            return "ERROR: KEY_NOT_CONFIGURED";
        }

        // 1. Prepare context with RAG
        String context = buildContext(ticket, clientMessage);
        
        // 2. Call Gemini
        return callGemini(context);
    }

    private String buildContext(Ticket ticket, String currentMessage) {
        StringBuilder sb = new StringBuilder();
        
        // 1. Start with the Core Identity
        sb.append(SYSTEM_PROMPT).append("\n\n");
        
        // 2. Add Knowledge Base (RAG Part)
        sb.append("--- BASE DE CONOCIMIENTO TÉCNICO (Casos Reales de SGIRI) ---\n");
        List<InformeTrabajoTecnico> historico = informeRepository.findByResultado("RESUELTO");
        if (historico.isEmpty()) {
            sb.append("- No hay reportes técnicos previos aún.\n");
        } else {
            // Include only the last 10 historical cases to keep prompt size reasonable
            int limit = Math.min(historico.size(), 10);
            for (int i = 0; i < limit; i++) {
                InformeTrabajoTecnico inf = historico.get(i);
                sb.append("CASO ").append(i + 1).append(":\n");
                sb.append("- Problema hallado: ").append(inf.getProblemasEncontrados()).append("\n");
                sb.append("- Solución aplicada: ").append(inf.getSolucionAplicada()).append("\n");
                sb.append("- Detalle técnico: ").append(inf.getComentarioTecnico()).append("\n");
                sb.append("----------------------------\n");
            }
        }
        sb.append("\n");

        // 3. Current Ticket Context
        sb.append("--- CONTEXTO DEL CASO ACTUAL ---\n");
        String clientName = (ticket.getCliente() != null && ticket.getCliente().getPersona() != null) 
            ? ticket.getCliente().getPersona().getNombre() + " " + ticket.getCliente().getPersona().getApellido()
            : "Cliente Desconocido";
        sb.append("Nombre del Cliente: ").append(clientName).append("\n");
        sb.append("Asunto: ").append(ticket.getAsunto()).append("\n");
        sb.append("Descripción del problema: ").append(ticket.getDescripcion()).append("\n\n");
        
        // 4. Chat History
        sb.append("--- HISTORIAL DE ESTA CONVERSACIÓN ---\n");
        if (ticket.getComentarios() != null) {
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
            // LOG the full prompt
            System.out.println("--- PROMPT ENVIADO A GEMINI ---");
            System.out.println(prompt);
            System.out.println("--- FIN DEL PROMPT ---");

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
