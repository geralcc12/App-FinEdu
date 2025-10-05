import 'package:flutter/material.dart';
import '../models/learning_topic.dart';

final List<LearningTopic> learningTopics = [
  LearningTopic(
    id: 'ahorro',
    title: 'El Arte de Ahorrar',
    icon: Icons.savings_rounded,
    content: '''### ¿Por qué es importante ahorrar?

Ahorrar no es solo guardar el dinero que te sobra, ¡es el primer paso hacia tu libertad financiera! Es la base que te permite construir tus sueños, ya sea comprar algo que deseas, viajar, o estar preparado para cualquier imprevisto.

### Estrategias para Ahorrar

- **La Regla 50/30/20:** Es un presupuesto simple. 50% de tus ingresos para necesidades (renta, comida), 30% para deseos (cine, hobbies) y **20% directo al ahorro**.
- **Automatiza tu Ahorro:** Configura una transferencia automática a tu cuenta de ahorros cada vez que recibas dinero. Si no lo ves, ¡no lo extrañarás!
- **Págate a ti primero:** Antes de gastar en cualquier otra cosa, aparta tu meta de ahorro. Es la mejor inversión que puedes hacer.''',
    quiz: [
      QuizQuestion(
        question: 'Según la regla 50/30/20, ¿qué porcentaje de tus ingresos deberías dedicar al ahorro?',
        options: ['10%', '20%', '50%'],
        correctAnswerIndex: 1,
      ),
      QuizQuestion(
        question: '¿Qué significa el concepto "págate a ti primero"?',
        options: [
          'Gastar en lujos antes que nada',
          'Apartar tu porción de ahorro antes de realizar otros gastos',
          'Pagar todas tus deudas de inmediato'
        ],
        correctAnswerIndex: 1,
      ),
    ],
  ),
  LearningTopic(
    id: 'presupuesto',
    title: 'Crea tu Presupuesto',
    icon: Icons.calculate_rounded,
    content: '''### ¿Qué es un presupuesto?

Un presupuesto es simplemente un plan para tu dinero. Te dice a dónde va cada centavo, dándote el control total sobre tus finanzas. No es una camisa de fuerza, ¡es un mapa hacia tus metas!

### Pasos para crear tu primer presupuesto

1.  **Calcula tus Ingresos:** Suma todo el dinero que recibes al mes (propina, trabajos, etc.).
2.  **Rastrea tus Gastos:** Durante un mes, anota absolutamente todo en lo que gastas. Usa una app o una libreta. Te sorprenderás de los resultados.
3.  **Clasifica y Analiza:** Agrupa tus gastos en categorías (comida, transporte, entretenimiento). ¿En qué se te va más dinero? ¿Puedes reducir algo?
4.  **Establece Límites:** Asigna una cantidad máxima a cada categoría para el próximo mes. ¡Y cúmplela!''',
    quiz: [
      QuizQuestion(
        question: '¿Cuál es el primer paso para crear un presupuesto efectivo?',
        options: [
          'Rastrear tus gastos',
          'Establecer límites de gasto',
          'Calcular tus ingresos totales'
        ],
        correctAnswerIndex: 2,
      ),
      QuizQuestion(
        question: '¿Por qué es útil clasificar tus gastos?',
        options: [
          'Para sentirte culpable por tus compras',
          'Para identificar áreas donde puedes reducir gastos',
          'Para presumir de cuánto dinero gastas'
        ],
        correctAnswerIndex: 1,
      ),
    ],
  ),
  LearningTopic(
    id: 'interes-compuesto',
    title: 'La Magia del Interés Compuesto',
    icon: Icons.trending_up_rounded,
    content: '''### El secreto mejor guardado de las finanzas

Albert Einstein lo llamó la octava maravilla del mundo. El interés compuesto es el interés que ganas sobre el interés que ya ganaste.

Imagina que inviertes \$100 y ganas un 10% de interés en un año. Ahora tienes \$110. Al siguiente año, no ganas interés sobre los \$100 originales, sino sobre los \$110. ¡Tu dinero empieza a trabajar para ti!

### ¿Cómo te beneficia?

- **El tiempo es tu mejor amigo:** Cuanto antes empieces a ahorrar o invertir, más tiempo tendrá tu dinero para crecer exponencialmente.
- **Pequeñas acciones, grandes resultados:** Ahorrar \$20 a la semana puede no parecer mucho, pero gracias al interés compuesto, ¡puede convertirse en una fortuna en el futuro!''',
    quiz: [
      QuizQuestion(
        question: '¿Qué es el interés compuesto?',
        options: [
          'Un tipo de interés simple que se paga anualmente',
          'El interés que ganas sobre el capital inicial más los intereses acumulados',
          'Un impuesto sobre las ganancias de inversión'
        ],
        correctAnswerIndex: 1,
      ),
      QuizQuestion(
        question: '¿Cuál es el factor más crucial para maximizar los beneficios del interés compuesto?',
        options: ['La cantidad de dinero inicial', 'El tiempo', 'La suerte'],
        correctAnswerIndex: 1,
      ),
    ],
  ),
];
