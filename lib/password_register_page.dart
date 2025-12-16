import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:credential_manager/credential_manager.dart';

class PasswordRegisterPage extends HookConsumerWidget {
  const PasswordRegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワード登録'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: userIdController,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'ユーザーID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                helperText: 'パスワードフィールドをタップして強力なパスワードを生成',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      if (userIdController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ユーザーIDとパスワードを入力してください'),
                          ),
                        );
                        return;
                      }

                      isLoading.value = true;
                      
                      try {
                        // credential_managerを使ってパスワードを保存
                        final credentialManager = CredentialManager();
                        final credential = PasswordCredential(
                          username: userIdController.text,
                          password: passwordController.text,
                        );
                        
                        print('Attempting to save credentials...');
                        await credentialManager.savePasswordCredentials(credential);
                        print('Credentials saved successfully');
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ユーザー「${userIdController.text}」のパスワードを安全に保存しました',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        print('Failed to save credentials: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('保存に失敗しました: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        isLoading.value = false;
                      }
                    },
              child: isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('新規登録'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}