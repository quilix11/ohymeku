class PhraseDelivery {
  final String title, intent;
  final DeliveryLine casual, polite;

  const PhraseDelivery(this.title, this.intent, this.casual, this.polite);

  List<DeliveryLine> get lines => [casual, polite];
}

class DeliveryLine {
  final String audience, english, translation, explanation;

  const DeliveryLine(
      this.audience, this.english, this.translation, this.explanation);
}

const phraseDeliveries = {
  'j13': PhraseDelivery(
    'Як знайти стежку',
    'Запитай, де починається нижня стежка.',
    DeliveryLine(
        'Другові в чаті',
        'Hey, where does the lower trail start?',
        'Привіт, де починається нижня стежка?',
        'Hey звучить невимушено. Пряме запитання з does природне в короткому чаті.'),
    DeliveryLine(
        'Працівниці вокзалу',
        'Could you tell me where the lower trail starts?',
        'Підкажіть, будь ласка, де починається нижня стежка.',
        'Could you tell me…? пом’якшує запитання. Усередині фрази кажемо the trail starts.'),
  ),
  'j14': PhraseDelivery(
    'Ще одна ковдра',
    'Попроси принести додаткову ковдру.',
    DeliveryLine(
        'Другові в кімнаті',
        'Can you grab me another blanket?',
        'Можеш захопити мені ще одну ковдру?',
        'Grab me звучить розмовно й доречне між друзями.'),
    DeliveryLine(
        'Доглядачу притулку',
        'Could you bring me an extra blanket, please?',
        'Принесіть мені, будь ласка, ще одну ковдру.',
        'Could you… please? ввічливо формулює прохання до працівника.'),
  ),
  'j15': PhraseDelivery(
    'Зміна маршруту',
    'Попередь, що через туман треба йти нижньою стежкою.',
    DeliveryLine(
        'Другові в чаті',
        'It’s foggy. Let’s take the lower trail.',
        'Туманно. Ходімо нижньою стежкою.',
        'Let’s підходить для спільного рішення з другом.'),
    DeliveryLine(
        'Групі незнайомих мандрівників',
        'Due to the fog, please use the lower trail.',
        'Через туман ідіть, будь ласка, нижньою стежкою.',
        'Due to називає причину, а please use дає чітку вказівку групі.'),
  ),
  'j16': PhraseDelivery(
    'Звістка для поста',
    'Попроси передати, що ви зустрінетеся біля мосту о п’ятій.',
    DeliveryLine(
        'Другові в груповому чаті',
        'Can you let them know we’ll meet at the bridge at five?',
        'Можеш сказати їм, що ми зустрінемося біля мосту о п’ятій?',
        'Let them know — розмовний спосіб попросити переказати новину.'),
    DeliveryLine(
        'Черговій сигнального поста',
        'Please relay this message: we will meet at the bridge at five.',
        'Передайте, будь ласка, це повідомлення: ми зустрінемося біля мосту о п’ятій.',
        'Relay this message явно відділяє прохання від тексту, який треба передати.'),
  ),
  'j17': PhraseDelivery(
    'Оновлення про ремонт',
    'Скажи, що приймач уже працює, а запасну батарею ще не перевірили.',
    DeliveryLine(
        'Другові з команди',
        'The receiver’s working now, but we haven’t checked the spare battery yet.',
        'Приймач уже працює, але запасну батарею ми ще не перевірили.',
        'Скорочення receiver’s і haven’t природно звучать у розмові.'),
    DeliveryLine(
        'У записі для наступної зміни',
        'The receiver is operational. The spare battery has not yet been tested.',
        'Приймач працює. Запасну батарею ще не перевірено.',
        'Operational і has not yet been tested підходять для короткого технічного запису.'),
  ),
  'j18': PhraseDelivery(
    'Перевір час ефіру',
    'Уточни, чи трансляція починається о шостій.',
    DeliveryLine(
        'Другові телефоном',
        'Just checking: we go live at six, right?',
        'Уточнюю: ми виходимо в ефір о шостій, так?',
        'Just checking і right? природно звучать у швидкій дружній розмові.'),
    DeliveryLine(
        'Координаторці ефіру',
        'Could you confirm that the broadcast starts at six?',
        'Підтвердьте, будь ласка, що трансляція починається о шостій.',
        'Could you confirm…? прямо вказує, яке підтвердження потрібне.'),
  ),
};
