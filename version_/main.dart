import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/python.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Skeleton Editor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const EditorPage(),
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late CodeController _codeController;
  final List<String> _skeletonLines = [
    '# ==================== 模块导入 ====================',
    'import module_1',
    'import module_2',
    'import module_3',
    '',
    '# ==================== 全局变量 ====================',
    'vector_1 = ""  # 🟢 [输入参数] 待定义',
    'vector_2 = ""  # 🟢 [输入参数] 待定义',
    'vector_3 = ""  # 🔵 [输出参数] 待定义',
    '',
    '# ==================== 函数1：数据加载 ====================',
    'def load_data(🟢file_path: str) -> 🔵data:',
    '    # [待实现] 数据加载逻辑',
    '    return data',
    '',
    '# ==================== 函数2：数据处理 ====================',
    'def process_data(🟢data, 🟢action: str) -> 🔵processed_data:',
    '    # [待实现] 数据处理逻辑',
    '    return processed_data',
    '',
    '# ==================== 函数3：结果输出 ====================',
    'def save_result(🟢processed_data, 🟢output_path: str) -> None:',
    '    # [待实现] 结果输出逻辑',
    '    pass',
    '',
    '# ==================== 命令行参数 ====================',
    '# -i: 输入文件路径',
    '# -o: 输出文件路径',
    '# -a: 操作类型 (process/analyze)',
    '',
    '# ==================== 主程序入口 ====================',
    'if __name__ == "__main__":',
    '    # [待实现] 主流程编排',
    '    pass',
  ];

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: _skeletonLines.join('\n'),
      language: python,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _insertSnippet(String snippet) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final cursorPos = selection.baseOffset;

    // 计算当前行缩进
    int lineStart = text.lastIndexOf('\n', cursorPos - 1);
    if (lineStart == -1) lineStart = 0;
    String currentLine = text.substring(lineStart, cursorPos);
    RegExp indentReg = RegExp(r'^(\s*)');
    String indent = indentReg.firstMatch(currentLine)?.group(1) ?? '';

    // 缩进处理
    String indentedSnippet = snippet.split('\n').map((line) {
      return line.isEmpty ? line : indent + line;
    }).join('\n');

    // 插入
    final newText = text.replaceRange(
      cursorPos,
      cursorPos,
      indentedSnippet,
    );
    _codeController.text = newText;

    // 移动光标到插入内容的末尾
    final newCursorPos = cursorPos + indentedSnippet.length;
    _codeController.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧大纲面板
          Container(
            width: 250,
            color: const Color(0xFF252526),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '📑 代码大纲',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: const [
                      _OutlineItem('模块导入', Icons.import_export),
                      _OutlineItem('全局变量', Icons.storage),
                      _OutlineItem('load_data', Icons.folder_open),
                      _OutlineItem('process_data', Icons.analytics),
                      _OutlineItem('save_result', Icons.save),
                      _OutlineItem('命令行参数', Icons.terminal),
                      _OutlineItem('主程序入口', Icons.play_arrow),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 中间代码编辑区
          Expanded(
            child: Column(
              children: [
                // 工具栏
                Container(
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFF2D2D30),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _ToolButton('for循环', () => _insertSnippet(_forSnippet)),
                      _ToolButton('if判断', () => _insertSnippet(_ifSnippet)),
                      _ToolButton('打开文件', () => _insertSnippet(_openFileSnippet)),
                      _ToolButton('字典操作', () => _insertSnippet(_dictSnippet)),
                      _ToolButton('添加参数', () => _insertSnippet(_argSnippet)),
                    ],
                  ),
                ),
                // 代码编辑区
                Expanded(
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右侧参数面板
          Container(
            width: 280,
            color: const Color(0xFF252526),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚙️ 参数配置',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('输入参数 (🟢)', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                _ParamChip('file_path', Colors.green),
                _ParamChip('action', Colors.green),
                const SizedBox(height: 16),
                const Text('输出参数 (🔵)', style: TextStyle(color: Colors.blue)),
                const SizedBox(height: 8),
                _ParamChip('data', Colors.blue),
                _ParamChip('processed_data', Colors.blue),
                const SizedBox(height: 16),
                const Text('命令行参数', style: TextStyle(color: Colors.purple)),
                const SizedBox(height: 8),
                _ParamChip('-i / --input', Colors.purple),
                _ParamChip('-o / --output', Colors.purple),
                _ParamChip('-a / --action', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 代码片段模板
  final String _forSnippet = '''
for item in collection:
    # [循环体待实现]
    pass
''';

  final String _ifSnippet = '''
if condition:
    # [条件成立时执行]
    pass
else:
    # [条件不成立时执行]
    pass
''';

  final String _openFileSnippet = '''
with open(file_path, 'r') as f:
    content = f.read()
    # [处理文件内容]
''';

  final String _dictSnippet = '''
# 字典操作示例
my_dict = {}
my_dict['key'] = 'value'
value = my_dict.get('key', 'default')
''';

  final String _argSnippet = '''
parser.add_argument("-i", "--input", help="输入文件路径")
parser.add_argument("-o", "--output", help="输出文件路径")
parser.add_argument("-a", "--action", choices=["process", "analyze"])
''';
}

// 大纲条目组件
class _OutlineItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const _OutlineItem(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 18, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      dense: true,
      onTap: () {
        // TODO: 跳转到对应代码行
      },
    );
  }
}

// 工具栏按钮
class _ToolButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ToolButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0E639C),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// 参数芯片组件
class _ParamChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ParamChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
