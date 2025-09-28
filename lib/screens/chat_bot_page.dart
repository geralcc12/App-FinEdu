import 'package:flutter/material.dart';

// Colores (puedes ajustarlos o importarlos de tu archivo de tema)
const Color darkScaffoldBackground = Color(0xFF121212);
const Color darkCardBackground = Color(0xFF1E1E1E);
const Color darkPrimaryTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const Color accentColorGreen = Color(0xFF00D19A);
const Color userMessageColor = accentColorGreen;
const Color botMessageColor = Color(0xFF2C2C2C); // Un gris un poco más claro que el card

class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    required this.timestamp,
  });
}

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // Estado de la conversación para establecer metas
  String? _metaAmount;
  String? _metaDeadline;
  String? _metaReason;
  int _conversationStep = 0; // 0: inicio, 1: esperando monto, 2: esperando plazo, 3: esperando razón, 4: resumen

  @override
  void initState() {
    super.initState();
    _addBotMessage("¡Hola! Soy tu asistente FinEdu. 👋\n¿Te gustaría establecer una nueva meta de ahorro?");
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true, timestamp: DateTime.now()));
    });
    _scrollToBottom();

    // Lógica simulada del bot
    String userMessage = text.toLowerCase();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_conversationStep == 0) { // Inicio de conversación sobre metas
        if (userMessage.contains("si") || userMessage.contains("sí") || userMessage.contains("claro") || userMessage.contains("ok")) {
          _addBotMessage("¡Excelente! Para empezar, ¿cuánto te gustaría ahorrar? (Ej: 500 soles, 1000 dólares)");
          _conversationStep = 1;
        } else if (userMessage.contains("no")) {
          _addBotMessage("Entendido. Si cambias de opinión o necesitas ayuda con otra cosa, ¡no dudes en preguntar!");
           _conversationStep = 0; // Reiniciar o ir a un estado general
        } else {
          _addBotMessage("Disculpa, no te entendí bien. ¿Quieres establecer una meta de ahorro? (Sí/No)");
        }
      } else if (_conversationStep == 1) { // Esperando monto
        // Aquí podrías intentar extraer el monto con regex, por ahora tomamos el texto completo
        _metaAmount = text;
        _addBotMessage("¡Anotado: $_metaAmount! ¿Para qué fecha te gustaría haber alcanzado esta meta? (Ej: fin de mes, 3 meses, 31/12/2024)");
        _conversationStep = 2;
      } else if (_conversationStep == 2) { // Esperando plazo
        _metaDeadline = text;
        _addBotMessage("Perfecto: para el $_metaDeadline. ¿Hay alguna razón o algo específico para lo que estás ahorrando? (Ej: vacaciones, un nuevo celular, fondo de emergencia)");
        _conversationStep = 3;
      } else if (_conversationStep == 3) { // Esperando razón
        _metaReason = text;
        _addBotMessage("¡Entendido! Entonces, este es el plan:\n🎯 Meta: $_metaAmount\n🗓️ Plazo: $_metaDeadline\n💡 Razón: $_metaReason\n\n¿Confirmamos esta meta?");
        _conversationStep = 4;
      } else if (_conversationStep == 4) { // Esperando confirmación
        if (userMessage.contains("si") || userMessage.contains("sí") || userMessage.contains("confirmar")) {
          _addBotMessage("¡Meta guardada! 🎉 Puedes ver tus metas en la sección de 'Metas' (próximamente). ¡Mucho éxito!");
          // Aquí iría la lógica para guardar la meta realmente (Firestore, etc.)
          // Por ahora, reiniciamos la conversación de metas.
           _resetMetaConversation();
        } else {
          _addBotMessage("De acuerdo. Si quieres cambiar algo, podemos empezar de nuevo. ¿Deseas modificar la meta o cancelarla?");
          // Lógica para modificar o cancelar... por ahora reiniciamos.
           _resetMetaConversation();
        }
      } else {
          _addBotMessage("Estoy aquí para ayudarte con tus metas de ahorro. ¿En qué puedo asistirte?");
      }
    });
  }
  
  void _resetMetaConversation(){
      _conversationStep = 0;
      _metaAmount = null;
      _metaDeadline = null;
      _metaReason = null;
      // Podríamos añadir un mensaje como "¿Hay algo más en lo que pueda ayudarte?"
      // o volver al saludo inicial después de un delay.
       Future.delayed(const Duration(milliseconds: 800), () {
         _addBotMessage("¿Hay algo más en lo que pueda ayudarte con tus finanzas hoy?");
       });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text('Asistente FinEdu', style: TextStyle(color: darkPrimaryTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: darkCardBackground,
        elevation: 1,
        iconTheme: const IconThemeData(color: darkPrimaryTextColor),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final align = message.isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = message.isUserMessage ? userMessageColor.withOpacity(0.8) : botMessageColor;
    final textColor = message.isUserMessage ? Colors.black87 : darkPrimaryTextColor;
    final radius = message.isUserMessage
        ? const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(16.0),
            bottomLeft: Radius.circular(16.0),
            bottomRight: Radius.circular(16.0),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: align,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius,
            ),
            child: Text(message.text, style: TextStyle(color: textColor, fontSize: 15)),
          ),
          // Option to show timestamp (uncomment if desired)
          /*Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 10, right: 10),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(color: darkSecondaryTextColor, fontSize: 10),
            ),
          ),*/
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0), 
        decoration: BoxDecoration(
            color: darkCardBackground,
            borderRadius: BorderRadius.circular(25.0),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(color: darkSecondaryTextColor)
                ),
                style: const TextStyle(color: darkPrimaryTextColor),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: accentColorGreen),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
