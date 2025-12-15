import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:credential_manager/credential_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final credentialManager = CredentialManager();
  if (credentialManager.isSupportedPlatform) {
    await credentialManager.init(
      preferImmediatelyAvailableCredentials: true,
    );
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter実験アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}

// メニュー画面
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー画面'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '検証用画面',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordRegisterScreen(),
                      ),
                    );
                  },
                  child: const Text('パスワード登録画面'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordUpdateScreen(),
                      ),
                    );
                  },
                  child: const Text('パスワード更新画面'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// パスワード登録画面
class PasswordRegisterScreen extends HookConsumerWidget {
  const PasswordRegisterScreen({super.key});

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
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
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
                        
                        await credentialManager.savePasswordCredentials(credential);
                        
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

// パスワード更新画面
class PasswordUpdateScreen extends HookConsumerWidget {
  const PasswordUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final isPasswordVisible = useState(false);
    final isConfirmPasswordVisible = useState(false);
    final hasExistingCredentials = useState(false);

    useEffect(() {
      // 既存の認証情報があるかチェック
      (() async {
        try {
          final credentialManager = CredentialManager();
          final credentials = await credentialManager.getCredentials(
            fetchOptions: FetchOptionsAndroid(
              passwordCredential: true,
              passKey: false,
              googleCredential: false,
            ),
          );
          if (credentials.passwordCredential != null && 
              credentials.passwordCredential!.username != null) {
            hasExistingCredentials.value = true;
            userIdController.text = credentials.passwordCredential!.username!;
          }
        } catch (e) {
          // 認証情報がない場合は何もしない
        }
      })();
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('パスワード更新'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasExistingCredentials.value) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.info, color: Colors.blue, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '既存のユーザー: ${userIdController.text}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Text('このユーザーのパスワードを更新します'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'ユーザーID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  hintText: '更新するユーザーIDを入力',
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: '新しいパスワード',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    isPasswordVisible.value = !isPasswordVisible.value;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: !isConfirmPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'パスワード確認',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    isConfirmPasswordVisible.value =
                        !isConfirmPasswordVisible.value;
                  },
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading.value
                  ? null
                  : () async {
                      if (userIdController.text.isEmpty ||
                          passwordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('すべてのフィールドを入力してください'),
                          ),
                        );
                        return;
                      }

                      if (passwordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('パスワードが一致しません'),
                          ),
                        );
                        return;
                      }

                      isLoading.value = true;
                      
                      try {
                        final credentialManager = CredentialManager();
                        final newCredential = PasswordCredential(
                          username: userIdController.text,
                          password: passwordController.text,
                        );
                        
                        await credentialManager.savePasswordCredentials(newCredential);
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'ユーザー「${userIdController.text}」のパスワードを更新しました',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('更新に失敗しました: $e'),
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
                  : const Text('更新'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
