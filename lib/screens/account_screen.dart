import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/google_identity.dart';
import '../services/progress_service.dart';
import '../widgets/ohymeku_design.dart';

class AccountScreen extends StatefulWidget {
  final ProgressService progress;
  final AccountService? service;
  const AccountScreen({super.key, required this.progress, this.service});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AccountService get account => widget.service ?? AccountService.shared;
  final _email = TextEditingController(), _password = TextEditingController();
  bool _register = false, _working = false;
  String? _message;
  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        setState(() => _message = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void initState() {
    super.initState();
    if (account.configured && account.googleAvailable) prepareGoogleIdentity();
  }

  void _say(String text) {
    if (mounted) setState(() => _message = text);
  }

  Future<void> _download() async {
    final j = await account.cloudProfile();
    if (j == null) {
      _say('У хмарі ще немає профілю. Спочатку збережи його.');
      return;
    }
    if (j['name'] is! String ||
        j['nickname'] is! String ||
        j['bio'] is! String ||
        j['avatar'] is! int ||
        j['avatarColor'] is! int) {
      throw StateError('Хмарний профіль пошкоджено. Локальні дані збережено.');
    }
    await widget.progress.saveProfile(j['name'], j['avatar'],
        nickname: j['nickname'], bio: j['bio'], avatarColor: j['avatarColor']);
    _say(
        'Профіль завантажено. Сюжет і навчальний прогрес на цьому пристрої збережено.');
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Твій акаунт')),
      body: SilkBackground(
          child: SafeArea(
              child: ListenableBuilder(
                  listenable: account,
                  builder: (context, _) =>
                      ListView(padding: const EdgeInsets.all(24), children: [
                        Text('Знайомі обличчя. На кожному пристрої.',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        const Text(
                            'Акаунт переносить ім’я, нік, опис та аватар. Історія, слова й навчальний прогрес поки зберігаються окремо на кожному пристрої. Вхід діє протягом поточної сесії.'),
                        const SizedBox(height: 24),
                        if (!account.configured)
                          const SilkPanel(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Акаунти ще не підключені',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(height: 12),
                                Text(
                                    'Профілем можна користуватися без реєстрації. Вхід з’явиться після налаштування Firebase власником застосунку.'),
                              ]))
                        else if (account.signedIn) ...[
                          Text(account.email ?? '',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          FilledButton(
                              onPressed: _working
                                  ? null
                                  : () => _run(() async {
                                        await account.cloudProfile(
                                            upload:
                                                widget.progress.profileData());
                                        _say('Профіль збережено у хмарі.');
                                      }),
                              child: const Text('Зберегти профіль у хмарі')),
                          const SizedBox(height: 12),
                          OutlinedButton(
                              onPressed:
                                  _working ? null : () => _run(_download),
                              child: const Text('Завантажити хмарний профіль')),
                          TextButton(
                              onPressed: _working
                                  ? null
                                  : () => _run(() async {
                                        await account.verifyEmail();
                                        _say(
                                            'Лист для підтвердження email надіслано. Після підтвердження вийди й увійди знову.');
                                      }),
                              child: const Text('Підтвердити email')),
                          TextButton(
                              onPressed: _working ? null : account.signOut,
                              child: const Text('Вийти з акаунта')),
                        ] else ...[
                          if (account.googleAvailable) ...[
                            OutlinedButton(
                              onPressed: _working
                                  ? null
                                  : () => _run(() async {
                                        if (await account
                                            .authenticateGoogle()) {
                                          _password.clear();
                                          _say(
                                              'Ти увійшов через Google. Обери, зберегти локальний профіль чи завантажити хмарний.');
                                        }
                                      }),
                              child: const Text('Продовжити з Google'),
                            ),
                            const SizedBox(height: 20),
                            const Center(child: Text('або через email')),
                            const SizedBox(height: 20),
                          ],
                          TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration:
                                  const InputDecoration(labelText: 'Email')),
                          const SizedBox(height: 16),
                          TextField(
                              controller: _password,
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                  labelText: 'Пароль',
                                  helperText: 'Від 8 символів')),
                          const SizedBox(height: 20),
                          FilledButton(
                              onPressed: _working
                                  ? null
                                  : () => _run(() async {
                                        await account.authenticate(
                                            _email.text, _password.text,
                                            register: _register);
                                        _password.clear();
                                        _say(_register
                                            ? 'Акаунт створено. Підтвердь email перед збереженням у хмарі.'
                                            : 'Ти увійшов. Обери, зберегти локальний профіль чи завантажити хмарний.');
                                      }),
                              child: Text(
                                  _register ? 'Створити акаунт' : 'Увійти')),
                          TextButton(
                              onPressed: _working
                                  ? null
                                  : () =>
                                      setState(() => _register = !_register),
                              child: Text(_register
                                  ? 'Вже є акаунт? Увійти'
                                  : 'Створити новий акаунт')),
                          TextButton(
                              onPressed: _working
                                  ? null
                                  : () => _run(() async {
                                        await account
                                            .resetPassword(_email.text);
                                        _say(
                                            'Якщо адреса зареєстрована, на неї надійде лист для відновлення.');
                                      }),
                              child: const Text('Забув пароль')),
                        ],
                        if (_working) const LinearProgressIndicator(),
                        if (_message != null)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(_message!)),
                      ])))));
}
